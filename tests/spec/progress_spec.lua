local progress = require "endpoint.utils.progress"
local config = require "endpoint.config"

describe("Progress Utility", function()
  before_each(function()
    config.reset()
  end)

  describe("create", function()
    it("should create a progress handle when enabled", function()
      config.setup { progress = { enabled = true, provider = "notify" } }
      local handle = progress.create("Test", "Initial message")
      assert.is_not_nil(handle)
      assert.equals("Test", handle.title)
      assert.equals("Initial message", handle.message)
      assert.equals("notify", handle._provider)
    end)

    it("should return nil when disabled", function()
      config.setup { progress = { enabled = false } }
      local handle = progress.create("Test", "Initial message")
      assert.is_nil(handle)
    end)

    it("should fallback to notify when fidget is not available", function()
      config.setup { progress = { enabled = true, provider = "fidget" } }
      local handle = progress.create("Test", "Initial message")
      -- Since fidget is not installed in test environment, should fallback to notify
      assert.is_not_nil(handle)
      assert.equals("notify", handle._provider)
    end)

    it("should use auto provider by default", function()
      config.setup { progress = { enabled = true } }
      local handle = progress.create("Test", "Initial message")
      assert.is_not_nil(handle)
      -- In test environment without fidget, auto should resolve to notify
      assert.equals("notify", handle._provider)
    end)
  end)

  describe("update", function()
    it("should update progress handle", function()
      config.setup { progress = { enabled = true, provider = "notify" } }
      local handle = progress.create("Test", "Initial")
      progress.update(handle, "Updated message", 50)
      assert.equals("Updated message", handle.message)
      assert.equals(50, handle.percentage)
    end)

    it("should handle nil handle gracefully", function()
      -- Should not error
      assert.has_no.errors(function()
        progress.update(nil, "message", 50)
      end)
    end)
  end)

  describe("finish", function()
    it("should handle nil handle gracefully", function()
      assert.has_no.errors(function()
        progress.finish(nil, "Done")
      end)
    end)
  end)

  describe("cancel", function()
    it("should handle nil handle gracefully", function()
      assert.has_no.errors(function()
        progress.cancel(nil, "Cancelled")
      end)
    end)
  end)
end)

describe("Events SCAN_PROGRESS", function()
  local Events = require "endpoint.core.Events"

  it("should have SCAN_PROGRESS event type", function()
    assert.is_not_nil(Events.static.EVENT_TYPES.SCAN_PROGRESS)
    assert.equals("scan_progress", Events.static.EVENT_TYPES.SCAN_PROGRESS)
  end)

  it("should emit SCAN_PROGRESS event with correct data", function()
    local events = Events.static.get_instance()
    local received_data = nil

    events:add_event_listener(Events.static.EVENT_TYPES.SCAN_PROGRESS, function(data)
      received_data = data
    end)

    events:emit_event(Events.static.EVENT_TYPES.SCAN_PROGRESS, {
      current = 1,
      total = 3,
      framework_name = "Spring",
      message = "Scanning Spring (1/3)",
    })

    assert.is_not_nil(received_data)
    assert.equals(1, received_data.current)
    assert.equals(3, received_data.total)
    assert.equals("Spring", received_data.framework_name)
    assert.equals("Scanning Spring (1/3)", received_data.message)

    -- Cleanup
    events:clear_all_event_listeners()
  end)
end)
