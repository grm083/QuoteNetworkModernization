/**
 * @description Service for managing baseline updates on quote lines
 * Handles End and Extend vs Update Baseline scenarios
 * Extracts baseline update logic from createDelivery() lines 3008-3076
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3C
 */
public class BaselineUpdateService {

    private ServiceDateManager dateManager;

    /**
     * @description Constructor
     */
    public BaselineUpdateService() {
        this.dateManager = new ServiceDateManager();
    }

    /**
     * @description Apply baseline updates to quote line based on comparison result
     * Replaces logic from createDelivery() lines 3008-3076
     * @param quoteLine Quote line to update
     * @param comparisonResult Comparison result determining update type
     * @param asset Related asset
     * @param serviceDate Service date from order wrapper
     * @param serviceEndDate Service end date from order wrapper
     * @return Updated quote line
     */
    public SBQQ__QuoteLine__c applyBaselineUpdate(
        SBQQ__QuoteLine__c quoteLine,
        AssetComparisonResult comparisonResult,
        Asset asset,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLine == null || comparisonResult == null) {
            return quoteLine;
        }

        // If matched, no updates needed
        if (comparisonResult.isMatched) {
            return quoteLine;
        }

        // Apply End and Extend baseline updates
        if (comparisonResult.isEndAndExtendBaseline) {
            applyEndAndExtendUpdates(quoteLine, asset, serviceDate, serviceEndDate);
        }
        // Apply Update Baseline updates (SDT-31788)
        else if (comparisonResult.isUpdateBaseline) {
            applyUpdateBaselineUpdates(quoteLine);
        }

        return quoteLine;
    }

    /**
     * @description Apply End and Extend baseline updates
     * Replaces logic from createDelivery() lines 3012-3059
     * @param quoteLine Quote line to update
     * @param asset Related asset
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     */
    private void applyEndAndExtendUpdates(
        SBQQ__QuoteLine__c quoteLine,
        Asset asset,
        Date serviceDate,
        Date serviceEndDate
    ) {
        // Update dates using ServiceDateManager (SDT-33378)
        dateManager.updateDatesForEndAndExtend(quoteLine, serviceDate, serviceEndDate);

        // Set service action for Amend/Exception/Correction quotes (SDT-38052)
        if (quoteLine.SBQQ__Quote__r.SBQQ__Type__c == Constant_Util.QUOTE_TYPE_AMEND
            || quoteLine.SBQQ__Quote__r.SBQQ__Type__c == Constant_Util.QUOTE_TYPE_EXCEPTION
            || quoteLine.SBQQ__Quote__r.SBQQ__Type__c == Constant_Util.QUOTE_TYPE_CORRECTION) {

            if (quoteLine.AssetId__c != null) {
                List<Schema.PicklistEntry> serviceActionEntries =
                    Schema.SObjectType.SBQQ__QuoteLine__c.fields.Service_Action__c.getPicklistValues();

                quoteLine.Service_Action__c = AssetQuoteProcurementController.getPicklistEntryByLabel(
                    serviceActionEntries,
                    Constant_Util.EXTEND_SERVICE
                );
            }
        }

        // Set default values (SDT-33285)
        QuoteLineServices.setDefaultValuesForQuoteLines(
            quoteLine,
            quoteLine.SBQQ__Quote__r.Name,
            asset
        );
    }

    /**
     * @description Apply Update Baseline updates
     * Replaces logic from createDelivery() lines 3061-3064 (SDT-31788)
     * @param quoteLine Quote line to update
     */
    private void applyUpdateBaselineUpdates(SBQQ__QuoteLine__c quoteLine) {
        // Set service action to Do Not Extend
        quoteLine.Service_Action__c = QuoteLineSelector.SERVICE_ACTION_DO_NOT_EXTEND_SERVICE;
    }

    /**
     * @description Track pickup lines for extra pickup handling
     * Replaces logic from createDelivery() lines 3053-3058 (SDT-32782)
     * @param quoteLine Quote line to check
     * @param pickupMap Map to store pickup lines
     */
    public void trackPickupLine(
        SBQQ__QuoteLine__c quoteLine,
        Map<Id, SBQQ__QuoteLine__c> pickupMap
    ) {
        if (quoteLine == null || pickupMap == null) {
            return;
        }

        if (quoteLine.SBQQ__ProductName__c == Constant_Util.PR_PICKUP) {
            pickupMap.put(quoteLine.SBQQ__RequiredBy__c, quoteLine);
        }
    }

    /**
     * @description Track extra pickup lines
     * Replaces logic from createDelivery() lines 3070-3075 (SDT-32782)
     * @param quoteLine Quote line to check
     * @param extraPickupMap Map to store extra pickup lines
     */
    public void trackExtraPickupLine(
        SBQQ__QuoteLine__c quoteLine,
        Map<Id, SBQQ__QuoteLine__c> extraPickupMap
    ) {
        if (quoteLine == null || extraPickupMap == null) {
            return;
        }

        if (quoteLine.SBQQ__ProductName__c == Constant_Util.PR_EXTRA_PICKUP) {
            extraPickupMap.put(quoteLine.SBQQ__RequiredBy__c, quoteLine);
        }
    }

    /**
     * @description Check if case is not a new service case
     * @param caseRecordType Case record type name
     * @return True if not new service case
     */
    public Boolean isExistingServiceCase(String caseRecordType) {
        return caseRecordType != Constant_Util.New_Service_Case;
    }

    /**
     * @description Apply baseline updates for quote line with no asset
     * Replaces logic from createDelivery() lines 3077-3098
     * @param quoteLine Quote line to update
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     * @return Updated quote line
     */
    public SBQQ__QuoteLine__c applyNewServiceUpdates(
        SBQQ__QuoteLine__c quoteLine,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLine == null) {
            return quoteLine;
        }

        // Skip waste category and waste stream
        if (quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_CATEGORY
            || quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_STREAM) {
            return quoteLine;
        }

        // Update dates
        dateManager.updateDatesForNewService(quoteLine, serviceDate, serviceEndDate);

        // Set default values (SDT-33285)
        QuoteLineServices.setDefaultValuesForQuoteLines(
            quoteLine,
            quoteLine.SBQQ__Quote__r.Name
        );

        return quoteLine;
    }

    /**
     * @description Update all quote lines when case is new service
     * Replaces logic from createDelivery() lines 3139-3149
     * @param quoteLines List of quote lines
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     * @return Updated quote lines
     */
    public List<SBQQ__QuoteLine__c> applyNewServiceCaseUpdates(
        List<SBQQ__QuoteLine__c> quoteLines,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLines == null || quoteLines.isEmpty()) {
            return quoteLines;
        }

        dateManager.updateDatesForAllLines(quoteLines, serviceDate, serviceEndDate);
        return quoteLines;
    }

    /**
     * @description Get extra pickup lines that need start date updates
     * Replaces QuoteProcurementController.getExtraPickupLineForStartDateUpdate() lines 5635-5673
     * @param bundlewisePickupQuoteLinesMap Map of pickup lines by bundle ID
     * @param bundlewiseExtraPickupQuoteLinesMap Map of extra pickup lines by bundle ID
     * @param updateFromIntakeScreen Whether update is from intake screen
     * @return List of extra pickup quote lines to update
     * @story SDT-32782
     */
    public List<SBQQ__QuoteLine__c> getExtraPickupLineForStartDateUpdate(
        Map<Id, SBQQ__QuoteLine__c> bundlewisePickupQuoteLinesMap,
        Map<Id, SBQQ__QuoteLine__c> bundlewiseExtraPickupQuoteLinesMap,
        Boolean updateFromIntakeScreen
    ) {
        List<SBQQ__QuoteLine__c> extraPickupQuoteLineListForUpdate = new List<SBQQ__QuoteLine__c>();

        if (bundlewiseExtraPickupQuoteLinesMap == null || bundlewiseExtraPickupQuoteLinesMap.isEmpty()) {
            return extraPickupQuoteLineListForUpdate;
        }

        if (bundlewisePickupQuoteLinesMap == null || bundlewisePickupQuoteLinesMap.isEmpty()) {
            return extraPickupQuoteLineListForUpdate;
        }

        for (Id parentQuoteLineId : bundlewiseExtraPickupQuoteLinesMap.keySet()) {
            SBQQ__QuoteLine__c extraPickupQuoteLine = bundlewiseExtraPickupQuoteLinesMap.get(parentQuoteLineId);

            // Check if Pickup exists for the Extra Pickup for the same Bundle
            if (bundlewisePickupQuoteLinesMap.containsKey(parentQuoteLineId)) {
                Date pickupLineStartDate = bundlewisePickupQuoteLinesMap.get(parentQuoteLineId).SBQQ__StartDate__c;
                Date extraPickupLineStartDate = extraPickupQuoteLine.SBQQ__StartDate__c;

                // Check if Extra Pickup lines need to be updated
                if (extraPickupLineStartDate != pickupLineStartDate && pickupLineStartDate != null) {
                    SBQQ__QuoteLine__c extraPickupLineForUpdate = bundlewiseExtraPickupQuoteLinesMap.get(parentQuoteLineId);
                    extraPickupLineForUpdate.SBQQ__StartDate__c = pickupLineStartDate;
                    extraPickupQuoteLineListForUpdate.add(extraPickupLineForUpdate);
                }
            }
        }

        return extraPickupQuoteLineListForUpdate;
    }
}
