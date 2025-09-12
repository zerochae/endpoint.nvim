# @tag Posts
# @path /posts
class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy like unlike share]

  # @summary List all posts
  # @description Retrieve a paginated list of all published blog posts
  # @parameter page [Integer] Page number for pagination
  # @parameter category [String] Filter by post category
  # @response 200 [Array<Post>] List of posts
  def index
    @posts = Post.published.order(created_at: :desc)
  end

  # @summary Get post details
  # @description Retrieve detailed information for a specific post including comments
  # @parameter id! [Integer] Post ID
  # @response 200 [Post] Post details with comments
  # @response 404 [Hash] Post not found error
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

  # @summary Like a post
  # @description Add a like to a specific post
  # @parameter id! [Integer] Post ID
  # @response 200 [Hash] Success message
  # @response 404 [Hash] Post not found error
  def like
    @post.likes.create(user: current_user)
    redirect_to @post
  end

  def unlike
    @post.likes.find_by(user: current_user)&.destroy
    redirect_to @post
  end

  # @summary Share a post
  # @description Share a post via social media or email
  # @parameter id! [Integer] Post ID
  # @parameter platform [String] Sharing platform (facebook, twitter, email)
  # @response 200 [Hash] Share URL and success message
  # @response 404 [Hash] Post not found error
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
