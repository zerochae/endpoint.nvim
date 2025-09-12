class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy like unlike share]

  def index
    @posts = Post.published.order(created_at: :desc)
  end

  def show
  end

  def new
    @post = Post.new
  end

  def edit
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post
    else
      render :new
    end
  end

  def update
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url
  end

  def like
    @post.likes.create(user: current_user)
    redirect_to @post
  end

  def unlike
    @post.likes.find_by(user: current_user)&.destroy
    redirect_to @post
  end

  def share
    @post.shares.create(user: current_user)
    redirect_to @post
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :status)
  end
end

