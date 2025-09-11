# OAS Rails documented Users Controller
class OasUsersController < ApplicationController
  before_action :authorize!, except: [:create, :login]
  before_action :set_user, only: %i[show update destroy]

  # @summary Login
  # @request_body_ref #/components/requestBodies/LoginRequest
  # @no_auth
  def login
    @user = User.find_by_email(params[:email])
    if @user&.authenticate(params[:password])
      render json: { token: 'jwt_token' }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  # Returns a list of Users.
  #
  # @parameter offset(query) [Integer] Used for pagination (default: 25)
  # @parameter status(query) [!String] Filter by status
  # @parameter stages(query) [Array<String>] Filter by stages
  # @response Users list(200) [Array<User>]
  def index
    @users = User.all
    render json: @users
  end

  # @summary Get a user by id.
  # @parameter id(path) [!Integer] Used for identify the user
  # @response A nice user(200) [Reference:#/components/schemas/User]
  # @response User not found(404) [Hash{success: Boolean, message: String}]
  def show
    render json: @user
  end

  # @summary Create a User New
  # @no_auth
  # @tags 1. First
  # @request_body The user to be created. At least include an `email`. [!User]
  # @request_body_example basic user
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: { success: false, errors: @user.errors }, status: :unprocessable_entity
    end
  end

  # Update a user.
  # @tags 2. Second
  # @request_body User to be created [Reference:#/components/schemas/User]
  # @request_body_example Update user [Reference:#/components/examples/UserExample]
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  # @oas_include
  def destroy
    @user.destroy!
    redirect_to users_url, notice: 'User was successfully destroyed.', status: :see_other
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end