import {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  Info,
  UseGuards,
  Context
} from '@nestjs/graphql';
import { GraphQLResolveInfo } from 'graphql';
import { MultilineService } from './multiline.service';
import { ComplexEntity } from './entities/complex.entity';
import { SearchFilters } from './dto/search-filters.input';
import { PaginationArgs } from './dto/pagination.args';
import { AuthGuard } from './guards/auth.guard';

@Resolver(() => ComplexEntity)
export class MultilineResolver {
  constructor(private readonly multilineService: MultilineService) {}

  // Simple multiline query without custom name
  @Query(() => [ComplexEntity])
  async getAllEntities(): Promise<ComplexEntity[]> {
    return this.multilineService.findAll();
  }

  // Multiline query with custom name and description
  @Query(() => [ComplexEntity], {
    name: 'searchEntities',
    description: `
      Advanced search functionality for complex entities.
      Supports multiple filter criteria and pagination.
    `
  })
  async performAdvancedSearch(
    @Args('filters') filters: SearchFilters,
    @Args() pagination: PaginationArgs
  ): Promise<ComplexEntity[]> {
    return this.multilineService.search(filters, pagination);
  }

  // Complex multiline query with multiple options
  @Query(() => ComplexEntity, {
    name: 'entityById',
    description: `
      Retrieve a single entity by its unique identifier.
      Includes related data and metadata.
    `,
    nullable: true,
    complexity: 5
  })
  @UseGuards(AuthGuard)
  async findEntityById(
    @Args('id', {
      type: () => ID,
      description: 'The unique identifier of the entity'
    }) id: string,
    @Info() info: GraphQLResolveInfo
  ): Promise<ComplexEntity | null> {
    return this.multilineService.findOneWithRelations(id, info);
  }

  // Very complex multiline query with extensive configuration
  @Query(() => [ComplexEntity], {
    name: 'entitiesByComplexCriteria',
    description: `
      Advanced query that supports:
      - Multiple filter types (text, date, numeric)
      - Sorting by various fields
      - Pagination with cursor support
      - Field selection optimization
      - Access control validation
    `,
    complexity: 25,
    deprecationReason: null
  })
  @UseGuards(AuthGuard)
  async findEntitiesByComplexCriteria(
    @Args('textFilter', {
      type: () => String,
      nullable: true,
      description: 'Text search across multiple fields'
    }) textFilter?: string,
    @Args('dateRange', {
      type: () => String,
      nullable: true,
      description: 'Date range filter in ISO format'
    }) dateRange?: string,
    @Args('numericFilters', {
      type: () => [String],
      nullable: true,
      description: 'Array of numeric range filters'
    }) numericFilters?: string[],
    @Args('sortBy', {
      type: () => String,
      defaultValue: 'createdAt',
      description: 'Field to sort results by'
    }) sortBy: string,
    @Args('sortOrder', {
      type: () => String,
      defaultValue: 'DESC',
      description: 'Sort direction (ASC or DESC)'
    }) sortOrder: string,
    @Context() context: any
  ): Promise<ComplexEntity[]> {
    return this.multilineService.findByComplexCriteria({
      textFilter,
      dateRange,
      numericFilters,
      sortBy,
      sortOrder,
      userId: context.user?.id
    });
  }

  // Simple multiline mutation
  @Mutation(() => ComplexEntity)
  async createEntity(
    @Args('input') input: any
  ): Promise<ComplexEntity> {
    return this.multilineService.create(input);
  }

  // Multiline mutation with custom name
  @Mutation(() => ComplexEntity, {
    name: 'updateEntity',
    description: 'Update an existing entity with new data'
  })
  async performEntityUpdate(
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: any
  ): Promise<ComplexEntity> {
    return this.multilineService.update(id, input);
  }

  // Complex multiline mutation with validation
  @Mutation(() => ComplexEntity, {
    name: 'createEntityWithValidation',
    description: `
      Create a new entity with comprehensive validation:
      - Input data validation
      - Business rule validation
      - Authorization checks
      - Audit logging
    `,
    complexity: 15
  })
  @UseGuards(AuthGuard)
  async createEntityWithComprehensiveValidation(
    @Args('entityData', {
      type: () => String,
      description: 'JSON string containing entity data'
    }) entityData: string,
    @Args('validationLevel', {
      type: () => String,
      defaultValue: 'STRICT',
      description: 'Level of validation to apply'
    }) validationLevel: string,
    @Args('skipBusinessRules', {
      type: () => Boolean,
      defaultValue: false,
      description: 'Whether to skip business rule validation'
    }) skipBusinessRules: boolean,
    @Context() context: any,
    @Info() info: GraphQLResolveInfo
  ): Promise<ComplexEntity> {
    const parsedData = JSON.parse(entityData);

    return this.multilineService.createWithValidation(
      parsedData,
      {
        validationLevel,
        skipBusinessRules,
        userId: context.user?.id,
        requestInfo: info
      }
    );
  }

  // Mutation with very long multiline configuration
  @Mutation(() => Boolean, {
    name: 'bulkProcessEntities',
    description: `
      Bulk process multiple entities in a single operation.

      This operation supports:
      - Batch creation, update, and deletion
      - Transaction safety with rollback capability
      - Progress tracking and status reporting
      - Error handling with partial success support
      - Rate limiting and throttling
      - Async processing for large datasets

      Usage Guidelines:
      - Maximum 1000 entities per operation
      - Use pagination for larger datasets
      - Monitor progress using the returned operation ID
    `,
    complexity: 50,
    deprecationReason: null
  })
  @UseGuards(AuthGuard)
  async performBulkEntityProcessing(
    @Args('operations', {
      type: () => [String],
      description: 'Array of operation definitions as JSON strings'
    }) operations: string[],
    @Args('options', {
      type: () => String,
      description: 'Processing options as JSON string',
      defaultValue: '{"async": false, "validate": true}'
    }) options: string,
    @Args('batchSize', {
      type: () => Number,
      description: 'Number of entities to process in each batch',
      defaultValue: 100
    }) batchSize: number,
    @Args('timeoutMs', {
      type: () => Number,
      description: 'Maximum processing time in milliseconds',
      defaultValue: 300000
    }) timeoutMs: number,
    @Context() context: any
  ): Promise<boolean> {
    const parsedOperations = operations.map(op => JSON.parse(op));
    const parsedOptions = JSON.parse(options);

    return this.multilineService.bulkProcess(
      parsedOperations,
      {
        ...parsedOptions,
        batchSize,
        timeoutMs,
        userId: context.user?.id
      }
    );
  }
}