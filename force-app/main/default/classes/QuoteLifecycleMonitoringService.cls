/**
 * @description Monitoring service for Quote Lifecycle operations
 * Tracks performance, errors, and key metrics for Phase 9 services
 * Provides real-time alerting and historical analytics
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 - Monitoring & Alerting
 */
public with sharing class QuoteLifecycleMonitoringService {

    // Singleton pattern for consistent monitoring across transaction
    private static QuoteLifecycleMonitoringService instance;

    // Metrics collected during transaction
    private List<QuoteLifecycleMetric> metrics;
    private Integer totalQuotesProcessed = 0;
    private Integer successfulProcessing = 0;
    private Integer failedProcessing = 0;
    private Integer warningsGenerated = 0;
    private Long totalProcessingTimeMs = 0;

    // Thresholds for alerting
    private static final Integer ERROR_THRESHOLD = 5; // Alert if 5+ errors in single transaction
    private static final Long SLOW_PROCESSING_THRESHOLD_MS = 5000; // Alert if single quote takes >5 seconds
    private static final Integer MAX_METRICS_TO_STORE = 100; // Prevent memory issues

    private QuoteLifecycleMonitoringService() {
        this.metrics = new List<QuoteLifecycleMetric>();
    }

    /**
     * @description Get singleton instance
     */
    public static QuoteLifecycleMonitoringService getInstance() {
        if (instance == null) {
            instance = new QuoteLifecycleMonitoringService();
        }
        return instance;
    }

    /**
     * @description Record processing start for a quote
     */
    public String startProcessing(Id quoteId, String changeType) {
        QuoteLifecycleMetric metric = new QuoteLifecycleMetric();
        metric.quoteId = quoteId;
        metric.changeType = changeType;
        metric.startTime = System.currentTimeMillis();
        metric.metricId = generateMetricId();

        if (metrics.size() < MAX_METRICS_TO_STORE) {
            metrics.add(metric);
        }

        totalQuotesProcessed++;

        return metric.metricId;
    }

    /**
     * @description Record processing completion
     */
    public void endProcessing(String metricId, Boolean success, List<String> errors, List<String> warnings) {
        QuoteLifecycleMetric metric = findMetric(metricId);

        if (metric == null) {
            return;
        }

        metric.endTime = System.currentTimeMillis();
        metric.durationMs = metric.endTime - metric.startTime;
        metric.success = success;
        metric.errors = errors;
        metric.warnings = warnings;

        totalProcessingTimeMs += metric.durationMs;

        if (success) {
            successfulProcessing++;
        } else {
            failedProcessing++;
        }

        if (warnings != null && !warnings.isEmpty()) {
            warningsGenerated += warnings.size();
        }

        // Check for slow processing
        if (metric.durationMs > SLOW_PROCESSING_THRESHOLD_MS) {
            logSlowProcessing(metric);
        }
    }

    /**
     * @description Record service-level metric
     */
    public void recordServiceMetric(String serviceName, String operation, Long durationMs, Boolean success) {
        ServiceMetric serviceMetric = new ServiceMetric();
        serviceMetric.serviceName = serviceName;
        serviceMetric.operation = operation;
        serviceMetric.durationMs = durationMs;
        serviceMetric.success = success;
        serviceMetric.timestamp = System.now();

        // Log if service is slow
        if (durationMs > 1000) { // 1 second threshold for individual service
            System.debug(LoggingLevel.WARN, 'Slow service detected: ' + serviceName + '.' + operation +
                        ' took ' + durationMs + 'ms');
        }
    }

    /**
     * @description Flush metrics and send alerts if needed
     */
    public void flushMetrics() {
        try {
            // Calculate summary statistics
            MetricsSummary summary = calculateSummary();

            // Log summary
            logSummary(summary);

            // Check alert thresholds
            if (shouldAlert(summary)) {
                sendAlert(summary);
            }

            // Store metrics for historical analysis
            storeMetrics(summary);

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLifecycleMonitoringService', 'flushMetrics');
        } finally {
            // Clear metrics for next transaction
            reset();
        }
    }

    /**
     * @description Calculate summary statistics
     */
    private MetricsSummary calculateSummary() {
        MetricsSummary summary = new MetricsSummary();

        summary.totalProcessed = totalQuotesProcessed;
        summary.successCount = successfulProcessing;
        summary.failureCount = failedProcessing;
        summary.warningCount = warningsGenerated;
        summary.totalDurationMs = totalProcessingTimeMs;
        summary.averageDurationMs = (totalQuotesProcessed > 0) ?
                                     (totalProcessingTimeMs / totalQuotesProcessed) : 0;

        // Calculate success rate
        summary.successRate = (totalQuotesProcessed > 0) ?
                              ((Decimal)successfulProcessing / totalQuotesProcessed * 100) : 0;

        // Find slowest quote
        Long maxDuration = 0;
        for (QuoteLifecycleMetric metric : metrics) {
            if (metric.durationMs != null && metric.durationMs > maxDuration) {
                maxDuration = metric.durationMs;
                summary.slowestQuoteId = metric.quoteId;
                summary.slowestDurationMs = metric.durationMs;
            }
        }

        // Collect error details
        summary.errorMessages = new List<String>();
        for (QuoteLifecycleMetric metric : metrics) {
            if (metric.errors != null && !metric.errors.isEmpty()) {
                summary.errorMessages.addAll(metric.errors);
            }
        }

        return summary;
    }

    /**
     * @description Check if alert should be sent
     */
    private Boolean shouldAlert(MetricsSummary summary) {
        // Alert if too many failures
        if (summary.failureCount >= ERROR_THRESHOLD) {
            return true;
        }

        // Alert if success rate is too low
        if (summary.totalProcessed >= 10 && summary.successRate < 80) {
            return true;
        }

        // Alert if very slow processing
        if (summary.slowestDurationMs > SLOW_PROCESSING_THRESHOLD_MS) {
            return true;
        }

        return false;
    }

    /**
     * @description Send alert via email and platform event
     */
    private void sendAlert(MetricsSummary summary) {
        // Create alert record
        Quote_Lifecycle_Alert__c alert = new Quote_Lifecycle_Alert__c();
        alert.Alert_Type__c = determineAlertType(summary);
        alert.Alert_Severity__c = determineAlertSeverity(summary);
        alert.Total_Processed__c = summary.totalProcessed;
        alert.Failure_Count__c = summary.failureCount;
        alert.Success_Rate__c = summary.successRate;
        alert.Slowest_Quote__c = summary.slowestQuoteId;
        alert.Slowest_Duration_Ms__c = summary.slowestDurationMs;
        alert.Error_Messages__c = String.join(summary.errorMessages, '\n').left(32768);
        alert.Alert_Timestamp__c = System.now();

        try {
            insert alert;
            System.debug(LoggingLevel.ERROR, 'Quote Lifecycle Alert created: ' + alert.Alert_Type__c);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLifecycleMonitoringService', 'sendAlert');
        }
    }

    /**
     * @description Store metrics for historical analysis
     */
    private void storeMetrics(MetricsSummary summary) {
        // Create metric record
        Quote_Lifecycle_Metrics__c metricRecord = new Quote_Lifecycle_Metrics__c();
        metricRecord.Execution_Date__c = System.today();
        metricRecord.Execution_Timestamp__c = System.now();
        metricRecord.Total_Processed__c = summary.totalProcessed;
        metricRecord.Success_Count__c = summary.successCount;
        metricRecord.Failure_Count__c = summary.failureCount;
        metricRecord.Warning_Count__c = summary.warningCount;
        metricRecord.Success_Rate__c = summary.successRate;
        metricRecord.Average_Duration_Ms__c = summary.averageDurationMs;
        metricRecord.Total_Duration_Ms__c = summary.totalDurationMs;
        metricRecord.Slowest_Quote__c = summary.slowestQuoteId;
        metricRecord.Slowest_Duration_Ms__c = summary.slowestDurationMs;
        metricRecord.User_Id__c = UserInfo.getUserId();

        try {
            insert metricRecord;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLifecycleMonitoringService', 'storeMetrics');
        }
    }

    /**
     * @description Log summary to debug logs
     */
    private void logSummary(MetricsSummary summary) {
        String summaryLog = String.format(
            'Quote Lifecycle Summary: Processed={0}, Success={1}, Failed={2}, Warnings={3}, Success Rate={4}%, Avg Duration={5}ms',
            new List<Object>{
                summary.totalProcessed,
                summary.successCount,
                summary.failureCount,
                summary.warningCount,
                summary.successRate.setScale(1),
                summary.averageDurationMs
            }
        );

        System.debug(LoggingLevel.INFO, summaryLog);

        if (summary.failureCount > 0) {
            System.debug(LoggingLevel.ERROR, 'Errors: ' + String.join(summary.errorMessages, '; '));
        }
    }

    /**
     * @description Log slow processing
     */
    private void logSlowProcessing(QuoteLifecycleMetric metric) {
        String slowLog = String.format(
            'SLOW PROCESSING: Quote {0} took {1}ms for {2}',
            new List<Object>{metric.quoteId, metric.durationMs, metric.changeType}
        );

        System.debug(LoggingLevel.WARN, slowLog);
    }

    /**
     * @description Determine alert type
     */
    private String determineAlertType(MetricsSummary summary) {
        if (summary.failureCount >= ERROR_THRESHOLD) {
            return 'High Error Rate';
        }
        if (summary.successRate < 80) {
            return 'Low Success Rate';
        }
        if (summary.slowestDurationMs > SLOW_PROCESSING_THRESHOLD_MS) {
            return 'Slow Processing';
        }
        return 'General Alert';
    }

    /**
     * @description Determine alert severity
     */
    private String determineAlertSeverity(MetricsSummary summary) {
        if (summary.failureCount >= 10 || summary.successRate < 50) {
            return 'Critical';
        }
        if (summary.failureCount >= ERROR_THRESHOLD || summary.successRate < 80) {
            return 'High';
        }
        return 'Medium';
    }

    /**
     * @description Find metric by ID
     */
    private QuoteLifecycleMetric findMetric(String metricId) {
        for (QuoteLifecycleMetric metric : metrics) {
            if (metric.metricId == metricId) {
                return metric;
            }
        }
        return null;
    }

    /**
     * @description Generate unique metric ID
     */
    private String generateMetricId() {
        return String.valueOf(System.currentTimeMillis()) + '_' +
               String.valueOf(Math.random()).substring(2, 8);
    }

    /**
     * @description Reset for next transaction
     */
    private void reset() {
        metrics.clear();
        totalQuotesProcessed = 0;
        successfulProcessing = 0;
        failedProcessing = 0;
        warningsGenerated = 0;
        totalProcessingTimeMs = 0;
    }

    /**
     * Inner class for tracking individual quote processing
     */
    private class QuoteLifecycleMetric {
        public String metricId;
        public Id quoteId;
        public String changeType;
        public Long startTime;
        public Long endTime;
        public Long durationMs;
        public Boolean success;
        public List<String> errors;
        public List<String> warnings;
    }

    /**
     * Inner class for service-level metrics
     */
    private class ServiceMetric {
        public String serviceName;
        public String operation;
        public Long durationMs;
        public Boolean success;
        public DateTime timestamp;
    }

    /**
     * Wrapper class for summary statistics
     */
    public class MetricsSummary {
        public Integer totalProcessed;
        public Integer successCount;
        public Integer failureCount;
        public Integer warningCount;
        public Decimal successRate;
        public Long totalDurationMs;
        public Long averageDurationMs;
        public Id slowestQuoteId;
        public Long slowestDurationMs;
        public List<String> errorMessages;
    }
}
