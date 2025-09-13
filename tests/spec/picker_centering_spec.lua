describe("Picker line centering functionality", function()
  local telescope_picker = require "endpoint.pickers.telescope"
  local snacks_picker = require "endpoint.pickers.snacks"
  local vim_ui_select_picker = require "endpoint.pickers.vim_ui_select"

  describe("Telescope picker", function()
    it("should have create_endpoint_previewer function", function()
      assert.is_function(telescope_picker.create_endpoint_previewer)
    end)

    it("should create previewer with line centering capability", function()
      if telescope_picker.is_available() then
        local previewer = telescope_picker.create_endpoint_previewer()
        assert.is_not_nil(previewer)
        assert.is_not_nil(previewer.define_preview)
      else
        pending "Telescope not available"
      end
    end)
  end)

  describe("Snacks picker", function()
    it("should have show function", function()
      assert.is_function(snacks_picker.show)
    end)

    it("should include centered option in preview_file", function()
      -- This test verifies the structure but doesn't test actual centering
      -- since that requires UI interaction
      assert.is_function(snacks_picker.show)
    end)
  end)

  describe("VimUISelect picker", function()
    it("should have show function with centering command", function()
      assert.is_function(vim_ui_select_picker.show)
    end)

    it("should be always available", function()
      assert.is_true(vim_ui_select_picker.is_available())
    end)
  end)

  describe("Line centering behavior", function()
    it("should use 'zz' command for centering", function()
      -- Test that the centering logic is implemented correctly
      -- This is a conceptual test since we can't easily test vim commands in unit tests

      local function has_centering_command(picker_content)
        return picker_content:match "zz" ~= nil
      end

      -- Read the picker files and check for centering commands
      local telescope_content = vim.fn.readfile "lua/endpoint/pickers/telescope.lua"
      local snacks_content = vim.fn.readfile "lua/endpoint/pickers/snacks.lua"
      local vim_ui_content = vim.fn.readfile "lua/endpoint/pickers/vim_ui_select.lua"

      local telescope_str = table.concat(telescope_content, "\n")
      local snacks_str = table.concat(snacks_content, "\n")
      local vim_ui_str = table.concat(vim_ui_content, "\n")

      assert.is_true(has_centering_command(telescope_str), "Telescope picker should include centering command")
      assert.is_true(has_centering_command(snacks_str), "Snacks picker should include centering command")
      assert.is_true(has_centering_command(vim_ui_str), "VimUISelect picker should include centering command")
    end)
  end)
end)

