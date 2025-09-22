const {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  Info,
  UseGuards,
  Context
} = require('@nestjs/graphql');
const { MultilineService } = require('./multiline.service');
const { ComplexEntity } = require('./entities/complex.entity');
const { AuthGuard } = require('./guards/auth.guard');

@Resolver(() => ComplexEntity)
class MultilineJsResolver {
  constructor(multilineService) {
    this.multilineService = multilineService;
  }

  // Simple multiline query
  @Query(() => [ComplexEntity])
  async getAllItems() {
    return this.multilineService.findAll();
  }

  // Multiline query with custom name in JavaScript
  @Query(() => [ComplexEntity], {
    name: 'searchItems',
    description: `
      Search items using flexible criteria.
      Supports text search and filtering.
    `
  })
  async performItemSearch(
    @Args('searchTerm') searchTerm,
    @Args('category') category
  ) {
    return this.multilineService.search(searchTerm, category);
  }

  // Complex multiline query with guards
  @Query(() => ComplexEntity, {
    name: 'itemDetails',
    description: `
      Get detailed information about a specific item.
      Includes metadata and related entities.
    `,
    nullable: true,
    complexity: 8
  })
  @UseGuards(AuthGuard)
  async getItemDetails(
    @Args('id', {
      type: () => ID,
      description: 'Item identifier'
    }) id,
    @Args('includeRelated', {
      type: () => Boolean,
      defaultValue: false,
      description: 'Whether to include related entities'
    }) includeRelated
  ) {
    return this.multilineService.findWithDetails(id, includeRelated);
  }

  // Very complex multiline query in JavaScript
  @Query(() => [ComplexEntity], {
    name: 'advancedItemSearch',
    description: `
      Advanced search with multiple criteria:
      - Full text search across multiple fields
      - Category and tag filtering
      - Date range filtering
      - Custom sorting options
      - Pagination support

      This query is optimized for performance
      and includes caching mechanisms.
    `,
    complexity: 20
  })
  @UseGuards(AuthGuard)
  async performAdvancedItemSearch(
    @Args('filters', {
      type: () => String,
      description: 'Search filters as JSON string'
    }) filters,
    @Args('pagination', {
      type: () => String,
      description: 'Pagination settings as JSON string',
      defaultValue: '{"page": 1, "limit": 20}'
    }) pagination,
    @Args('sortBy', {
      type: () => String,
      defaultValue: 'relevance',
      description: 'Sort field'
    }) sortBy,
    @Context() context
  ) {
    const parsedFilters = JSON.parse(filters);
    const parsedPagination = JSON.parse(pagination);

    return this.multilineService.advancedSearch({
      filters: parsedFilters,
      pagination: parsedPagination,
      sortBy,
      userId: context.user?.id
    });
  }

  // Simple multiline mutation
  @Mutation(() => ComplexEntity)
  async createItem(
    @Args('data') data
  ) {
    return this.multilineService.create(data);
  }

  // Multiline mutation with custom name
  @Mutation(() => ComplexEntity, {
    name: 'updateItemData',
    description: 'Update item with new information'
  })
  async performItemUpdate(
    @Args('itemId', { type: () => ID }) itemId,
    @Args('updateData') updateData
  ) {
    return this.multilineService.update(itemId, updateData);
  }

  // Complex multiline mutation with extensive configuration
  @Mutation(() => Boolean, {
    name: 'batchProcessItems',
    description: `
      Process multiple items in a batch operation.

      Features:
      - Supports create, update, delete operations
      - Transaction rollback on failure
      - Progress tracking
      - Partial success handling
      - Async processing for large batches

      Limitations:
      - Maximum 500 items per batch
      - Operations must be of the same type
    `,
    complexity: 30
  })
  @UseGuards(AuthGuard)
  async processBatchItems(
    @Args('operations', {
      type: () => [String],
      description: 'Array of operations as JSON strings'
    }) operations,
    @Args('batchOptions', {
      type: () => String,
      description: 'Batch processing options',
      defaultValue: '{"validateAll": true, "stopOnError": false}'
    }) batchOptions,
    @Args('priority', {
      type: () => String,
      defaultValue: 'NORMAL',
      description: 'Processing priority level'
    }) priority,
    @Context() context
  ) {
    const parsedOperations = operations.map(op => JSON.parse(op));
    const parsedOptions = JSON.parse(batchOptions);

    return this.multilineService.batchProcess(
      parsedOperations,
      {
        ...parsedOptions,
        priority,
        userId: context.user?.id
      }
    );
  }

  // Mutation with very detailed multiline description
  @Mutation(() => ComplexEntity, {
    name: 'createComplexItem',
    description: `
      Create a complex item with comprehensive validation and processing.

      This mutation performs the following steps:
      1. Input validation and sanitization
      2. Business rule validation
      3. Duplicate detection
      4. Resource allocation
      5. Entity creation
      6. Related entity linking
      7. Index updates
      8. Cache invalidation
      9. Event publishing
      10. Audit logging

      Error Handling:
      - Validation errors return detailed field-level messages
      - Business rule violations include suggested corrections
      - System errors are logged and return generic messages

      Performance Notes:
      - Average execution time: 150ms
      - Resource usage is optimized for concurrent requests
      - Automatic retry on transient failures
    `
  })
  @UseGuards(AuthGuard)
  async createComplexItemWithFullProcessing(
    @Args('itemData', {
      type: () => String,
      description: 'Complete item data as JSON'
    }) itemData,
    @Args('processingOptions', {
      type: () => String,
      description: 'Processing configuration options',
      defaultValue: '{"validate": true, "publishEvents": true}'
    }) processingOptions,
    @Args('metadata', {
      type: () => String,
      nullable: true,
      description: 'Additional metadata as JSON'
    }) metadata,
    @Context() context,
    @Info() info
  ) {
    const parsedData = JSON.parse(itemData);
    const parsedOptions = JSON.parse(processingOptions);
    const parsedMetadata = metadata ? JSON.parse(metadata) : null;

    return this.multilineService.createComplex(
      parsedData,
      {
        ...parsedOptions,
        metadata: parsedMetadata,
        userId: context.user?.id,
        requestInfo: info
      }
    );
  }
}

module.exports = { MultilineJsResolver };