-- Rails Framework Parser
local utils = require "endpoint.frameworks.rails.utils"

---@param content string[] Array of file content lines
---@param file_path string The file path
---@param framework_opts any Framework options
---@return endpoint.entry[] entries Array of endpoint entries
return function(content, file_path, framework_opts)
  local endpoints = {}

  -- Handle controller files
  if file_path:match "controller" then
    for i, line in ipairs(content) do
      local action = line:match "def ([%w_]+)"
      if action then
        -- Generate path based on controller and action
        local controller_name = utils.extract_controller_name(file_path)
        if controller_name then
          local path = utils.generate_action_path(controller_name, action, file_path)
          local method = utils.determine_http_method(action)

          table.insert(endpoints, {
            method = method,
            endpoint_path = path,
            file_path = file_path,
            line_number = i,
            column = 1,
            display_value = method .. "[" .. controller_name .. "#" .. action .. "] " .. path,
            confidence = 0.9,
            tags = { "api", "rails", "controller" },
            framework = framework_opts.name,
            metadata = {
              action = action,
              controller = controller_name,
            }
          })
        end
      end
    end
  end

  -- Handle routes.rb files
  if file_path:match "routes%.rb" then
    for i, line in ipairs(content) do
      local route_info = utils.extract_route_definition(line, i)
      if route_info then
        -- Handle routes that need resource context
        if route_info.needs_context then
          local resource_context = utils.find_resource_context(file_path, i)
          if resource_context then
            local path
            if utils.is_in_member_block(file_path, i) then
              path = resource_context.path .. "/:id/" .. route_info.action
            elseif utils.is_in_collection_block(file_path, i) then
              path = resource_context.path .. "/" .. route_info.action
            else
              path = "/" .. route_info.action
            end

            table.insert(endpoints, {
              method = route_info.method,
              endpoint_path = path,
              file_path = file_path,
              line_number = i,
              column = 1,
              display_value = route_info.method .. "[" .. route_info.action .. "] " .. path,
              confidence = 0.8,
              tags = { "api", "rails", "routes" },
              framework = framework_opts.name,
              metadata = {
                action = route_info.action,
                resource_context = resource_context,
              }
            })
          end
        else
          -- Direct route definitions
          local display_value
          if route_info.controller_action then
            display_value = route_info.method .. "[" .. route_info.controller_action .. "] " .. route_info.path
          else
            display_value = route_info.method .. " " .. route_info.path
          end

          table.insert(endpoints, {
            method = route_info.method,
            endpoint_path = route_info.path,
            file_path = file_path,
            line_number = i,
            column = 1,
            display_value = display_value,
            confidence = 0.9,
            tags = { "api", "rails", "routes" },
            framework = framework_opts.name,
            metadata = {
              action = route_info.action,
              controller = route_info.controller,
              controller_action = route_info.controller_action,
            }
          })
        end
      end
    end
  end

  return endpoints
end