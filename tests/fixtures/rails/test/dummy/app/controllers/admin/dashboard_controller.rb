# frozen_string_literal: true

module Admin
  # Admin Dashboard Controller
  class DashboardController < ApplicationController
    before_action :authenticate_admin!

    # GET /admin/dashboard
    def index
      @users_count = User.count
      @articles_count = Article.count
      @recent_activities = Activity.recent.limit(10)
    end

    # GET /admin/dashboard/stats
    def stats
      render json: {
        users: {
          total: User.count,
          active: User.active.count,
          new_today: User.created_today.count
        },
        articles: {
          total: Article.count,
          published: Article.published.count,
          draft: Article.draft.count
        },
        system: {
          uptime: system_uptime,
          memory_usage: memory_usage
        }
      }
    end

    # GET /admin/dashboard/health
    def health
      render json: {
        status: 'ok',
        timestamp: Time.current,
        services: check_services_health
      }
    end

    # POST /admin/dashboard/maintenance
    def maintenance
      if params[:enable] == 'true'
        enable_maintenance_mode
        render json: { message: 'Maintenance mode enabled' }
      else
        disable_maintenance_mode
        render json: { message: 'Maintenance mode disabled' }
      end
    end

    private

    def authenticate_admin!
      redirect_to root_path unless current_user&.admin?
    end

    def system_uptime
      `uptime`.strip
    end

    def memory_usage
      `free -h | grep '^Mem:'`.strip
    end

    def check_services_health
      {
        database: database_healthy?,
        redis: redis_healthy?,
        storage: storage_healthy?
      }
    end

    def database_healthy?
      ActiveRecord::Base.connection.active?
    rescue
      false
    end

    def redis_healthy?
      Redis.current.ping == 'PONG'
    rescue
      false
    end

    def storage_healthy?
      File.writable?(Rails.root.join('tmp'))
    rescue
      false
    end

    def enable_maintenance_mode
      Rails.cache.write('maintenance_mode', true)
    end

    def disable_maintenance_mode
      Rails.cache.delete('maintenance_mode')
    end
  end
end