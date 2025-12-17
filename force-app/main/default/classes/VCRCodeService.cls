/**
 * @description Service for VCR (Valet, Change, Regular) code orchestration
 * Extracts orchestration logic from QuoteTriggerHelper for better testability and error handling
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7B (VCR Code Service Enhancement)
 * @reference SDT-31118, SDT-38847, SDT-39669
 */
public class VCRCodeService {

    // Quote types that trigger VCR code calculation
    private static final List<String> QUOTETYPE_EXCEPTION_AMENDMENT_CORRECTION =
        new List<String>{'Exception', 'Amendment', 'Correction'};

    /**
     * @description Process quotes and update quote lines with VCR codes when status changes to Approved
     * Extracted from QuoteTriggerHelper.filterQuoteAndUpdateQuoteLinesWithVCR()
     * @param oldMap Map of old quote records (before update)
     * @param newMap Map of new quote records (after update)
     * @reference SDT-38847: Modified to trigger VCR Code calculation when status changes to Approved
     * @reference SDT-39669: Filter quotes by type (Exception, Amendment, Correction)
     */
    public void processQuoteStatusChangeForVCR(
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        if (newMap == null || newMap.isEmpty()) {
            return;
        }

        try {
            Set<Id> eligibleQuoteIds = filterEligibleQuotes(oldMap, newMap);

            if (!eligibleQuoteIds.isEmpty()) {
                updateVCRCodesForQuotes(eligibleQuoteIds);
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logException(
                ex,
                'VCRCodeService',
                'processQuoteStatusChangeForVCR'
            );
            throw ex;
        }
    }

    /**
     * @description Filter quotes that are eligible for VCR code calculation
     * A quote is eligible if:
     * - Status changed to Approved
     * - Quote type is Exception, Amendment, or Correction
     * @param oldMap Map of old quote records
     * @param newMap Map of new quote records
     * @return Set of eligible quote IDs
     */
    public Set<Id> filterEligibleQuotes(
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        Set<Id> filteredQuoteIds = new Set<Id>();

        if (newMap == null || newMap.isEmpty()) {
            return filteredQuoteIds;
        }

        for (Id currentQuoteId : newMap.keySet()) {
            SBQQ__Quote__c oldQuote = oldMap != null ? oldMap.get(currentQuoteId) : null;
            SBQQ__Quote__c newQuote = newMap.get(currentQuoteId);

            if (isEligibleForVCRCalculation(oldQuote, newQuote)) {
                filteredQuoteIds.add(currentQuoteId);
            }
        }

        System.debug('VCRCodeService: Filtered ' + filteredQuoteIds.size() +
                    ' quotes eligible for VCR calculation');

        return filteredQuoteIds;
    }

    /**
     * @description Check if a quote is eligible for VCR code calculation
     * @param oldQuote Quote record before update (can be null for inserts)
     * @param newQuote Quote record after update
     * @return True if quote is eligible for VCR calculation
     */
    public Boolean isEligibleForVCRCalculation(
        SBQQ__Quote__c oldQuote,
        SBQQ__Quote__c newQuote
    ) {
        if (newQuote == null) {
            return false;
        }

        // Check if status changed to Approved
        Boolean statusChangedToApproved =
            newQuote.SBQQ__Status__c == Constant_Util.QUOTE_APPROVED &&
            (oldQuote == null || oldQuote.SBQQ__Status__c != Constant_Util.QUOTE_APPROVED);

        // Check if quote type is eligible
        Boolean isEligibleType =
            QUOTETYPE_EXCEPTION_AMENDMENT_CORRECTION.contains(newQuote.SBQQ__Type__c);

        return statusChangedToApproved && isEligibleType;
    }

    /**
     * @description Update VCR codes for eligible quotes
     * Delegates to VCRCodeController for actual VCR code calculation
     * @param quoteIds Set of quote IDs to process
     */
    public void updateVCRCodesForQuotes(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) {
            return;
        }

        try {
            System.debug('VCRCodeService: Updating VCR codes for ' +
                        quoteIds.size() + ' quotes');

            // Delegate to VCRCodeController for VCR code calculation
            VCRCodeController.setVCRCodeForBundle(quoteIds);

            System.debug('VCRCodeService: Successfully updated VCR codes');
        } catch (Exception ex) {
            UTIL_LoggingService.logException(
                ex,
                'VCRCodeService',
                'updateVCRCodesForQuotes'
            );
            throw ex;
        }
    }

    /**
     * @description Get the list of quote types that trigger VCR calculation
     * Exposed for testing and configuration purposes
     * @return List of eligible quote types
     */
    @TestVisible
    public List<String> getEligibleQuoteTypes() {
        return QUOTETYPE_EXCEPTION_AMENDMENT_CORRECTION.clone();
    }

    /**
     * @description Bulk process multiple quote updates for VCR calculation
     * Useful for batch operations and data migrations
     * @param quotesToProcess List of quotes to evaluate for VCR calculation
     * @return Number of quotes processed
     */
    public Integer bulkProcessQuotesForVCR(List<SBQQ__Quote__c> quotesToProcess) {
        if (quotesToProcess == null || quotesToProcess.isEmpty()) {
            return 0;
        }

        try {
            Set<Id> eligibleQuoteIds = new Set<Id>();

            for (SBQQ__Quote__c quote : quotesToProcess) {
                if (quote.SBQQ__Status__c == Constant_Util.QUOTE_APPROVED &&
                    QUOTETYPE_EXCEPTION_AMENDMENT_CORRECTION.contains(quote.SBQQ__Type__c)) {
                    eligibleQuoteIds.add(quote.Id);
                }
            }

            if (!eligibleQuoteIds.isEmpty()) {
                updateVCRCodesForQuotes(eligibleQuoteIds);
            }

            return eligibleQuoteIds.size();
        } catch (Exception ex) {
            UTIL_LoggingService.logException(
                ex,
                'VCRCodeService',
                'bulkProcessQuotesForVCR'
            );
            throw ex;
        }
    }
}
