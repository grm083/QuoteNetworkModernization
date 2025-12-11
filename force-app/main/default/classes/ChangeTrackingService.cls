/**
 * @description Service for tracking changes between Assets and Quote Lines
 * Extracts change tracking logic from QuoteTriggerHelper
 * Used for amendment quotes to identify what changed
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7A
 */
public class ChangeTrackingService {

    private static String UNKNOWN = 'UNK';
    private static String SCHEDULED = 'SCH';
    private static String SCHEDULED_ON_CALL = 'SOC';

    /**
     * @description Update Type of Change field on quote lines when quote status changes
     * Replaces QuoteTriggerHelper.updateTypeOfChangeFieldOnQuoteLines() lines 527-542
     * @param oldMap Old quote map
     * @param newMap New quote map
     */
    public void updateTypeOfChangeFieldOnQuoteLines(
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        Set<Id> quoteStatusUpdated = new Set<Id>();

        for (Id quoteId : oldMap.keySet()) {
            SBQQ__Quote__c oldQuoteRecord = oldMap.get(quoteId);
            SBQQ__Quote__c newQuoteRecord = newMap.get(quoteId);

            if ((newQuoteRecord.SBQQ__Status__c == Constant_Util.QUOTE_APPROVED ||
                 newQuoteRecord.SBQQ__Status__c == Constant_Util.QUOTE_PRODUCT_CONFIGURED) &&
                oldQuoteRecord.SBQQ__Status__c != newQuoteRecord.SBQQ__Status__c) {
                quoteStatusUpdated.add(quoteId);
            }
        }

        if (!quoteStatusUpdated.isEmpty()) {
            compareAndUpdateTypeOfChangeFieldOnQuoteLine(quoteStatusUpdated);
        }
    }

    /**
     * @description Compare assets with quote lines and update Type of Change field
     * Replaces QuoteTriggerHelper.compareAndUpdateTypeOfChangeFieldOnQuoteLine() lines 546-680
     * @param quotesUpdated Set of quote IDs that were updated
     */
    public void compareAndUpdateTypeOfChangeFieldOnQuoteLine(Set<Id> quotesUpdated) {
        if (quotesUpdated == null || quotesUpdated.isEmpty()) {
            return;
        }

        try {
            // Get picklist values for comparison
            List<Schema.PicklistEntry> occurrenceTypeEntries =
                Schema.SObjectType.SBQQ__QuoteLine__c.fields.Occurrence_Type__c.getPicklistValues();
            List<Schema.PicklistEntry> sCodeEntries =
                Schema.SObjectType.SBQQ__QuoteLine__c.fields.sCode__c.getPicklistValues();
            List<Schema.PicklistEntry> ownershipEntries =
                Schema.SObjectType.SBQQ__QuoteLine__c.fields.Ownership__c.getPicklistValues();

            List<SBQQ__QuoteLine__c> quoteLinesTobeUpdated = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> quoteLines = QuoteLineSelector.getQuoteLinesToUpdateTypeOfChangeField(quotesUpdated);

            // Compare Quote line field with Asset field and update the Type Of Change field on Quote Line
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                Set<String> changeTypes = detectChanges(
                    quoteLine,
                    occurrenceTypeEntries,
                    sCodeEntries,
                    ownershipEntries
                );

                if (!changeTypes.isEmpty()) {
                    String changeTypeValue = QuoteLineTriggerHelper.setToStr(changeTypes, Constant_Util.SEMI_COLON);
                    quoteLine.Type_of_Change__c = changeTypeValue;
                }
                quoteLinesTobeUpdated.add(quoteLine);
            }

            if (!quoteLinesTobeUpdated.isEmpty()) {
                update quoteLinesTobeUpdated;
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ChangeTrackingService', 'compareAndUpdateTypeOfChangeFieldOnQuoteLine');
        }
    }

    /**
     * @description Detect all changes between quote line and asset
     * @param quoteLine Quote line with asset relationship
     * @param occurrenceTypeEntries Picklist entries for Occurrence_Type__c
     * @param sCodeEntries Picklist entries for sCode__c
     * @param ownershipEntries Picklist entries for Ownership__c
     * @return Set of change type strings
     */
    private Set<String> detectChanges(
        SBQQ__QuoteLine__c quoteLine,
        List<Schema.PicklistEntry> occurrenceTypeEntries,
        List<Schema.PicklistEntry> sCodeEntries,
        List<Schema.PicklistEntry> ownershipEntries
    ) {
        Set<String> changeTypes = new Set<String>();

        if (quoteLine.AssetId__c == null) {
            return changeTypes;
        }

        // Position Change
        if (quoteLine.LocationPositionName__c != quoteLine.AssetId__r.Container_Position__c) {
            changeTypes.add('Position Change');
        }

        // Billing Administration Change
        if (quoteLine.ClientGLAccount__c != quoteLine.AssetId__r.GL_Code__c ||
            quoteLine.ClientCostCenter__c != quoteLine.AssetId__r.Cost_Center__c ||
            quoteLine.CompanyCategoryCode__c != quoteLine.AssetId__r.Category__c) {
            changeTypes.add('Billing Administration Change');
        }

        // Start Date Change
        if (quoteLine.SBQQ__StartDate__c != quoteLine.AssetId__r.Start_Date__c) {
            changeTypes.add('Start Date Change');
        }

        // End Date Change
        if (quoteLine.SBQQ__EndDate__c != quoteLine.AssetId__r.End_Date__c) {
            changeTypes.add('End Date Change');
        }

        // Market Restriction Change
        String assetSCode = UTIL_Picklist.getPicklistEntryByLabel(sCodeEntries, quoteLine.AssetId__r.Sensitivity_Code__c);
        if (quoteLine.sCode__c != assetSCode) {
            changeTypes.add('Market Restriction Change');
        }

        // Equipment Change
        if ((quoteLine.Equipment_Style__c != null && quoteLine.Equipment_Style__c != '') ||
            (quoteLine.Service_Style__c != null && quoteLine.Service_Style__c != '')) {
            changeTypes.add('Equipment Change');
        }

        // Ownership Change
        String assetOwnership = UTIL_Picklist.getPicklistEntryByLabel(ownershipEntries, quoteLine.AssetId__r.Equipment_Owner__c);
        if (quoteLine.Ownership__c != assetOwnership) {
            changeTypes.add('Ownership Change');
        }

        // MAS Change
        if (quoteLine.MASLibrary__c != quoteLine.AssetId__r.MAS_Library__c ||
            quoteLine.MASCompany__c != quoteLine.AssetId__r.MAS_Company_Code__c ||
            quoteLine.MASCustomerUniqueId__c != quoteLine.AssetId__r.MAS_Customer_Unique_Id__c ||
            quoteLine.MASServiceLine__c != quoteLine.AssetId__r.MAS_Line_Number__c ||
            String.valueOf(quoteLine.MASAccount__c) != quoteLine.AssetId__r.MAS_Account_Number__c) {
            changeTypes.add('MAS Change');
        }

        // Quantity Changes
        if (Integer.valueOf(quoteLine.SBQQ__Quantity__c) > Integer.valueOf(quoteLine.AssetId__r.Quantity__c)) {
            changeTypes.add('Quantity Increase');
        }
        if (Integer.valueOf(quoteLine.SBQQ__Quantity__c) < Integer.valueOf(quoteLine.AssetId__r.Quantity__c)) {
            changeTypes.add('Quantity Decrease');
        }

        // Size Changes (SDT-42068, SDT-42390)
        if (quoteLine.Equipment_Size__c != null && quoteLine.Equipment_Size__c != '' &&
            quoteLine.AssetId__r.Equipment_Size__c != null && quoteLine.AssetId__r.Equipment_Size__c != '' &&
            !UNKNOWN.equalsIgnoreCase(quoteLine.Equipment_Size__c)) {
            try {
                Decimal quoteLineSize = Decimal.valueOf(quoteLine.Equipment_Size__c.substringAfter('-'));
                Decimal assetSize = Decimal.valueOf(quoteLine.AssetId__r.Equipment_Size__c.substringBefore(' '));

                if (quoteLineSize > assetSize) {
                    changeTypes.add('Size Increase');
                }
                if (quoteLineSize < assetSize) {
                    changeTypes.add('Size Decrease');
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'Could not parse equipment size: ' + ex.getMessage());
            }
        }

        // Schedule Type Change
        String assetOccurrenceType = UTIL_Picklist.getPicklistEntryByLabel(
            occurrenceTypeEntries,
            quoteLine.AssetId__r.Occurrence_Type__c
        );
        if (quoteLine.Occurrence_Type__c != assetOccurrenceType) {
            changeTypes.add('Change Schedule Type');
        } else {
            // Check frequency changes if schedule type is same
            if ((quoteLine.Occurrence_Type__c == SCHEDULED_ON_CALL && assetOccurrenceType == SCHEDULED_ON_CALL) ||
                (quoteLine.Occurrence_Type__c == SCHEDULED && assetOccurrenceType == SCHEDULED)) {
                String frequencyChange = calculateFrequencyChange(quoteLine);
                if (frequencyChange != '') {
                    changeTypes.add(frequencyChange);
                }
            }
        }

        // Vendor Change
        if (quoteLine.Vendor__c != quoteLine.AssetId__r.Supplier__c) {
            changeTypes.add('Change Vendor');
        }

        // Price Changes
        if (quoteLine.SBQQ__ListPrice__c > quoteLine.AssetId__r.SBQQ__RegularPrice__c) {
            changeTypes.add('Price Increase');
        }
        if (quoteLine.SBQQ__ListPrice__c < quoteLine.AssetId__r.SBQQ__RegularPrice__c) {
            changeTypes.add('Price Decrease');
        }

        // Cost Changes
        if (quoteLine.SBQQ__UnitCost__c > quoteLine.AssetId__r.SBQQ__OriginalUnitCost__c) {
            changeTypes.add('Cost Increase');
        }
        if (quoteLine.SBQQ__UnitCost__c < quoteLine.AssetId__r.SBQQ__OriginalUnitCost__c) {
            changeTypes.add('Cost Decrease');
        }

        return changeTypes;
    }

    /**
     * @description Calculate frequency change between quote line and asset
     * Replaces QuoteTriggerHelper.calculateFrequencyChange() lines 684-701
     * @param quoteLine Quote line with asset relationship
     * @return Frequency change string or empty string
     */
    public String calculateFrequencyChange(SBQQ__QuoteLine__c quoteLine) {
        String returnValue = '';

        try {
            // Calculate Quote Line's frequency
            Decimal quoteLineFrequency = calculateQuoteLineFrequency(quoteLine);
            // Calculate Asset's frequency
            Decimal assetFrequency = calculateAssetFrequency(quoteLine);

            if (quoteLineFrequency > assetFrequency) {
                returnValue = 'Frequency Increase';
            }
            if (quoteLineFrequency < assetFrequency) {
                returnValue = 'Frequency Decrease';
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Error calculating frequency change: ' + ex.getMessage());
        }

        return returnValue;
    }

    /**
     * @description Calculate weekly frequency for a quote line
     * Replaces QuoteTriggerHelper.calculateQuoteLineFrequency() lines 705-731
     * @param quoteLine Quote line with schedule frequency fields
     * @return Weekly frequency as decimal
     */
    public Decimal calculateQuoteLineFrequency(SBQQ__QuoteLine__c quoteLine) {
        Decimal quoteLineFrequency = 0;

        try {
            // Check for valid frequency interval (SDT-42068)
            if (quoteLine.Frequency_Interval__c != null &&
                quoteLine.Frequency_Interval__c != '' &&
                Integer.valueOf(quoteLine.Frequency_Interval__c) != 0) {

                // Calculate Quote Line's weekly frequency
                if (quoteLine.Schedule_Frequency__c == 'D') {
                    // Daily: 7 days per week / interval
                    quoteLineFrequency = 7 / Decimal.valueOf(quoteLine.Frequency_Interval__c);
                } else if (quoteLine.Schedule_Frequency__c == 'W') {
                    // Weekly: Count service days / interval
                    if (quoteLine.Service_Days__c != null) {
                        List<String> serviceDaysList = quoteLine.Service_Days__c.split(';');
                        quoteLineFrequency = serviceDaysList.size() / Decimal.valueOf(quoteLine.Frequency_Interval__c);
                    }
                } else if (quoteLine.Schedule_Frequency__c == 'M') {
                    // Monthly: 1 / (4 weeks * interval)
                    quoteLineFrequency = 1 / (4 * Decimal.valueOf(quoteLine.Frequency_Interval__c));
                } else if (quoteLine.Schedule_Frequency__c == 'Y') {
                    // Yearly: 1 / (52 weeks * interval)
                    quoteLineFrequency = 1 / (52 * Decimal.valueOf(quoteLine.Frequency_Interval__c));
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Error calculating quote line frequency: ' + ex.getMessage());
        }

        return quoteLineFrequency;
    }

    /**
     * @description Calculate weekly frequency for an asset
     * Replaces QuoteTriggerHelper.calculateAssetFrequency() lines 735-792
     * @param quoteLine Quote line with asset relationship containing frequency fields
     * @return Weekly frequency as decimal
     */
    public Decimal calculateAssetFrequency(SBQQ__QuoteLine__c quoteLine) {
        Decimal assetFrequency = 0;

        try {
            // Check for valid occurrence (SDT-42068)
            if (quoteLine.AssetId__r.Occurs__c != null &&
                quoteLine.AssetId__r.Occurs__c != '' &&
                Integer.valueOf(quoteLine.AssetId__r.Occurs__c) != 0) {

                // Calculate Asset's weekly frequency
                if (quoteLine.AssetId__r.Frequency__c == 'Daily') {
                    // Daily: 7 days per week / occurs
                    assetFrequency = 7 / Decimal.valueOf(quoteLine.AssetId__r.Occurs__c);
                } else if (quoteLine.AssetId__r.Frequency__c == 'Weekly') {
                    // Weekly: Count selected days / occurs
                    Integer dayCount = 0;
                    if (quoteLine.AssetId__r.Monday__c) dayCount++;
                    if (quoteLine.AssetId__r.Tuesday__c) dayCount++;
                    if (quoteLine.AssetId__r.Wednesday__c) dayCount++;
                    if (quoteLine.AssetId__r.Thursday__c) dayCount++;
                    if (quoteLine.AssetId__r.Friday__c) dayCount++;
                    if (quoteLine.AssetId__r.Saturday__c) dayCount++;
                    if (quoteLine.AssetId__r.Sunday__c) dayCount++;

                    if (dayCount > 0) {
                        assetFrequency = dayCount / Decimal.valueOf(quoteLine.AssetId__r.Occurs__c);
                    }
                } else if (quoteLine.AssetId__r.Frequency__c == 'Monthly') {
                    // Monthly: 1 / (4 weeks * occurs)
                    assetFrequency = 1 / (4 * Decimal.valueOf(quoteLine.AssetId__r.Occurs__c));
                } else if (quoteLine.AssetId__r.Frequency__c == 'Yearly') {
                    // Yearly: 1 / (52 weeks * occurs)
                    assetFrequency = 1 / (52 * Decimal.valueOf(quoteLine.AssetId__r.Occurs__c));
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Error calculating asset frequency: ' + ex.getMessage());
        }

        return assetFrequency;
    }
}
