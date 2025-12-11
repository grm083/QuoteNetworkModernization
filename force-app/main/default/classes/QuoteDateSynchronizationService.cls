/**
 * @description Service for synchronizing quote and case dates based on quote lines
 * Extracts date synchronization logic from QuoteLineTriggerHelper
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7C
 */
public class QuoteDateSynchronizationService {

    /**
     * @description Update quote start dates and case service dates based on quote lines
     * Replaces QuoteLineTriggerHelper.updateQuotedate() lines 678-876
     * SDT-29106: Update logic for new service cases and non-new service cases
     * SDT-33101: Map handling improvements
     * @param quoteLineList List of quote lines to process
     * @return Map of quote IDs to quotes
     */
    public Map<Id, SBQQ__Quote__c> updateQuoteDates(List<SBQQ__QuoteLine__c> quoteLineList) {
        if (quoteLineList == null || quoteLineList.isEmpty()) {
            return new Map<Id, SBQQ__Quote__c>();
        }

        try {
            List<SObject> soList = new List<SObject>();
            Set<Id> quotelist = new Set<Id>();
            Map<Id, SBQQ__Quote__c> mapOfquote = new Map<Id, SBQQ__Quote__c>();

            // Creating quote list from updated quote lines
            for (SBQQ__QuoteLine__c qline : quoteLineList) {
                quotelist.add(qline.SBQQ__Quote__c);
            }

            // Get quotes and cases (removed new service case restriction for SDT-29106)
            List<SBQQ__Quote__c> qList = [
                SELECT Id, SBQQ__StartDate__c, SBQQ__Opportunity2__r.Case__c,
                       SBQQ__Opportunity2__r.Case__r.Tracking_Number__c,
                       SBQQ__Opportunity2__r.Case__r.Service_Date__c,
                       SBQQ__Opportunity2__r.Case__r.RecordType.Name,
                       SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.case__r.CaseNumber,
                       SBQQ__Opportunity2__r.case__r.Case_Type__c, SBQQ__Status__c,
                       SBQQ__Opportunity2__r.case__r.account.Primary_Segment__c,
                       SBQQ__Opportunity2__r.case__r.Case_Sub_Type__c,
                       SBQQ__Opportunity2__r.case__r.Case_Reason__c, RecordType.Name,
                       SBQQ__Opportunity2__r.Case__r.Account.Vendor_ID__c,
                       SBQQ__Opportunity2__r.Case__r.Id,
                       SBQQ__Opportunity2__r.Case__r.Supplier__r.Name,
                       SBQQ__Opportunity2__r.Case__r.Supplier__r.Vendor_ID__c,
                       SBQQ__Opportunity2__r.Case__r.Supplier__r.Parent.Vendor_ID__c,
                       SBQQ__Opportunity2__r.Case__r.Supplier__r.Parent.Name,
                       SBQQ__ShippingName__c,
                       SBQQ__Opportunity2__r.Case__r.Last_Agent_ID__c,
                       SBQQ__Opportunity2__r.Case__r.Asset.Project_Code__c,
                       SBQQ__Opportunity2__r.Case__r.Asset.Active__c,
                       SBQQ__Opportunity2__r.Case__r.SLA_Service_Date_Time__c,
                       Next_Action_Due_Date__c, LastModifiedBy.UserName,
                       SBQQ__Opportunity2__r.case__r.Location__r.tz__Timezone__c,
                       LastModifiedById
                FROM SBQQ__Quote__c
                WHERE Id IN :quotelist
            ];

            Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>(qList);

            if (!qList.isEmpty()) {
                // Creating quoteId and Quote Map
                for (SBQQ__Quote__c q : qList) {
                    mapOfquote.put(q.Id, q);
                }

                List<SBQQ__Quote__c> tobeUpdatedQuotes = new List<SBQQ__Quote__c>();
                Map<Id, List<SBQQ__QuoteLine__c>> quoteQuotelineMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
                Map<Id, List<Id>> parentQuoteandQuotelineMap = new Map<Id, List<Id>>();

                // Get parent quote lines which are in draft quote status
                List<SBQQ__QuoteLine__c> quotelines = [
                    SELECT Id, SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__StartDate__c,
                           SBQQ__RequiredBy__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c IN :quotelist
                    AND SBQQ__Quote__r.SBQQ__Status__c != :Constant_Util.QUOTE_APPROVED
                    AND SBQQ__Quote__r.SBQQ__Status__c != :Constant_Util.QUOTE_DECLINED
                    AND SBQQ__Quote__r.SBQQ__StartDate__c != null
                    AND SBQQ__Product__r.Family != :Constant_Util.WASTE_STREAM
                    AND SBQQ__Product__r.Family != :Constant_Util.WASTE_CATEGORY
                    ORDER BY SBQQ__Number__c
                ];

                // Added date null check and list empty check for SDT-29106
                if (!quotelines.isEmpty()) {
                    // Loop through the Quote line to fill the quoteQuotelineMap
                    for (SBQQ__QuoteLine__c ql : quotelines) {
                        if (quoteQuotelineMap.containsKey(ql.SBQQ__Quote__c)) {
                            List<SBQQ__QuoteLine__c> tempQL = quoteQuotelineMap.get(ql.SBQQ__Quote__c);
                            tempQL.add(ql);
                            quoteQuotelineMap.put(ql.SBQQ__Quote__c, tempQL);

                            // Changes for SDT-29106: Creating Map of Quote and Parent Lines
                            if (ql.SBQQ__RequiredBy__c == null) {
                                // SDT 33101: Improved map handling
                                if (parentQuoteandQuotelineMap != null &&
                                    parentQuoteandQuotelineMap.size() > 0) {
                                    List<Id> tempQLId = parentQuoteandQuotelineMap.get(ql.SBQQ__Quote__c);
                                    tempQLId.add(ql.Id);
                                    parentQuoteandQuotelineMap.put(ql.SBQQ__Quote__c, tempQLId);
                                } else {
                                    parentQuoteandQuotelineMap.put(ql.SBQQ__Quote__c, new List<Id>{ql.Id});
                                }
                            }
                        } else {
                            quoteQuotelineMap.put(ql.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>{ql});

                            // Changes for SDT-29106: Creating Map of Quote and Parent Lines
                            if (ql.SBQQ__RequiredBy__c == null) {
                                parentQuoteandQuotelineMap.put(ql.SBQQ__Quote__c, new List<Id>{ql.Id});
                            }
                        }
                    }

                    // Changes for SDT-29106
                    Boolean isDateChanged = false;

                    // Get quote ID to service date map from CaseSLAEntitlementUTIL
                    Map<Id, Date> quoteIdServiceDateMap =
                        CaseSLAEntitlementUTIL.getQuoteIdServiceDateMap(quoteQuotelineMap.keySet());

                    // Loop through quoteQuotelineMap key which is quote
                    for (Id key : quoteQuotelineMap.keySet()) {
                        // Creating probable quote update object
                        SBQQ__Quote__c quote = new SBQQ__Quote__c();
                        quote.Id = key;
                        SBQQ__Quote__c qvalue = mapOfquote.get(key);
                        Date updateDate;
                        Integer startDateDifference;

                        if (qvalue != null && qvalue.SBQQ__StartDate__c != null) {
                            updateDate = qvalue.SBQQ__StartDate__c;
                        }

                        // Loop through quote lines and determine earliest start date
                        for (SBQQ__QuoteLine__c ql : quoteQuotelineMap.get(key)) {
                            // Changes for SDT-29106: Different logic for new service cases
                            if (qvalue.SBQQ__Opportunity2__r.Case__r.RecordType.Name ==
                                Constant_Util.New_Service_Case) {
                                if (parentQuoteandQuotelineMap.get(key).size() == 1 &&
                                    ql.SBQQ__StartDate__c != null) {
                                    updateDate = ql.SBQQ__StartDate__c;
                                    isDateChanged = true;
                                } else {
                                    if (ql.SBQQ__StartDate__c != null &&
                                        ql.SBQQ__StartDate__c < updateDate) {
                                        updateDate = ql.SBQQ__StartDate__c;
                                        isDateChanged = true;
                                    }
                                }
                            } else {
                                // Changes for SDT-29106: Non-new service cases
                                if (ql.SBQQ__StartDate__c != null) {
                                    Integer numberDaysDue = Date.today().daysBetween(ql.SBQQ__StartDate__c);
                                    if (ql.SBQQ__StartDate__c >= Date.today() && numberDaysDue >= 0) {
                                        if (startDateDifference == null) {
                                            startDateDifference = numberDaysDue;
                                            updateDate = ql.SBQQ__StartDate__c;
                                            isDateChanged = true;
                                        } else if (startDateDifference > numberDaysDue) {
                                            startDateDifference = numberDaysDue;
                                            updateDate = ql.SBQQ__StartDate__c;
                                            isDateChanged = true;
                                        }
                                    }
                                }
                            }
                        }

                        // Changes for SDT-29106: Update quote if date changed
                        if (isDateChanged) {
                            quote.SBQQ__StartDate__c = updateDate;
                            soList.add(quote);
                        }

                        // Creating probable case update object
                        Case cs = new Case();

                        // If case doesn't have tracking then will update the case
                        // Changes for SDT-29106
                        if (qvalue != null &&
                            qvalue.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c == null &&
                            isDateChanged) {
                            cs.Id = qvalue.SBQQ__Opportunity2__r.Case__c;
                            cs.Service_Date__c = updateDate;

                            if (quoteIdServiceDateMap.containsKey(qvalue.Id) &&
                                quoteIdServiceDateMap.get(qvalue.Id) != null) {
                                if (cs.Service_Date__c > quoteIdServiceDateMap.get(qvalue.Id)) {
                                    cs.Service_Date__c = quoteIdServiceDateMap.get(qvalue.Id);
                                }
                            }
                            soList.add(cs);
                        }
                    }

                    // Check if sObject list is available and update
                    if (!soList.isEmpty()) {
                        SBQQ.TriggerControl.disable();
                        try {
                            update soList;
                        } catch (Exception ex) {
                            System.debug(LoggingLevel.ERROR, 'Exception updating dates: ' + ex.getMessage());
                            UTIL_LoggingService.logException(ex, 'QuoteDateSynchronizationService', 'updateQuoteDates');
                        } finally {
                            SBQQ.TriggerControl.enable();
                        }
                    }
                }
            }

            return quoteMap;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteDateSynchronizationService', 'updateQuoteDates');
            throw ex;
        }
    }
}
