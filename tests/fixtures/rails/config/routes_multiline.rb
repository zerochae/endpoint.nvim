# Rails routes with multiline definitions for testing
Rails.application.routes.draw do
  # Test case 1: Simple multiline routes
  get(
    '/users',
    to: 'users#index'
  )

  post(
    '/users',
    to: 'users#create'
  )

  # Test case 2: Complex multiline route definitions
  get(
    '/users/:id',
    to: 'users#show',
    constraints: { id: /\d+/ }
  )

  put(
    '/users/:id',
    to: 'users#update',
    constraints: { id: /\d+/ }
  )

  patch(
    '/users/:id',
    to: 'users#update',
    constraints: { id: /\d+/ }
  )

  delete(
    '/users/:id',
    to: 'users#destroy',
    constraints: { id: /\d+/ }
  )

  # Test case 3: Multiline resources with options
  resources(
    :posts,
    only: [:index, :show, :create, :update, :destroy]
  ) do
    resources(
      :comments,
      except: [:edit, :new]
    )
  end

  # Test case 4: Complex multiline namespace
  namespace(
    :api,
    defaults: { format: :json }
  ) do
    namespace(
      :v1,
      path: '/v1'
    ) do
      resources(
        :users,
        only: [:index, :show, :create, :update, :destroy]
      ) do
        member do
          get(
            :profile,
            to: 'users#profile'
          )

          post(
            :like,
            to: 'users#like'
          )

          delete(
            :unlike,
            to: 'users#unlike'
          )

          patch(
            :status,
            to: 'users#update_status'
          )
        end

        collection do
          get(
            :search,
            to: 'users#search'
          )

          post(
            :bulk_create,
            to: 'users#bulk_create'
          )
        end
      end

      # Test case 5: Multiline resource with nested resources
      resources(
        :posts,
        shallow: true
      ) do
        resources(
          :comments,
          except: [:new, :edit]
        ) do
          resources(
            :likes,
            only: [:create, :destroy]
          )
        end
      end
    end
  end

  # Test case 6: Multiline scope definitions
  scope(
    :admin,
    module: :admin,
    path: '/admin'
  ) do
    resources(
      :users,
      only: [:index, :show, :update, :destroy]
    )

    resources(
      :posts,
      only: [:index, :show, :update, :destroy]
    )
  end

  # Test case 7: Complex multiline route with constraints
  get(
    '/users/:id/posts/:post_id',
    to: 'posts#show',
    constraints: {
      id: /\d+/,
      post_id: /\d+/
    },
    as: :user_post
  )

  # Test case 8: Multiline root and custom routes
  root(
    to: 'home#index'
  )

  get(
    '/health',
    to: 'application#health'
  )

  post(
    '/webhooks/stripe',
    to: 'webhooks#stripe'
  )

  # Test case 9: Multiline route with custom HTTP methods
  match(
    '/users/:id/archive',
    to: 'users#archive',
    via: [:put, :patch]
  )

  # Test case 10: Very complex multiline route with all options
  get(
    '/users/:user_id/posts/:post_id/comments/:id',
    to: 'comments#show',
    constraints: {
      user_id: /\d+/,
      post_id: /\d+/,
      id: /\d+/
    },
    defaults: {
      format: :json
    },
    as: :nested_comment
  )

  # Test case 11: Multiline concern usage
  concern(
    :commentable
  ) do
    resources(
      :comments,
      only: [:index, :create, :show, :update, :destroy]
    )
  end

  resources(
    :articles,
    concerns: :commentable
  )

  # Test case 12: Multiline route with lambda constraints
  get(
    '/special/:token',
    to: 'special#show',
    constraints: lambda { |request|
      request.params[:token].present? &&
      request.params[:token].length > 10
    }
  )
end