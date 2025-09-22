const { Resolver, Query, Mutation, Args, ID } = require('@nestjs/graphql');
const { ProductService } = require('./product.service');
const { Product } = require('./entities/product.entity');
const { CreateProductInput } = require('./dto/create-product.input');

@Resolver(() => Product)
class ProductResolver {
  constructor(productService) {
    this.productService = productService;
  }

  @Query(() => [Product], { name: 'products' })
  async findAll() {
    return this.productService.findAll();
  }

  @Query(() => Product, { name: 'product' })
  async findOne(@Args('id', { type: () => ID }) id) {
    return this.productService.findOne(id);
  }

  @Query(() => [Product])
  async searchProducts(@Args('query') query) {
    return this.productService.search(query);
  }

  @Query(() => [Product])
  async productsByCategory(@Args('category') category) {
    return this.productService.findByCategory(category);
  }

  @Mutation(() => Product)
  async createProduct(@Args('createProductInput') createProductInput) {
    return this.productService.create(createProductInput);
  }

  @Mutation(() => Product)
  async updateProduct(@Args('id') id, @Args('data') data) {
    return this.productService.update(id, data);
  }

  @Mutation(() => Boolean)
  async removeProduct(@Args('id', { type: () => ID }) id) {
    return this.productService.remove(id);
  }
}

module.exports = { ProductResolver };