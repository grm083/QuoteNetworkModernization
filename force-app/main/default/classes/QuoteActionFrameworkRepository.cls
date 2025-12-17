/**
 * @description Repository for Quote_Action_Framework__mdt metadata access
 * Consolidates vendor delay configuration queries from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Repository Layer
 */
public with sharing class QuoteActionFrameworkRepository {

    // Cache for action frameworks
    private static Map<String, Quote_Action_Framework__mdt> frameworkCache;

    /**
     * @description Get action framework by quote status
     * Returns framework with vendor delay configurations
     * @param quoteStatus Quote status (Draft, Product Configured, etc.)
     * @return Quote_Action_Framework__mdt or null
     */
    public Quote_Action_Framework__mdt getFrameworkByStatus(String quoteStatus) {
        if (String.isBlank(quoteStatus)) {
            return null;
        }

        // Check cache first
        if (frameworkCache == null) {
            frameworkCache = new Map<String, Quote_Action_Framework__mdt>();
        }

        if (frameworkCache.containsKey(quoteStatus)) {
            return frameworkCache.get(quoteStatus);
        }

        try {
            List<Quote_Action_Framework__mdt> results = [
                SELECT Id, MasterLabel, DeveloperName,
                       Quote_Status__c,
                       RSG_Delay__c,
                       TPH_Delay__c,
                       WM_Delay__c,
                       Customer_Delay__c,
                       Default_Delay__c,
                       Active__c
                FROM Quote_Action_Framework__mdt
                WHERE Active__c = true
                AND Quote_Status__c = :quoteStatus
                LIMIT 1
            ];

            Quote_Action_Framework__mdt result = results.isEmpty() ? null : results[0];

            // Cache the result
            frameworkCache.put(quoteStatus, result);

            return result;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteActionFrameworkRepository', 'getFrameworkByStatus');
            return null;
        }
    }

    /**
     * @description Get vendor delays for a quote status
     * Returns wrapper with all vendor-specific delays
     * @param quoteStatus Quote status
     * @return VendorDelayConfig wrapper
     */
    public VendorDelayConfig getVendorDelays(String quoteStatus) {
        VendorDelayConfig config = new VendorDelayConfig();

        Quote_Action_Framework__mdt framework = getFrameworkByStatus(quoteStatus);

        if (framework != null) {
            config.rsgDelay = framework.RSG_Delay__c;
            config.tphDelay = framework.TPH_Delay__c;
            config.wmDelay = framework.WM_Delay__c;
            config.customerDelay = framework.Customer_Delay__c;
            config.defaultDelay = framework.Default_Delay__c;
            config.found = true;
        }

        return config;
    }

    /**
     * @description Get RSG (Republic Services Group) delay
     * @param quoteStatus Quote status
     * @return Decimal delay in minutes, or null if not found
     */
    public Decimal getRSGDelay(String quoteStatus) {
        Quote_Action_Framework__mdt framework = getFrameworkByStatus(quoteStatus);
        return (framework != null) ? framework.RSG_Delay__c : null;
    }

    /**
     * @description Get TPH (Third Party Handler) delay
     * @param quoteStatus Quote status
     * @return Decimal delay in minutes, or null if not found
     */
    public Decimal getTPHDelay(String quoteStatus) {
        Quote_Action_Framework__mdt framework = getFrameworkByStatus(quoteStatus);
        return (framework != null) ? framework.TPH_Delay__c : null;
    }

    /**
     * @description Get WM (Waste Management) delay
     * @param quoteStatus Quote status
     * @return Decimal delay in minutes, or null if not found
     */
    public Decimal getWMDelay(String quoteStatus) {
        Quote_Action_Framework__mdt framework = getFrameworkByStatus(quoteStatus);
        return (framework != null) ? framework.WM_Delay__c : null;
    }

    /**
     * @description Get customer delay
     * @param quoteStatus Quote status
     * @return Decimal delay in minutes, or null if not found
     */
    public Decimal getCustomerDelay(String quoteStatus) {
        Quote_Action_Framework__mdt framework = getFrameworkByStatus(quoteStatus);
        return (framework != null) ? framework.Customer_Delay__c : null;
    }

    /**
     * @description Get all active frameworks
     * Used for bulk processing or validation
     * @return List of Quote_Action_Framework__mdt
     */
    public List<Quote_Action_Framework__mdt> getAllActiveFrameworks() {
        try {
            return [
                SELECT Id, MasterLabel, Quote_Status__c,
                       RSG_Delay__c, TPH_Delay__c, WM_Delay__c,
                       Customer_Delay__c, Default_Delay__c
                FROM Quote_Action_Framework__mdt
                WHERE Active__c = true
                ORDER BY Quote_Status__c
            ];

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteActionFrameworkRepository', 'getAllActiveFrameworks');
            return new List<Quote_Action_Framework__mdt>();
        }
    }

    /**
     * @description Clear framework cache
     * Useful for testing or when metadata changes
     */
    public static void clearCache() {
        if (frameworkCache != null) {
            frameworkCache.clear();
        }
    }

    /**
     * @description Wrapper class for vendor delay configuration
     */
    public class VendorDelayConfig {
        public Decimal rsgDelay;
        public Decimal tphDelay;
        public Decimal wmDelay;
        public Decimal customerDelay;
        public Decimal defaultDelay;
        public Boolean found = false;

        public VendorDelayConfig() {
            this.found = false;
        }

        /**
         * @description Get delay for specific vendor code
         * @param vendorCode Vendor code (WM, RSG, TPH, etc.)
         * @return Decimal delay or default if vendor not found
         */
        public Decimal getDelayForVendor(String vendorCode) {
            if (String.isBlank(vendorCode)) {
                return defaultDelay;
            }

            String vendorCodeUpper = vendorCode.toUpperCase();

            if (vendorCodeUpper.contains('WM')) {
                return wmDelay != null ? wmDelay : defaultDelay;
            } else if (vendorCodeUpper.contains('RSG') || vendorCodeUpper.contains('REPUBLIC')) {
                return rsgDelay != null ? rsgDelay : defaultDelay;
            } else if (vendorCodeUpper.contains('TPH')) {
                return tphDelay != null ? tphDelay : defaultDelay;
            }

            return defaultDelay;
        }

        /**
         * @description Check if customer delay is configured
         * @return Boolean true if customer delay exists
         */
        public Boolean hasCustomerDelay() {
            return customerDelay != null && customerDelay > 0;
        }

        /**
         * @description Check if any vendor delay is configured
         * @return Boolean true if any vendor delay exists
         */
        public Boolean hasVendorDelay() {
            return (rsgDelay != null && rsgDelay > 0) ||
                   (tphDelay != null && tphDelay > 0) ||
                   (wmDelay != null && wmDelay > 0);
        }
    }
}
