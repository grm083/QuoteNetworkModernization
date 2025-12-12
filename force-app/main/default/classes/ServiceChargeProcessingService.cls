/**
 * @description Service for processing service charges from pricing API responses
 * Extracts service charge logic from PricingRequestSTPProcess
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 * @note Centralizes service charge CRUD operations and action handling
 */
public with sharing class ServiceChargeProcessingService {

    /**
     * @description Service charge action result
     */
    public class ServiceChargeActionResult {
        @AuraEnabled public SBQQ__QuoteLine__c quoteLine { get; set; }
        @AuraEnabled public String action { get; set; }
        @AuraEnabled public Boolean createNewLine { get; set; }
        @AuraEnabled public Boolean updateExisting { get; set; }
        @AuraEnabled public Boolean deleteExisting { get; set; }
        @AuraEnabled public Boolean skipProcessing { get; set; }
        @AuraEnabled public String skipReason { get; set; }

        public ServiceChargeActionResult() {
            this.createNewLine = false;
            this.updateExisting = false;
            this.deleteExisting = false;
            this.skipProcessing = false;
        }
    }

    /**
     * @description Service charge configuration from metadata
     */
    public class ServiceChargeConfig {
        @AuraEnabled public String serviceChargeName { get; set; }
        @AuraEnabled public String serviceChargeCode { get; set; }
        @AuraEnabled public String actionName { get; set; }
        @AuraEnabled public Boolean isCreateQuoteLine { get; set; }
        @AuraEnabled public Boolean isDeleteQuoteLine { get; set; }
        @AuraEnabled public Boolean additionalProcessingNeeded { get; set; }
    }

    /**
     * @description Get all active service charge configurations from metadata
     * @return List of service charge configurations
     */
    public List<ServiceChargeConfig> getActiveServiceChargeConfigs() {
        List<ServiceChargeConfig> configs = new List<ServiceChargeConfig>();

        try {
            List<PricingSTP__mdt> pricingSTP = [
                SELECT Id, ServiceChargeName__c, ServiceChargeCode__c, AcitonName__c,
                       IsCreateQuoteLine__c, IsDeleteQuoteLine__c, Additional_Processing_Needed__c
                FROM PricingSTP__mdt
                WHERE IsActive__c = true
            ];

            for (PricingSTP__mdt meta : pricingSTP) {
                ServiceChargeConfig config = new ServiceChargeConfig();
                config.serviceChargeName = meta.ServiceChargeName__c;
                config.serviceChargeCode = meta.ServiceChargeCode__c;
                config.actionName = meta.AcitonName__c;
                config.isCreateQuoteLine = meta.IsCreateQuoteLine__c;
                config.isDeleteQuoteLine = meta.IsDeleteQuoteLine__c;
                config.additionalProcessingNeeded = meta.Additional_Processing_Needed__c;
                configs.add(config);
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ServiceChargeProcessingService', 'getActiveServiceChargeConfigs');
        }

        return configs;
    }

    /**
     * @description Process service charge based on action name
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess()
     *
     * Actions:
     * - Allow/Adjust/null: Create or update quote line with API values
     * - Exclude: Delete quote line OR set cost/price to 0
     * - Manual Review: (future use - currently not implemented)
     *
     * @param serviceChargeName Service charge name from API
     * @param actionName Action from API (Allow, Adjust, Exclude, Manual Review)
     * @param cost Cost value from API
     * @param price Price value from API
     * @param existingQuoteLine Existing quote line (if found)
     * @param config Service charge configuration from metadata
     * @param overrideAction Whether to override the default action behavior
     * @return Service charge action result with quote line and action to take
     */
    public ServiceChargeActionResult processServiceChargeAction(
        String serviceChargeName,
        String actionName,
        Decimal cost,
        Decimal price,
        SBQQ__QuoteLine__c existingQuoteLine,
        ServiceChargeConfig config,
        Boolean overrideAction
    ) {
        ServiceChargeActionResult result = new ServiceChargeActionResult();
        result.action = actionName;

        // Null safety
        if (String.isBlank(serviceChargeName) || config == null) {
            result.skipProcessing = true;
            result.skipReason = 'Missing service charge name or configuration';
            return result;
        }

        Boolean isServiceExist = (existingQuoteLine != null);

        // Process based on action name
        if (actionName == 'Allow' || actionName == 'Adjust' || actionName == null) {
            result = processAllowAdjustAction(cost, price, existingQuoteLine, config, overrideAction);
        }
        else if (actionName == 'Exclude') {
            result = processExcludeAction(existingQuoteLine, config, overrideAction);
        }
        else if (actionName == 'Manual Review') {
            result = processManualReviewAction(existingQuoteLine, config);
        }
        else {
            result.skipProcessing = true;
            result.skipReason = 'Unknown action name: ' + actionName;
        }

        return result;
    }

    /**
     * @description Process Allow/Adjust action
     * Creates new quote line or updates existing with API cost/price
     * @param cost Cost from API
     * @param price Price from API
     * @param existingQuoteLine Existing quote line
     * @param config Service charge configuration
     * @param overrideAction Override flag
     * @return Action result
     */
    private ServiceChargeActionResult processAllowAdjustAction(
        Decimal cost,
        Decimal price,
        SBQQ__QuoteLine__c existingQuoteLine,
        ServiceChargeConfig config,
        Boolean overrideAction
    ) {
        ServiceChargeActionResult result = new ServiceChargeActionResult();

        // Check if cost and price are null (skip if both null - SDT-23997)
        if (cost == null && price == null) {
            result.skipProcessing = true;
            result.skipReason = 'Both cost and price are null';
            return result;
        }

        // Check for additional processing override
        if (config.additionalProcessingNeeded == true) {
            if (overrideAction == false) {
                result.skipProcessing = true;
                result.skipReason = 'Additional processing needed but override is false';
                return result;
            }
        }

        if (existingQuoteLine != null) {
            // Update existing quote line
            result.quoteLine = existingQuoteLine;
            result.updateExisting = true;
        }
        else if (config.isCreateQuoteLine == true) {
            // Create new quote line
            result.createNewLine = true;
        }
        else {
            result.skipProcessing = true;
            result.skipReason = 'No existing quote line and create not allowed';
        }

        return result;
    }

    /**
     * @description Process Exclude action
     * Deletes quote line OR sets cost/price to 0
     * @param existingQuoteLine Existing quote line
     * @param config Service charge configuration
     * @param overrideAction Override flag
     * @return Action result
     */
    private ServiceChargeActionResult processExcludeAction(
        SBQQ__QuoteLine__c existingQuoteLine,
        ServiceChargeConfig config,
        Boolean overrideAction
    ) {
        ServiceChargeActionResult result = new ServiceChargeActionResult();

        if (existingQuoteLine == null) {
            result.skipProcessing = true;
            result.skipReason = 'No existing quote line to exclude';
            return result;
        }

        // Check for additional processing override
        if (config.additionalProcessingNeeded == false ||
            (config.additionalProcessingNeeded == true && overrideAction == false)) {

            if (config.isDeleteQuoteLine == true) {
                // Delete the quote line
                result.deleteExisting = true;
                result.quoteLine = existingQuoteLine;
            }
            else {
                // Set cost/price to 0
                result.quoteLine = existingQuoteLine;
                result.updateExisting = true;
            }
        }
        else if (config.additionalProcessingNeeded == true && overrideAction == true) {
            // Additional processing with override - skip
            result.skipProcessing = true;
            result.skipReason = 'Additional processing with override enabled';
        }

        return result;
    }

    /**
     * @description Process Manual Review action
     * Placeholder for future implementation
     * @param existingQuoteLine Existing quote line
     * @param config Service charge configuration
     * @return Action result
     */
    private ServiceChargeActionResult processManualReviewAction(
        SBQQ__QuoteLine__c existingQuoteLine,
        ServiceChargeConfig config
    ) {
        ServiceChargeActionResult result = new ServiceChargeActionResult();
        result.skipProcessing = true;
        result.skipReason = 'Manual Review action not yet implemented';
        return result;
    }

    /**
     * @description Apply cost and price to quote line
     * Handles percentage vs fixed values
     * @param quoteLine Quote line to update
     * @param cost Cost value from API
     * @param price Price value from API
     * @param costValueType Cost value type (PERCENT or null for fixed)
     * @param priceValueType Price value type (PERCENT or null for fixed)
     * @param costUOM Cost unit of measure
     * @param priceUOM Price unit of measure
     * @return Updated quote line (not saved)
     */
    public SBQQ__QuoteLine__c applyCostAndPrice(
        SBQQ__QuoteLine__c quoteLine,
        Decimal cost,
        Decimal price,
        String costValueType,
        String priceValueType,
        String costUOM,
        String priceUOM
    ) {
        if (quoteLine == null) {
            return null;
        }

        // Apply cost
        if (costValueType == Constant_Util.PERCENT) {
            quoteLine.SBQQ__SubscriptionPercent__c = cost;
            quoteLine.SBQQ__UnitCost__c = 0.00;
        }
        else {
            quoteLine.SBQQ__UnitCost__c = (cost != null ? cost : 0.00);
            quoteLine.SBQQ__SubscriptionPercent__c = null;
        }

        // Apply price
        if (priceValueType == Constant_Util.PERCENT) {
            quoteLine.SBQQ__MarkupRate__c = price;
            quoteLine.SBQQ__ListPrice__c = 0.00;
        }
        else {
            quoteLine.SBQQ__ListPrice__c = (price != null ? price : 0.00);
            quoteLine.SBQQ__MarkupRate__c = null;
        }

        // Apply UOMs
        if (String.isNotBlank(costUOM)) {
            quoteLine.Cost_Unit_of_Measure__c = costUOM;
        }
        if (String.isNotBlank(priceUOM)) {
            quoteLine.PriceUOM__c = priceUOM;
        }

        return quoteLine;
    }

    /**
     * @description Set quote line to zero cost and price (for Exclude action)
     * @param quoteLine Quote line to update
     * @param costUOM Cost unit of measure
     * @param priceUOM Price unit of measure
     * @return Updated quote line (not saved)
     */
    public SBQQ__QuoteLine__c setZeroCostAndPrice(
        SBQQ__QuoteLine__c quoteLine,
        String costUOM,
        String priceUOM
    ) {
        if (quoteLine == null) {
            return null;
        }

        quoteLine.SBQQ__UnitCost__c = 0.00;
        quoteLine.SBQQ__ListPrice__c = 0.00;

        if (String.isNotBlank(costUOM)) {
            quoteLine.Cost_Unit_of_Measure__c = costUOM;
        }
        if (String.isNotBlank(priceUOM)) {
            quoteLine.PriceUOM__c = priceUOM;
        }

        return quoteLine;
    }

    /**
     * @description Find matching service charge configuration
     * Matches by service charge name and action name
     * @param serviceChargeName Service charge name from API
     * @param actionName Action name from API
     * @param configs List of configurations
     * @return Matching configuration or null
     */
    public ServiceChargeConfig findMatchingConfig(
        String serviceChargeName,
        String actionName,
        List<ServiceChargeConfig> configs
    ) {
        if (String.isBlank(serviceChargeName) || configs == null || configs.isEmpty()) {
            return null;
        }

        for (ServiceChargeConfig config : configs) {
            if (serviceChargeName.contains(config.serviceChargeName) &&
                (actionName == config.actionName || actionName == null)) {
                return config;
            }
        }

        return null;
    }

    /**
     * @description Find existing service charge quote line
     * Searches for quote line with matching product code
     * @param serviceLines List of service lines to search
     * @param serviceChargeCode Service charge product code
     * @return Matching quote line or null
     */
    public SBQQ__QuoteLine__c findExistingServiceLine(
        List<SBQQ__QuoteLine__c> serviceLines,
        String serviceChargeCode
    ) {
        if (serviceLines == null || serviceLines.isEmpty() || String.isBlank(serviceChargeCode)) {
            return null;
        }

        for (SBQQ__QuoteLine__c serviceLine : serviceLines) {
            if (serviceLine.SBQQ__ProductCode__c == serviceChargeCode) {
                return serviceLine;
            }
        }

        return null;
    }

    /**
     * @description Create base ancillary service quote line
     * Sets common fields for ancillary service charges
     * @param quoteId Quote ID
     * @param productId Product ID for service charge
     * @param bundleId Parent bundle ID
     * @param equipmentSize Equipment size from bundle
     * @param duration Duration from bundle
     * @param vendorId Vendor ID
     * @param currencyCode Currency ISO code
     * @param startDate Start date from bundle
     * @param endDate End date from bundle
     * @param quoteLineNumber Quote line number
     * @return New quote line (not saved)
     */
    public SBQQ__QuoteLine__c createAncillaryServiceLine(
        Id quoteId,
        Id productId,
        Id bundleId,
        String equipmentSize,
        Decimal duration,
        Id vendorId,
        String currencyCode,
        Date startDate,
        Date endDate,
        Integer quoteLineNumber
    ) {
        SBQQ__QuoteLine__c serviceLine = new SBQQ__QuoteLine__c();

        serviceLine.SBQQ__Quote__c = quoteId;
        serviceLine.SBQQ__Product__c = productId;
        serviceLine.Equipment_Size__c = equipmentSize;
        serviceLine.SBQQ__RequiredBy__c = bundleId;
        serviceLine.Duration__c = duration;
        serviceLine.Vendor__c = vendorId;
        serviceLine.SBQQ__OptionLevel__c = 1;
        serviceLine.SBQQ__Quantity__c = 1;
        serviceLine.SBQQ__Number__c = quoteLineNumber != null ? quoteLineNumber + 1 : null;
        serviceLine.SBQQ__CostEditable__c = true;
        serviceLine.SBQQ__PriceEditable__c = true;
        serviceLine.SBQQ__StartDate__c = startDate;
        serviceLine.SBQQ__EndDate__c = endDate;
        serviceLine.CurrencyIsoCode = currencyCode;

        return serviceLine;
    }

    /**
     * @description Apply product option details to service line
     * Sets occurrence type, schedule frequency, and UOMs from product option
     * @param serviceLine Service line to update
     * @param productOption Product option with configuration
     * @param costUOM Cost UOM override (if any)
     * @param priceUOM Price UOM override (if any)
     * @return Updated service line (not saved)
     */
    public SBQQ__QuoteLine__c applyProductOptionDetails(
        SBQQ__QuoteLine__c serviceLine,
        SBQQ__ProductOption__c productOption,
        String costUOM,
        String priceUOM
    ) {
        if (serviceLine == null || productOption == null) {
            return serviceLine;
        }

        serviceLine.SBQQ__ProductOption__c = productOption.Id;
        serviceLine.Occurrence_Type__c = productOption.Occurrence_Type__c;
        serviceLine.CostModelType__c = productOption.CostModelType__c;

        if (productOption.Occurrence_Type__c == 'SCH') {
            serviceLine.Schedule_Frequency__c = productOption.Schedule_Frequency__c;
            serviceLine.Frequency_Interval__c = productOption.Frequency_Interval__c;
        }

        // Apply UOMs from product option or use overrides
        serviceLine.Cost_Unit_of_Measure__c = String.isNotBlank(costUOM) ?
            costUOM : productOption.Cost_Unit_of_Measure__c;
        serviceLine.PriceUOM__c = String.isNotBlank(priceUOM) ?
            priceUOM : productOption.PriceUOM__c;

        return serviceLine;
    }

    /**
     * @description Batch process service charge deletions
     * @param quoteLineIds List of quote line IDs to delete
     * @return Delete results
     */
    public List<Database.DeleteResult> deleteServiceChargeLines(List<Id> quoteLineIds) {
        if (quoteLineIds == null || quoteLineIds.isEmpty()) {
            return new List<Database.DeleteResult>();
        }

        try {
            List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();
            for (Id lineId : quoteLineIds) {
                linesToDelete.add(new SBQQ__QuoteLine__c(Id = lineId));
            }
            return Database.delete(linesToDelete, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ServiceChargeProcessingService', 'deleteServiceChargeLines');
            return new List<Database.DeleteResult>();
        }
    }
}
