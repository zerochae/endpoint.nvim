# frozen_string_literal: true

# Webhooks Controller for handling external service callbacks
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_signature, except: [:mailgun]

  # POST /webhooks/github
  def github
    case request.headers['X-GitHub-Event']
    when 'push'
      handle_github_push
    when 'pull_request'
      handle_github_pr
    when 'issues'
      handle_github_issue
    else
      head :ok
    end
  end

  # POST /webhooks/stripe
  def stripe
    case params[:type]
    when 'payment_intent.succeeded'
      handle_payment_success
    when 'payment_intent.payment_failed'
      handle_payment_failure
    when 'customer.subscription.created'
      handle_subscription_created
    when 'customer.subscription.deleted'
      handle_subscription_deleted
    else
      head :ok
    end
  end

  # POST /webhooks/mailgun
  def mailgun
    verify_mailgun_signature!
    
    case params['event-data']['event']
    when 'delivered'
      handle_email_delivered
    when 'opened'
      handle_email_opened
    when 'clicked'
      handle_email_clicked
    when 'bounced'
      handle_email_bounced
    when 'complained'
      handle_email_complained
    else
      head :ok
    end
  end

  private

  def verify_webhook_signature
    case action_name
    when 'github'
      verify_github_signature!
    when 'stripe'
      verify_stripe_signature!
    end
  end

  def verify_github_signature!
    signature = request.headers['X-Hub-Signature-256']
    return head :unauthorized unless signature

    expected_signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', Rails.application.credentials.github_webhook_secret, request.raw_post)}"
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  end

  def verify_stripe_signature!
    payload = request.raw_post
    sig_header = request.headers['Stripe-Signature']
    endpoint_secret = Rails.application.credentials.stripe_webhook_secret

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue Stripe::SignatureVerificationError
      head :unauthorized
    end
  end

  def verify_mailgun_signature!
    timestamp = params['signature']['timestamp']
    token = params['signature']['token'] 
    signature = params['signature']['signature']
    
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', Rails.application.credentials.mailgun_webhook_secret, "#{timestamp}#{token}")
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
  end

  def handle_github_push
    # Handle GitHub push webhook
    repository = params[:repository][:name]
    pusher = params[:pusher][:name]
    commits = params[:commits]
    
    # Process the push event
    Rails.logger.info "GitHub push to #{repository} by #{pusher}, #{commits.size} commits"
    head :ok
  end

  def handle_github_pr
    # Handle GitHub pull request webhook
    action = params[:action]
    pr = params[:pull_request]
    
    Rails.logger.info "GitHub PR #{action}: #{pr[:title]}"
    head :ok
  end

  def handle_github_issue
    # Handle GitHub issue webhook
    action = params[:action]
    issue = params[:issue]
    
    Rails.logger.info "GitHub issue #{action}: #{issue[:title]}"
    head :ok
  end

  def handle_payment_success
    payment_intent = params[:data][:object]
    # Process successful payment
    Rails.logger.info "Payment succeeded: #{payment_intent[:id]}"
    head :ok
  end

  def handle_payment_failure
    payment_intent = params[:data][:object]
    # Process failed payment
    Rails.logger.info "Payment failed: #{payment_intent[:id]}"
    head :ok
  end

  def handle_subscription_created
    subscription = params[:data][:object]
    # Process new subscription
    Rails.logger.info "Subscription created: #{subscription[:id]}"
    head :ok
  end

  def handle_subscription_deleted
    subscription = params[:data][:object]
    # Process cancelled subscription
    Rails.logger.info "Subscription deleted: #{subscription[:id]}"
    head :ok
  end

  def handle_email_delivered
    message_data = params['event-data']['message']
    Rails.logger.info "Email delivered: #{message_data['headers']['subject']}"
    head :ok
  end

  def handle_email_opened
    message_data = params['event-data']['message']
    Rails.logger.info "Email opened: #{message_data['headers']['subject']}"
    head :ok
  end

  def handle_email_clicked
    message_data = params['event-data']['message']
    url = params['event-data']['url']
    Rails.logger.info "Email clicked: #{message_data['headers']['subject']}, URL: #{url}"
    head :ok
  end

  def handle_email_bounced
    message_data = params['event-data']['message']
    Rails.logger.info "Email bounced: #{message_data['headers']['subject']}"
    head :ok
  end

  def handle_email_complained
    message_data = params['event-data']['message']
    Rails.logger.info "Email complained: #{message_data['headers']['subject']}"
    head :ok
  end
end