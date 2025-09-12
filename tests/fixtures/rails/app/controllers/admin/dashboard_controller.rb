class Admin::DashboardController < ApplicationController
  before_action :ensure_admin

  def index
    @user_count = User.count
    @product_count = Product.count
    @order_count = Order.count
  end

  private

  def ensure_admin
    redirect_to root_path unless current_user&.admin?
  end
end
