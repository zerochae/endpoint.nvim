module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_admin!

    # GET /admin/dashboard  
    def index
      @stats = {
        users_count: User.count,
        posts_count: Post.count,
        comments_count: Comment.count,
        revenue: calculate_revenue
      }
      
      render json: @stats
    end

    # GET /admin/dashboard/analytics
    def analytics
      @analytics = {
        daily_signups: User.where(created_at: 1.week.ago..Time.current).group_by_day(:created_at).count,
        popular_posts: Post.order(views_count: :desc).limit(10),
        user_activity: calculate_user_activity
      }
      
      render json: @analytics
    end

    # POST /admin/dashboard/maintenance
    def maintenance
      if params[:enabled]
        Rails.cache.write('maintenance_mode', true)
        message = 'Maintenance mode enabled'
      else
        Rails.cache.delete('maintenance_mode')
        message = 'Maintenance mode disabled'
      end
      
      render json: { message: message }
    end

    # GET /admin/dashboard/health
    def health
      health_status = {
        database: database_healthy?,
        redis: redis_healthy?,
        storage: storage_healthy?,
        timestamp: Time.current
      }
      
      status_code = health_status.values.all? ? :ok : :service_unavailable
      render json: health_status, status: status_code
    end

    # POST /admin/dashboard/backup
    def backup
      BackupJob.perform_later
      render json: { message: 'Backup started' }
    end

    private

    def authenticate_admin!
      redirect_to root_path unless current_user&.admin?
    end

    def calculate_revenue
      # Mock calculation
      rand(10000..50000)
    end

    def calculate_user_activity
      {
        active_today: User.where('last_seen_at > ?', 1.day.ago).count,
        active_this_week: User.where('last_seen_at > ?', 1.week.ago).count
      }
    end

    def database_healthy?
      ActiveRecord::Base.connection.active?
    rescue
      false
    end

    def redis_healthy?
      Rails.cache.read('health_check') || Rails.cache.write('health_check', true)
    rescue
      false
    end

    def storage_healthy?
      File.writable?(Rails.root.join('tmp'))
    rescue
      false
    end
  end
end