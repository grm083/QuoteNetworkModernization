/**
 * @description Refactored Price Only STP Process using orchestration pattern
 * Maintains backward compatibility with original PriceOnlyRequestSTPProcess
 * Part of Phase 8 Phase 3 - Final STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 8 Phase 3 - Price Only Process Layer
 * @note Replaces monolithic 1,569-line class with clean orchestration
 */
public class PriceOnlyRequestSTPProcessV2 {

    /**
     * @description Main entry point for price only STP functionality
     * Replaces: PriceOnlyRequestSTPProcess.callPriceOnlySTPFunctionality()
     * @param quoteId Quote ID
     */
    public static void callPriceOnlySTPFunctionality(String quoteId) {
        if (String.isBlank(quoteId)) {
            System.debug('callPriceOnlySTPFunctionality called with blank quoteId');
            return;
        }

        try {
            // Use new orchestrator
            PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();
            PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
                orchestrator.processQuoteForPriceOnly(quoteId);

            // Log result
            if (!result.success) {
                String errorMessage = 'Price Only STP Processing failed for quote ' + quoteId + ': ' +
                                     String.join(result.errors, '; ');
                System.debug(LoggingLevel.ERROR, errorMessage);
                UTIL_LoggingService.logError('PriceOnlyRequestSTPProcessV2', 'callPriceOnlySTPFunctionality', errorMessage);
            } else {
                System.debug('Price Only STP Processing completed successfully: ' +
                           'Bundles=' + result.bundlesProcessed +
                           ', Updated=' + result.quoteLinesUpdated +
                           ', Requests Created=' + result.pricingRequestsCreated);

                if (!result.warnings.isEmpty()) {
                    System.debug('Warnings: ' + String.join(result.warnings, '; '));
                }
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'callPriceOnlySTPFunctionality');

            // Re-throw for original behavior compatibility
            STPExceptionUtil.setStepByStepExceptionObj(
                'callPriceOnlySTPFunctionality',
                'createPricingRequestForMultiBundle - ' + quoteId,
                ex.getMessage()
            );
        }
    }

    /**
     * @description Validate price only call
     * Replaces: PriceOnlyRequestSTPProcess.validatePriceOnlyCall()
     * @param quoteId Quote ID
     * @return Set of eligible bundle IDs
     */
    public static Set<Id> validatePriceOnlyCall(String quoteId) {
        if (String.isBlank(quoteId)) {
            return new Set<Id>();
        }

        try {
            PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();
            return orchestrator.validatePriceOnlyEligibility(quoteId);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'validatePriceOnlyCall');
            return new Set<Id>();
        }
    }

    /**
     * @description Create pricing requests for multiple bundles
     * Replaces: PriceOnlyRequestSTPProcess.createPricingRequestForMultiBundle()
     * @param bundleIds Set of bundle IDs
     * @param callingFromUI Whether calling from UI
     */
    public static void createPricingRequestForMultiBundle(Set<Id> bundleIds, Boolean callingFromUI) {
        if (bundleIds == null || bundleIds.isEmpty()) {
            return;
        }

        try {
            PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();
            Integer requestsCreated = orchestrator.createPricingRequestsForBundles(bundleIds, callingFromUI);

            System.debug('Created ' + requestsCreated + ' pricing requests for ' + bundleIds.size() + ' bundles');

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'createPricingRequestForMultiBundle');
            throw ex;
        }
    }

    /**
     * @description Save prices to quote lines
     * Replaces: PriceOnlyRequestSTPProcess.savePricetoQuoteline()
     * @param quoteID Quote ID
     */
    public static void savePricetoQuoteline(Id quoteID) {
        if (quoteID == null) {
            System.debug('savePricetoQuoteline called with null quoteID');
            return;
        }

        try {
            // Use new orchestrator
            PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();
            PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
                orchestrator.savePricesToQuoteLines(quoteID);

            // Log result
            if (!result.success) {
                String errorMessage = 'Save prices failed for quote ' + quoteID + ': ' +
                                     String.join(result.errors, '; ');
                System.debug(LoggingLevel.ERROR, errorMessage);
                UTIL_LoggingService.logError('PriceOnlyRequestSTPProcessV2', 'savePricetoQuoteline', errorMessage);
            } else {
                System.debug('Save prices completed successfully: ' +
                           'Bundles=' + result.bundlesProcessed +
                           ', Lines Updated=' + result.quoteLinesUpdated);
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'savePricetoQuoteline');
            throw ex;
        }
    }

    /**
     * @description Get product details
     * Replaces: PriceOnlyRequestSTPProcess.getProductdetails()
     * @return List of products
     */
    public static List<Product2> getProductdetails() {
        Set<String> productCodeList = new Set<String>{
            'CSC','DLV','RECV','DEM','REM','SWO','PSW','COF','REL','DRUN','CAS','PUSH','EQI','GTF', 'REC'
        };

        try {
            return [
                SELECT Id, ProductCode, Name, SBQQ__PricingMethod__c
                FROM Product2
                WHERE (Family = 'Surcharge/Fee' OR ProductCode IN :productCodeList)
                AND IsActive = true
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'getProductdetails');
            return new List<Product2>();
        }
    }

    /**
     * @description Get product options
     * Replaces: PriceOnlyRequestSTPProcess.getProductOptions()
     * @param productCode List of product codes
     * @return List of product options
     */
    public static List<SBQQ__ProductOption__c> getProductOptions(List<String> productCode) {
        if (productCode == null || productCode.isEmpty()) {
            return new List<SBQQ__ProductOption__c>();
        }

        try {
            return [
                SELECT Id, Name, SBQQ__ProductCode__c, SBQQ__ConfiguredSKU__c,
                       SBQQ__ConfiguredSKU__r.Name, SBQQ__ConfiguredSKU__r.ProductCode,
                       SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name,
                       SBQQ__OptionalSKU__r.ProductCode, Occurrence_Type__c,
                       Schedule_Frequency__c, Frequency_Interval__c,
                       CostModelType__c, PriceUOM__c, Cost_Unit_of_Measure__c
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__r.Name IN :productCode
                LIMIT 20000
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PriceOnlyRequestSTPProcessV2', 'getProductOptions');
            return new List<SBQQ__ProductOption__c>();
        }
    }

    /**
     * @description Process quote with result tracking
     * Enhanced version that returns detailed results
     * @param quoteId Quote ID
     * @return Processing result with counts and errors
     */
    public static PriceOnlySTPOrchestrator.PriceOnlyProcessingResult processQuoteWithResult(Id quoteId) {
        if (quoteId == null) {
            PriceOnlySTPOrchestrator.PriceOnlyProcessingResult errorResult =
                new PriceOnlySTPOrchestrator.PriceOnlyProcessingResult();
            errorResult.success = false;
            errorResult.errors.add('Quote ID is null');
            return errorResult;
        }

        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();
        return orchestrator.processQuoteForPriceOnly(quoteId);
    }

    /**
     * @description Validate and get eligible bundles with result
     * Enhanced version for monitoring
     * @param quoteId Quote ID
     * @return Set of eligible bundle IDs
     */
    public static Set<Id> validateAndGetEligibleBundles(String quoteId) {
        return validatePriceOnlyCall(quoteId);
    }
}
