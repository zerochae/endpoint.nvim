class ReviewsController < ApplicationController
  before_action :set_review, only: %i[show edit update destroy]
  before_action :set_product, only: %i[index new create]

  def index
    @reviews = @product.reviews
  end

  def show
  end

  def new
    @review = @product.reviews.build
  end

  def edit
  end

  def create
    @review = @product.reviews.build(review_params)

    if @review.save
      redirect_to [@product, @review]
    else
      render :new
    end
  end

  def update
    if @review.update(review_params)
      redirect_to [@product, @review]
    else
      render :edit
    end
  end

  def destroy
    @review.destroy
    redirect_to product_reviews_url(@product)
  end

  private

  def set_review
    @review = Review.find(params[:id])
    @product = @review.product
  end

  def set_product
    @product = Product.find(params[:product_id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :user_id)
  end
end