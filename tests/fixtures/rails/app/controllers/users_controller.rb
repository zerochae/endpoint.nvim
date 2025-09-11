class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy profile update_status]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url
  end

  def profile
    # Custom action for user profile
  end

  def update_status
    @user.update(status: params[:status])
    redirect_to @user
  end

  def search
    @users = User.where('name ILIKE ?', "%#{params[:q]}%")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :status)
  end
end

