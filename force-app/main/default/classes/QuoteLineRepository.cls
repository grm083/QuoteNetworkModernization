/**
 * @description Repository for SBQQ__QuoteLine__c data access
 * Centralizes all quote line queries to eliminate duplication and ensure consistent SOQL
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
public with sharing class QuoteLineRepository {

    /**
     * @description Get top-level bundle quote lines (parent lines with no RequiredBy parent)
     * Pattern 1: Bundle/Parent Lines
     * Extracted from: PricingRequestSTPProcess.getQuoteLineList()
     * @param quoteId Quote ID to retrieve bundles for
     * @return List of bundle quote lines with comprehensive pricing and vendor data
     */
    public List<SBQQ__QuoteLine__c> getQuoteBundles(Id quoteId) {
        if (quoteId == null) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, Pricing_Error__c, Is_Vendor_Mismatch__c, SBQQ__ProductCode__c,
                       SBQQ__ProductName__c, Equipment_Size__c, SBQQ__Quote__c,
                       SBQQ__Quote__r.Name, Name, SBQQ__StartDate__c, SBQQ__EndDate__c,
                       Duration__c, CurrencyIsoCode, ProcurementErrorMessage__c,
                       ByPassFunctionality__c, BundleProcuredStatus__c,
                       Is_Substituted_Container__c, Type_of_Change__c, Vendor__c,
                       Vendor__r.Name, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c,
                       Original_Equipment_Size__c, Material_Type__c, Pricing_Request__c,
                       Pricing_Request__r.IsCaseError__c,
                       Pricing_Request__r.APIRequestOutput__c,
                       Account__r.Parent.IsPricingEligible__c,
                       SBQQ__Product__r.Is_Pricing_Eligible__c, SBQQ__Quote__r.STP__c,
                       BypassPriceReview__c, PriceMinQuantity__c, CostMinQuantity__c,
                       SBQQ__Quote__r.Special_Handling__c,
                       SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.DeveloperName,
                       AAV_Service_Availability__c, AAV_Delivery_Availability__c,
                       AAV_Requested_AdditionalServicesAccessor__c, Availability_Flag__c,
                       SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.SBQQ__ShippingCountry__c,
                       Account__r.Parent.Primary_Segment__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND SBQQ__RequiredBy__c = null
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getQuoteBundles');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get service/child lines for specific bundles
     * Pattern 2: Service Lines by Bundle
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess()
     * @param bundleIds Set of bundle IDs to retrieve child lines for
     * @return List of service lines ordered by quote line number descending
     */
    public List<SBQQ__QuoteLine__c> getServiceLinesByBundles(Set<Id> bundleIds) {
        if (bundleIds == null || bundleIds.isEmpty()) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, SBQQ__ProductCode__c, SBQQ__ProductName__c, SBQQ__Number__c,
                       SBQQ__ProductFamily__c, SBQQ__Quote__c, Occurrence_Type__c,
                       Cost_Unit_of_Measure__c, SBQQ__UnitCost__c, PriceUOM__c,
                       SBQQ__ListPrice__c, SBQQ__RequiredBy__c, SBQQ__CustomerPrice__c,
                       CostModelType__c, Type_of_Change__c, AssetId__c,
                       ByPassFunctionality__c, Schedule_Frequency__c,
                       Frequency_Interval__c, Service_Days__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__RequiredBy__c IN :bundleIds
                ORDER BY SBQQ__Number__c DESC
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getServiceLinesByBundles');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get service lines filtered by product family
     * Pattern 2: Service Lines with Product Family Filter
     * Extracted from: PricingRequestSTPProcess.getPricingDetails()
     * @param bundleIds Set of bundle IDs
     * @param productFamilies Set of product families to filter (Rolloff, Commercial, etc.)
     * @return List of service lines with pricing data
     */
    public List<SBQQ__QuoteLine__c> getServiceLinesByProductFamily(
        Set<Id> bundleIds,
        Set<String> productFamilies
    ) {
        if (bundleIds == null || bundleIds.isEmpty() ||
            productFamilies == null || productFamilies.isEmpty()) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, Is_Vendor_Mismatch__c, BundleProcuredStatus__c,
                       Pricing_Error__c, ProcurementErrorMessage__c, SBQQ__ProductCode__c,
                       SBQQ__ProductName__c, SBQQ__Quote__c, Occurrence_Type__c,
                       Cost_Unit_of_Measure__c, SBQQ__UnitCost__c, PriceUOM__c,
                       SBQQ__ListPrice__c, SBQQ__RequiredBy__c, SBQQ__CustomerPrice__c,
                       Pricing_API_Method__c, CostModelType__c, SBQQ__PricingMethod__c,
                       SBQQ__SubscriptionPercent__c, SBQQ__MarkupRate__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__RequiredBy__c IN :bundleIds
                AND SBQQ__ProductFamily__c IN :productFamilies
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getServiceLinesByProductFamily');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get all quote lines (bundles + services) for a quote
     * Pattern 3: All Quote Lines (Hierarchy Agnostic)
     * Extracted from: PricingRequestSTPProcess.saveProcuredStatus()
     * @param quoteId Quote ID
     * @return Map of quote line ID to quote line record
     */
    public Map<Id, SBQQ__QuoteLine__c> getAllQuoteLines(Id quoteId) {
        if (quoteId == null) {
            return new Map<Id, SBQQ__QuoteLine__c>();
        }

        try {
            return new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, SBQQ__ProductCode__c, Pricing_Error__c,
                       ProcurementErrorMessage__c, BundleProcuredStatus__c,
                       Pricing_API_Method__c, SBQQ__ProductName__c, SBQQ__Quote__c,
                       Occurrence_Type__c, SBQQ__ProductFamily__c,
                       SBQQ__RequiredBy__r.SBQQ__ProductFamily__c,
                       Cost_Unit_of_Measure__c, SBQQ__UnitCost__c, PriceUOM__c,
                       SBQQ__ListPrice__c, SBQQ__RequiredBy__c, SBQQ__CustomerPrice__c,
                       CostPrice1__c, CostPrice2__c, ContractNotes__c,
                       SBQQ__Product__r.Is_Pricing_Eligible__c, SBQQ__Product__r.Name,
                       Source_Code__c,
                       SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.DeveloperName,
                       AAV_Service_Availability__c, AAV_Delivery_Availability__c,
                       AAV_Requested_AdditionalServicesAccessor__c, Availability_Flag__c,
                       AAV_Priority__c, SBQQ__StartDate__c,
                       Pricing_Request__r.Customer_Price_Type__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
            ]);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getAllQuoteLines');
            return new Map<Id, SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get all quote lines for product detail evaluation
     * Pattern 3: All Quote Lines (Minimal Fields)
     * Extracted from: PricingRequestSTPProcess.getQuoteProductDetail()
     * @param quoteId Quote ID
     * @return Map of quote line ID to quote line record
     */
    public Map<Id, SBQQ__QuoteLine__c> getAllQuoteLinesForProductDetail(Id quoteId) {
        if (quoteId == null) {
            return new Map<Id, SBQQ__QuoteLine__c>();
        }

        try {
            return new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductFamily__c,
                       SBQQ__RequiredBy__r.SBQQ__ProductFamily__c, SBQQ__ProductCode__c,
                       SBQQ__ProductName__c, SBQQ__UnitCost__c, SBQQ__ListPrice__c,
                       CostPrice1__c, CostPrice2__c, Pricing_API_Method__c,
                       SBQQ__Product__r.Is_Pricing_Eligible__c, Source_Code__c,
                       ServiceBaselineId__c, Pricing_Request__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
            ]);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getAllQuoteLinesForProductDetail');
            return new Map<Id, SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get all quote lines for SLA and date processing
     * Pattern 3: All Quote Lines for SLA
     * Extracted from: PricingJSONRequest.CheckAndUpdateVendorCommitDateAndStartDate()
     * @param quoteId Quote ID
     * @return List of quote lines with SLA date fields
     */
    public List<SBQQ__QuoteLine__c> getAllQuoteLinesForSLA(Id quoteId) {
        if (quoteId == null) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, Exception_Type__c, Exception_Reason__c, Exception_Comments__c,
                       Exception_Effective_Date__c, SBQQ__Quote__r.Name,
                       SBQQ__Quote__r.Case_Number__c,
                       SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Reference_Number__c,
                       SBQQ__EndDate__c, SBQQ__ProductName__c, Quote_SLA_Date__c,
                       Vendor_Commit_Date__c, Exceptions_Effective_Date__c,
                       SBQQ__StartDate__c, SBQQ__ProductFamily__c, SBQQ__Quote__c,
                       SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                       SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name,
                       Duration__c,
                       SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Quote__r.Name,
                       SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Quote__r.Case_Number__c,
                       SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Reference_Number__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getAllQuoteLinesForSLA');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get waste stream lines by quote name
     * Pattern 4: Waste Stream/Specialty Lines
     * Extracted from: PricingJSONRequest.integrationToAPI()
     * @param quoteName Quote name (not ID!)
     * @return List of waste stream quote lines
     */
    public List<SBQQ__QuoteLine__c> getWasteStreamLines(String quoteName) {
        if (String.isEmpty(quoteName)) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, SBQQ__Product__r.Name, SBQQ__Product__r.ProductCode,
                       SBQQ__RequiredBy__r.SBQQ__RequiredBy__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Product__r.Family = 'Waste Stream'
                AND SBQQ__Quote__r.Name = :quoteName
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getWasteStreamLines');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Get waste category lines for material grade mapping
     * Pattern 4: Waste Category Lines
     * Extracted from: PricingJSONRequest.integrationToAPI()
     * @param quoteName Quote name (not ID!)
     * @return List of waste category quote lines
     */
    public List<SBQQ__QuoteLine__c> getWasteCategoryLines(String quoteName) {
        if (String.isEmpty(quoteName)) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, SBQQ__Product__r.Name, material_type__c, materialGrade__c,
                       SBQQ__Product__r.ProductCode, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Product__r.Family = 'Waste Category'
                AND SBQQ__Quote__r.Name = :quoteName
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getWasteCategoryLines');
            return new List<SBQQ__QuoteLine__c>();
        }
    }

    /**
     * @description Update quote lines in bulk
     * @param quoteLines List of quote lines to update
     * @return Database.SaveResult list
     */
    public List<Database.SaveResult> updateQuoteLines(List<SBQQ__QuoteLine__c> quoteLines) {
        if (quoteLines == null || quoteLines.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        try {
            return Database.update(quoteLines, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'updateQuoteLines');
            return new List<Database.SaveResult>();
        }
    }

    /**
     * @description Delete quote lines in bulk
     * @param quoteLines List of quote lines to delete
     * @return Database.DeleteResult list
     */
    public List<Database.DeleteResult> deleteQuoteLines(List<SBQQ__QuoteLine__c> quoteLines) {
        if (quoteLines == null || quoteLines.isEmpty()) {
            return new List<Database.DeleteResult>();
        }

        try {
            return Database.delete(quoteLines, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'deleteQuoteLines');
            return new List<Database.DeleteResult>();
        }
    }

    /**
     * @description Get core service lines (scheduled occurrence, core service flag)
     * Useful for pricing and VCR calculations
     * @param bundleIds Set of bundle IDs
     * @return List of core service quote lines
     */
    public List<SBQQ__QuoteLine__c> getCoreServiceLines(Set<Id> bundleIds) {
        if (bundleIds == null || bundleIds.isEmpty()) {
            return new List<SBQQ__QuoteLine__c>();
        }

        try {
            return [
                SELECT Id, SBQQ__ProductCode__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c,
                       Occurrence_Type__c, Schedule_Frequency__c, Frequency_Interval__c,
                       Service_Days__c, Core_Service__c, SBQQ__Quantity__c,
                       Equipment_Size__c, SBQQ__UnitCost__c, Cost_Unit_of_Measure__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__RequiredBy__c IN :bundleIds
                AND Core_Service__c = true
                AND Occurrence_Type__c = 'Scheduled'
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLineRepository', 'getCoreServiceLines');
            return new List<SBQQ__QuoteLine__c>();
        }
    }
}
