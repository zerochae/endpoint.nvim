# Changelog

## [2.5.0](https://github.com/zerochae/endpoint.nvim/compare/v2.4.0...v2.5.0) (2025-09-24)


### Features

* complete DotNet multiline annotation support with comprehensive fixes ([7162f3e](https://github.com/zerochae/endpoint.nvim/commit/7162f3edefc839281159addc9cdc50c6f736bce9))
* complete FastAPI multiline support and resolve DotNet parsing artifacts ([751ada7](https://github.com/zerochae/endpoint.nvim/commit/751ada71257f9843a47117c768dec6ab8cabebae))
* implement comprehensive DotNet multiline attribute support ([d96853d](https://github.com/zerochae/endpoint.nvim/commit/d96853d10221ec665264c3db703beeb7602fd6ae))


### Bug Fixes

* enhance comment filtering with file context awareness ([fb556f0](https://github.com/zerochae/endpoint.nvim/commit/fb556f0e905b622f0758167c574702b0cfe26dc5))
* filter DotNet multiline artifacts and improve search patterns ([b4f1ccd](https://github.com/zerochae/endpoint.nvim/commit/b4f1ccde23de6f9299898c6361a5c66a513e2523))
* improve DotNet multiline attribute detection and path extraction logic ([89d128d](https://github.com/zerochae/endpoint.nvim/commit/89d128d3e6822515ac761d1ab88f285b4475a2f3))
* improve DotNet multiline attribute parsing and comment filtering ([03a3222](https://github.com/zerochae/endpoint.nvim/commit/03a3222a934de29717d2cf8d5305f6123136c7a0))
* resolve critical DotNet parser path extraction and comment filtering issues ([99162e0](https://github.com/zerochae/endpoint.nvim/commit/99162e07ee8aa33d108cdb0569be29cb20913184))
* resolve DotNet parser path combination and commented code issues ([299e88b](https://github.com/zerochae/endpoint.nvim/commit/299e88b5c4026f3f40241e36046d8b1a7db93098))
* simplify DotNet path combination logic for proper endpoint display ([f814c11](https://github.com/zerochae/endpoint.nvim/commit/f814c11a363ac018a7d76bfe2b4562c271e8024f))
* strengthen DotNet multiline artifact filtering with comprehensive checks ([581fc70](https://github.com/zerochae/endpoint.nvim/commit/581fc70d912be645688c8656bec85022a5960e20))

## [2.4.0](https://github.com/zerochae/endpoint.nvim/compare/v2.3.0...v2.4.0) (2025-09-24)


### Features

* implement comprehensive Ktor multiline routing support ([c91dc9b](https://github.com/zerochae/endpoint.nvim/commit/c91dc9b701fefd86ff903cafad6fad5472fa8a60))
* implement comprehensive Ktor multiline routing support ([f4b6014](https://github.com/zerochae/endpoint.nvim/commit/f4b6014da34c5f9c6425686a034778b5419d30de))
* implement comprehensive Symfony multiline annotation support ([fcbd3fb](https://github.com/zerochae/endpoint.nvim/commit/fcbd3fb5d5ea4eec3dcb801839c41a6a2e752df0))

## [2.3.0](https://github.com/zerochae/endpoint.nvim/compare/v2.2.1...v2.3.0) (2025-09-24)


### Features

* add configurable previewer highlighting toggle ([fd934ca](https://github.com/zerochae/endpoint.nvim/commit/fd934ca1f1d7c483cc51bae2e743a594ef5b81cf))
* add multiline endpoint support across all frameworks ([d6989b7](https://github.com/zerochae/endpoint.nvim/commit/d6989b7f570b21e9235185b093b1472c1e6d231c))
* enhance picker system with improved highlighting and multiline support ([2d82e3a](https://github.com/zerochae/endpoint.nvim/commit/2d82e3a4dde79d5369b3272001a7a3b85b38c90d))
* enhance Spring parser with comprehensive multiline annotation support ([2e1b619](https://github.com/zerochae/endpoint.nvim/commit/2e1b619e9edc5bbe7edd17c4023e4d90352f1509))


### Bug Fixes

* add end_line_number field to endpoint.entry type ([9b7d55e](https://github.com/zerochae/endpoint.nvim/commit/9b7d55ee185e0bdd8a30441b7875039d7d4e3739))
* remove unused parameter warnings in parsers ([9bb6695](https://github.com/zerochae/endpoint.nvim/commit/9bb66956090e1deb299548d1299f662bb8f4a92d))
* resolve type issues and remove unused code in servlet parser ([73363cb](https://github.com/zerochae/endpoint.nvim/commit/73363cbcb9ac033406241521246dcc22ca6f56bc))
* resolve undefined field warning in plugin ([0a004dc](https://github.com/zerochae/endpoint.nvim/commit/0a004dc7042cb5661643abb8d5a6eb51bb75dadc))
* resolve variable redefinition in nestjs parser ([cf5bab6](https://github.com/zerochae/endpoint.nvim/commit/cf5bab6d4cda6fef8fd5d52c82b1ff2b0f55f8a9))

## [2.2.1](https://github.com/zerochae/endpoint.nvim/compare/v2.2.0...v2.2.1) (2025-09-23)


### Bug Fixes

* improve picker selection logic with explicit configuration ([d1a451d](https://github.com/zerochae/endpoint.nvim/commit/d1a451da63a22f9ba6c444b045288d724e513536))

## [2.2.0](https://github.com/zerochae/endpoint.nvim/compare/v2.1.0...v2.2.0) (2025-09-23)


### Features

* add HTTP method filtering to endpoint command ([55d7fba](https://github.com/zerochae/endpoint.nvim/commit/55d7fbabbdb79e7ea512a6065fef36c7ac672e00))
* implement persistent disk cache with configurable cache modes ([e101692](https://github.com/zerochae/endpoint.nvim/commit/e1016925c668580d1c2b153c7329ae4ec49af478))


### Performance Improvements

* implement method-specific search with optimized caching ([d0010fa](https://github.com/zerochae/endpoint.nvim/commit/d0010fa1a292b625839b4c98f47be55de192ff48))
* switch from JSON to Lua file format for persistent cache ([153ab50](https://github.com/zerochae/endpoint.nvim/commit/153ab50ea14b0cda4cc36a0731ec37e78e562b28))

## [2.1.0](https://github.com/zerochae/endpoint.nvim/compare/v2.0.0...v2.1.0) (2025-09-22)


### Features

* add comprehensive Express TypeScript support ([9ef6c89](https://github.com/zerochae/endpoint.nvim/commit/9ef6c89770e85e2e55537d45bcb152c91a34c713))
* add comprehensive multiline TypeScript generic support ([0b0d0ef](https://github.com/zerochae/endpoint.nvim/commit/0b0d0ef1b5d6b687915baebfac07e00e01e869cd))
* comprehensive NestJS improvements with GraphQL and multiline support ([9498d34](https://github.com/zerochae/endpoint.nvim/commit/9498d34c474a61369e9373d598f1de92c5a575f0))
* Express TypeScript support with comprehensive multiline generic detection ([3625bd0](https://github.com/zerochae/endpoint.nvim/commit/3625bd025f7a122dea6993a8cafef6cb88e1bf26))

## [2.0.0](https://github.com/zerochae/endpoint.nvim/compare/v1.11.0...v2.0.0) (2025-09-19)


### ⚠ BREAKING CHANGES

* complete framework system refactor with comprehensive parser improvements

### Features

* add Django framework support for Python projects ([139237b](https://github.com/zerochae/endpoint.nvim/commit/139237be0a94aac75b98380e22d3ae9efabe5bc7))
* complete framework system refactor with comprehensive parser improvements ([84c0e4b](https://github.com/zerochae/endpoint.nvim/commit/84c0e4b74cd5da7ddd6ae63ab294613135007feb))
* complete framework system refactor with comprehensive parser improvements ([8f92a3d](https://github.com/zerochae/endpoint.nvim/commit/8f92a3da92d611b5cf4be369d0cd612aa02998cc))
* complete Ktor framework implementation with clean code ([79a8a18](https://github.com/zerochae/endpoint.nvim/commit/79a8a18166a767527f39850f28166deecc7aab23))
* completely refactor framework system architecture ([daf0057](https://github.com/zerochae/endpoint.nvim/commit/daf005793e5215dc74d8236fd356d1a970a3b886))
* finalize framework system refactor with comprehensive improvements ([bae1b23](https://github.com/zerochae/endpoint.nvim/commit/bae1b239286618d589f061f320072deaf3aa87e4))
* fix and reorganize framework tests ([52b6f4d](https://github.com/zerochae/endpoint.nvim/commit/52b6f4d17816df11db747ece56bb1e76e6fac546))
* fix Symfony and React Router framework tests ([5dd7163](https://github.com/zerochae/endpoint.nvim/commit/5dd71638aaf48e5ba869f1393e8141aac25b870d))
* implement complete servlet framework support with multiple URL patterns ([f919b7d](https://github.com/zerochae/endpoint.nvim/commit/f919b7d0b0384a24c1ac84381014d4a6f757e9b3))
* implement Express framework with unified parser architecture ([ebc0a22](https://github.com/zerochae/endpoint.nvim/commit/ebc0a224800bd49e412f22f133407243ed84af1c))
* implement NestJS, FastAPI, DotNet, and Ktor frameworks with unified architecture ([147263f](https://github.com/zerochae/endpoint.nvim/commit/147263f6024c3fae63bdd14b9257fcef1b367c06))
* implement Servlet and React Router frameworks completing framework ecosystem ([b94d722](https://github.com/zerochae/endpoint.nvim/commit/b94d722a8f51c697cc7c5fdcf92dae8ab02f30a3))
* implement Symfony framework with unified parser architecture ([30ae5c6](https://github.com/zerochae/endpoint.nvim/commit/30ae5c672040402dcc7f847c7378167c8fc065f8))
* refactor framework system to modular architecture ([13196b5](https://github.com/zerochae/endpoint.nvim/commit/13196b53e23cb439230aa7a8bb48a9bcff8856da))
* refactor to proper OOP architecture with encapsulation ([7a435af](https://github.com/zerochae/endpoint.nvim/commit/7a435afb9fde47529f38ebdd871a6db297b7c7ce))
* remove Strategy naming pattern and reorganize codebase structure ([38d7d11](https://github.com/zerochae/endpoint.nvim/commit/38d7d11eb17c70b20f6186a574f50f01c48e4354))
* simplify framework system and add comprehensive documentation ([dbac762](https://github.com/zerochae/endpoint.nvim/commit/dbac76207e23d1c2a9631f00efce9ba1614981f4))


### Bug Fixes

* add missing orders_controller.rb to fix Rails resources navigation ([42441a5](https://github.com/zerochae/endpoint.nvim/commit/42441a54655745bba453983124c6bd05e411f1a8))
* eliminate duplicate .NET endpoint results by focusing search on Route attributes ([e412617](https://github.com/zerochae/endpoint.nvim/commit/e412617e6e2b7ca439e9ae3b86df4a0cc4de741d))
* filter member/collection routes in Rails parser ([c0d5b24](https://github.com/zerochae/endpoint.nvim/commit/c0d5b2402534733a99654da286ee4a82bf6173b4))
* filter out URL patterns and class definitions from Django search results ([16ac2b5](https://github.com/zerochae/endpoint.nvim/commit/16ac2b5897063da0b4827b908310837f161ed60a))
* filter standalone HTTP attributes without Route in .NET parser ([8738203](https://github.com/zerochae/endpoint.nvim/commit/8738203ef1cc3ae930efc0778cdd344688de84d0))
* improve .NET and Rails parser accuracy ([2e89755](https://github.com/zerochae/endpoint.nvim/commit/2e897550282a1ab6e1a963a2389431cb2c32b2cc))
* improve Django ViewSet URL generation and action display ([ca33f3e](https://github.com/zerochae/endpoint.nvim/commit/ca33f3ecb3869a4675249b4aa4c8ffd9e9e438c0))
* resolve .NET [controller] token replacement in Route attributes ([9e85230](https://github.com/zerochae/endpoint.nvim/commit/9e85230600340fad23bbd98739681446647877d9))
* resolve .NET controller endpoint parsing issues ([40f3880](https://github.com/zerochae/endpoint.nvim/commit/40f3880766119bf5628914bf09eb6678fe0acd51))
* simplify .NET duplicate filtering using Spring approach ([d5bbf2f](https://github.com/zerochae/endpoint.nvim/commit/d5bbf2fc0e41a10807b475181646730abcdb7877))
* update parser files after framework refactoring ([add88fc](https://github.com/zerochae/endpoint.nvim/commit/add88fc7d03dad4f976a70bb9b90adcfbe29638b))
* update Rails test to match actual framework implementation ([4b8cba0](https://github.com/zerochae/endpoint.nvim/commit/4b8cba0e3e5f405f62b841f5b0abb147e7e61cba))
* update type definitions for Strategy naming removal ([24ed81f](https://github.com/zerochae/endpoint.nvim/commit/24ed81f3c27c629bc7de6840eef62a14f7bf208c))

## [1.12.0] (2025-09-17)

### Features

* **rails**: comprehensive nested route support with accurate path generation
* **rails**: direct controller action linking for all route types
* **rails**: precise column positioning for accurate previews
* **rails**: enhanced member and collection route context preservation
* **rails**: Rails-familiar `controller#action` endpoint display format
* **rails**: enhanced telescope highlighting for `METHOD[controller#action]` pattern

### Bug Fixes

* **rails**: fix nested routes linking to routes.rb instead of controller actions
* **rails**: fix member/collection routes missing parent resource context
* **rails**: fix preview truncation due to incorrect column values
* **rails**: improve parent resource detection for deeply nested routes

### UI/UX Improvements

* **rails**: endpoint display now uses `GET[users#profile] /users/:id/profile` format
* **rails**: telescope picker highlights `METHOD[controller#action]` portion for easy identification
* **rails**: format matches Rails `routes` command output for developer familiarity

## [1.11.0](https://github.com/zerochae/endpoint.nvim/compare/v1.10.0...v1.11.0) (2025-09-14)


### Features

* add GitHub Wiki as submodule ([36ef13b](https://github.com/zerochae/endpoint.nvim/commit/36ef13bc29899aedf310c0de0130312f6c8707a6))
* add GitHub Wiki as submodule ([12bfffb](https://github.com/zerochae/endpoint.nvim/commit/12bfffbaca7d526774d1812036ea576365dcfc1e))


### Bug Fixes

* handle string picker config in migration logic ([6eef57d](https://github.com/zerochae/endpoint.nvim/commit/6eef57de9c91f6fbd94df5f4a5bdb5d5af0ebd03))

## [1.10.0](https://github.com/zerochae/endpoint.nvim/compare/v1.9.0...v1.10.0) (2025-09-13)


### Features

* add comprehensive .NET Core framework support ([b39c7b2](https://github.com/zerochae/endpoint.nvim/commit/b39c7b2a964f698e595b9c21ffa1f32353467e5c))

## [1.9.0](https://github.com/zerochae/endpoint.nvim/compare/v1.8.0...v1.9.0) (2025-09-13)


### Features

* add Ktor framework support for Kotlin projects ([86dd68f](https://github.com/zerochae/endpoint.nvim/commit/86dd68f5cc109bb8d884ad90c22d8b899fe188c3))
* add search command utility to reduce framework code duplication ([3c2b416](https://github.com/zerochae/endpoint.nvim/commit/3c2b41618d3386c199c1573ff5220c397a48bce9))
* integrate cache status UI with show_cache_stats function ([0475b35](https://github.com/zerochae/endpoint.nvim/commit/0475b35737f8c2934852c310c74dea8f9e880b5e))


### Bug Fixes

* improve Ktor framework detection patterns ([68964f7](https://github.com/zerochae/endpoint.nvim/commit/68964f725e9309beb297bda2db2bbb1ce63ba84e))
* resolve symfony search command utility integration ([326187e](https://github.com/zerochae/endpoint.nvim/commit/326187e343ec80a1cd8da650a72e4219118479d6))
* update cache_status.lua to use current project structure ([d88c866](https://github.com/zerochae/endpoint.nvim/commit/d88c866c84c8b85c778fcaceede813222840de3a))

## [1.8.0](https://github.com/zerochae/endpoint.nvim/compare/v1.7.0...v1.8.0) (2025-09-13)


### Features

* Add comprehensive Snacks.nvim picker support with picker-specific configuration ([2916329](https://github.com/zerochae/endpoint.nvim/commit/2916329dc9f786678cc79f79d71324a11e3c8cd4))
* add picker_opts support to snacks picker ([439c642](https://github.com/zerochae/endpoint.nvim/commit/439c64256897f641d13df4af41444f907f2ea7a3))
* add picker_opts support to vim_ui_select picker ([a12fec8](https://github.com/zerochae/endpoint.nvim/commit/a12fec872c97ef77bff663ea122f7b524d13bf8d))
* finalize snacks.nvim picker implementation with working navigation ([0035690](https://github.com/zerochae/endpoint.nvim/commit/0035690f01280bd452f6384ed69990e95b998db0))
* implement comprehensive snacks.nvim picker support ([b014fb9](https://github.com/zerochae/endpoint.nvim/commit/b014fb9fe9205869ef67263a25ed02b839da359e))
* implement picker-specific configuration structure ([2658b83](https://github.com/zerochae/endpoint.nvim/commit/2658b833ee0caa9d71c2fdaab5614b3168b874d9))


### Bug Fixes

* update vim_ui_select prompt text for consistency ([7f6dc12](https://github.com/zerochae/endpoint.nvim/commit/7f6dc12a415e62fe57aadf90c76836dc5cea2fd4))

## [1.7.0](https://github.com/zerochae/endpoint.nvim/compare/v1.6.0...v1.7.0) (2025-09-13)


### Features

* add common test utilities and refactor framework specs ([4608366](https://github.com/zerochae/endpoint.nvim/commit/4608366dfba182329b7e759f0ee53b9bff8a528f))


### Bug Fixes

* improve Spring framework detection to avoid conflicts with servlet ([0f52453](https://github.com/zerochae/endpoint.nvim/commit/0f52453eb4085a9f901cfe5e1b1636965953c3ba))

## [1.6.0](https://github.com/zerochae/endpoint.nvim/compare/v1.5.1...v1.6.0) (2025-09-13)


### Features

* add Java Servlet framework support ([a986092](https://github.com/zerochae/endpoint.nvim/commit/a9860927c3dbcf5d1a56fedff5c2c83a2d7adcec))

## [1.5.1](https://github.com/zerochae/endpoint.nvim/compare/v1.5.0...v1.5.1) (2025-09-13)


### Bug Fixes

* resolve Express destructured parsing and React Router pattern matching ([197605c](https://github.com/zerochae/endpoint.nvim/commit/197605c6d1c051ce9b076d0cdbf5fd5f199bc45f))

## [1.5.0](https://github.com/zerochae/endpoint.nvim/compare/v1.4.0...v1.5.0) (2025-09-13)


### Features

* **express:** add comprehensive Express.js framework support ([6e54749](https://github.com/zerochae/endpoint.nvim/commit/6e54749f0687d6b673d187ae406a3fb2b31861d2))

## [1.4.0](https://github.com/zerochae/endpoint.nvim/compare/v1.3.1...v1.4.0) (2025-09-13)


### Features

* **rails:** enhance Rails support with configurable display formats and improve search functionality ([c4bd7d4](https://github.com/zerochae/endpoint.nvim/commit/c4bd7d42ee891d7cd380182405dfd92b6ef99e2e))

## [1.3.1](https://github.com/zerochae/endpoint.nvim/compare/v1.3.0...v1.3.1) (2025-09-12)


### Bug Fixes

* **spring:** exclude class-level @RequestMapping from endpoint detection ([bd0c271](https://github.com/zerochae/endpoint.nvim/commit/bd0c271b5c36752e90d622d04cb79ac49dcce44c))

## [1.3.0](https://github.com/zerochae/endpoint.nvim/compare/v1.2.0...v1.3.0) (2025-09-12)


### Features

* add Rails framework support with endpoint detection ([8423ac0](https://github.com/zerochae/endpoint.nvim/commit/8423ac043ea4cde557902353f3bfe9162d9dac25))
* enhance Rails framework with comprehensive routes.rb support ([327bc75](https://github.com/zerochae/endpoint.nvim/commit/327bc75a4d39597b63dd86d97ea8e0b1f34dfffc))
* implement Rails action annotations with enhanced display format ([1579c3a](https://github.com/zerochae/endpoint.nvim/commit/1579c3add4328f55fd9789331c462bfeb63ae691))
* improve picker UI with centering and display enhancements ([12115d8](https://github.com/zerochae/endpoint.nvim/commit/12115d88ea00be6c066fcce4f24fbaf17f8bb5c8))


### Bug Fixes

* improve test assertions across framework specs ([8700e26](https://github.com/zerochae/endpoint.nvim/commit/8700e262b315375b80163a68df5ffd84ac63cdb7))

## [1.2.0](https://github.com/zerochae/endpoint.nvim/compare/v1.1.0...v1.2.0) (2025-09-12)


### Features

* add UI configuration types for method display customization ([fdae803](https://github.com/zerochae/endpoint.nvim/commit/fdae8037c726bfac40978d7bc229884198eb2c55))

## [1.1.0](https://github.com/zerochae/endpoint.nvim/compare/v1.0.1...v1.1.0) (2025-09-12)


### Features

* enhance Symfony framework support and clean up legacy code ([fb0dafb](https://github.com/zerochae/endpoint.nvim/commit/fb0dafb155b15d2746aad2d293e85a1b66e241a4))
* enhance test fixtures with comprehensive endpoint coverage ([bad5290](https://github.com/zerochae/endpoint.nvim/commit/bad5290e91064e35c7d6819bfc1d43c8b38cdcc7))
* extract actual HTTP methods when searching with ALL ([89ba40d](https://github.com/zerochae/endpoint.nvim/commit/89ba40d49a9daf27a2f5e835acf678ea3b829566))
* unify scanner service - merge duplicate utils ([ecf2165](https://github.com/zerochae/endpoint.nvim/commit/ecf21651a43ed9499fa7ec8fa6ec8d1a10eb7991))


### Bug Fixes

* allow memory caching when cache_mode is none for UI display ([f95ad3c](https://github.com/zerochae/endpoint.nvim/commit/f95ad3c395ebe8f00ef8241226491432fc7b00d0))
* enhance Spring framework with comprehensive path parameter support ([6f1e537](https://github.com/zerochae/endpoint.nvim/commit/6f1e5373c695232246c421a9e230871a968b5b5b))
* improve persistent mode cache performance and prevent duplicates ([e145e9c](https://github.com/zerochae/endpoint.nvim/commit/e145e9c72e050fddb057ca40f3de25a3f5d7ac75))
* prevent data loss in session cache mode by disabling cleanup operations ([d54610b](https://github.com/zerochae/endpoint.nvim/commit/d54610bb025341d7a94b08c701546344619d4f03))
* resolve 260+ Lua type errors and improve type safety ([4a05c70](https://github.com/zerochae/endpoint.nvim/commit/4a05c7084df677c2808b43065ea7cad1ce0517da))
* resolve FastAPI framework multiline decorator and base path issues ([b7b2a06](https://github.com/zerochae/endpoint.nvim/commit/b7b2a068cf773778b65572d490104c532d15c402))
* resolve framework test failures and improve pattern matching ([3783809](https://github.com/zerochae/endpoint.nvim/commit/37838096ec3fb1308014c0f679161e36dc7b1fb4))
* resolve Lua linter warnings and errors ([d6a922a](https://github.com/zerochae/endpoint.nvim/commit/d6a922abb3c0417862073c0221c5cd52e6615a7c))
* resolve NestJS path formatting and controller prefix issues ([60f059f](https://github.com/zerochae/endpoint.nvim/commit/60f059fa15e988132505cf713e57ee74fdf2c0d7))
* skip cache operations when cache_mode is none ([bc7bfd6](https://github.com/zerochae/endpoint.nvim/commit/bc7bfd6e7a00e816f214a7c31f8756290b9c3452))
* use all patterns in grep commands instead of just the first one ([41f384d](https://github.com/zerochae/endpoint.nvim/commit/41f384d22ec64e7a540c7571dc701729a0f6bdd4))
* use endpoint.method instead of search method for cache table creation ([07c62e0](https://github.com/zerochae/endpoint.nvim/commit/07c62e093dca28b9052d627a8ed0ed0dd6a8d8ba))


### Performance Improvements

* optimize cache performance and previewer generation ([4b1a861](https://github.com/zerochae/endpoint.nvim/commit/4b1a8614b4fedf6ffda7d239a74e1a9bd880e46c))

## [1.0.1](https://github.com/zerochae/endpoint.nvim/compare/v1.0.0...v1.0.1) (2025-09-11)


### Bug Fixes

* enable preview data and ensure temp tables clear in cache_mode = 'none' ([44ca4b9](https://github.com/zerochae/endpoint.nvim/commit/44ca4b90a53d4427ac2ff2e8033d13b732f58e8d))
* enable telescope finder to show results in cache_mode = 'none' ([b85641a](https://github.com/zerochae/endpoint.nvim/commit/b85641a55863ead92dc446fbe533cb4663c2e6a8))
* prevent cache operations when cache_mode is 'none' ([554ccb9](https://github.com/zerochae/endpoint.nvim/commit/554ccb9cd83261e413f52f720168c9e94e313e6c))
* prevent nil temp_find_table errors in cache functions ([ac4b143](https://github.com/zerochae/endpoint.nvim/commit/ac4b143dc06a69fc1955f4504f6e387619caf7cf))

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
