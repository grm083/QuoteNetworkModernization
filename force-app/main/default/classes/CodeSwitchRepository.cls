/**
 * @description Repository for Code_Switch__c custom setting access
 * Centralizes feature flag queries from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Repository Layer
 */
public with sharing class CodeSwitchRepository {

    // Cache for code switches
    private static Map<String, Code_Switch__c> switchCache;

    /**
     * @description Get code switch by name
     * @param switchName Name of the code switch
     * @return Code_Switch__c or null if not found
     */
    public Code_Switch__c getCodeSwitch(String switchName) {
        if (String.isBlank(switchName)) {
            return null;
        }

        // Initialize cache if needed
        if (switchCache == null) {
            switchCache = new Map<String, Code_Switch__c>();
        }

        // Check cache
        if (switchCache.containsKey(switchName)) {
            return switchCache.get(switchName);
        }

        try {
            Code_Switch__c codeSwitch = Code_Switch__c.getInstance(switchName);

            // Cache the result (even if null)
            switchCache.put(switchName, codeSwitch);

            return codeSwitch;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'CodeSwitchRepository', 'getCodeSwitch');
            return null;
        }
    }

    /**
     * @description Check if code switch is enabled (not switched off)
     * @param switchName Name of the code switch
     * @return Boolean true if enabled (Switch_Off__c = false)
     */
    public Boolean isSwitchEnabled(String switchName) {
        Code_Switch__c codeSwitch = getCodeSwitch(switchName);

        if (codeSwitch == null) {
            // Default to false if switch not found
            return false;
        }

        return !(codeSwitch.Switch_Off__c == true);
    }

    /**
     * @description Check if Haul Away feature is enabled
     * Used in Quote_Status_Change_Flow for Haul Away routing
     * @return Boolean true if enabled
     */
    public Boolean isHaulAwayEnabled() {
        return isSwitchEnabled('Haul_Away_Service');
    }

    /**
     * @description Check if Quote Only feature is enabled
     * Used in Quote_Status_Change_Flow for Quote Only routing
     * @return Boolean true if enabled
     */
    public Boolean isQuoteOnlyEnabled() {
        return isSwitchEnabled('Quote_Only_Enabled');
    }

    /**
     * @description Check if Amendment Quote Approvals are enabled
     * @return Boolean true if enabled
     */
    public Boolean isAmendmentQuoteApprovalsEnabled() {
        return isSwitchEnabled('Amendment Quote Approvals');
    }

    /**
     * @description Check if Exception Quote Approvals are enabled
     * @return Boolean true if enabled
     */
    public Boolean isExceptionQuoteApprovalsEnabled() {
        return isSwitchEnabled('Exception Quote Approvals');
    }

    /**
     * @description Check if Correction Quote Approvals are enabled
     * @return Boolean true if enabled
     */
    public Boolean isCorrectionQuoteApprovalsEnabled() {
        return isSwitchEnabled('Correction Quote Approvals');
    }

    /**
     * @description Get multiple code switches at once
     * More efficient than multiple individual queries
     * @param switchNames Set of code switch names
     * @return Map of switch name to Code_Switch__c
     */
    public Map<String, Code_Switch__c> getCodeSwitches(Set<String> switchNames) {
        Map<String, Code_Switch__c> switches = new Map<String, Code_Switch__c>();

        if (switchNames == null || switchNames.isEmpty()) {
            return switches;
        }

        for (String switchName : switchNames) {
            Code_Switch__c codeSwitch = getCodeSwitch(switchName);
            if (codeSwitch != null) {
                switches.put(switchName, codeSwitch);
            }
        }

        return switches;
    }

    /**
     * @description Get enabled status for multiple switches
     * @param switchNames Set of code switch names
     * @return Map of switch name to enabled status
     */
    public Map<String, Boolean> getEnabledStatuses(Set<String> switchNames) {
        Map<String, Boolean> statuses = new Map<String, Boolean>();

        if (switchNames == null || switchNames.isEmpty()) {
            return statuses;
        }

        for (String switchName : switchNames) {
            statuses.put(switchName, isSwitchEnabled(switchName));
        }

        return statuses;
    }

    /**
     * @description Clear code switch cache
     * Useful for testing or when switches change
     */
    public static void clearCache() {
        if (switchCache != null) {
            switchCache.clear();
        }
    }

    /**
     * @description Wrapper class for feature flags
     * Groups related feature flags for quote processing
     */
    public class QuoteFeatureFlags {
        public Boolean haulAwayEnabled;
        public Boolean quoteOnlyEnabled;
        public Boolean amendmentApprovalsEnabled;
        public Boolean exceptionApprovalsEnabled;
        public Boolean correctionApprovalsEnabled;

        public QuoteFeatureFlags() {
            // Default all to false
            this.haulAwayEnabled = false;
            this.quoteOnlyEnabled = false;
            this.amendmentApprovalsEnabled = false;
            this.exceptionApprovalsEnabled = false;
            this.correctionApprovalsEnabled = false;
        }
    }

    /**
     * @description Get all quote-related feature flags at once
     * More efficient than multiple individual checks
     * @return QuoteFeatureFlags wrapper with all flags
     */
    public QuoteFeatureFlags getQuoteFeatureFlags() {
        QuoteFeatureFlags flags = new QuoteFeatureFlags();

        flags.haulAwayEnabled = isHaulAwayEnabled();
        flags.quoteOnlyEnabled = isQuoteOnlyEnabled();
        flags.amendmentApprovalsEnabled = isAmendmentQuoteApprovalsEnabled();
        flags.exceptionApprovalsEnabled = isExceptionQuoteApprovalsEnabled();
        flags.correctionApprovalsEnabled = isCorrectionQuoteApprovalsEnabled();

        return flags;
    }
}
