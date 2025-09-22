import {
  Resolver,
  Query,
  Mutation,
  Args,
  ID,
  Float,
  Int,
  ResolveField,
  Parent,
  Context,
  Info
} from '@nestjs/graphql';
import { AnalyticsService } from './analytics.service';
import { Analytics } from './entities/analytics.entity';
import { DateRange } from './dto/date-range.input';

@Resolver(() => Analytics)
export class AnalyticsResolver {
  constructor(private readonly analyticsService: AnalyticsService) {}

  // Query with complex return type and multiline decorator
  @Query(() => [Analytics], {
    name: 'getAnalytics',
    description: `
      Retrieve comprehensive analytics data for the specified time period.

      This endpoint aggregates various metrics including:
      • User engagement statistics
      • Revenue and conversion data
      • Traffic sources and patterns
      • Performance metrics

      Data is automatically cached for 15 minutes to improve performance.
    `,
    complexity: 25,
    deprecationReason: null
  })
  async fetchAnalyticsData(
    @Args('dateRange', {
      type: () => DateRange,
      description: `
        Date range for analytics data retrieval.
        Both start and end dates are inclusive.
      `
    }) dateRange: DateRange,
    @Args('metrics', {
      type: () => [String],
      description: 'Specific metrics to include in the response',
      defaultValue: ['pageviews', 'users', 'revenue']
    }) metrics: string[],
    @Args('granularity', {
      type: () => String,
      description: 'Data aggregation level: hourly, daily, weekly, monthly',
      defaultValue: 'daily'
    }) granularity: string
  ): Promise<Analytics[]> {
    return this.analyticsService.getAnalytics(dateRange, metrics, granularity);
  }

  // Mutation with validation and error handling
  @Mutation(() => Boolean, {
    name: 'trackEvent',
    description: `
      Track a custom analytics event with optional metadata.

      Event tracking supports:
      - Custom event names and categories
      - Arbitrary metadata as JSON
      - User attribution and session tracking
      - Real-time processing and aggregation

      Returns true if event was successfully recorded.
    `
  })
  async trackAnalyticsEvent(
    @Args('eventName', {
      type: () => String,
      description: 'Name of the event to track'
    }) eventName: string,
    @Args('category', {
      type: () => String,
      description: 'Event category for organization',
      defaultValue: 'general'
    }) category: string,
    @Args('userId', {
      type: () => ID,
      nullable: true,
      description: 'User ID associated with this event'
    }) userId?: string,
    @Args('metadata', {
      type: () => String,
      nullable: true,
      description: 'Additional event data as JSON string'
    }) metadata?: string,
    @Context() context?: any
  ): Promise<boolean> {
    return this.analyticsService.trackEvent({
      eventName,
      category,
      userId,
      metadata: metadata ? JSON.parse(metadata) : null,
      timestamp: new Date(),
      userAgent: context?.req?.headers?.['user-agent'],
      ipAddress: context?.req?.ip
    });
  }

  // Query with complex aggregation
  @Query(() => Float, {
    name: 'conversionRate',
    description: `
      Calculate conversion rate for a specific funnel or goal.

      Conversion rate is calculated as:
      (Number of conversions / Number of unique visitors) * 100

      Supports various conversion definitions and attribution models.
    `,
    complexity: 15
  })
  async calculateConversionRate(
    @Args('goalId', {
      type: () => ID,
      description: 'Goal or funnel ID to calculate conversion rate for'
    }) goalId: string,
    @Args('dateRange', {
      type: () => DateRange,
      description: 'Date range for conversion rate calculation'
    }) dateRange: DateRange,
    @Args('attributionModel', {
      type: () => String,
      description: 'Attribution model: first-touch, last-touch, linear',
      defaultValue: 'last-touch'
    }) attributionModel: string
  ): Promise<number> {
    return this.analyticsService.calculateConversionRate(
      goalId,
      dateRange,
      attributionModel
    );
  }

  // ResolveField with complex computation
  @ResolveField(() => Int, {
    name: 'uniqueVisitors',
    description: `
      Calculate unique visitors for this analytics period.

      Deduplication is performed based on:
      - User ID (if available)
      - Session ID
      - Browser fingerprint
      - IP address (as fallback)
    `
  })
  async calculateUniqueVisitors(
    @Parent() analytics: Analytics,
    @Args('deduplicationMethod', {
      type: () => String,
      description: 'Method to use for visitor deduplication',
      defaultValue: 'session-based'
    }) deduplicationMethod: string
  ): Promise<number> {
    return this.analyticsService.calculateUniqueVisitors(
      analytics.id,
      deduplicationMethod
    );
  }

  // Query with complex filtering and sorting
  @Query(() => [Analytics], {
    name: 'topPerformingPages',
    description: `
      Get top performing pages based on specified metrics.

      Performance can be measured by:
      • Page views and unique page views
      • Time on page and bounce rate
      • Conversion events and goal completions
      • Custom performance indicators

      Results are automatically sorted by the primary metric.
    `
  })
  async getTopPerformingPages(
    @Args('metric', {
      type: () => String,
      description: 'Primary metric to rank pages by',
      defaultValue: 'pageviews'
    }) metric: string,
    @Args('limit', {
      type: () => Int,
      description: 'Maximum number of pages to return',
      defaultValue: 10
    }) limit: number,
    @Args('dateRange', {
      type: () => DateRange,
      description: 'Date range for performance analysis'
    }) dateRange: DateRange,
    @Args('filters', {
      type: () => [String],
      nullable: true,
      description: 'Optional filters to apply (e.g., traffic source, device type)'
    }) filters?: string[]
  ): Promise<Analytics[]> {
    return this.analyticsService.getTopPerformingPages({
      metric,
      limit,
      dateRange,
      filters: filters || []
    });
  }

  // Mutation with batch processing
  @Mutation(() => Int, {
    name: 'processBatchEvents',
    description: `
      Process multiple analytics events in a single batch operation.

      Batch processing offers several advantages:
      - Improved performance for bulk operations
      - Reduced network overhead
      - Atomic transaction guarantees
      - Built-in deduplication

      Returns the number of successfully processed events.
    `
  })
  async processBatchAnalyticsEvents(
    @Args('events', {
      type: () => [String],
      description: 'Array of event JSON strings to process'
    }) events: string[],
    @Args('validateOnly', {
      type: () => Boolean,
      description: 'If true, validate events without persisting them',
      defaultValue: false
    }) validateOnly: boolean,
    @Args('allowPartialSuccess', {
      type: () => Boolean,
      description: 'If true, continue processing even if some events fail',
      defaultValue: true
    }) allowPartialSuccess: boolean
  ): Promise<number> {
    const parsedEvents = events.map(eventJson => {
      try {
        return JSON.parse(eventJson);
      } catch (error) {
        throw new Error(`Invalid JSON in event: ${eventJson}`);
      }
    });

    return this.analyticsService.processBatchEvents(
      parsedEvents,
      { validateOnly, allowPartialSuccess }
    );
  }
}