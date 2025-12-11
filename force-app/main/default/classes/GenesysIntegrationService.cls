/**
 * @description Service for Genesys integration and routing
 * Extracts Genesys integration logic from QuoteTriggerHelper
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7B
 */
public class GenesysIntegrationService {

    private static Boolean flag = false;

    // Flag to control async vs sync Genesys creation (SDT-23088)
    public static Boolean runAsyncGenesysCreation = true;

    /**
     * @description Update Genesys required flag on quotes
     * Replaces QuoteTriggerHelper.updateGenesysRequired() lines 74-93
     * SDT-23339: Update GR Service Flag of Quote with respect to Assigned To User
     * @param quoteNewList New quote list
     * @param oldMap Old quote map
     * @param newMap New quote map
     */
    public void updateGenesysRequired(
        List<SBQQ__Quote__c> quoteNewList,
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        for (SBQQ__Quote__c quote : quoteNewList) {
            Boolean isStartDateWithin30Days = checkQuoteStartDateWithin30Days(quote.SBQQ__StartDate__c);

            if (quote.Genesys_Enabled__c &&
                quote.Next_Action_Start_Date__c < System.now() &&
                (!quote.Genesys_Record_Created__c || flag) &&
                quote.Genesys_Record_Created__c == oldMap.get(quote.Id).Genesys_Record_Created__c &&
                !isStartDateWithin30Days) {
                quote.Is_Genesys_Required__c = true;
            }
        }
    }

    /**
     * @description Check if quotes are eligible for Genesys and create records
     * Replaces QuoteTriggerHelper.isEligibleForGenesys() lines 96-115
     * @param quoteNewList New quote list
     * @param oldMap Old quote map
     * @param newMap New quote map
     */
    public void isEligibleForGenesys(
        List<SBQQ__Quote__c> quoteNewList,
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        List<Id> quoteListId = new List<Id>();

        for (SBQQ__Quote__c quote : newMap.values()) {
            Boolean isStartDateWithin30Days = checkQuoteStartDateWithin30Days(quote.SBQQ__StartDate__c);

            if (quote.Genesys_Enabled__c &&
                quote.Next_Action_Start_Date__c < System.now() &&
                (!quote.Genesys_Record_Created__c || flag) &&
                quote.Genesys_Record_Created__c == oldMap.get(quote.Id).Genesys_Record_Created__c &&
                isStartDateWithin30Days) {
                quoteListId.add(quote.Id);
                quoteList.add(quote);
            }
        }

        if (!quoteList.isEmpty()) {
            createGenesysForQuote(quoteList, quoteListId, Constant_Util.STATUS_NEW, null);
        }
    }

    /**
     * @description Create Genesys routing records for quotes
     * Replaces QuoteTriggerHelper.createGenesysForQuote() lines 117-242
     * @param quoteList List of quotes to create Genesys records for
     * @param quoteListId List of quote IDs
     * @param action Action type (new/cancel)
     * @param newMessage Optional email message for email-to-case routing
     */
    public void createGenesysForQuote(
        List<SBQQ__Quote__c> quoteList,
        List<Id> quoteListId,
        String action,
        EmailMessage newMessage
    ) {
        List<Genesys_Routing__c> genList = new List<Genesys_Routing__c>();
        Map<Id, String> durationMap = new Map<Id, String>();
        Map<String, String> mapOfoldStatus = new Map<String, String>();
        Boolean orgWideEmailFound = false;

        // Map quote statuses for cancellation (SDT-37849)
        mapOfoldStatus.put(Constant_Util.QUOTE_DRAFT, Constant_Util.QUOTE_DRAFT);
        mapOfoldStatus.put(Constant_Util.QUOTE_PRODUCT_CONFIGURED, Constant_Util.QUOTE_DRAFT);
        mapOfoldStatus.put(Constant_Util.QUOTE_COST_CONFIGURED, Constant_Util.QUOTE_PRODUCT_CONFIGURED);
        mapOfoldStatus.put(Constant_Util.QUOTE_PRICE_CONFIGURED, Constant_Util.QUOTE_COST_CONFIGURED);
        mapOfoldStatus.put(Constant_Util.QUOTE_DECLINED, Constant_Util.QUOTE_PRICE_CONFIGURED);

        // Get record type IDs
        Id genesysRoutingRec = Schema.getGlobalDescribe()
            .get(Constant_Util.Genesys_Routing)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get(Constant_Util.OBJECT_TASK)
            .getRecordTypeId();

        Id emailToCaseRec = Schema.getGlobalDescribe()
            .get(Constant_Util.Genesys_Routing)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get(Constant_Util.EMAILTOCASERECORD)
            .getRecordTypeId();

        // Query quotes with all required fields
        List<SBQQ__Quote__c> quoteLst = [
            SELECT Id, LastModifiedBy.UserName, Assigned_To__r.GR_Service_Flag__c,
                   LastModifiedBy.Genesys_Enabled__c, Priority__c, LastModifiedById,
                   SBQQ__Account__r.Parent.Customer_Code__c,
                   SBQQ__Account__r.Location_Code__c,
                   SBQQ__Account__r.tz__Timezone__c,
                   SBQQ__Opportunity2__r.Case__r.CaseNumber,
                   SBQQ__Opportunity2__r.Case__r.Reference_Number__c,
                   GR_Service_Flag__c,
                   SBQQ__Opportunity2__r.Case__r.Case_Type__c,
                   SBQQ__Opportunity2__r.Case__r.Case_Reason__c,
                   SBQQ__Opportunity2__r.Case__r.createdby.userRole.name,
                   SBQQ__Account__r.Parent.Primary_Segment__c,
                   SBQQ__Opportunity2__r.Case__r.Asset.Project_Code__c,
                   SBQQ__Status__c, Next_Action_Due_Date__c, Project__c,
                   Project_Services_Request__c, createdby.userRole.name
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteList
        ];

        // Check for org-wide email address (SDT-37849)
        if (newMessage != null) {
            orgWideEmailFound = findOrgWideEmailAddress(newMessage);
        }

        // Get duration for each quote
        for (SBQQ__QuoteLine__c qLine : [
            SELECT Id, toLabel(Duration__c), SBQQ__Quote__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteListId
            AND SBQQ__RequiredBy__c = null
        ]) {
            if (!durationMap.containsKey(qLine.SBQQ__Quote__c)) {
                durationMap.put(qLine.SBQQ__Quote__c, qLine.Duration__c);
            }
        }

        // Get task descriptions from metadata
        Map<String, TaskDesc__mdt> taskDescMap = TaskDesc__mdt.getAll();
        Map<String, TaskDesc__mdt> quoteTaskDescMap = new Map<String, TaskDesc__mdt>();
        Generic_Values__mdt genValue = Generic_Values__mdt.getInstance(Constant_Util.GENESYS_USER);

        for (TaskDesc__mdt taskDesc : taskDescMap.values()) {
            quoteTaskDescMap.put(taskDesc.Quote_Status__c, taskDesc);
        }

        try {
            for (SBQQ__Quote__c quote : quoteLst) {
                Genesys_Routing__c gen = new Genesys_Routing__c();

                // Set last agent ID
                String userName = quote.LastModifiedBy.UserName.substringBefore(Constant_Util.AT_SYMBOL);
                gen.LastAgentId__c = quote.LastModifiedBy.Genesys_Enabled__c ? userName : null;

                // Set media type and record type (SDT-37849)
                gen.MediaType__c = (newMessage != null && !orgWideEmailFound) ?
                    Constant_Util.SFDCEMAILTASK : Constant_Util.SFDCCPQQUOTE;
                gen.RecordTypeId = newMessage != null ? emailToCaseRec : genesysRoutingRec;

                // Set action
                gen.Action__c = action;
                gen.Action_Reason__c = action == Constant_Util.CANCEL ? Constant_Util.TRANSFERRED : null;

                // Set SFDC object reference
                gen.SFDCObjRecordID__c = newMessage != null ? newMessage.Id : quote.Id;
                gen.SFDCObjType__c = newMessage != null ? Constant_Util.EMAILMESSAGE : Constant_Util.QUOTE;

                // Set account and case information
                gen.SFDCAcctID__c = quote.SBQQ__Account__r.Parent.Customer_Code__c;
                gen.SFDCAcctSegment__c = quote.SBQQ__Account__r.Parent.Primary_Segment__c;
                gen.SFDCAcctLocation__c = quote.SBQQ__Account__r.Location_Code__c;
                gen.SFDCAcctLocationTimeZone__c = quote.SBQQ__Account__r.tz__Timezone__c;
                gen.SFDCCaseNumber__c = quote.SBQQ__Opportunity2__r.Case__r.CaseNumber;
                gen.SFDCCaseRefNo__c = quote.SBQQ__Opportunity2__r.Case__r.Reference_Number__c;
                gen.SFDCCaseType__c = quote.SBQQ__Opportunity2__r.Case__r.Case_Type__c;
                gen.SFDCCaseSubCaseType__c = durationMap.get(quote.Id);
                gen.SFDCCaseReason__c = quote.SBQQ__Opportunity2__r.Case__r.Case_Reason__c;
                gen.SFDCServiceFlag__c = quote.Assigned_To__r.GR_Service_Flag__c != null ?
                    quote.Assigned_To__r.GR_Service_Flag__c : Constant_Util.CS;

                // Set task description based on action and status
                if (flag && action == Constant_Util.CANCEL) {
                    String oldStatus = mapOfoldStatus.get(quote.SBQQ__Status__c);
                    if (quoteTaskDescMap.containsKey(oldStatus)) {
                        gen.SFDCTaskDescCode__c = quoteTaskDescMap.get(oldStatus).TaskDescCode__c;
                        gen.SFDCTaskDescription__c = quoteTaskDescMap.get(oldStatus).MasterLabel;
                    }
                } else {
                    // SDT-41190: Special handling for approved status
                    if (quote.SBQQ__Status__c == Constant_Util.QUOTE_APPROVED) {
                        gen.SFDCTaskDescCode__c = Constant_Util.APPROVED;
                        gen.SFDCTaskDescription__c = Constant_Util.APPROVED;
                    } else if (quoteTaskDescMap.containsKey(quote.SBQQ__Status__c)) {
                        gen.SFDCTaskDescCode__c = quoteTaskDescMap.get(quote.SBQQ__Status__c).TaskDescCode__c;
                        gen.SFDCTaskDescription__c = quoteTaskDescMap.get(quote.SBQQ__Status__c).MasterLabel;
                    }
                }

                // Set routing information
                gen.SFDCTaskDueDateTime__c = quote.Next_Action_Due_Date__c;
                gen.SFDCRouteStartTime__c = String.valueOf(System.today()) + Constant_Util.START_TIME_TEXT;
                gen.SFDCRouteEndTime__c = String.valueOf(System.today()) + Constant_Util.END_TIME_TEXT;
                gen.SFDCRoutePriority__c = quote.Priority__c;
                gen.Integrate_with_Genesys_Routing__c = true;
                gen.OwnerId = genValue.Id__c;

                // Set email information if present (SDT-41263)
                if (newMessage != null) {
                    gen.LastAgentId__c = newMessage.Message_ID__c;
                    gen.EmailFrom__c = newMessage.FromAddress;
                    gen.EmailTo__c = newMessage.ToAddress.substringBefore('; ');
                    gen.EmailSubject__c = newMessage.Subject;
                    gen.SFDCIsEmailNew__c = 'False';
                }

                genList.add(gen);
            }

            // Insert Genesys routing records
            List<Database.SaveResult> insertOutcome = Database.insert(genList);
            List<Id> insertedGenesysIdList = new List<Id>();

            for (Integer i = 0; i < insertOutcome.size(); i++) {
                if (insertOutcome.get(i).isSuccess()) {
                    insertedGenesysIdList.add(insertOutcome.get(i).getId());
                }
            }

            // SDT-25008: Quote flag update is now handled via Flow
            // Comment for enqueueJob, part of 25008. This will cover with Flow of Genesys.

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'GenesysIntegrationService', 'createGenesysForQuote');
        }
    }

    /**
     * @description Update quote flag after Genesys record creation
     * Replaces QuoteTriggerHelper.updateQuoteFlag() lines 280-293
     * @param insertedGenesysIdList List of inserted Genesys routing IDs
     * @param action Action type
     */
    public void updateQuoteFlag(List<Id> insertedGenesysIdList, String action) {
        if (!insertedGenesysIdList.isEmpty() && runAsyncGenesysCreation) {
            System.enqueueJob(new AsyncUpdateQuoteFlag(insertedGenesysIdList, action));
        } else {
            AsyncUpdateQuoteFlag syncQuoteFlag = new AsyncUpdateQuoteFlag(insertedGenesysIdList, action);
            syncQuoteFlag.execute(null);
        }
    }

    /**
     * @description Check if quote start date is within 30 days
     * Replaces QuoteTriggerHelper.checkQuoteStartDateWithinthirtyDays() lines 384-397
     * SDT-27107: Added null check for startDate
     * @param startDate Quote start date
     * @return True if within 30 days, false otherwise
     */
    public Boolean checkQuoteStartDateWithin30Days(Date startDate) {
        if (startDate != null) {
            Integer days = startDate.daysBetween(System.today());
            if (days < 0) {
                days = days * (-1);
            }
            if (days <= Constant_Util.THIRTY) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Find org-wide email address in email message
     * Replaces QuoteTriggerHelper.findOrgWideEmailAddress() lines 1026-1051
     * SDT-37849: Check for org-wide email addresses
     * @param newMessage Email message to check
     * @return True if org-wide email found, false otherwise
     */
    private Boolean findOrgWideEmailAddress(EmailMessage newMessage) {
        Boolean foundOrgWideEmailForGenesys = false;
        List<String> emailsForNSQueueRouting = System.Label.Emails_For_NSQueue_Routing.split('; ');

        // Combine toAddresses and ccAddresses into a single list
        List<String> allAddresses = new List<String>();
        if (newMessage.ToAddress != null) {
            allAddresses.addAll(newMessage.ToAddress.split('; '));
        }
        if (newMessage.CcAddress != null) {
            allAddresses.addAll(newMessage.CcAddress.split('; '));
        }

        // Loop over list of OrgWideEmailAddresses
        for (OrgWideEmailAddress objEmail : OrgWideEmailSelector.getOrgWideAddressList(emailsForNSQueueRouting)) {
            if (allAddresses.contains(objEmail.Address)) {
                newMessage.ToAddress = objEmail.Address;
                foundOrgWideEmailForGenesys = true;
                break; // Exit the loop if one is found
            }
        }

        return foundOrgWideEmailForGenesys;
    }
}
