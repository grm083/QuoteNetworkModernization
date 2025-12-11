/**
 * @description Service for vendor matching and validation operations
 * Extracts vendor matching logic from PricingRequestSTPProcess
 * Part of Phase 8 - STP Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 * @note Centralizes vendor comparison and mismatch detection logic
 */
public with sharing class VendorMatchingService {

    /**
     * @description Result of vendor matching operation
     */
    public class VendorMatchResult {
        @AuraEnabled public Boolean isMatch { get; set; }
        @AuraEnabled public Boolean isMismatch { get; set; }
        @AuraEnabled public String mismatchReason { get; set; }

        public VendorMatchResult() {
            this.isMatch = false;
            this.isMismatch = false;
            this.mismatchReason = null;
        }
    }

    /**
     * @description Compare QuoteLine vendor with Pricing Request vendor
     * Extracted from: PricingRequestSTPProcess.compareQuotelineVendorWithPRVendor()
     * Used for: Service modification cases to ensure vendor consistency
     *
     * Matching Rules:
     * 1. Vendor IDs match directly (ql.Vendor__r.Vendor_ID__c == vendorAccount.Vendor_ID__c)
     * 2. OR Parent Vendor IDs match (ql.Vendor__r.Parent_Vendor_ID__c == vendorAccount.Parent_Vendor_ID__c)
     * 3. AND Type_of_Change__c must be populated (service modification indicator)
     *
     * @param quoteLine The quote line with existing vendor relationship
     * @param vendorAccount The vendor account from pricing request
     * @return VendorMatchResult with match status and mismatch details
     */
    public VendorMatchResult compareQuoteLineVendor(
        SBQQ__QuoteLine__c quoteLine,
        Account vendorAccount
    ) {
        VendorMatchResult result = new VendorMatchResult();

        // Null safety checks
        if (quoteLine == null) {
            result.isMismatch = true;
            result.mismatchReason = 'Quote line is null';
            return result;
        }

        // Vendor account null check
        if (vendorAccount == null) {
            result.isMismatch = true;
            result.mismatchReason = 'Vendor account is null';
            return result;
        }

        // Check if quote line has vendor relationship
        if (quoteLine.Vendor__r == null) {
            result.isMismatch = true;
            result.mismatchReason = 'Quote line has no vendor relationship';
            return result;
        }

        // Check Type_of_Change__c requirement for service modifications
        if (String.isBlank(quoteLine.Type_of_Change__c)) {
            result.isMismatch = true;
            result.mismatchReason = 'Type of Change is not populated';
            return result;
        }

        // Perform vendor matching
        Boolean vendorIdMatch = quoteLine.Vendor__r.Vendor_ID__c == vendorAccount.Vendor_ID__c;
        Boolean parentVendorIdMatch = quoteLine.Vendor__r.Parent_Vendor_ID__c == vendorAccount.Parent_Vendor_ID__c;

        if (vendorIdMatch || parentVendorIdMatch) {
            result.isMatch = true;
            result.isMismatch = false;
            result.mismatchReason = null;
        } else {
            result.isMatch = false;
            result.isMismatch = true;
            result.mismatchReason = String.format(
                'Vendor mismatch: QuoteLine vendor {0}/{1} does not match Pricing Request vendor {2}/{3}',
                new List<String>{
                    quoteLine.Vendor__r.Vendor_ID__c,
                    quoteLine.Vendor__r.Parent_Vendor_ID__c,
                    vendorAccount.Vendor_ID__c,
                    vendorAccount.Parent_Vendor_ID__c
                }
            );
        }

        return result;
    }

    /**
     * @description Apply vendor mismatch result to quote line
     * Updates Is_Vendor_Mismatch__c and BundleProcuredStatus__c flags
     * @param quoteLine Quote line to update
     * @param matchResult Result from vendor matching
     * @return Updated quote line (not saved to database)
     */
    public SBQQ__QuoteLine__c applyVendorMismatchResult(
        SBQQ__QuoteLine__c quoteLine,
        VendorMatchResult matchResult
    ) {
        if (quoteLine == null || matchResult == null) {
            return quoteLine;
        }

        quoteLine.Is_Vendor_Mismatch__c = matchResult.isMismatch;

        if (matchResult.isMismatch) {
            quoteLine.BundleProcuredStatus__c = 'NO';
            // Note: ProcurementErrorMessage__c can be set by caller if needed
            // Original code had commented line: sqlHdr.ProcurementErrorMessage__c += System.label.Vendor_Mismatch;
        }

        return quoteLine;
    }

    /**
     * @description Check if vendor matches by ID or parent hierarchy
     * Simplified version without Type_of_Change__c requirement
     * @param quoteLineVendorId Quote line vendor ID
     * @param quoteLineParentVendorId Quote line parent vendor ID
     * @param pricingVendorId Pricing request vendor ID
     * @param pricingParentVendorId Pricing request parent vendor ID
     * @return True if vendors match by ID or parent hierarchy
     */
    public Boolean isVendorMatch(
        String quoteLineVendorId,
        String quoteLineParentVendorId,
        String pricingVendorId,
        String pricingParentVendorId
    ) {
        if (String.isBlank(quoteLineVendorId) || String.isBlank(pricingVendorId)) {
            return false;
        }

        // Direct vendor ID match
        if (quoteLineVendorId == pricingVendorId) {
            return true;
        }

        // Parent vendor hierarchy match
        if (String.isNotBlank(quoteLineParentVendorId) &&
            String.isNotBlank(pricingParentVendorId) &&
            quoteLineParentVendorId == pricingParentVendorId) {
            return true;
        }

        return false;
    }

    /**
     * @description Validate vendor assignment for service modification
     * Used in: Modify Existing Service case record type scenarios
     * @param quoteLine Quote line with existing vendor
     * @param vendorAccount New vendor from pricing request
     * @param caseRecordTypeDeveloperName Case record type developer name
     * @return True if vendor assignment is valid for the case type
     */
    public Boolean isValidVendorForServiceModification(
        SBQQ__QuoteLine__c quoteLine,
        Account vendorAccount,
        String caseRecordTypeDeveloperName
    ) {
        // Only validate for Modify Existing Service cases
        if (caseRecordTypeDeveloperName != Constant_Util.MODIFY_EXISTING_SERVICE_CASE_API) {
            return true; // No validation required for other case types
        }

        VendorMatchResult matchResult = compareQuoteLineVendor(quoteLine, vendorAccount);
        return matchResult.isMatch;
    }

    /**
     * @description Find matching vendor from map by vendor code
     * Supports pipe-delimited vendor codes via VendorRepository
     * @param vendorMap Map of vendor ID to Account
     * @param vendorCode Vendor code (may be pipe-delimited)
     * @param vendorRepository Repository for vendor code extraction
     * @return Matching vendor account or null
     */
    public Account findVendorInMap(
        Map<String, Account> vendorMap,
        String vendorCode,
        VendorRepository vendorRepository
    ) {
        if (vendorMap == null || String.isBlank(vendorCode)) {
            return null;
        }

        // Extract base vendor code (handles pipe-delimited format)
        String extractedCode = vendorRepository != null ?
            vendorRepository.extractVendorCode(vendorCode) :
            vendorCode;

        return vendorMap.get(extractedCode);
    }

    /**
     * @description Check if vendors match by Account records
     * Convenience method for account-based matching
     * @param vendor1 First vendor account
     * @param vendor2 Second vendor account
     * @return True if vendors match by ID or parent hierarchy
     */
    public Boolean areVendorsEqual(Account vendor1, Account vendor2) {
        if (vendor1 == null || vendor2 == null) {
            return false;
        }

        return isVendorMatch(
            vendor1.Vendor_ID__c,
            vendor1.Parent_Vendor_ID__c,
            vendor2.Vendor_ID__c,
            vendor2.Parent_Vendor_ID__c
        );
    }

    /**
     * @description Batch process vendor matching for multiple quote lines
     * @param quoteLines List of quote lines to validate
     * @param vendorMap Map of vendor codes to vendor accounts
     * @param vendorRepository Repository for vendor operations
     * @return Map of quote line ID to match result
     */
    public Map<Id, VendorMatchResult> batchValidateVendors(
        List<SBQQ__QuoteLine__c> quoteLines,
        Map<String, Account> vendorMap,
        VendorRepository vendorRepository
    ) {
        Map<Id, VendorMatchResult> results = new Map<Id, VendorMatchResult>();

        if (quoteLines == null || quoteLines.isEmpty()) {
            return results;
        }

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.Vendor__r == null) {
                VendorMatchResult noVendorResult = new VendorMatchResult();
                noVendorResult.isMismatch = true;
                noVendorResult.mismatchReason = 'Quote line has no vendor';
                results.put(quoteLine.Id, noVendorResult);
                continue;
            }

            // Find corresponding vendor from pricing request
            // This would typically come from a pricing request's vendor code
            // For now, just validate that the vendor exists in the map
            String vendorId = quoteLine.Vendor__r.Vendor_ID__c;
            Account vendorAccount = vendorMap != null ? vendorMap.get(vendorId) : null;

            VendorMatchResult matchResult = compareQuoteLineVendor(quoteLine, vendorAccount);
            results.put(quoteLine.Id, matchResult);
        }

        return results;
    }
}
