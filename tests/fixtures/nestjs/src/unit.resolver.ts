import {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  Info,
  UseGuards
} from '@nestjs/graphql';
import { GraphQLResolveInfo } from 'graphql';
import { Roles } from '@nestjs/common';
import { UnitService } from './unit.service';
import { Unit } from './entities/unit.entity';
import { FindUnitsArgs } from './dto/find-units.args';
import { UnitListingArgs } from './dto/unit-listing.args';
import { CreateUnitInput } from './dto/create-unit.input';
import { UnitInput } from './dto/unit.input';
import { GqlAuthGuard } from './guards/gql-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { ValidationMutationPipe } from './pipes/validation-mutation.pipe';
import { Role } from './enums/role.enum';

@Resolver(() => Unit)
export class UnitResolver {
  constructor(private readonly unitService: UnitService) {}

  // Complex query with guards and multiple args
  @Query(() => [Unit], { name: 'units' })
  @UseGuards(GqlAuthGuard)
  async find(
    @Args({
      name: 'filters',
      type: () => FindUnitsArgs,
      defaultValue: new FindUnitsArgs(),
    })
    filterArgs: FindUnitsArgs,
    @Args() listingArgs: UnitListingArgs = {},
    @Info() info: GraphQLResolveInfo = null,
  ): Promise<Unit[]> {
    return this.unitService.findAll(filterArgs, listingArgs, info);
  }

  // Simple query without custom name
  @Query(() => Unit)
  async unit(@Args('id', { type: () => ID }) id: string): Promise<Unit> {
    return this.unitService.findOne(id);
  }

  // Query with guards and complex return type
  @Query(() => [Unit], {
    name: 'availableUnits',
    description: 'Get all available units for booking'
  })
  @UseGuards(GqlAuthGuard)
  async getAvailableUnits(
    @Args('checkIn') checkIn: Date,
    @Args('checkOut') checkOut: Date,
    @Args('capacity', { nullable: true }) capacity?: number
  ): Promise<Unit[]> {
    return this.unitService.findAvailable(checkIn, checkOut, capacity);
  }

  // Mutation with guards
  @Mutation(() => Unit, {
    name: 'createUnit',
    description: 'Create a new rental unit'
  })
  @UseGuards(GqlAuthGuard)
  async createNewUnit(
    @Args('input') input: CreateUnitInput,
    @Info() info: GraphQLResolveInfo
  ): Promise<Unit> {
    return this.unitService.create(input, info);
  }

  // Mutation without custom name
  @Mutation(() => Boolean)
  async deleteUnit(@Args('id', { type: () => ID }) id: string): Promise<boolean> {
    return this.unitService.remove(id);
  }

  // Complex mutation with multiple decorators
  @Mutation(() => Unit, {
    name: 'updateUnitAvailability',
    description: `
      Update the availability status of a unit.
      This will affect booking calculations and search results.
    `
  })
  @UseGuards(GqlAuthGuard)
  async updateAvailability(
    @Args('id', { type: () => ID }) id: string,
    @Args('available', { type: () => Boolean }) available: boolean,
    @Args('reason', { nullable: true }) reason?: string
  ): Promise<Unit> {
    return this.unitService.updateAvailability(id, available, reason);
  }

  // Mutation with multiple guards and roles
  @Mutation(() => Unit, { name: 'createUnit' })
  @UseGuards(GqlAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.EDITOR)
  async createOne(
    @Args(
      {
        name: 'values',
        type: () => UnitInput,
      },
      new ValidationMutationPipe<UnitInput>(UnitInput),
    )
    dto: UnitInput,
  ): Promise<Unit> {
    return this.unitService.createWithValidation(dto);
  }
}