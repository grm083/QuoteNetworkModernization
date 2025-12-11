/**
 * @description Service for managing product add-ons (e.g., Extra Pickup)
 * Extracts product add-on logic from QuoteLineTriggerHelper
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7B
 */
public class ProductAddOnService {

    private static final String EXTRA_PICKUP_PRODUCT = 'Extra Pickup';
    private static final String PICKUP_PRODUCT = 'Pickup';
    private static final String SCHEDULED_TYPE = 'SCH';

    /**
     * @description Remove extra pickup flag from pickup quote lines
     * Replaces QuoteLineTriggerHelper.removeExtraPickupQuoteLine() lines 29-53
     * @param quoteLineNewList List of new quote lines being deleted
     */
    public void removeExtraPickupQuoteLine(List<SBQQ__QuoteLine__c> quoteLineNewList) {
        if (quoteLineNewList == null || quoteLineNewList.isEmpty()) {
            return;
        }

        try {
            Set<Id> requiredByIds = new Set<Id>();

            // Find parent quote lines for extra pickup products being removed
            for (SBQQ__QuoteLine__c quoteLine : quoteLineNewList) {
                if (quoteLine.SBQQ__RequiredBy__c != null &&
                    quoteLine.SBQQ__ProductName__c == EXTRA_PICKUP_PRODUCT) {
                    requiredByIds.add(quoteLine.SBQQ__RequiredBy__c);
                }
            }

            System.debug('RequiredBy IDs for extra pickup removal: ' + requiredByIds);

            if (!requiredByIds.isEmpty()) {
                List<SBQQ__QuoteLine__c> updateQuoteLine = new List<SBQQ__QuoteLine__c>();

                // Find pickup quote lines that need their extra pickup flag cleared
                for (SBQQ__QuoteLine__c quotePickupLine : [
                    SELECT Id, IsExtrapickup__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__ProductName__c = :PICKUP_PRODUCT
                    AND SBQQ__RequiredBy__c IN :requiredByIds
                ]) {
                    quotePickupLine.IsExtrapickup__c = false;
                    updateQuoteLine.add(quotePickupLine);
                }

                System.debug('Pickup lines to update: ' + updateQuoteLine);

                if (!updateQuoteLine.isEmpty()) {
                    update updateQuoteLine;
                }
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ProductAddOnService', 'removeExtraPickupQuoteLine');
            throw ex;
        }
    }

    /**
     * @description Mark pickup quote lines as having extra pickup
     * Replaces QuoteLineTriggerHelper.addExtraPickupQuoteLine() lines 140-165
     * Developer: Arvind Kumar
     * Date: 03/June/2021
     * @param quoteLineNewList List of new quote lines being created
     */
    public void addExtraPickupQuoteLine(List<SBQQ__QuoteLine__c> quoteLineNewList) {
        if (quoteLineNewList == null || quoteLineNewList.isEmpty()) {
            return;
        }

        try {
            Set<Id> requiredByIds = new Set<Id>();

            // Find parent quote lines for extra pickup products being added
            for (SBQQ__QuoteLine__c quoteLine : quoteLineNewList) {
                if (quoteLine.SBQQ__RequiredBy__c != null &&
                    quoteLine.SBQQ__ProductName__c == EXTRA_PICKUP_PRODUCT) {
                    requiredByIds.add(quoteLine.SBQQ__RequiredBy__c);
                }
            }

            System.debug('RequiredBy IDs for extra pickup addition: ' + requiredByIds);

            if (!requiredByIds.isEmpty()) {
                List<SBQQ__QuoteLine__c> updateQuoteLine = new List<SBQQ__QuoteLine__c>();

                // Find scheduled pickup quote lines that need extra pickup flag set
                for (SBQQ__QuoteLine__c quotePickupLine : [
                    SELECT Id, IsExtrapickup__c, Occurrence_Type__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__ProductName__c = :PICKUP_PRODUCT
                    AND SBQQ__RequiredBy__c IN :requiredByIds
                    AND Occurrence_Type__c = :SCHEDULED_TYPE
                ]) {
                    quotePickupLine.IsExtrapickup__c = true;
                    updateQuoteLine.add(quotePickupLine);
                }

                System.debug('Pickup lines to update: ' + updateQuoteLine);

                if (!updateQuoteLine.isEmpty()) {
                    update updateQuoteLine;
                }
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ProductAddOnService', 'addExtraPickupQuoteLine');
            throw ex;
        }
    }

    /**
     * @description Check if a quote line is an extra pickup product
     * @param quoteLine Quote line to check
     * @return True if extra pickup, false otherwise
     */
    public Boolean isExtraPickupProduct(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null) {
            return false;
        }
        return quoteLine.SBQQ__ProductName__c == EXTRA_PICKUP_PRODUCT;
    }

    /**
     * @description Check if a quote line is a pickup product
     * @param quoteLine Quote line to check
     * @return True if pickup, false otherwise
     */
    public Boolean isPickupProduct(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null) {
            return false;
        }
        return quoteLine.SBQQ__ProductName__c == PICKUP_PRODUCT;
    }

    /**
     * @description Check if a quote line is scheduled type
     * @param quoteLine Quote line to check
     * @return True if scheduled, false otherwise
     */
    public Boolean isScheduledType(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null) {
            return false;
        }
        return quoteLine.Occurrence_Type__c == SCHEDULED_TYPE;
    }
}
