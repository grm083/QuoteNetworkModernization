# Quote Lifecycle Monitoring & Alerting Setup Guide

## Overview
This guide explains how to set up comprehensive monitoring and alerting for the Phase 9 Quote Lifecycle services.

## Architecture

The monitoring system consists of:
1. **QuoteLifecycleMonitoringService** - Real-time metric collection and alerting
2. **Quote_Lifecycle_Metrics__c** - Historical metrics storage (custom object)
3. **Quote_Lifecycle_Alert__c** - Alert tracking (custom object)
4. **Dashboard & Reports** - Visual monitoring interface

---

## Step 1: Create Custom Objects

### A. Quote_Lifecycle_Metrics__c (Custom Object)

**Purpose**: Store historical metrics for trend analysis

**Fields to Create:**

| Field Label | API Name | Type | Description |
|------------|----------|------|-------------|
| Execution Date | Execution_Date__c | Date | Date of execution |
| Execution Timestamp | Execution_Timestamp__c | DateTime | Precise timestamp |
| Total Processed | Total_Processed__c | Number(18,0) | Quotes processed |
| Success Count | Success_Count__c | Number(18,0) | Successful processing |
| Failure Count | Failure_Count__c | Number(18,0) | Failed processing |
| Warning Count | Warning_Count__c | Number(18,0) | Warnings generated |
| Success Rate | Success_Rate__c | Percent(5,2) | Success percentage |
| Average Duration (ms) | Average_Duration_Ms__c | Number(18,0) | Avg processing time |
| Total Duration (ms) | Total_Duration_Ms__c | Number(18,0) | Total processing time |
| Slowest Quote | Slowest_Quote__c | Lookup(Quote) | Reference to slowest quote |
| Slowest Duration (ms) | Slowest_Duration_Ms__c | Number(18,0) | Slowest quote time |
| User | User_Id__c | Lookup(User) | User who triggered |

**Setup Steps:**
```
1. Setup → Object Manager → Create → Custom Object
2. Object Label: Quote Lifecycle Metrics
3. Object Name: Quote_Lifecycle_Metrics
4. Record Name: Metric {Auto Number}
5. Add all fields from table above
6. Page Layouts: Add all fields to layout
7. Grant Read access to all Quote users
```

### B. Quote_Lifecycle_Alert__c (Custom Object)

**Purpose**: Track and manage alerts for critical issues

**Fields to Create:**

| Field Label | API Name | Type | Description |
|------------|----------|------|-------------|
| Alert Type | Alert_Type__c | Picklist | High Error Rate, Low Success Rate, Slow Processing, General Alert |
| Alert Severity | Alert_Severity__c | Picklist | Critical, High, Medium, Low |
| Total Processed | Total_Processed__c | Number(18,0) | Quotes in batch |
| Failure Count | Failure_Count__c | Number(18,0) | Failed quotes |
| Success Rate | Success_Rate__c | Percent(5,2) | Success percentage |
| Slowest Quote | Slowest_Quote__c | Lookup(Quote) | Reference to slowest |
| Slowest Duration (ms) | Slowest_Duration_Ms__c | Number(18,0) | Duration in ms |
| Error Messages | Error_Messages__c | Long Text Area(32768) | Concatenated errors |
| Alert Timestamp | Alert_Timestamp__c | DateTime | When alert created |
| Acknowledged | Acknowledged__c | Checkbox | Alert reviewed |
| Acknowledged By | Acknowledged_By__c | Lookup(User) | Who reviewed |
| Resolution Notes | Resolution_Notes__c | Long Text Area(5000) | How resolved |

**Picklist Values:**

Alert Type:
- High Error Rate
- Low Success Rate
- Slow Processing
- General Alert

Alert Severity:
- Critical
- High
- Medium
- Low

**Setup Steps:**
```
1. Setup → Object Manager → Create → Custom Object
2. Object Label: Quote Lifecycle Alert
3. Object Name: Quote_Lifecycle_Alert
4. Record Name: Alert {Auto Number}
5. Add all fields from table above
6. Create List Views: Critical Alerts, Unacknowledged Alerts
7. Grant Read/Edit access to System Administrators
```

---

## Step 2: Configure Thresholds

The monitoring service has configurable thresholds (edit QuoteLifecycleMonitoringService.cls):

```apex
private static final Integer ERROR_THRESHOLD = 5; // Alert if 5+ errors
private static final Long SLOW_PROCESSING_THRESHOLD_MS = 5000; // Alert if >5 seconds
private static final Integer MAX_METRICS_TO_STORE = 100; // Memory limit
```

**Recommended Settings by Org Size:**

| Org Size | ERROR_THRESHOLD | SLOW_PROCESSING_THRESHOLD_MS |
|----------|-----------------|------------------------------|
| Small (<1000 quotes/day) | 3 | 3000 |
| Medium (1000-10000) | 5 | 5000 |
| Large (10000+) | 10 | 7000 |

---

## Step 3: Set Up Email Alerts (Optional)

### A. Create Email Template

```
Setup → Email Templates → New Template
Type: Text
Name: Quote Lifecycle Alert
Subject: [ALERT] Quote Lifecycle Issues Detected

Body:
Alert Type: {!Quote_Lifecycle_Alert__c.Alert_Type__c}
Severity: {!Quote_Lifecycle_Alert__c.Alert_Severity__c}
Total Processed: {!Quote_Lifecycle_Alert__c.Total_Processed__c}
Failures: {!Quote_Lifecycle_Alert__c.Failure_Count__c}
Success Rate: {!Quote_Lifecycle_Alert__c.Success_Rate__c}%
Slowest Quote: {!Quote_Lifecycle_Alert__c.Slowest_Quote__c}

Error Details:
{!Quote_Lifecycle_Alert__c.Error_Messages__c}

Review alerts: [Your Org URL]/lightning/o/Quote_Lifecycle_Alert__c/list
```

### B. Create Workflow/Process Builder (if needed)

If you want automatic email alerts:
```
1. Setup → Process Builder → New Process
2. Object: Quote_Lifecycle_Alert__c
3. Criteria: Alert_Severity__c = 'Critical' OR 'High'
4. Action: Send Email
5. Recipients: System Admin Group
6. Template: Quote Lifecycle Alert
```

---

## Step 4: Create Dashboard

### A. Create Reports

**Report 1: Daily Success Rate**
```
Report Type: Quote Lifecycle Metrics
Grouping: Execution Date
Fields: Success Rate, Total Processed, Failure Count
Chart: Line Chart (Success Rate over time)
```

**Report 2: Top Slow Quotes**
```
Report Type: Quote Lifecycle Metrics
Grouping: Slowest Quote
Fields: Slowest Duration (ms), Execution Timestamp
Sort: Slowest Duration DESC
Filters: Slowest Duration > 3000ms
```

**Report 3: Alert Summary**
```
Report Type: Quote Lifecycle Alerts
Grouping: Alert Type, Alert Severity
Fields: Count, Average Success Rate
Chart: Donut Chart (Alert Type distribution)
Filters: Alert Timestamp = THIS_MONTH
```

**Report 4: Processing Volume Trend**
```
Report Type: Quote Lifecycle Metrics
Grouping: Execution Date
Fields: Total Processed, Average Duration
Chart: Combo Chart (Volume + Duration)
```

### B. Create Dashboard

```
Setup → Dashboards → New Dashboard
Name: Quote Lifecycle Monitoring

Components:
1. Daily Success Rate (Line Chart) - Full Width
2. Alert Summary (Donut Chart) - Left Column
3. Top Slow Quotes (Table) - Right Column
4. Processing Volume (Combo Chart) - Full Width

Running User: System Administrator
Refresh: Daily at 6 AM
```

---

## Step 5: Monitoring Queries

### Check Current Health
```sql
SELECT Id, Execution_Timestamp__c, Success_Rate__c,
       Total_Processed__c, Failure_Count__c, Average_Duration_Ms__c
FROM Quote_Lifecycle_Metrics__c
WHERE Execution_Date__c = TODAY
ORDER BY Execution_Timestamp__c DESC
LIMIT 10
```

### Find Recent Alerts
```sql
SELECT Id, Alert_Type__c, Alert_Severity__c, Alert_Timestamp__c,
       Failure_Count__c, Success_Rate__c, Acknowledged__c
FROM Quote_Lifecycle_Alert__c
WHERE Alert_Timestamp__c = LAST_N_DAYS:7
ORDER BY Alert_Severity__c, Alert_Timestamp__c DESC
```

### Identify Slow Quotes
```sql
SELECT Id, Slowest_Quote__c, Slowest_Quote__r.Name,
       Slowest_Duration_Ms__c, Execution_Timestamp__c
FROM Quote_Lifecycle_Metrics__c
WHERE Slowest_Duration_Ms__c > 5000
ORDER BY Slowest_Duration_Ms__c DESC
LIMIT 20
```

### Calculate Weekly Trends
```sql
SELECT WEEK_IN_YEAR(Execution_Date__c) WeekNum,
       AVG(Success_Rate__c) AvgSuccessRate,
       AVG(Average_Duration_Ms__c) AvgDuration,
       SUM(Total_Processed__c) TotalProcessed
FROM Quote_Lifecycle_Metrics__c
WHERE Execution_Date__c = LAST_N_DAYS:30
GROUP BY WEEK_IN_YEAR(Execution_Date__c)
ORDER BY WEEK_IN_YEAR(Execution_Date__c)
```

---

## Step 6: Debug Log Monitoring

### Key Log Patterns

**Success Summary:**
```
Quote Lifecycle Summary: Processed=10, Success=10, Failed=0, Warnings=0, Success Rate=100.0%, Avg Duration=250ms
```

**Error Pattern:**
```
Quote lifecycle processing failed for Quote 0Q0xx000000001: [Error details]
```

**Slow Processing:**
```
SLOW PROCESSING: Quote 0Q0xx000000001 took 6500ms for STATUS_CHANGE
```

### Enable Debug Logging
```
Setup → Debug Logs → New
User: [Select user]
Debug Level: SFDC_DevConsole
Apex Code: FINEST
Start Time: Now
Expiration: 1 hour
```

---

## Step 7: Performance Baselines

### Establish Baselines (Week 1)

Monitor these metrics to establish normal ranges:

| Metric | Expected Range | Alert If |
|--------|---------------|----------|
| Success Rate | 95-100% | < 90% |
| Avg Duration | 200-500ms | > 1000ms |
| Max Duration | 500-2000ms | > 5000ms |
| Failure Count | 0-2 per batch | > 5 per batch |

### Weekly Review Checklist

- [ ] Review critical alerts
- [ ] Check success rate trends
- [ ] Identify slowest quotes
- [ ] Verify threshold appropriateness
- [ ] Update documentation

---

## Step 8: Troubleshooting

### High Error Rate
```
1. Query Quote_Lifecycle_Alert__c for error messages
2. Check if specific change type is failing
3. Review UTIL_LoggingService logs
4. Verify metadata (Quote_Teams_Framework__mdt, Quote_Action_Framework__mdt)
5. Check for data quality issues
```

### Slow Processing
```
1. Query for slowest quotes
2. Check quote complexity (# of lines, # of service charges)
3. Review SOQL query performance
4. Check for governor limit warnings
5. Consider caching optimizations
```

### Alert Fatigue
```
1. Review threshold settings
2. Adjust ERROR_THRESHOLD upward
3. Adjust SLOW_PROCESSING_THRESHOLD_MS upward
4. Filter alerts by severity
5. Implement alert deduplication
```

---

## Monitoring Checklist

### Daily
- [ ] Check dashboard for critical alerts
- [ ] Review success rate (should be >95%)
- [ ] Acknowledge critical alerts

### Weekly
- [ ] Review slow quote trend
- [ ] Check for recurring errors
- [ ] Verify threshold appropriateness

### Monthly
- [ ] Analyze success rate trends
- [ ] Review alert patterns
- [ ] Update baselines if needed
- [ ] Archive old metrics (optional)

---

## Support & Escalation

### Level 1: Review Metrics
1. Check dashboard
2. Review recent alerts
3. Query debug logs

### Level 2: Investigate Errors
1. Review error messages in alerts
2. Check affected quotes directly
3. Verify metadata configuration

### Level 3: Code Review
1. Review QuoteLifecycleOrchestrator code
2. Check service-specific logic
3. Verify integration with flow (if running in parallel)

---

## Maintenance

### Data Retention

**Quote_Lifecycle_Metrics__c:**
- Retain: 90 days of daily metrics
- Archive: After 90 days (optional)
- Delete: After 1 year (optional)

**Quote_Lifecycle_Alert__c:**
- Retain: All alerts indefinitely
- Mark resolved: After acknowledged + resolution notes
- Archive: Critical alerts after 180 days (optional)

### Optimization

1. **Index Fields** (for faster queries):
   - Quote_Lifecycle_Metrics__c: Execution_Date__c, Execution_Timestamp__c
   - Quote_Lifecycle_Alert__c: Alert_Severity__c, Alert_Timestamp__c, Acknowledged__c

2. **Scheduled Cleanup** (optional Apex batch):
   ```apex
   // Delete metrics older than 90 days
   DELETE [SELECT Id FROM Quote_Lifecycle_Metrics__c
           WHERE Execution_Date__c < LAST_N_DAYS:90];
   ```

---

## Additional Resources

- **Phase 9 Services Documentation**: See main README
- **Service Architecture**: See Phase 8 & 9 commit messages
- **UTIL_LoggingService**: See existing logging documentation
- **Salesforce Debug Logs**: Setup → Debug Logs

---

## Questions?

For issues or questions:
1. Review this guide
2. Check debug logs
3. Query metrics objects
4. Review service code
5. Contact development team

Last Updated: 2025-12-12
Version: 1.0
