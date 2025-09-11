class ApiController < ApplicationController
  # GET /api/health
  def health
    render json: { status: 'ok', timestamp: Time.current }
  end

  # @route GET /api/version
  def version
    render json: { version: '1.0.0' }
  end

  # @api {post} /api/authenticate Authenticate user
  def authenticate
    # Authentication logic here
    render json: { token: 'jwt_token' }
  end

  # @method POST /api/refresh
  def refresh_token
    # Token refresh logic
    render json: { token: 'new_jwt_token' }
  end

  # Custom endpoint not following REST conventions
  # POST /api/bulk-import
  def bulk_import
    # Bulk import logic
    render json: { message: 'Import started' }
  end

  # GET /api/stats/daily
  def daily_stats
    render json: { stats: 'daily data' }
  end
end