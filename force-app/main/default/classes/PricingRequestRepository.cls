/**
 * @description Repository for Pricing_Request__c data access
 * Centralizes all pricing request queries with proper error handling
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 * @note Enhances existing PricingRequestSelector with clean separation of concerns
 */
public with sharing class PricingRequestRepository {

    /**
     * @description Get price-only (AMPO) pricing requests by quote ID
     * Pattern: Quote + AMPO type filtering
     * Extracted from: PricingRequestSelector.getPricingList()
     * @param quoteId Quote ID
     * @param limitSize Maximum number of records to return
     * @return List of AMPO pricing requests ordered by CreatedDate DESC
     */
    public List<Pricing_Request__c> getPriceOnlyRequests(Id quoteId, Integer limitSize) {
        if (quoteId == null || limitSize == null || limitSize <= 0) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Line_of_Business__c, Container_Type__c, Container_Size__c,
                       Material_Code__c, Service_Type__c, Quote__c, Quote__r.Name,
                       Quote_Line_Bundle__c, Quote_Line_Bundle__r.Name, Zone_Type__c,
                       Haul_Rate_Type__c, Haul_Cost__c, Haul_Price__c,
                       Disposal_Rate_Type__c, Disposal_Cost__c, Disposal_Price__c,
                       Pickup_Rate_Type__c, Pickup_Cost__c, Pickup_Price__c,
                       Extra_Pickup_Cost__c, Extra_Pickup_Price__c, isAPIResult__c,
                       APIRequestOutput__c, Case_Error_Message__c, IsCaseError__c,
                       Cost_Source__c, Source_Code__c, Vendor_Code__c, Vendor_Name__c,
                       Business_Unit__c, Project_Request__c, Customer_Price_Type__c,
                       Disposal_Record_Id__c, Haul_Record_Id__c, Pickup_Record_Id__c,
                       Extra_Pickup_Record_Id__c, Vendor_Comments__c, Facility_Id__c,
                       Facility_Name__c, Schedule_or_On_Call__c, Service_Baseline_ID__c,
                       IsPriceChangeRequest__c, Pricing_Type__c
                FROM Pricing_Request__c
                WHERE Quote__c = :quoteId
                AND Pricing_Type__c = 'AMPO'
                ORDER BY CreatedDate DESC
                LIMIT :limitSize
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'getPriceOnlyRequests');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get standard (AM) pricing requests by quote ID
     * Pattern: Quote + AM type filtering
     * Extracted from: PricingRequestSelector.getStandardPricingRequestList()
     * @param quoteId Quote ID
     * @return List of AM pricing requests ordered by CreatedDate DESC
     */
    public List<Pricing_Request__c> getStandardRequests(Id quoteId) {
        if (quoteId == null) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Line_of_Business__c, Container_Type__c, Container_Size__c,
                       Material_Code__c, Service_Type__c, Quote__c, Quote__r.Name,
                       Quote_Line_Bundle__c, Quote_Line_Bundle__r.Name, Zone_Type__c,
                       Haul_Rate_Type__c, Haul_Cost__c, Haul_Price__c,
                       Disposal_Rate_Type__c, Disposal_Cost__c, Disposal_Price__c,
                       Pickup_Rate_Type__c, Pickup_Cost__c, Pickup_Price__c,
                       Extra_Pickup_Cost__c, Extra_Pickup_Price__c, isAPIResult__c,
                       APIRequestOutput__c, Case_Error_Message__c, IsCaseError__c,
                       Cost_Source__c, Source_Code__c, Vendor_Code__c, Vendor_Name__c,
                       Business_Unit__c, Project_Request__c, Customer_Price_Type__c,
                       Disposal_Record_Id__c, Haul_Record_Id__c, Pickup_Record_Id__c,
                       Extra_Pickup_Record_Id__c, Vendor_Comments__c, Facility_Id__c,
                       Facility_Name__c, Schedule_or_On_Call__c, Service_Baseline_ID__c,
                       IsPriceChangeRequest__c, Pricing_Type__c,
                       Quote_Line_Bundle__r.Availability_Flag__c,
                       Quote_Line_Bundle__r.Vendor__r.Customer_Code__c,
                       Quote_Line_Bundle__r.SBQQ__StartDate__c,
                       Quote_Line_Bundle__r.SBQQ__EndDate__c,
                       Quote_Line_Bundle__r.ProcurementErrorMessage__c,
                       Quote_Line_Bundle__r.BundleProcuredStatus__c,
                       Quote_Line_Bundle__r.Pricing_Error__c, Is_Multi_Vendor__c
                FROM Pricing_Request__c
                WHERE Quote__c = :quoteId
                AND Pricing_Type__c = 'AM'
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'getStandardRequests');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get standard/cost override (AM/AMCO) pricing requests with limit
     * Pattern: Quote + (AM OR AMCO) type filtering
     * Extracted from: PricingRequestSelector.getStandardPricingRequestList() overload
     * @param quoteId Quote ID
     * @param limitSize Maximum number of records to return
     * @return List of AM/AMCO pricing requests ordered by CreatedDate DESC
     */
    public List<Pricing_Request__c> getStandardOrCostOverrideRequests(Id quoteId, Integer limitSize) {
        if (quoteId == null || limitSize == null || limitSize <= 0) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Line_of_Business__c, Container_Type__c, Container_Size__c,
                       Material_Code__c, Service_Type__c, Quote__c, Quote__r.Name,
                       Quote_Line_Bundle__c, Quote_Line_Bundle__r.Name, Zone_Type__c,
                       Haul_Rate_Type__c, Haul_Cost__c, Haul_Price__c,
                       Disposal_Rate_Type__c, Disposal_Cost__c, Disposal_Price__c,
                       Pickup_Rate_Type__c, Pickup_Cost__c, Pickup_Price__c,
                       Extra_Pickup_Cost__c, Extra_Pickup_Price__c, isAPIResult__c,
                       APIRequestOutput__c, Case_Error_Message__c, IsCaseError__c,
                       Cost_Source__c, Source_Code__c, Vendor_Code__c, Vendor_Name__c,
                       Business_Unit__c, Project_Request__c, Customer_Price_Type__c,
                       Disposal_Record_Id__c, Haul_Record_Id__c, Pickup_Record_Id__c,
                       Extra_Pickup_Record_Id__c, Vendor_Comments__c, Facility_Id__c,
                       Facility_Name__c, Schedule_or_On_Call__c, Service_Baseline_ID__c,
                       IsPriceChangeRequest__c, Pricing_Type__c,
                       Quote_Line_Bundle__r.Availability_Flag__c,
                       Quote_Line_Bundle__r.Vendor__r.Customer_Code__c,
                       Quote_Line_Bundle__r.SBQQ__StartDate__c,
                       Quote_Line_Bundle__r.SBQQ__EndDate__c,
                       Quote_Line_Bundle__r.ProcurementErrorMessage__c,
                       Quote_Line_Bundle__r.BundleProcuredStatus__c,
                       Quote_Line_Bundle__r.Pricing_Error__c
                FROM Pricing_Request__c
                WHERE Quote__c = :quoteId
                AND (Pricing_Type__c = 'AM' OR Pricing_Type__c = 'AMCO')
                ORDER BY CreatedDate DESC
                LIMIT :limitSize
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'getStandardOrCostOverrideRequests');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get pricing requests by ID set with full details
     * Pattern: Direct ID lookup
     * Extracted from: PricingRequestSelector.getPricingRequestListById()
     * @param pricingRequestIds Set of pricing request IDs
     * @return List of pricing requests with account/location/case details
     */
    public List<Pricing_Request__c> findByIds(Set<Id> pricingRequestIds) {
        if (pricingRequestIds == null || pricingRequestIds.isEmpty()) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Account__c, Location__c, Location__r.Location_Code__c,
                       Container_Type__c, Container_Size__c, Material_Code__c,
                       Service_Type__c, APIRequestOutput__c, Case__c, Case__r.CaseNumber,
                       Line_of_Business__c, Quote_Line_Bundle__c, Disposal_Cost__c,
                       Extra_Pickup_Cost__c, Haul_Cost__c, Pickup_Cost__c, Vendor_Code__c,
                       Project_Request__c, Project_Code__c, Project_Code__r.Name, Quote__c,
                       Account__r.IsPricingEligible__c, Quote__r.Name,
                       Account__r.Customer_Code__c, Quantity__c, Hauls_Month__c,
                       Industry_Classification__c, Customer_Owned__c,
                       Service_Street_Address__c, Service_City__c, Service_State__c,
                       Service_Country__c, Service_Postal_Code__c, Frequency_Type__c,
                       Frequency_Count__c, Account__r.Primary_Segment__c,
                       Schedule_or_On_Call__c,
                       Quote__r.SBQQ__Opportunity2__r.Case__r.Price_Quote_Identifier__c,
                       Quote__r.Quote_Only__c, Service_Baseline_ID__c,
                       IsPriceChangeRequest__c, Is_Multi_Vendor__c
                FROM Pricing_Request__c
                WHERE Id IN :pricingRequestIds
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'findByIds');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get pricing requests by case ID for status checking
     * Pattern: Case + pricing type filtering (compact field set)
     * Used for: Quote procurement status validation
     * @param caseId Case ID
     * @param pricingTypes Set of pricing types to filter (e.g., {'AM', 'AMCO'})
     * @return List of pricing requests with quote status fields
     */
    public List<Pricing_Request__c> findByCaseIdWithTypes(Id caseId, Set<String> pricingTypes) {
        if (caseId == null || pricingTypes == null || pricingTypes.isEmpty()) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, isAPIResult__c, IsCaseError__c, Quote__c, Case__c,
                       Case_Number__c, Quote__r.QuoteProcuredStatus__c,
                       Quote__r.SBQQ__Status__c, Pricing_Type__c
                FROM Pricing_Request__c
                WHERE Case__c = :caseId
                AND Pricing_Type__c IN :pricingTypes
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'findByCaseIdWithTypes');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get all pricing requests for a quote (all types)
     * Pattern: Quote-based retrieval without type filtering
     * @param quoteId Quote ID
     * @return List of all pricing requests for the quote
     */
    public List<Pricing_Request__c> findByQuoteId(Id quoteId) {
        if (quoteId == null) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Quote__c, Quote_Line_Bundle__c, Pricing_Type__c,
                       isAPIResult__c, APIRequestOutput__c, IsCaseError__c,
                       Case_Error_Message__c, Vendor_Code__c, Vendor_Name__c,
                       Cost_Source__c, Source_Code__c, Is_Multi_Vendor__c,
                       CreatedDate, LastModifiedDate
                FROM Pricing_Request__c
                WHERE Quote__c = :quoteId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'findByQuoteId');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Update pricing requests in bulk
     * @param pricingRequests List of pricing requests to update
     * @return Database.SaveResult list
     */
    public List<Database.SaveResult> updatePricingRequests(List<Pricing_Request__c> pricingRequests) {
        if (pricingRequests == null || pricingRequests.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        try {
            return Database.update(pricingRequests, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'updatePricingRequests');
            return new List<Database.SaveResult>();
        }
    }

    /**
     * @description Insert pricing requests in bulk
     * @param pricingRequests List of pricing requests to insert
     * @return Database.SaveResult list
     */
    public List<Database.SaveResult> insertPricingRequests(List<Pricing_Request__c> pricingRequests) {
        if (pricingRequests == null || pricingRequests.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        try {
            return Database.insert(pricingRequests, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'insertPricingRequests');
            return new List<Database.SaveResult>();
        }
    }

    /**
     * @description Delete pricing requests in bulk
     * @param pricingRequests List of pricing requests to delete
     * @return Database.DeleteResult list
     */
    public List<Database.DeleteResult> deletePricingRequests(List<Pricing_Request__c> pricingRequests) {
        if (pricingRequests == null || pricingRequests.isEmpty()) {
            return new List<Database.DeleteResult>();
        }

        try {
            return Database.delete(pricingRequests, false);
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'deletePricingRequests');
            return new List<Database.DeleteResult>();
        }
    }

    /**
     * @description Get pricing requests by bundle IDs
     * Useful for: Mapping pricing requests to specific bundles
     * @param bundleIds Set of quote line bundle IDs
     * @return List of pricing requests for the bundles
     */
    public List<Pricing_Request__c> findByBundleIds(Set<Id> bundleIds) {
        if (bundleIds == null || bundleIds.isEmpty()) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Quote__c, Quote_Line_Bundle__c, Pricing_Type__c,
                       Vendor_Code__c, Vendor_Name__c, APIRequestOutput__c,
                       isAPIResult__c, IsCaseError__c, Case_Error_Message__c,
                       Haul_Cost__c, Disposal_Cost__c, Pickup_Cost__c,
                       Haul_Price__c, Disposal_Price__c, Pickup_Price__c,
                       Is_Multi_Vendor__c
                FROM Pricing_Request__c
                WHERE Quote_Line_Bundle__c IN :bundleIds
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'findByBundleIds');
            return new List<Pricing_Request__c>();
        }
    }

    /**
     * @description Get multi-vendor pricing requests by quote ID
     * Pattern: Quote + multi-vendor flag filtering
     * @param quoteId Quote ID
     * @return List of multi-vendor pricing requests
     */
    public List<Pricing_Request__c> getMultiVendorRequests(Id quoteId) {
        if (quoteId == null) {
            return new List<Pricing_Request__c>();
        }

        try {
            return [
                SELECT Id, Name, Quote__c, Quote_Line_Bundle__c, Pricing_Type__c,
                       Vendor_Code__c, Vendor_Name__c, APIRequestOutput__c,
                       isAPIResult__c, Is_Multi_Vendor__c, Cost_Source__c,
                       Haul_Cost__c, Disposal_Cost__c, Pickup_Cost__c,
                       Haul_Price__c, Disposal_Price__c, Pickup_Price__c,
                       Quote_Line_Bundle__r.SBQQ__ProductCode__c,
                       Quote_Line_Bundle__r.Equipment_Size__c
                FROM Pricing_Request__c
                WHERE Quote__c = :quoteId
                AND Is_Multi_Vendor__c = true
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'PricingRequestRepository', 'getMultiVendorRequests');
            return new List<Pricing_Request__c>();
        }
    }
}
