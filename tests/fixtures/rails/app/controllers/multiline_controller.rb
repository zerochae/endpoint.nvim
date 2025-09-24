# Rails multiline route examples for testing endpoint detection
class MultilineController < ApplicationController
  before_action :authenticate_user!, except: [:health]

  # Test case 1: Simple multiline method definition
  def index
    @users = User.all
    render json: @users
  end

  # Test case 2: Complex multiline method with parameters
  def show
    @user = User.find(params[:id])
    if @user
      render json: @user
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # Test case 3: Multiline create method
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  # Test case 4: Complex multiline update method
  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # Test case 5: Multiline destroy method
  def destroy
    @user = User.find(params[:id])

    if @user.destroy
      head :no_content
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # Test case 6: Custom multiline action methods
  def profile
    @user = User.find(params[:id])
    @profile = @user.profile

    render json: {
      user: @user,
      profile: @profile,
      additional_info: calculate_user_stats(@user)
    }
  end

  def search
    query = params[:q]
    @users = User.where(
      "name ILIKE ? OR email ILIKE ?",
      "%#{query}%",
      "%#{query}%"
    ).limit(20)

    render json: @users
  end

  def like
    @user = User.find(params[:id])
    @current_user = current_user

    if @current_user.like(@user)
      render json: { message: 'User liked successfully' }
    else
      render json: { error: 'Unable to like user' }, status: :unprocessable_entity
    end
  end

  def share
    @user = User.find(params[:id])
    share_service = UserShareService.new(@user, current_user)

    if share_service.perform
      render json: {
        message: 'User shared successfully',
        share_url: share_service.share_url
      }
    else
      render json: { error: 'Unable to share user' }, status: :unprocessable_entity
    end
  end

  def unlike
    @user = User.find(params[:id])
    @current_user = current_user

    if @current_user.unlike(@user)
      render json: { message: 'User unliked successfully' }
    else
      render json: { error: 'Unable to unlike user' }, status: :unprocessable_entity
    end
  end

  # Test case 7: Complex multiline method with multiple conditions
  def update_status
    @user = User.find(params[:id])
    new_status = params[:status]
    reason = params[:reason]

    case new_status
    when 'active'
      if @user.activate!(reason)
        render json: { message: 'User activated', status: @user.status }
      else
        render json: { error: 'Unable to activate user' }, status: :unprocessable_entity
      end
    when 'inactive'
      if @user.deactivate!(reason)
        render json: { message: 'User deactivated', status: @user.status }
      else
        render json: { error: 'Unable to deactivate user' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid status' }, status: :bad_request
    end
  end

  # Test case 8: Health check endpoint (typically in routes but shown here)
  def health
    render json: {
      status: 'ok',
      timestamp: Time.current,
      version: Rails.application.version
    }
  end

  private

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :bio,
      :avatar,
      profile_attributes: [
        :first_name,
        :last_name,
        :phone,
        :address
      ]
    )
  end

  def authenticate_user!
    head :unauthorized unless current_user
  end

  def current_user
    @current_user ||= User.find_by(
      id: request.headers['X-User-ID']
    )
  end

  def calculate_user_stats(user)
    {
      posts_count: user.posts.count,
      followers_count: user.followers.count,
      following_count: user.following.count,
      last_login: user.last_sign_in_at
    }
  end
end

# Supporting service class
class UserShareService
  def initialize(user, current_user)
    @user = user
    @current_user = current_user
  end

  def perform
    # Complex sharing logic here
    generate_share_url
    send_notifications
    update_share_count
    true
  rescue => e
    Rails.logger.error "Share failed: #{e.message}"
    false
  end

  def share_url
    @share_url ||= Rails.application.routes.url_helpers.user_url(
      @user,
      host: Rails.application.config.default_url_options[:host]
    )
  end

  private

  def generate_share_url
    # URL generation logic
  end

  def send_notifications
    # Notification logic
  end

  def update_share_count
    # Share count update logic
  end
end