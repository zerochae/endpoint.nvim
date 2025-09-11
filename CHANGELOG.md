# Changelog

## 1.0.0 (2025-09-11)


### Features

* add real-time cache mode with 'none' option as default ([f50b5c2](https://github.com/zerochae/endpoint.nvim/commit/f50b5c2ef47d384d3654ebd8e21b24fb93e51850))
* add real-time cache mode with "none" option as default ([de23d72](https://github.com/zerochae/endpoint.nvim/commit/de23d72f3a53c162af30f8f99c5c3035c9169434))

## [1.9.0](https://github.com/zerochae/endpoint.nvim/compare/v1.8.0...v1.9.0) (2025-09-11)


### Features

* reorganize tests and improve framework support ([2deb181](https://github.com/zerochae/endpoint.nvim/commit/2deb181edcd933f2da2ee34256ef1b9355bb128e))
* reorganize tests and improve framework support ([9afb3e3](https://github.com/zerochae/endpoint.nvim/commit/9afb3e3db8fb3a9ac7bccea385209bd8b7c9ee09))


### Bug Fixes

* add cache validation to create_endpoint_preview_table ([c76b886](https://github.com/zerochae/endpoint.nvim/commit/c76b88604a70f6c362a14697e14f9b546ebb51b7))
* ensure cache initialization in get_missing_methods ([08bb435](https://github.com/zerochae/endpoint.nvim/commit/08bb43511ab257784c42343b2b78d19f80d4c549))
* implement lazy cache initialization to respect cache_mode setting ([ba73139](https://github.com/zerochae/endpoint.nvim/commit/ba73139d99fd2e9d8e62b33aa58cf2739ad8e801))
* improve missing methods detection for persistent mode ([62b7aa7](https://github.com/zerochae/endpoint.nvim/commit/62b7aa7189b49e5aa97d1e6ac653781352d25a8b))
* improve persistent cache validation logic ([01f5ce0](https://github.com/zerochae/endpoint.nvim/commit/01f5ce090515863a3ad5b90fb0d919de9f8c4472))
* move get_cache_config function before its usage ([3346412](https://github.com/zerochae/endpoint.nvim/commit/334641284bdacaadb76700c542dd0b10f7ddf595))
* replace unused loop variable with underscore ([05469e6](https://github.com/zerochae/endpoint.nvim/commit/05469e6a896af7b7ddd69b8f0cc80e2af3b352d4))
* resolve function declaration order issue ([4878541](https://github.com/zerochae/endpoint.nvim/commit/4878541c00a0cb8631c365870f8bd587fa43f9cd))

## [1.8.0](https://github.com/zerochae/endpoint.nvim/compare/v1.7.0...v1.8.0) (2025-09-11)


### Features

* add FastAPI framework support ([46a86e0](https://github.com/zerochae/endpoint.nvim/commit/46a86e052751c8a43896b2d76e82498db4016eb2))


### Bug Fixes

* **#feature/fastapi-framework:** empty test file ([7e01b2e](https://github.com/zerochae/endpoint.nvim/commit/7e01b2e5e2befc10d9784bc08e8bb3e53a4d77c0))
* improve Python framework detection to prevent Django misdetection ([ced6746](https://github.com/zerochae/endpoint.nvim/commit/ced6746544db64d5866dd204463939e5ddca9ceb))
* remove trailing slash when endpoint is root path ([f01c2cd](https://github.com/zerochae/endpoint.nvim/commit/f01c2cd29c88e1bde6c838fe96cac1e59bcdf11d))

## [1.7.0](https://github.com/zerochae/endpoint.nvim/compare/v1.6.1...v1.7.0) (2025-09-11)


### Features

* add Makefile to gitignore for local development ([834dd22](https://github.com/zerochae/endpoint.nvim/commit/834dd22de9c8f35fa4aea5b9a9a83ec91359b130))
* add Symfony framework support with config and registry ([b610cee](https://github.com/zerochae/endpoint.nvim/commit/b610cee7668877aaa59d1f65e678e3f29f303e10))
* migrate to lazy.nvim for test dependencies ([958e72e](https://github.com/zerochae/endpoint.nvim/commit/958e72e1dc731316535f00d918e13f5316107061))
* **symfony:** add base path pattern extraction for class-level routes ([086abe0](https://github.com/zerochae/endpoint.nvim/commit/086abe038e24f92f0de76cd84ac1f0b9e7941a88))


### Bug Fixes

* improve Symfony @Route annotation parsing and add test infrastructure ([43b590b](https://github.com/zerochae/endpoint.nvim/commit/43b590b0733f332bfe3763ccdbfee8c6cf958e83))
* improve Symfony framework search patterns and debugging ([2d7849b](https://github.com/zerochae/endpoint.nvim/commit/2d7849b7622d80327642de99fee2314afc729949))
* isolate test environment from user nvim config ([3dbc22e](https://github.com/zerochae/endpoint.nvim/commit/3dbc22e02ad2d9fab0eb3b423671e398ec4e1aa8))
* resolve all test failures across frameworks ([5b0eb40](https://github.com/zerochae/endpoint.nvim/commit/5b0eb40300ea22ff0feefec5bab7621c6f40c44d))
* **symfony:** add fallback logic for base path extraction ([8c5b73a](https://github.com/zerochae/endpoint.nvim/commit/8c5b73aa5c4d592105212003482a6375efbc48c7))
* **symfony:** handle Route attributes with additional parameters ([77dc89f](https://github.com/zerochae/endpoint.nvim/commit/77dc89fd43b7899b3725c35ce540479cdf5387f1))
* **symfony:** improve base path pattern matching ([dd7a005](https://github.com/zerochae/endpoint.nvim/commit/dd7a005277abe4dbee3f8fc31a0eed140222e6a6))
* **symfony:** improve class declaration detection and base path extraction ([6f317e4](https://github.com/zerochae/endpoint.nvim/commit/6f317e42ff73d43c887f3eb6403b32d237fb46f7))

## [1.6.1](https://github.com/zerochae/endpoint.nvim/compare/v1.6.0...v1.6.1) (2025-09-06)


### Bug Fixes

* resolve merge conflicts and maintain unified cache structure ([e4d7789](https://github.com/zerochae/endpoint.nvim/commit/e4d77899b93b46e8a6d4cd3fd32c88461f47b83d))
* restore and update README.md with correct implementation ([897ded6](https://github.com/zerochae/endpoint.nvim/commit/897ded677feb9724737b6a2c6f35617cdec50cb2))

## [1.6.0](https://github.com/zerochae/endpoint.nvim/compare/v1.5.0...v1.6.0) (2025-09-06)


### Features

* simplify cache structure and unify cache keys ([a9b7a2b](https://github.com/zerochae/endpoint.nvim/commit/a9b7a2b0ff7a926493b5d0ad08f8e41928204adb))
* simplify cache structure and unify cache keys ([98960b9](https://github.com/zerochae/endpoint.nvim/commit/98960b924adfb6db8565147f5bbdb6d1c9a30775))

## [1.5.0](https://github.com/zerochae/endpoint.nvim/compare/v1.4.0...v1.5.0) (2025-09-06)


### Features

* add conditional debug logging function to cache service ([fd2aa01](https://github.com/zerochae/endpoint.nvim/commit/fd2aa013c5806b599662b9e3ceab2c088941b31f))
* implement high-performance batch scanning for all HTTP methods ([7bbea2a](https://github.com/zerochae/endpoint.nvim/commit/7bbea2a7972e0ddf7325a26432eb693a11c2961a))
* implement intelligent cache management for selective method scanning ([9dd6465](https://github.com/zerochae/endpoint.nvim/commit/9dd6465c81ba92fac7ed5aa1a4b17fa3cdc2ac2b))


### Bug Fixes

* add config nil checks for robust error handling ([da7d18d](https://github.com/zerochae/endpoint.nvim/commit/da7d18d17271834fa936cb573d1dc06fa7428d61))
* add fallback for batch scan failures in all_finder ([426ad63](https://github.com/zerochae/endpoint.nvim/commit/426ad63a7cc3e7eaad48c893ba5573c9d40a9d8b))
* add fallback preview data creation for missing entries ([7739d76](https://github.com/zerochae/endpoint.nvim/commit/7739d76673aaf80d89fec19b462994bad95d696a))
* add missing cache persistence after batch scanning ([7eef68e](https://github.com/zerochae/endpoint.nvim/commit/7eef68ec17c5a90633426aaf5f28bab6455f7230))
* convert method names to lowercase for Spring framework patterns ([00971b6](https://github.com/zerochae/endpoint.nvim/commit/00971b6ba4e43610a014b969686c6c15a7a8842e))
* correct framework API calls in batch_scan ([9ab1c3b](https://github.com/zerochae/endpoint.nvim/commit/9ab1c3bc80acc35c6d06c42827461fa19ab8b5d9))
* eliminate duplicate endpoint entries in results ([df8b896](https://github.com/zerochae/endpoint.nvim/commit/df8b896d9e0f9b1fe58341c4de3e37bc3164e162))
* filter out empty endpoint paths to prevent preview errors ([dc9347d](https://github.com/zerochae/endpoint.nvim/commit/dc9347d86b9ef33237561ab30051e7cd6858b980))
* pass method parameter to get_patterns in batch scan ([3b9e0a3](https://github.com/zerochae/endpoint.nvim/commit/3b9e0a38aaa3a7bb378760e31e6c9613725792d7))
* telescope extension should show all endpoints by default ([6e674aa](https://github.com/zerochae/endpoint.nvim/commit/6e674aa26de8fc8b2e16471a56765bdd2c51abce))
* use framework_manager for file patterns in batch scan ([a5ba23e](https://github.com/zerochae/endpoint.nvim/commit/a5ba23ea2dce5f7aabb112f4c1e0d7732d927468))

## [1.4.0](https://github.com/zerochae/endpoint.nvim/compare/v1.3.1...v1.4.0) (2025-09-06)


### Features

* add project-specific cache mode configuration ([f26f4a5](https://github.com/zerochae/endpoint.nvim/commit/f26f4a5eadc7ee4179dd16fa7c9e0d0b60d47f12))

## [1.3.1](https://github.com/zerochae/endpoint.nvim/compare/v1.3.0...v1.3.1) (2025-09-06)


### Bug Fixes

* make Endpoint command argument optional ([3acf1a9](https://github.com/zerochae/endpoint.nvim/commit/3acf1a90e2698e58287f66a4df79f54e90a67ef7))

## [1.3.0](https://github.com/zerochae/endpoint.nvim/compare/v1.2.0...v1.3.0) (2025-09-06)


### Features

* default Endpoint command to show all endpoints ([dcc32b3](https://github.com/zerochae/endpoint.nvim/commit/dcc32b33e64eca9855666e011212594864eda316))

## [1.2.0](https://github.com/zerochae/endpoint.nvim/compare/v1.1.0...v1.2.0) (2025-09-06)


### Features

* add configurable cache status window dimensions ([360af07](https://github.com/zerochae/endpoint.nvim/commit/360af072f261e9053d0387c19872afda2fd874d8))
* add interactive navigation to cache status UI ([9978967](https://github.com/zerochae/endpoint.nvim/commit/9978967ca74830fb20e4f6b03efb552a8127f357))


### Bug Fixes

* handle ALL method in create_endpoint_preview_table ([4312283](https://github.com/zerochae/endpoint.nvim/commit/4312283189c50235a4d40e3bff6aea84ab5b8bfe))
* improve cache status syntax highlighting precision ([21ff3e7](https://github.com/zerochae/endpoint.nvim/commit/21ff3e7d8a9b2e9d3e721b29d93738193a048745))

## [1.1.0](https://github.com/zerochae/endpoint.nvim/compare/v1.0.0...v1.1.0) (2025-09-06)


### Features

* add Endpoint All command to search all HTTP methods ([00ac3be](https://github.com/zerochae/endpoint.nvim/commit/00ac3be5afeec3900d35bea3dc866ef506038825))
* add GitHub issue and PR templates ([681185b](https://github.com/zerochae/endpoint.nvim/commit/681185bd05069c5637cd223bbc36575f5d410c9c))
* add project-specific configuration system ([9a2745a](https://github.com/zerochae/endpoint.nvim/commit/9a2745abfd7dc1b2f852ed3716ae4514b7006441))
* consolidate all commands under main Endpoint command ([19e34ec](https://github.com/zerochae/endpoint.nvim/commit/19e34ec46efd241dbbedab9e44d194da31abc649))
* enhance cache status UI with tree structure and ASCII design ([2eecc37](https://github.com/zerochae/endpoint.nvim/commit/2eecc375863d7e8e507339cb4e4071a537bd0134))
* enhance cache status UI with tree structure and ASCII design ([7a7f4ff](https://github.com/zerochae/endpoint.nvim/commit/7a7f4ff267b7c63c825b9f37fee69cbe0c71d8d1))
* remove time cache mode and add nerd font UI support ([7a11f66](https://github.com/zerochae/endpoint.nvim/commit/7a11f66ac269913ed680a58f17535827caaf2d7e))


### Bug Fixes

* improve cache status UI display ([f119474](https://github.com/zerochae/endpoint.nvim/commit/f119474c655c8384187c393829ebb10a26f09d18))
* improve EndpointCacheKey syntax highlighting specificity ([2cb66b0](https://github.com/zerochae/endpoint.nvim/commit/2cb66b0ca405d54f16de1a2fd034dd82e2f1ec4c))
* improve NestJS controller base path and endpoint path combination ([b77680a](https://github.com/zerochae/endpoint.nvim/commit/b77680ab45c9a5cb2f99a1e64ea2c8be08640f59))
* improve NestJS Controller base path extraction ([685370b](https://github.com/zerochae/endpoint.nvim/commit/685370bad430a8eef26a22d11970330f93d13443))
* improve NestJS Controller base path extraction ([2f84ea2](https://github.com/zerochae/endpoint.nvim/commit/2f84ea2b504b58f1618d5141cda1773f6fb1c8b7))
* improve syntax highlighting and add customization options ([5edfead](https://github.com/zerochae/endpoint.nvim/commit/5edfead01fb4520980ac001dc0079df393e658ea))
* NestJS search patterns and base path combination ([e84509d](https://github.com/zerochae/endpoint.nvim/commit/e84509d0a6aa8b9f72affe8fc2b3a6533139c7d2))
* NestJS search patterns and base path combination ([6223c3f](https://github.com/zerochae/endpoint.nvim/commit/6223c3fcb8990026a56c3e01c573009e222463d7))
* remove _ENDPOINT suffix and fix unknown endpoint display ([8d37b2a](https://github.com/zerochae/endpoint.nvim/commit/8d37b2aa99362335d70ea7c757f248252049dca8))
* resolve buffer name collision in cache status UI ([40870c1](https://github.com/zerochae/endpoint.nvim/commit/40870c1f3bd7b2332b80b87a634c49379e3832ff))
* resolve NestJS syntax errors and remove framework fallback ([ab8ee4d](https://github.com/zerochae/endpoint.nvim/commit/ab8ee4dd69615337b4863393ac1fcf11896eb84b))
* update plugin commands to use new modular structure ([d8e6d04](https://github.com/zerochae/endpoint.nvim/commit/d8e6d042069e90175e91ba2ae86036a88b2b0540))


### Performance Improvements

* remove slow cachemode 'time' and optimize cache logic ([938c298](https://github.com/zerochae/endpoint.nvim/commit/938c2982106d95cc572e78dac735969683a01eff))
* remove slow cachemode 'time' and optimize cache logic ([145838f](https://github.com/zerochae/endpoint.nvim/commit/145838fcdddd7d1f78a21f83d43249788ce9c556))

## 1.0.0 (2025-09-06)


### Features

* add project-specific configuration system ([9a2745a](https://github.com/zerochae/endpoint.nvim/commit/9a2745abfd7dc1b2f852ed3716ae4514b7006441))
* consolidate all commands under main Endpoint command ([19e34ec](https://github.com/zerochae/endpoint.nvim/commit/19e34ec46efd241dbbedab9e44d194da31abc649))
* enhance cache status UI with tree structure and ASCII design ([2eecc37](https://github.com/zerochae/endpoint.nvim/commit/2eecc375863d7e8e507339cb4e4071a537bd0134))
* enhance cache status UI with tree structure and ASCII design ([7a7f4ff](https://github.com/zerochae/endpoint.nvim/commit/7a7f4ff267b7c63c825b9f37fee69cbe0c71d8d1))
* remove time cache mode and add nerd font UI support ([7a11f66](https://github.com/zerochae/endpoint.nvim/commit/7a11f66ac269913ed680a58f17535827caaf2d7e))


### Bug Fixes

* improve cache status UI display ([f119474](https://github.com/zerochae/endpoint.nvim/commit/f119474c655c8384187c393829ebb10a26f09d18))
* improve EndpointCacheKey syntax highlighting specificity ([2cb66b0](https://github.com/zerochae/endpoint.nvim/commit/2cb66b0ca405d54f16de1a2fd034dd82e2f1ec4c))
* improve NestJS controller base path and endpoint path combination ([b77680a](https://github.com/zerochae/endpoint.nvim/commit/b77680ab45c9a5cb2f99a1e64ea2c8be08640f59))
* improve NestJS Controller base path extraction ([685370b](https://github.com/zerochae/endpoint.nvim/commit/685370bad430a8eef26a22d11970330f93d13443))
* improve NestJS Controller base path extraction ([2f84ea2](https://github.com/zerochae/endpoint.nvim/commit/2f84ea2b504b58f1618d5141cda1773f6fb1c8b7))
* improve syntax highlighting and add customization options ([5edfead](https://github.com/zerochae/endpoint.nvim/commit/5edfead01fb4520980ac001dc0079df393e658ea))
* NestJS search patterns and base path combination ([e84509d](https://github.com/zerochae/endpoint.nvim/commit/e84509d0a6aa8b9f72affe8fc2b3a6533139c7d2))
* NestJS search patterns and base path combination ([6223c3f](https://github.com/zerochae/endpoint.nvim/commit/6223c3fcb8990026a56c3e01c573009e222463d7))
* resolve buffer name collision in cache status UI ([40870c1](https://github.com/zerochae/endpoint.nvim/commit/40870c1f3bd7b2332b80b87a634c49379e3832ff))
* resolve NestJS syntax errors and remove framework fallback ([ab8ee4d](https://github.com/zerochae/endpoint.nvim/commit/ab8ee4dd69615337b4863393ac1fcf11896eb84b))
* update plugin commands to use new modular structure ([d8e6d04](https://github.com/zerochae/endpoint.nvim/commit/d8e6d042069e90175e91ba2ae86036a88b2b0540))


### Performance Improvements

* remove slow cachemode 'time' and optimize cache logic ([938c298](https://github.com/zerochae/endpoint.nvim/commit/938c2982106d95cc572e78dac735969683a01eff))
* remove slow cachemode 'time' and optimize cache logic ([145838f](https://github.com/zerochae/endpoint.nvim/commit/145838fcdddd7d1f78a21f83d43249788ce9c556))
