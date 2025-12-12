/**
 * @description Service for calculating quote priority (P1, P2, P3, P4)
 * Wraps and enhances existing CalculateQuotePriority invocable logic
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Service Layer
 */
public with sharing class QuotePriorityService {

    private QuoteActionFrameworkRepository actionFrameworkRepo;

    public QuotePriorityService() {
        this.actionFrameworkRepo = new QuoteActionFrameworkRepository();
    }

    /**
     * @description Determine priority for a quote based on start date
     * Replaces logic from CalculateQuotePriority invocable method
     * @param quote Quote record with start date
     * @return String priority code (P1, P2, P3, P4)
     */
    public String determinePriority(SBQQ__Quote__c quote) {
        if (quote == null || quote.SBQQ__StartDate__c == null) {
            return 'P4'; // Default to lowest priority
        }

        Integer daysUntilStart = getDaysUntilStartDate(quote.SBQQ__StartDate__c);

        return getPriorityFromDays(daysUntilStart);
    }

    /**
     * @description Get number of business days until start date
     * Uses BusinessDays class (same as CalculateQuotePriority)
     * @param startDate Quote start date
     * @return Integer number of days
     */
    public Integer getDaysUntilStartDate(Date startDate) {
        if (startDate == null) {
            return 999; // Far future
        }

        try {
            BusinessDays bd = new BusinessDays();
            // Convert Date to DateTime for compatibility
            DateTime startDateTime = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day());
            return bd.getNoOfDaysfromCurrentDate(startDateTime);

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuotePriorityService', 'getDaysUntilStartDate');
            return 999; // Default to far future on error
        }
    }

    /**
     * @description Convert days until start to priority code
     * Business rules:
     * - P1: 0-3 business days (urgent)
     * - P2: 4-10 business days (high)
     * - P3: 11-30 business days (medium)
     * - P4: 31+ business days (low)
     * @param days Number of business days
     * @return String priority code
     */
    public String getPriorityFromDays(Integer days) {
        if (days <= 3) {
            return 'P1';
        } else if (days <= 10) {
            return 'P2';
        } else if (days <= 30) {
            return 'P3';
        } else {
            return 'P4';
        }
    }

    /**
     * @description Determine priority for multiple quotes at once
     * Bulk-friendly version
     * @param quotes List of quotes
     * @return Map of quote ID to priority
     */
    public Map<Id, String> determinePrioritiesForQuotes(List<SBQQ__Quote__c> quotes) {
        Map<Id, String> priorities = new Map<Id, String>();

        if (quotes == null || quotes.isEmpty()) {
            return priorities;
        }

        for (SBQQ__Quote__c quote : quotes) {
            String priority = determinePriority(quote);
            priorities.put(quote.Id, priority);
        }

        return priorities;
    }

    /**
     * @description Check if quote priority should be recalculated
     * True if start date changed
     * @param newQuote New quote record
     * @param oldQuote Old quote record
     * @return Boolean true if priority needs recalculation
     */
    public Boolean shouldRecalculatePriority(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        if (newQuote == null) {
            return false;
        }

        // Recalculate if start date changed
        if (oldQuote != null && newQuote.SBQQ__StartDate__c != oldQuote.SBQQ__StartDate__c) {
            return true;
        }

        // Recalculate if start date exists but priority is missing
        if (newQuote.SBQQ__StartDate__c != null && String.isBlank(newQuote.Priority__c)) {
            return true;
        }

        return false;
    }

    /**
     * @description Get priority description
     * @param priorityCode Priority code (P1, P2, P3, P4)
     * @return String description
     */
    public String getPriorityDescription(String priorityCode) {
        if (priorityCode == 'P1') {
            return 'Urgent (0-3 business days)';
        } else if (priorityCode == 'P2') {
            return 'High (4-10 business days)';
        } else if (priorityCode == 'P3') {
            return 'Medium (11-30 business days)';
        } else if (priorityCode == 'P4') {
            return 'Low (31+ business days)';
        } else {
            return 'Unknown';
        }
    }

    /**
     * @description Result wrapper for priority calculation
     */
    public class PriorityResult {
        public String priority;
        public Integer daysUntilStart;
        public String description;
        public Boolean success = true;
        public String errorMessage;

        public PriorityResult() {
            this.success = true;
        }
    }

    /**
     * @description Calculate priority with detailed results
     * Enhanced version that returns all calculation details
     * @param quote Quote record
     * @return PriorityResult wrapper
     */
    public PriorityResult calculatePriorityWithDetails(SBQQ__Quote__c quote) {
        PriorityResult result = new PriorityResult();

        try {
            if (quote == null || quote.SBQQ__StartDate__c == null) {
                result.priority = 'P4';
                result.daysUntilStart = 999;
                result.description = 'No start date';
                return result;
            }

            result.daysUntilStart = getDaysUntilStartDate(quote.SBQQ__StartDate__c);
            result.priority = getPriorityFromDays(result.daysUntilStart);
            result.description = getPriorityDescription(result.priority);

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuotePriorityService', 'calculatePriorityWithDetails');
            result.success = false;
            result.errorMessage = ex.getMessage();
            result.priority = 'P4'; // Safe default
        }

        return result;
    }
}
