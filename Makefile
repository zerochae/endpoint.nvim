# Endpoint.nvim Development Makefile

.PHONY: test test-symfony test-nestjs test-spring test-fastapi test-rails

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

test-rails:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/spec/rails_spec.lua"
