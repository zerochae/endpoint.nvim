# Rails Framework Support

## Overview

The Rails Framework implementation provides comprehensive support for Ruby on Rails applications, including RESTful routing and controller-based organization. It detects Rails projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `rails`
- **Language**: Ruby
- **File Extensions**: `*.rb`
- **Framework Class**: `RailsFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Rails projects by looking for specific files and dependencies:

**Required Dependencies:**
- `rails`
- `actionpack`
- `railties`

**Manifest Files Searched:**
- `Gemfile`
- `Gemfile.lock`
- `config/application.rb`
- `config/routes.rb`

> [!NOTE]
> Rails detection uses dependency-based strategy to search for Rails-related dependencies in Ruby package manifest files and configuration files.

## Parsing Strategy

### Annotation-Based Parsing (Route Parsing)

The framework uses route-based parsing to extract endpoint information from Rails route definitions and controller actions.

### Supported Route Methods

| Method | HTTP Method | Example |
|--------|-------------|---------|
| `get` | GET | `get '/users', to: 'users#index'` |
| `post` | POST | `post '/users', to: 'users#create'` |
| `put` | PUT | `put '/users/:id', to: 'users#update'` |
| `patch` | PATCH | `patch '/users/:id', to: 'users#update'` |
| `delete` | DELETE | `delete '/users/:id', to: 'users#destroy'` |
| `resources` | Multiple | `resources :users` |
| `resource` | Multiple | `resource :profile` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Direct Routes**: `get '/users', to: 'users#index'`
2. **Single Quotes**: `get "/users", to: "users#index"`
3. **Resources**: `resources :users`
4. **Nested Resources**: `resources :users do ... end`
5. **Namespaced Routes**: `namespace :api do ... end`

### Resources and RESTful Routes

Rails's resourceful routing is fully supported:

```ruby
Rails.application.routes.draw do
  resources :users do
    resources :posts
  end
end
```

This generates:
- `GET /users` (index)
- `GET /users/:id` (show)
- `POST /users` (create)
- `PUT /users/:id` (update)
- `PATCH /users/:id` (update)
- `DELETE /users/:id` (destroy)
- `GET /users/:user_id/posts` (nested index)
- etc.

> [!TIP]
> Rails resource routes are automatically expanded to their RESTful endpoints.

## Configuration Options

### File Processing
- **Include Patterns**: `*.rb`
- **Exclude Patterns**:
  - `**/vendor` (Vendor gems)
  - `**/tmp` (Temporary files)
  - `**/log` (Log files)
  - `**/.bundle` (Bundle cache)

### Search Options
- `--type ruby`: Optimizes search for Ruby files

### Pattern Matching
```lua
patterns = {
  GET = { "get\\s+['\"]", "resources\\s+:", "resource\\s+:" },
  POST = { "post\\s+['\"]", "resources\\s+:", "resource\\s+:" },
  PUT = { "put\\s+['\"]", "resources\\s+:" },
  PATCH = { "patch\\s+['\"]", "resources\\s+:" },
  DELETE = { "delete\\s+['\"]", "resources\\s+:" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `ruby` (language)
- `rails` (framework)

### Metadata Fields
- `framework_version`: "rails"
- `language`: "ruby"
- `controller`: Controller name (extracted from route)
- `action`: Action name (extracted from route)

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard RESTful actions

## Example Endpoint Structures

### Basic Routes Configuration
```ruby
Rails.application.routes.draw do
  root 'home#index'
  # Detected: GET[home#index] /

  get '/users', to: 'users#index'
  # Detected: GET[users#index] /users

  post '/users', to: 'users#create'
  # Detected: POST[users#create] /users

  get '/users/:id', to: 'users#show'
  # Detected: GET[users#show] /users/:id

  put '/users/:id', to: 'users#update'
  # Detected: PUT[users#update] /users/:id

  delete '/users/:id', to: 'users#destroy'
  # Detected: DELETE[users#destroy] /users/:id
end
```

### Resourceful Routes
```ruby
Rails.application.routes.draw do
  resources :users
  # Detected: GET[users#index] /users
  # Detected: GET[users#show] /users/:id
  # Detected: POST[users#create] /users
  # Detected: PUT[users#update] /users/:id
  # Detected: PATCH[users#update] /users/:id
  # Detected: DELETE[users#destroy] /users/:id
  # Detected: GET[users#new] /users/new
  # Detected: GET[users#edit] /users/:id/edit

  resources :users, only: [:index, :show]
  # Detected: GET[users#index] /users
  # Detected: GET[users#show] /users/:id

  resources :users, except: [:destroy]
  # Detected: All except DELETE[users#destroy] /users/:id
end
```

### Nested and Namespaced Routes
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users do
        resources :posts
      end
    end
  end
  # Detected: GET[users#index] /api/v1/users
  # Detected: GET[posts#index] /api/v1/users/:user_id/posts
  # etc.

  resources :users do
    member do
      get :profile
    end
    collection do
      get :search
    end
  end
  # Detected: GET[users#profile] /users/:id/profile (member)
  # Detected: GET[users#search] /users/search (collection)

  resources :posts do
    resources :comments, except: [:show]
  end
  # Detected: GET[comments#index] /posts/:post_id/comments (nested)
  # Detected: POST[comments#create] /posts/:post_id/comments (nested)
  # Detected: GET[comments#edit] /posts/:post_id/comments/:id/edit (nested)
  # Detected: PUT[comments#update] /posts/:post_id/comments/:id (nested)
  # Detected: DELETE[comments#destroy] /posts/:post_id/comments/:id (nested)
  # Note: show action excluded due to except: [:show]
end
```

### Advanced Route Patterns
```ruby
Rails.application.routes.draw do
  get '/users/:user_id/posts/:id', to: 'posts#show'
  # Detected: GET[posts#show] /users/:user_id/posts/:id

  get '/search', to: 'search#index'
  # Detected: GET[search#index] /search

  scope '/admin' do
    resources :users
  end
  # Detected: GET[users#index] /admin/users
  # etc.
end
```

## Enhanced Display Format

### Rails-Specific Endpoint Display
Endpoints now use Rails-familiar `controller#action` notation for better developer experience:

**Format**: `METHOD[controller#action] /path`

Examples:
- `GET[users#index] /users`
- `POST[users#create] /users`
- `GET[users#show] /users/:id`
- `GET[users#profile] /users/:id/profile` (member route)
- `GET[users#search] /users/search` (collection route)
- `GET[comments#index] /posts/:post_id/comments` (nested route)
- `GET[home#index] /` (root route)

### Visual Highlighting
In Telescope picker, the `METHOD[controller#action]` portion is highlighted for easy identification:
- **Highlighted**: `GET[users#profile]`
- **Normal**: `/users/:id/profile`

This format matches Rails `routes` command output, making it instantly familiar to Rails developers.

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Rails dependency in `Gemfile`
> - Check that `config/routes.rb` exists and contains routes
> - Ensure files have `.rb` extensions

> [!CAUTION]
> **Nested Routes Not Detected**
> - Verify proper nesting syntax in routes file
> - Check for missing `do...end` blocks

> [!TIP]
> **Missing RESTful Actions**
> - Ensure `resources` declarations are properly formatted
> - Check for restrictions with `only` or `except` options

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Advanced Features

### Nested Resource Resolution
The framework now provides comprehensive support for deeply nested resources with accurate path generation:

```ruby
resources :posts do
  resources :comments do
    resources :replies
  end
end
```
- **Generates**: `/posts/:post_id/comments/:comment_id/replies`
- **Links to**: Actual controller action implementations (not routes.rb)
- **Supports**: `only` and `except` options in nested contexts

### Controller Action Linking
Endpoint previews now link directly to controller implementations rather than route definitions:

- **Before**: `GET /posts/:post_id/comments` → `config/routes.rb:16`
- **After**: `GET /posts/:post_id/comments` → `app/controllers/comments_controller.rb:5` (def index)

### Precise Column Positioning
Preview positions are now accurate to the exact character:
- **Before**: Preview might show `f destroy` (truncated)
- **After**: Preview shows complete `def destroy` method signature

### Member and Collection Route Context
Member and collection routes maintain their parent resource context:

```ruby
resources :users do
  member do
    get :profile      # → GET /users/:id/profile
    patch :activate   # → PATCH /users/:id/activate
  end
  collection do
    get :search       # → GET /users/search
    post :bulk_create # → POST /users/bulk_create
  end
end
```

## Integration Notes

> [!INFO]
> - Works with Rails 5.x, 6.x, and 7.x
> - Compatible with Rails API mode
> - Supports both traditional and resourceful routing
> - Handles nested resources and namespaced routes
> - Automatically excludes vendor gems and temporary files
> - Supports member and collection routes
> - Compatible with Rails engines and mountable apps
> - **NEW**: Accurate nested resource path generation
> - **NEW**: Direct controller action linking for all route types
> - **NEW**: Precise preview positioning with correct column values