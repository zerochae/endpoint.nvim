import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { UserService } from './user.service';
import { User } from './entities/user.entity';
import { CreateUserInput } from './dto/create-user.input';
import { UpdateUserInput } from './dto/update-user.input';

@Resolver(() => User)
export class UserResolver {
  constructor(private readonly userService: UserService) {}

  @Query(() => [User], { name: 'users' })
  async findAll(): Promise<User[]> {
    return this.userService.findAll();
  }

  @Query(() => User, { name: 'user' })
  async findOne(@Args('id', { type: () => ID }) id: string): Promise<User> {
    return this.userService.findOne(id);
  }

  @Query(() => [User])
  async searchUsers(@Args('query') query: string): Promise<User[]> {
    return this.userService.search(query);
  }

  @Mutation(() => User)
  async createUser(@Args('createUserInput') createUserInput: CreateUserInput): Promise<User> {
    return this.userService.create(createUserInput);
  }

  @Mutation(() => User)
  async updateUser(@Args('updateUserInput') updateUserInput: UpdateUserInput): Promise<User> {
    return this.userService.update(updateUserInput.id, updateUserInput);
  }

  @Mutation(() => Boolean)
  async removeUser(@Args('id', { type: () => ID }) id: string): Promise<boolean> {
    return this.userService.remove(id);
  }

  @Mutation(() => User)
  async activateUser(@Args('id', { type: () => ID }) id: string): Promise<User> {
    return this.userService.activate(id);
  }

  @Mutation(() => User)
  async deactivateUser(@Args('id', { type: () => ID }) id: string): Promise<User> {
    return this.userService.deactivate(id);
  }
}