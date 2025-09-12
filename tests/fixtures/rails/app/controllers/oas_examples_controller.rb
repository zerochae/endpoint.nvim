# @tag OasRails Examples
# @path /oas_examples
# @description Examples demonstrating oas_rails documentation patterns
class OasExamplesController < ApplicationController
  before_action :authenticate_user!, except: [:public_endpoint]
  before_action :set_example, only: %i[show update destroy]

  # @summary List examples with advanced filtering
  # @description Retrieve examples with complex filtering and sorting options
  # @parameter page [Integer] Page number for pagination (default: 1)
  # @parameter per_page [Integer] Items per page (default: 25, max: 100)
  # @parameter filter[status] [String] Filter by status (active, inactive, pending)
  # @parameter filter[category_id] [Integer] Filter by category ID
  # @parameter filter[created_after] [String] ISO8601 date string for created after filter
  # @parameter sort [String] Sort field with direction (created_at, updated_at, name)
  # @parameter direction [String] Sort direction (asc, desc)
  # @response 200 [Array<Example>] Paginated list of examples
  # @response 401 [Hash] Authentication required
  # @response 422 [Hash] Invalid parameters
  def index
    @examples = Example.includes(:category, :user)

    # Apply filters
    @examples = @examples.where(status: params.dig(:filter, :status)) if params.dig(:filter, :status)
    @examples = @examples.where(category_id: params.dig(:filter, :category_id)) if params.dig(:filter, :category_id)
    @examples = @examples.where('created_at >= ?', params.dig(:filter, :created_after)) if params.dig(:filter,
                                                                                                      :created_after)

    # Apply sorting
    sort_field = params[:sort]&.in?(%w[created_at updated_at name]) ? params[:sort] : 'created_at'
    direction = params[:direction]&.in?(%w[asc desc]) ? params[:direction] : 'desc'
    @examples = @examples.order("#{sort_field} #{direction}")

    # Paginate
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    per_page = 25 if per_page == 0

    @examples = @examples.page(page).per(per_page)

    render json: {
      examples: @examples,
      meta: {
        current_page: @examples.current_page,
        per_page: @examples.limit_value,
        total_pages: @examples.total_pages,
        total_count: @examples.total_count
      }
    }
  end

  # @summary Get example with relationships
  # @description Retrieve a specific example with all related data
  # @parameter id! [Integer] Example ID
  # @parameter include [String] Comma-separated list of relationships to include (user,category,comments)
  # @response 200 [Example] Example with optional relationships
  # @response 404 [Hash] Example not found
  # @response 401 [Hash] Authentication required
  def show
    includes = params[:include]&.split(',')&.map(&:strip) || []
    valid_includes = includes.select { |inc| %w[user category comments].include?(inc) }

    @example = @example.as_json(include: valid_includes) if valid_includes.any?

    render json: @example
  end

  # @summary Create example with validation
  # @description Create a new example with comprehensive validation and error handling
  # @parameter example! [Hash] Example data object
  # @parameter example.title! [String] Example title (3-100 characters)
  # @parameter example.description! [String] Detailed description (10-1000 characters)
  # @parameter example.category_id! [Integer] Valid category ID
  # @parameter example.status [String] Status (active, inactive, pending) - defaults to pending
  # @parameter example.tags [Array<String>] Array of tag strings (max 10 tags)
  # @parameter example.metadata [Hash] Flexible metadata object
  # @parameter example.config [Hash] Configuration settings
  # @parameter example.config.public [Boolean] Whether example is public
  # @parameter example.config.featured [Boolean] Whether example is featured
  # @response 201 [Example] Created example
  # @response 422 [Hash] Validation errors with detailed field-level messages
  # @response 401 [Hash] Authentication required
  def create
    @example = current_user.examples.build(example_params)

    if @example.save
      render json: @example, status: :created, location: @example
    else
      render json: {
        errors: @example.errors.full_messages,
        field_errors: @example.errors.messages
      }, status: :unprocessable_entity
    end
  end

  # @summary Update example with partial updates
  # @description Update an existing example with support for partial updates
  # @parameter id! [Integer] Example ID
  # @parameter example! [Hash] Example data object (only changed fields required)
  # @parameter example.title [String] Example title (3-100 characters)
  # @parameter example.description [String] Detailed description (10-1000 characters)
  # @parameter example.category_id [Integer] Valid category ID
  # @parameter example.status [String] Status (active, inactive, pending)
  # @parameter example.tags [Array<String>] Array of tag strings (max 10 tags)
  # @parameter example.metadata [Hash] Flexible metadata object (merged with existing)
  # @response 200 [Example] Updated example
  # @response 422 [Hash] Validation errors
  # @response 404 [Hash] Example not found
  # @response 401 [Hash] Authentication required
  def update
    if @example.update(example_params)
      render json: @example
    else
      render json: {
        errors: @example.errors.full_messages,
        field_errors: @example.errors.messages
      }, status: :unprocessable_entity
    end
  end

  # @summary Delete example
  # @description Soft delete an example (marks as deleted but preserves data)
  # @parameter id! [Integer] Example ID
  # @response 204 [] Successfully deleted
  # @response 404 [Hash] Example not found
  # @response 401 [Hash] Authentication required
  def destroy
    @example.update(deleted_at: Time.current)
    head :no_content
  end

  # @summary Public endpoint example
  # @description Example of a public endpoint that doesn't require authentication
  # @parameter format [String] Response format (json, xml) - defaults to json
  # @response 200 [Hash] Public data
  # @response 406 [Hash] Unsupported format
  def public_endpoint
    case params[:format]&.downcase
    when 'xml'
      render xml: { message: 'This is a public endpoint', timestamp: Time.current }
    when 'json', nil
      render json: { message: 'This is a public endpoint', timestamp: Time.current }
    else
      render json: { error: 'Unsupported format' }, status: :not_acceptable
    end
  end

  # @summary Bulk operations example
  # @description Perform bulk operations on multiple examples
  # @parameter action! [String] Bulk action (delete, update_status, archive)
  # @parameter example_ids! [Array<Integer>] Array of example IDs to operate on
  # @parameter bulk_params [Hash] Parameters for bulk operation
  # @parameter bulk_params.status [String] New status for update_status action
  # @response 200 [Hash] Bulk operation results with success/failure counts
  # @response 422 [Hash] Invalid parameters or bulk operation errors
  # @response 401 [Hash] Authentication required
  def bulk_operations
    action = params[:action]
    example_ids = params[:example_ids] || []

    unless %w[delete update_status archive].include?(action)
      return render json: { error: 'Invalid action' }, status: :unprocessable_entity
    end

    examples = current_user.examples.where(id: example_ids)

    results = { success: 0, failed: 0, errors: [] }

    examples.find_each do |example|
      case action
      when 'delete'
        example.update!(deleted_at: Time.current)
      when 'update_status'
        example.update!(status: params.dig(:bulk_params, :status))
      when 'archive'
        example.update!(archived_at: Time.current)
      end
      results[:success] += 1
    rescue StandardError => e
      results[:failed] += 1
      results[:errors] << { id: example.id, error: e.message }
    end

    render json: results
  end

  private

  def set_example
    @example = current_user.examples.find(params[:id])
  end

  def example_params
    params.require(:example).permit(
      :title, :description, :category_id, :status,
      tags: [],
      metadata: {},
      config: %i[public featured]
    )
  end
end
