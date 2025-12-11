/**
 * @description Repository for Account (Vendor) data access
 * Centralizes vendor lookups and eliminates duplicate vendor queries
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
public with sharing class VendorRepository {

    /**
     * @description Get active vendors by vendor IDs
     * Pattern: Bulk vendor lookup with active status filter
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess() line 529
     * Extracted from: PricingRequestMultiVendorSTPProcess.quoteLineMultiVendorProcess() line 905
     * @param vendorIds Set of vendor IDs to retrieve
     * @return List of active vendor accounts
     */
    public List<Account> getActiveVendorsByIds(Set<String> vendorIds) {
        if (vendorIds == null || vendorIds.isEmpty()) {
            return new List<Account>();
        }

        try {
            return [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c
                FROM Account
                WHERE Status__c = 'Active'
                AND Vendor_ID__c IN :vendorIds
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getActiveVendorsByIds');
            return new List<Account>();
        }
    }

    /**
     * @description Get active vendors as a map keyed by Vendor_ID__c
     * Pattern: Efficient lookup map for vendor matching
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess() lines 533-535
     * @param vendorIds Set of vendor IDs
     * @return Map of Vendor_ID__c to Account
     */
    public Map<String, Account> getActiveVendorMapByIds(Set<String> vendorIds) {
        if (vendorIds == null || vendorIds.isEmpty()) {
            return new Map<String, Account>();
        }

        try {
            Map<String, Account> vendorMap = new Map<String, Account>();
            List<Account> vendors = getActiveVendorsByIds(vendorIds);

            for (Account vendor : vendors) {
                vendorMap.put(vendor.Vendor_ID__c, vendor);
            }

            return vendorMap;
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getActiveVendorMapByIds');
            return new Map<String, Account>();
        }
    }

    /**
     * @description Get vendors by parent vendor IDs
     * Pattern: Hierarchical vendor lookup
     * @param parentVendorIds Set of parent vendor IDs
     * @return List of vendor accounts
     */
    public List<Account> getVendorsByParentVendorIds(Set<String> parentVendorIds) {
        if (parentVendorIds == null || parentVendorIds.isEmpty()) {
            return new List<Account>();
        }

        try {
            return [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c
                FROM Account
                WHERE Status__c = 'Active'
                AND Parent_Vendor_ID__c IN :parentVendorIds
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getVendorsByParentVendorIds');
            return new List<Account>();
        }
    }

    /**
     * @description Get vendor by single vendor ID
     * Pattern: Single vendor lookup
     * @param vendorId Vendor ID to retrieve
     * @return Vendor account or null if not found
     */
    public Account getActiveVendorById(String vendorId) {
        if (String.isEmpty(vendorId)) {
            return null;
        }

        try {
            List<Account> vendors = [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c
                FROM Account
                WHERE Status__c = 'Active'
                AND Vendor_ID__c = :vendorId
                LIMIT 1
            ];

            return vendors.isEmpty() ? null : vendors[0];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getActiveVendorById');
            return null;
        }
    }

    /**
     * @description Get vendor account by Account ID
     * Pattern: Direct ID lookup
     * @param accountId Account record ID
     * @return Vendor account or null if not found
     */
    public Account getVendorByAccountId(Id accountId) {
        if (accountId == null) {
            return null;
        }

        try {
            List<Account> vendors = [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c,
                       Status__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            return vendors.isEmpty() ? null : vendors[0];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getVendorByAccountId');
            return null;
        }
    }

    /**
     * @description Extract vendor code from pipe-delimited value
     * Pattern: Vendor code normalization
     * Extracted from: PricingRequestSTPProcess lines 524-526, 574-579
     * @param vendorCode Raw vendor code (may contain pipe delimiter)
     * @return Normalized vendor code
     */
    public String extractVendorCode(String vendorCode) {
        if (String.isEmpty(vendorCode)) {
            return null;
        }

        // Handle pipe-delimited vendor codes like "VENDOR001|additional_info"
        return vendorCode.contains('|') ?
               vendorCode.substringBefore('|') :
               vendorCode;
    }

    /**
     * @description Extract vendor codes from a list of Pricing_Request__c records
     * Pattern: Bulk vendor code extraction
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess() lines 519-527
     * @param pricingRequests List of pricing request records
     * @return Set of normalized vendor codes
     */
    public Set<String> extractVendorCodesFromPricingRequests(
        List<Pricing_Request__c> pricingRequests
    ) {
        Set<String> vendorCodes = new Set<String>();

        if (pricingRequests == null || pricingRequests.isEmpty()) {
            return vendorCodes;
        }

        for (Pricing_Request__c pr : pricingRequests) {
            if (!String.isEmpty(pr.Vendor_Code__c)) {
                vendorCodes.add(extractVendorCode(pr.Vendor_Code__c));
            }
        }

        return vendorCodes;
    }

    /**
     * @description Get vendor from map with code normalization
     * Pattern: Safe vendor lookup from map with pipe-delimited handling
     * Extracted from: PricingRequestSTPProcess.quoteLineProcess() lines 574-579
     * @param vendorMap Map of vendor codes to accounts
     * @param vendorCode Raw vendor code
     * @return Vendor account or null
     */
    public Account getVendorFromMap(Map<String, Account> vendorMap, String vendorCode) {
        if (vendorMap == null || vendorMap.isEmpty() || String.isEmpty(vendorCode)) {
            return null;
        }

        String normalizedCode = extractVendorCode(vendorCode);
        return vendorMap.get(normalizedCode);
    }

    /**
     * @description Get all active vendors (use with caution - can return large result sets)
     * Pattern: Full vendor list retrieval
     * @return List of all active vendors
     */
    public List<Account> getAllActiveVendors() {
        try {
            return [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c
                FROM Account
                WHERE Status__c = 'Active'
                AND Vendor_ID__c != null
                ORDER BY Name
                LIMIT 10000
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getAllActiveVendors');
            return new List<Account>();
        }
    }

    /**
     * @description Check if vendor account is WM vendor (WM or WM Canada)
     * Pattern: Vendor type checking
     * @param parentVendorId Parent vendor ID to check
     * @return True if WM vendor
     */
    public Boolean isWMVendor(String parentVendorId) {
        if (String.isEmpty(parentVendorId)) {
            return false;
        }

        return parentVendorId == Constant_Util.WM_US_VENDOR ||
               parentVendorId == Constant_Util.WM_CANADA_VENDOR;
    }

    /**
     * @description Get vendors with detailed information
     * Pattern: Extended vendor details for reporting/analysis
     * @param vendorIds Set of vendor IDs
     * @return List of vendors with extended fields
     */
    public List<Account> getVendorsWithDetails(Set<String> vendorIds) {
        if (vendorIds == null || vendorIds.isEmpty()) {
            return new List<Account>();
        }

        try {
            return [
                SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c, Name, Customer_Code__c,
                       Status__c, Type, Phone, BillingStreet, BillingCity, BillingState,
                       BillingPostalCode, BillingCountry, Primary_Segment__c
                FROM Account
                WHERE Status__c = 'Active'
                AND Vendor_ID__c IN :vendorIds
            ];
        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'VendorRepository', 'getVendorsWithDetails');
            return new List<Account>();
        }
    }
}
