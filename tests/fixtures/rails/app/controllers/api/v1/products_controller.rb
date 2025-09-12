class Api::V1::ProductsController < ApplicationController
  before_action :set_product, only: %i[show]

  # @summary List all products
  # @description Retrieve a paginated list of all available products
  # @parameter page [Integer] Page number for pagination
  # @parameter per_page [Integer] Number of items per page
  # @parameter category [String] Filter by product category
  # @parameter featured [Boolean] Filter for featured products only
  # @response 200 [Array<Product>] List of products
  # @response 422 [Hash] Validation errors
  def index
    @products = Product.all
    @products = @products.where(category: params[:category]) if params[:category].present?
    @products = @products.where(featured: true) if params[:featured] == 'true'
    render json: @products
  end

  # @summary Get product details
  # @description Retrieve detailed information for a specific product
  # @parameter id! [Integer] Product ID
  # @response 200 [Product] Product details with reviews and ratings
  # @response 404 [Hash] Product not found error
  def show
    render json: @product, include: [:reviews, :category]
  end

  # @summary Get featured products
  # @description Retrieve a list of featured products for homepage display
  # @parameter limit [Integer] Maximum number of products to return (default: 10)
  # @response 200 [Array<Product>] List of featured products
  def featured
    limit = params[:limit]&.to_i || 10
    @products = Product.where(featured: true).limit(limit)
    render json: @products
  end

  # @summary Get products on sale
  # @description Retrieve products that are currently on sale
  # @parameter discount_min [Float] Minimum discount percentage
  # @response 200 [Array<Product>] List of products on sale
  def on_sale
    @products = Product.where('discount_percentage > 0')
    @products = @products.where('discount_percentage >= ?', params[:discount_min]) if params[:discount_min].present?
    render json: @products
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end
end