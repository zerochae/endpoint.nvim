# Endpoint.nvim Development Makefile

.PHONY: test test-symfony test-nestjs test-spring test-fastapi test-rails test-oas-rails test-express test-react-router test-cache test-scanner test-picker-centering test-all-rails test-frameworks

test:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/"

test-symfony:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/symfony_spec.lua"
	
test-nestjs:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/nestjs_spec.lua"

test-spring:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/spring_spec.lua"

test-fastapi:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/fastapi_spec.lua"

test-express:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/express_spec.lua"

test-react-router:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/react_router_spec.lua"

test-cache:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/cache_spec.lua"

test-scanner:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/scanner_spec.lua"

test-rails:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/rails_spec.lua"

test-oas-rails:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/oas_rails_spec.lua"

test-picker-centering:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/picker_centering_spec.lua"

test-all-rails: test-rails test-oas-rails
	@echo "Rails tests completed"

test-frameworks: test-symfony test-nestjs test-spring test-fastapi test-rails test-express test-react-router
	@echo "Framework tests completed"
