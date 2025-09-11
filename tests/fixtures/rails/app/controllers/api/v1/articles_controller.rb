module Api
  module V1
    class ArticlesController < ApplicationController
      before_action :set_article, only: [:show, :update, :destroy]

      # @summary Get all articles
      # @parameter page(query) [Integer] Page number for pagination
      # @parameter per_page(query) [Integer] Number of articles per page  
      # @parameter category(query) [String] Filter by category
      # @response Articles list(200) [Array<Article>]
      def index
        @articles = Article.published
          .page(params[:page])
          .per(params[:per_page] || 10)
        
        @articles = @articles.where(category: params[:category]) if params[:category]
        
        render json: {
          articles: @articles,
          meta: pagination_meta(@articles)
        }
      end

      # @summary Get article by ID
      # @parameter id(path) [!Integer] Article ID
      # @response Article details(200) [Article]
      # @response Article not found(404) [Error]
      def show
        render json: @article, include: [:author, :comments, :tags]
      end

      # @summary Create new article
      # @request_body Article data [!ArticleRequest]
      # @response Article created(201) [Article]
      # @response Validation errors(422) [ValidationError]
      def create
        @article = Article.new(article_params)

        if @article.save
          render json: @article, status: :created
        else
          render json: { errors: @article.errors }, status: :unprocessable_entity
        end
      end

      # @summary Update article
      # @parameter id(path) [!Integer] Article ID
      # @request_body Updated article data [ArticleRequest]
      # @response Updated article(200) [Article]
      # @response Validation errors(422) [ValidationError]
      def update
        if @article.update(article_params)
          render json: @article
        else
          render json: { errors: @article.errors }, status: :unprocessable_entity
        end
      end

      # @summary Delete article
      # @parameter id(path) [!Integer] Article ID
      # @response No content(204)
      # @response Article not found(404) [Error]
      def destroy
        @article.destroy
        head :no_content
      end

      # GET /api/v1/articles/featured
      def featured
        @articles = Article.featured.limit(5)
        render json: @articles
      end

      # POST /api/v1/articles/1/like
      def like
        @article = Article.find(params[:id])
        @article.increment!(:likes_count)
        render json: { likes: @article.likes_count }
      end

      private

      def set_article
        @article = Article.find(params[:id])
      end

      def article_params
        params.require(:article).permit(:title, :content, :category, :published, tag_ids: [])
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end