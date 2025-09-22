import {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  ResolveField,
  Parent,
  Subscription
} from '@nestjs/graphql';
import { OrderService } from './order.service';
import { Order } from './entities/order.entity';
import { CreateOrderInput } from './dto/create-order.input';

@Resolver(() => Order)
export class OrderResolver {
  constructor(private readonly orderService: OrderService) {}

  // Simple single-line query
  @Query(() => [Order])
  async orders(): Promise<Order[]> {
    return this.orderService.findAll();
  }

  // Multiline query with complex options
  @Query(() => Order, {
    name: 'orderById',
    description: 'Find a specific order by its ID',
    nullable: true,
    complexity: 5
  })
  async findOrderById(
    @Args('id', {
      type: () => ID,
      description: 'The unique identifier for the order'
    }) id: string
  ): Promise<Order | null> {
    return this.orderService.findOne(id);
  }

  // Complex multiline query with multiple decorators
  @Query(() => [Order], {
    name: 'ordersByStatus',
    description: `
      Retrieve orders filtered by their current status.
      Supports pagination and sorting options.
    `,
    complexity: 10
  })
  async getOrdersByStatus(
    @Args('status', {
      type: () => String,
      description: 'Order status to filter by'
    }) status: string,
    @Args('limit', {
      type: () => Number,
      defaultValue: 10,
      description: 'Maximum number of orders to return'
    }) limit: number,
    @Args('offset', {
      type: () => Number,
      defaultValue: 0,
      description: 'Number of orders to skip'
    }) offset: number
  ): Promise<Order[]> {
    return this.orderService.findByStatus(status, { limit, offset });
  }

  // Multiline mutation with validation
  @Mutation(() => Order, {
    name: 'createOrder',
    description: `
      Create a new order with the provided input data.
      Validates customer information and product availability.
    `
  })
  async createNewOrder(
    @Args('input', {
      type: () => CreateOrderInput,
      description: 'Order creation data including customer and items'
    }) input: CreateOrderInput
  ): Promise<Order> {
    return this.orderService.create(input);
  }

  // Complex mutation with multiple steps
  @Mutation(() => Order, {
    name: 'processOrder',
    description: `
      Process an existing order through multiple stages:
      1. Validate payment information
      2. Reserve inventory
      3. Generate shipping label
      4. Send confirmation email
    `,
    complexity: 20
  })
  async processExistingOrder(
    @Args('orderId', { type: () => ID }) orderId: string,
    @Args('paymentMethod', {
      type: () => String,
      description: 'Payment method to use for processing'
    }) paymentMethod: string
  ): Promise<Order> {
    return this.orderService.process(orderId, paymentMethod);
  }

  // Subscription with multiline configuration
  @Subscription(() => Order, {
    name: 'orderStatusUpdated',
    description: `
      Subscribe to real-time order status updates.
      Emits events when order status changes.
    `,
    filter: (payload, variables) => {
      return payload.orderStatusUpdated.customerId === variables.customerId;
    }
  })
  orderStatusUpdated(
    @Args('customerId', { type: () => ID }) customerId: string
  ) {
    return this.orderService.subscribeToStatusUpdates(customerId);
  }

  // ResolveField with complex logic
  @ResolveField(() => Number, {
    name: 'totalAmount',
    description: `
      Calculate the total amount for this order including:
      - Base item costs
      - Applicable taxes
      - Shipping fees
      - Discounts and promotions
    `
  })
  async calculateTotalAmount(
    @Parent() order: Order
  ): Promise<number> {
    return this.orderService.calculateTotal(order.id);
  }
}