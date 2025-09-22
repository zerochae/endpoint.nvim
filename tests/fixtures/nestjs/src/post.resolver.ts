import { Resolver, Query, Mutation, Args, ID, ResolveField, Parent } from '@nestjs/graphql';
import { PostService } from './post.service';
import { UserService } from './user.service';
import { Post } from './entities/post.entity';
import { User } from './entities/user.entity';
import { CreatePostInput } from './dto/create-post.input';
import { UpdatePostInput } from './dto/update-post.input';
import { PostsArgs } from './dto/posts.args';

@Resolver(() => Post)
export class PostResolver {
  constructor(
    private readonly postService: PostService,
    private readonly userService: UserService,
  ) {}

  @Query(() => [Post], { name: 'posts' })
  async findAll(@Args() postsArgs: PostsArgs): Promise<Post[]> {
    return this.postService.findAll(postsArgs);
  }

  @Query(() => Post, { name: 'post' })
  async findOne(@Args('id', { type: () => ID }) id: string): Promise<Post> {
    return this.postService.findOne(id);
  }

  @Query(() => [Post])
  async postsByAuthor(@Args('authorId', { type: () => ID }) authorId: string): Promise<Post[]> {
    return this.postService.findByAuthor(authorId);
  }

  @Query(() => [Post])
  async searchPosts(@Args('query') query: string): Promise<Post[]> {
    return this.postService.search(query);
  }

  @Query(() => [Post])
  async featuredPosts(): Promise<Post[]> {
    return this.postService.findFeatured();
  }

  @Mutation(() => Post)
  async createPost(@Args('createPostInput') createPostInput: CreatePostInput): Promise<Post> {
    return this.postService.create(createPostInput);
  }

  @Mutation(() => Post)
  async updatePost(@Args('updatePostInput') updatePostInput: UpdatePostInput): Promise<Post> {
    return this.postService.update(updatePostInput.id, updatePostInput);
  }

  @Mutation(() => Boolean)
  async removePost(@Args('id', { type: () => ID }) id: string): Promise<boolean> {
    return this.postService.remove(id);
  }

  @Mutation(() => Post)
  async publishPost(@Args('id', { type: () => ID }) id: string): Promise<Post> {
    return this.postService.publish(id);
  }

  @Mutation(() => Post)
  async unpublishPost(@Args('id', { type: () => ID }) id: string): Promise<Post> {
    return this.postService.unpublish(id);
  }

  @Mutation(() => Post)
  async likePost(@Args('id', { type: () => ID }) id: string): Promise<Post> {
    return this.postService.like(id);
  }

  @ResolveField(() => User)
  async author(@Parent() post: Post): Promise<User> {
    return this.userService.findOne(post.authorId);
  }
}