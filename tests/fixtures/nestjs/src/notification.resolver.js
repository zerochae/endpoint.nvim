const {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  Subscription,
  ResolveField,
  Parent
} = require('@nestjs/graphql');
const { NotificationService } = require('./notification.service');
const { Notification } = require('./entities/notification.entity');

@Resolver(() => Notification)
class NotificationResolver {
  constructor(notificationService) {
    this.notificationService = notificationService;
  }

  // Basic query
  @Query(() => [Notification])
  async notifications() {
    return this.notificationService.findAll();
  }

  // Multiline query in JavaScript
  @Query(() => [Notification], {
    name: 'unreadNotifications',
    description: `
      Fetch all unread notifications for a specific user.
      Results are sorted by creation date in descending order.
    `,
    complexity: 8
  })
  async getUnreadNotifications(
    @Args('userId', {
      type: () => ID,
      description: 'User ID to fetch notifications for'
    }) userId
  ) {
    return this.notificationService.findUnreadByUser(userId);
  }

  // Complex multiline mutation
  @Mutation(() => Notification, {
    name: 'createBulkNotification',
    description: `
      Create and send notifications to multiple users at once.
      Supports different notification types and delivery methods.

      Available types:
      - EMAIL: Send via email
      - PUSH: Push notification to mobile devices
      - IN_APP: Show in application interface
    `,
    complexity: 15
  })
  async createBulkNotifications(
    @Args('userIds', {
      type: () => [ID],
      description: 'Array of user IDs to send notifications to'
    }) userIds,
    @Args('message', {
      type: () => String,
      description: 'Notification message content'
    }) message,
    @Args('type', {
      type: () => String,
      defaultValue: 'IN_APP',
      description: 'Notification delivery type'
    }) type,
    @Args('priority', {
      type: () => String,
      defaultValue: 'NORMAL',
      description: 'Notification priority level'
    }) priority
  ) {
    return this.notificationService.createBulk({
      userIds,
      message,
      type,
      priority
    });
  }

  // Subscription with complex filtering
  @Subscription(() => Notification, {
    name: 'notificationReceived',
    description: `
      Real-time subscription for new notifications.
      Filters notifications based on user preferences and priority.
    `,
    filter: (payload, variables, context) => {
      const notification = payload.notificationReceived;
      return (
        notification.userId === variables.userId &&
        notification.priority >= variables.minPriority
      );
    },
    resolve: (payload) => {
      return payload.notificationReceived;
    }
  })
  notificationReceived(
    @Args('userId', { type: () => ID }) userId,
    @Args('minPriority', {
      type: () => String,
      defaultValue: 'LOW'
    }) minPriority
  ) {
    return this.notificationService.subscribeToNotifications(userId);
  }

  // Mutation with error handling documentation
  @Mutation(() => Boolean, {
    name: 'markAsRead',
    description: `
      Mark one or more notifications as read.

      Returns true if all notifications were successfully marked,
      false if any notification could not be updated.

      Possible error scenarios:
      - Notification not found
      - User doesn't have permission
      - Notification already read
    `
  })
  async markNotificationsAsRead(
    @Args('notificationIds', {
      type: () => [ID],
      description: 'Array of notification IDs to mark as read'
    }) notificationIds,
    @Args('userId', {
      type: () => ID,
      description: 'ID of the user marking notifications as read'
    }) userId
  ) {
    return this.notificationService.markAsRead(notificationIds, userId);
  }

  // ResolveField with conditional logic
  @ResolveField(() => Boolean, {
    name: 'isUrgent',
    description: `
      Determine if notification requires immediate attention based on:
      - Priority level
      - Notification type
      - Time since creation
      - User's current status
    `
  })
  async checkIfUrgent(
    @Parent() notification
  ) {
    return this.notificationService.evaluateUrgency(notification);
  }

  // Query with complex where clause
  @Query(() => [Notification], {
    name: 'searchNotifications',
    description: `
      Advanced notification search with multiple filter criteria.
      Supports text search, date ranges, and type filtering.
    `
  })
  async searchNotifications(
    @Args('query', {
      type: () => String,
      nullable: true,
      description: 'Text to search in notification content'
    }) query,
    @Args('fromDate', {
      type: () => String,
      nullable: true,
      description: 'Start date for date range filter (ISO string)'
    }) fromDate,
    @Args('toDate', {
      type: () => String,
      nullable: true,
      description: 'End date for date range filter (ISO string)'
    }) toDate,
    @Args('types', {
      type: () => [String],
      nullable: true,
      description: 'Array of notification types to include'
    }) types
  ) {
    return this.notificationService.search({
      query,
      fromDate,
      toDate,
      types
    });
  }
}

module.exports = { NotificationResolver };