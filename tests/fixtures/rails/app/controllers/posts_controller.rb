class PostsController < ApplicationController
  # GET /posts
  def index
    @posts = Post.all
    render json: @posts
  end

  # GET /posts/:id
  def show
    @post = Post.find(params[:id])
    render json: @post
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    if @post.save
      render json: @post, status: :created
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/:id
  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # DELETE /posts/:id
  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    head :no_content
  end

  # POST /posts/:id/publish
  def publish
    @post = Post.find(params[:id])
    @post.update!(published: true)
    render json: @post
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end