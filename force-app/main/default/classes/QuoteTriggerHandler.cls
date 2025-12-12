public class QuoteTriggerHandler {
    
    public static void onBeforeUpdate(List<SBQQ__Quote__c > QuoteList,Map<Id,SBQQ__Quote__c> oldMap,Map<Id,SBQQ__Quote__c> newMap){
        
        //TCS-pkulkarn-SDT-33101-11-Nov-2024-Added new method to validate Amendment quotes for Approval
        QuoteOnlyController.validateAmendmentQuoteApproval(QuoteList, oldMap);
        //TCS-pkulkarn-SDT-41186-18-Oct-2024-Added following method call
        //TCS-pkulkarn-SDT-44690-21-01-2025-Moved the following method call below - QuoteOnlyController.validateAmendmentQuoteApproval
        QuoteTriggerHelper.verifyAmendmentQuoteApprovalBySalesTeam(QuoteList, oldMap);
        QuoteTriggerHelper.updateLastModifiedSubmittedUser(QuoteList,oldMap); //Jira ID -> SDT-20030
        //QuoteTriggerHelper.updateGenesysRequired(QuoteList,oldMap,newMap);
	// Changes for Story 30515 & 30514
        if(!PricingJSONRequest.isRecurrsiveIntegrationCheck)
        {
            //pkulkarn-TCS-Commented below line for SDT-31408
            //QuoteTriggerHelper.CheckAndUpdateDateOnStatusChange(QuoteList,oldMap);
            QuoteTriggerHelper.integrationRequired(QuoteList,oldMap);
        }
		QuoteTriggerHelper.updateExpirationDate(QuoteList,oldMap);

        //calling method to set VCR to default value based on calculation for SDT 31118
        QuoteTriggerHelper.filterQuoteAndUpdateQuoteLinesWithVCR(oldMap, newMap);

        //TCS-pkulkarn-SDT-32740-25-09-2024-Added following line to update Type Of Change field on Quote Lines when Quote Status changes
        QuoteTriggerHelper.updateTypeOfChangeFieldOnQuoteLines(oldMap, newMap);

        //SDT 44716 
        if(RecurrsiveTriggerHandler.getRunTimes() < 1)
        {
        QuoteTriggerHelper.populateSysdefaultFieldForQLs(oldMap, newMap);
        }
    }  

		 public static void onBeforeInsert(List<SBQQ__Quote__c > QuoteList){
        System.debug('in before insert block>>>');
        QuoteTriggerHelper.updateExpirationDate(QuoteList,null);
    }
    
    public static void onAfterUpdate(List<SBQQ__Quote__c > QuoteList, Map<Id,SBQQ__Quote__c> oldMap, Map<Id,SBQQ__Quote__c> newMap){
        System.debug('In SBQQ__Quote__c afterupdate --- ');

		// Phase 9: Quote Lifecycle Processing
        // Replaces Quote_Status_Change_Flow logic with service-oriented architecture
        if(RecurrsiveTriggerHandler.getRunTimes() < 1) {
            processQuoteLifecycleChanges(QuoteList, oldMap, newMap);
        }

		//SDT-31298 - START
        
        //if(System.Label.Step_By_Step_Switch == 'On'){
        	QuoteTriggerHelper.stpPricingOnlyIntegration(QuoteList , oldMap );
       //}
        //SDT-31298 - END
        //Changes done by Chandu Kari for SDT-45082 single bundle Ammendment quote Customer Culumn as approved.
       QuoteTriggerHelper.amendmentQuoteApprovalBySingleBundle(QuoteList);
       //SDT-45082 - END
        //QuoteTriggerHelper.getQuoteData(QuoteList,oldMap,newMap);
        //QuoteTriggerHelper.updateExtraPickup(QuoteList, oldMap);//Changes done by jatan for SDT-19655
        //Added for Genesys Integration
        if(RecurrsiveTriggerHandler.getRunTimes() < 1)
        {
            //QuoteTriggerHelper.getQuotePriceData(QuoteList,oldMap); //Changes done by Ruchika for SDT-20127
            QuoteTriggerHelper.oldMapStatic = oldMap;
            // Commented for SDT-20835, Now this call happend from QuoteDecline Class for Syncronous call
            // QuoteTriggerHelper.sendDeclineQuoteNotification(QuoteList,oldMap,newMap);// SDT-20076, calling helper class method for declined quote notification send
            
        }
	//Moving out for IVR_NS, This will not required recurssioin as there are multiple condition exist.
        //Changes related to SDT-48086
        try
        {
            SBQQ.TriggerControl.disable();
            QuoteTriggerHelper.getQuotePriceData(QuoteList,oldMap);
        }
        catch(Exception ex)
        {
            UTIL_LoggingService.logHandledExceptionWithClass(ex, UserInfo.getOrganizationId(),
                                                            UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
                                                            System.LoggingLevel.Error,
                                                            UTIL_ErrorConstants.QUOTETRIGGERHELPER_CLASSNAME,
                                                            UTIL_ErrorConstants.GETQUOTEPRICEDATA_METHODNAME + ' '+ 
                                                            UTIL_ErrorConstants.CREATEPRICINGREQUEST_METHODNAME,
                                                            UTIL_ErrorConstants.QUOTETRIGGER_TRIGGERNAME);
        }
        finally{
            SBQQ.TriggerControl.enable();
        }
        //Added for Genesys Integration
        
        List<SBQQ__Quote__c>lstTobeProcessed = new List<SBQQ__Quote__c>() ;
        List<SBQQ__Quote__c>lstTobeProcessedforDraft = new List<SBQQ__Quote__c>();
        
        for(SBQQ__Quote__c sbQ : QuoteList){
            if((sbQ.SBQQ__Status__c == Constant_Util.QUOTE_DRAFT && sbQ.Action_Type__c == Constant_Util.QUOTE_STATUS_CHANGE) || (sbQ.Assigned_To__c != oldMap.get(sbQ.id).Assigned_To__c && RecurrsiveTriggerHandler.getRunTimes() < 1)){
                lstTobeProcessedforDraft.add(sbQ);
            }
            else{
                lstTobeProcessed.add(sbQ);
            }
        }
        //Commented for 25008 because this shuld cover with genesys flow
       //system.debug('RecurrsiveTriggerHandler.getRunTimes()'+ RecurrsiveTriggerHandler.getRunTimes());
        /*if(RecurrsiveTriggerHandler.getRunTimes() < 1 && !lstTobeProcessedforDraft.isEmpty())
       
        {           
            System.debug('@@in if');
            QuoteTriggerHelper.changeInOwnerOfQuote(lstTobeProcessedforDraft,oldMap);
            QuoteTriggerHelper.isEligibleForGenesys(lstTobeProcessedforDraft,oldMap,newMap);           
        }
        else if(RecurrsiveTriggerHandler.getRunTimes() <= 4) // SDT-24191 RecurrsiveTriggerHandler.getRunTimes() <= 2 is added to call method when Quote is being updated via update on QuoteLine.
        {                    
            System.debug('@@in else');
            QuoteTriggerHelper.changeInOwnerOfQuote(lstTobeProcessed,oldMap);
            QuoteTriggerHelper.isEligibleForGenesys(lstTobeProcessed,oldMap,newMap);
        }
          */
          //SDT-41625,41544,41473

        //Changes related to SDT-48086
        try
        {
            SBQQ.TriggerControl.disable();
            QuoteTriggerHelper.createTaskonHaulAwayQuote(QuoteList,oldMap); //-- Approve / Decline
            QuoteTriggerHelper.createChargeabilityChildCase(QuoteList,oldMap); //-- Approve
            //40723
            QuoteTriggerHelper.updateRelatedTaskAndGenesys(QuoteList,oldMap, newMap); //-- Submit for Approval	
        }
        catch(Exception ex)
        {
            //Changes related to SDT-48086
            UTIL_LoggingService.logHandledExceptionWithClass(ex, UserInfo.getOrganizationId(),
                                                            UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
                                                            System.LoggingLevel.Error,UTIL_ErrorConstants.QUOTETRIGGERHANDLER_CLASSNAME,
                                                            UTIL_ErrorConstants.CREATETASKONHAULAWAYQUOTE_METHODNAME + ' '+ 
                                                            UTIL_ErrorConstants.CREATECHARGEABILITYCHILDCASE_METHODNAME +' '+
                                                            UTIL_ErrorConstants.CREATEGENESYSTASK_METHODNAME + ' '+
                                                            UTIL_ErrorConstants.CREATEGENESYSRECORD_METHODNAME + ' '+
                                                            UTIL_ErrorConstants.CREATEMULTIPLECASESINVOKE_METHODNAME + ' '+
                                                            UTIL_ErrorConstants.COPYEMAILTOCHILDCASE_METHODNAME + ' '+
                                                            UTIL_ErrorConstants.CREATEOBTAININTERNALRESPOTASK_METHODNAME, 
                                                            UTIL_ErrorConstants.QUOTETRIGGER_TRIGGERNAME);
         }
         finally{
            SBQQ.TriggerControl.enable();
         }

        //SDT-41538

        RecurrsiveTriggerHandler.setRunTimes();
    }

    /**
     * @description Process quote lifecycle changes using service architecture
     * Phase 9: Replaces Quote_Status_Change_Flow (127 elements)
     * Handles: Status changes, assignments, priority, next action timing
     * @param QuoteList List of updated quotes
     * @param oldMap Old quote values
     * @param newMap New quote values
     */
    private static void processQuoteLifecycleChanges(
        List<SBQQ__Quote__c> QuoteList,
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> newMap
    ) {
        try {
            QuoteLifecycleOrchestrator orchestrator = new QuoteLifecycleOrchestrator();

            for (SBQQ__Quote__c quote : QuoteList) {
                SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);

                // Process quote changes
                QuoteLifecycleOrchestrator.ProcessingResult result =
                    orchestrator.processQuoteChange(quote, oldQuote);

                // Log any processing errors
                if (!result.success && !result.errors.isEmpty()) {
                    String errorMessage = 'Quote lifecycle processing failed for Quote ' +
                                        quote.Id + ': ' + String.join(result.errors, '; ');
                    System.debug(LoggingLevel.ERROR, errorMessage);
                    UTIL_LoggingService.logError(
                        'QuoteTriggerHandler',
                        'processQuoteLifecycleChanges',
                        errorMessage
                    );
                }

                // Log warnings if any
                if (!result.warnings.isEmpty()) {
                    String warningMessage = 'Quote lifecycle warnings for Quote ' +
                                          quote.Id + ': ' + String.join(result.warnings, '; ');
                    System.debug(LoggingLevel.WARN, warningMessage);
                }
            }

        } catch (Exception ex) {
            UTIL_LoggingService.logHandledExceptionWithClass(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
                System.LoggingLevel.Error,
                UTIL_ErrorConstants.QUOTETRIGGERHANDLER_CLASSNAME,
                'processQuoteLifecycleChanges',
                UTIL_ErrorConstants.QUOTETRIGGER_TRIGGERNAME
            );

            // Don't throw - allow other trigger logic to continue
            System.debug(LoggingLevel.ERROR, 'Quote lifecycle orchestrator failed: ' + ex.getMessage());
        }
    }
}
