class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: %i[show update]

  # @summary List all users
  # @description Retrieve a paginated list of all users in the system
  # @parameter page [Integer] Page number for pagination
  # @parameter per_page [Integer] Number of items per page
  # @response 200 [Array<User>] List of users
  # @response 422 [Hash] Validation errors
  def index
    @users = User.all
    render json: @users
  end

  # @summary Get user details
  # @description Retrieve detailed information for a specific user
  # @parameter id! [Integer] User ID
  # @response 200 [User] User details
  # @response 404 [Hash] User not found error
  def show
    render json: @user
  end

  # @summary Create a new user
  # @description Create a new user account with the provided information
  # @parameter user! [Hash] User attributes
  # @parameter user.name! [String] User's full name
  # @parameter user.email! [String] User's email address
  # @parameter user.status [String] User's status (active, inactive)
  # @response 201 [User] Created user
  # @response 422 [Hash] Validation errors
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # @summary Update user information
  # @description Update an existing user's information
  # @parameter id! [Integer] User ID
  # @parameter user! [Hash] User attributes to update
  # @parameter user.name [String] User's full name
  # @parameter user.email [String] User's email address
  # @parameter user.status [String] User's status (active, inactive)
  # @response 200 [User] Updated user
  # @response 422 [Hash] Validation errors
  # @response 404 [Hash] User not found error
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :status)
  end
end

