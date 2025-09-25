class CommentedController < ApplicationController
  # Single line commented endpoints - should be filtered
  # def index
  #   render json: { message: 'filtered' }
  # end

  # def create
  #   render json: { message: 'filtered' }
  # end

=begin
Multi-line block commented endpoints - should be filtered
def show
  render json: { message: 'filtered' }
end

def update
  render json: { message: 'filtered' }
end
=end

  # Active endpoints - should NOT be filtered
  def active_index
    render json: { message: 'active' }
  end

  def active_create
    render json: { message: 'created' }
  end

  # Mixed scenarios
  # def commented_method # This should be filtered

  def active_after_comment
    render json: { message: 'active' } # This should NOT be filtered
  end

  # Hash comment with different content
  # This is just a regular comment, not a method

  private

  # Private methods (should also be filtered when commented)
  # def commented_private_method
  #   # filtered
  # end

  def active_private_method
    # active
  end
end