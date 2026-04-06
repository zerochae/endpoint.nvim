---@diagnostic disable: duplicate-set-field
local java_constant_resolver = require "endpoint.resolver.java_constant_resolver"

describe("JavaConstantResolver", function()
  local fixtures_root = "tests/fixtures/spring"

  before_each(function()
    java_constant_resolver.clear_cache()
  end)

  describe("_parse_constants_from_file", function()
    it("should parse constants from PathConstants file", function()
      local constants = java_constant_resolver._parse_constants_from_file(
        fixtures_root .. "/src/main/java/com/example/constants/PathConstants.java"
      )

      assert.is_not_nil(constants)
      assert.equals("/api", constants["PathConstants.API_BASE"])
      assert.equals("/api/v0/students", constants["PathConstants.Student.BASE_V0"])
      assert.equals("/all", constants["PathConstants.Student.GET_ALL"])
      assert.equals("/{id}", constants["PathConstants.Student.GET_BY_ID"])
      assert.equals("/create", constants["PathConstants.Student.CREATE"])
      assert.equals("/api/v1/teachers", constants["PathConstants.Teacher.BASE"])
      assert.equals("/list", constants["PathConstants.Teacher.GET_ALL"])
      assert.equals("/{teacherId}", constants["PathConstants.Teacher.GET_BY_ID"])
      assert.equals("/api/v1/courses", constants["PathConstants.Course.BASE"])
      assert.equals("/enroll", constants["PathConstants.Course.ENROLL"])
    end)

    it("should parse constants from interface-style file", function()
      local constants = java_constant_resolver._parse_constants_from_file(
        fixtures_root .. "/src/main/java/com/example/constants/ApiRoutes.java"
      )

      assert.is_not_nil(constants)
      assert.equals("/api", constants["ApiRoutes.API_PREFIX"])
      assert.equals("/api/v1/users", constants["ApiRoutes.Users.BASE"])
      assert.equals("/list", constants["ApiRoutes.Users.FIND_ALL"])
      assert.equals("/{id}", constants["ApiRoutes.Users.FIND_BY_ID"])
      assert.equals("/create", constants["ApiRoutes.Users.CREATE"])
      assert.equals("/api/v1/products", constants["ApiRoutes.Products.BASE"])
      assert.equals("/search", constants["ApiRoutes.Products.SEARCH"])
    end)

    it("should return empty table for non-existent file", function()
      local constants = java_constant_resolver._parse_constants_from_file("nonexistent.java")
      assert.same({}, constants)
    end)
  end)

  describe("resolve", function()
    it("should resolve fully qualified constant reference", function()
      local value = java_constant_resolver.resolve("PathConstants.Student.BASE_V0", fixtures_root)
      assert.equals("/api/v0/students", value)
    end)

    it("should resolve nested class constant", function()
      local value = java_constant_resolver.resolve("PathConstants.Student.GET_ALL", fixtures_root)
      assert.equals("/all", value)
    end)

    it("should resolve top-level constant", function()
      local value = java_constant_resolver.resolve("PathConstants.API_BASE", fixtures_root)
      assert.equals("/api", value)
    end)

    it("should resolve Teacher constants", function()
      local value = java_constant_resolver.resolve("PathConstants.Teacher.BASE", fixtures_root)
      assert.equals("/api/v1/teachers", value)
    end)

    it("should return nil for unknown constant", function()
      local value = java_constant_resolver.resolve("PathConstants.Unknown.FIELD", fixtures_root)
      assert.is_nil(value)
    end)

    it("should resolve partial match (suffix)", function()
      local value = java_constant_resolver.resolve("Student.BASE_V0", fixtures_root)
      assert.equals("/api/v0/students", value)
    end)
  end)

  describe("resolve_from_file_context", function()
    it("should resolve constant using import context", function()
      local controller_path = fixtures_root .. "/src/main/java/com/example/ConstantController.java"
      local value = java_constant_resolver.resolve_from_file_context(
        "PathConstants.Student.BASE_V0",
        controller_path,
        fixtures_root
      )
      assert.equals("/api/v0/students", value)
    end)
  end)

  describe("get_all_constants", function()
    it("should return all constants in project", function()
      local all = java_constant_resolver.get_all_constants(fixtures_root)
      assert.is_table(all)
      assert.is_true(vim.tbl_count(all) >= 10)
    end)
  end)

  describe("clear_cache", function()
    it("should clear cached constants", function()
      java_constant_resolver.resolve("PathConstants.Student.BASE_V0", fixtures_root)
      java_constant_resolver.clear_cache()
      -- After clearing, resolve should still work (rebuilds cache)
      local value = java_constant_resolver.resolve("PathConstants.Student.BASE_V0", fixtures_root)
      assert.equals("/api/v0/students", value)
    end)
  end)
end)
