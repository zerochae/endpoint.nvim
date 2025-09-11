# frozen_string_literal: true

module Api
  module V1
    # Articles API Controller
    class ArticlesController < ApplicationController
      before_action :set_article, only: %i[show update destroy]

      # GET /api/v1/articles
      def index
        @articles = Article.published.includes(:author, :tags)
        render json: @articles
      end

      # GET /api/v1/articles/:id
      def show
        render json: @article
      end

      # POST /api/v1/articles
      def create
        @article = Article.new(article_params)
        @article.author = current_user

        if @article.save
          render json: @article, status: :created
        else
          render json: { errors: @article.errors }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/articles/:id
      # PATCH /api/v1/articles/:id
      def update
        if @article.update(article_params)
          render json: @article
        else
          render json: { errors: @article.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/articles/:id
      def destroy
        @article.destroy
        head :no_content
      end

      # POST /api/v1/articles/:id/publish
      def publish
        @article = Article.find(params[:id])
        @article.publish!
        render json: @article
      end

      # POST /api/v1/articles/:id/unpublish
      def unpublish
        @article = Article.find(params[:id])
        @article.unpublish!
        render json: @article
      end

      # GET /api/v1/articles/:id/stats
      def stats
        @article = Article.find(params[:id])
        render json: {
          views: @article.views_count,
          likes: @article.likes_count,
          comments: @article.comments_count
        }
      end

      private

      def set_article
        @article = Article.find(params[:id])
      end

      def article_params
        params.require(:article).permit(:title, :content, :summary, :published, tag_ids: [])
      end
    end
  end
end