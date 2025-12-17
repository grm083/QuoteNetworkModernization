/**
 * @description Service for SLA (Service Level Agreement) management operations
 * Handles SLA override comments, validation, and date calculations
 * @author Quote Network Modernization Team
 * @date 2025-12-13
 * @story Phase 10.5: SLA & Special Handling
 */
public class SLAManagementService {

    // Constants for special handling reasons
    public static final String SPECIAL_HANDLING_AUTOMATIC_REASON = 'Automatically flagged by system';
    public static final String SPECIAL_HANDLING_BACKDATED_REASON = 'Back-dated service requested';

    /**
     * @description Add SLA override comment to case
     * Wrapper method for intake screen calls
     * @param caseId Case ID
     */
    public void addCommentForSLAOverrideFromIntake(String caseId) {
        addCommentForSLAOverride(caseId, null, null);
    }

    /**
     * @description Add SLA override comment from flow
     * @param caseId Case ID
     * @param slaComment SLA override comment
     * @param slaReason SLA override reason
     */
    public void addCommentForSLAOverrideFromFlow(String caseId, String slaComment, String slaReason) {
        addCommentForSLAOverride(caseId, slaComment, slaReason);
    }

    /**
     * @description Create case comment displaying SLA override reason and comment
     * @param caseId Case ID
     * @param slaComment SLA override comment (optional)
     * @param slaReason SLA override reason (optional)
     * @story SDT-25005
     */
    public void addCommentForSLAOverride(String caseId, String slaComment, String slaReason) {
        try {
            String commentBody;
            String trackingNumber;
            String caseNumber;

            // Get SLA Override comment template from metadata
            Map<String, Comment_Log_Detail__mdt> commentLogTemplateData = new Map<String, Comment_Log_Detail__mdt>();
            for (Comment_Log_Detail__mdt c : Comment_Log_Detail__mdt.getAll().values()) {
                commentLogTemplateData.put(c.DeveloperName, c);
            }
            Comment_Log_Detail__mdt slaOverrideCommentTemplate = commentLogTemplateData.get('SLA_Override');

            Id recordTypeId = Schema.getGlobalDescribe()
                .get('Comment__c')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('Acorn_Ticket_Comment')
                .getRecordTypeId();

            // When called from MIF flow with explicit comment and reason
            if (String.isNotEmpty(slaComment) && String.isNotEmpty(slaReason)) {
                commentBody = slaOverrideCommentTemplate.Comment__c.replaceAll('<Reason__x>', slaReason);
                commentBody = commentBody.replaceAll('<Comment__c>', slaComment);

                List<Case> csList = [
                    SELECT Id, CaseNumber, Tracking_Number__c
                    FROM Case
                    WHERE Id = :caseId
                    LIMIT 1
                ];

                if (csList.size() > 0) {
                    caseNumber = csList[0].CaseNumber;
                    trackingNumber = csList[0].Tracking_Number__c;
                }
            } else {
                // Query quote line for SLA override details
                List<SBQQ__QuoteLine__c> ql = [
                    SELECT Id, SLA_Override_Reason__c, SLA_Override_Comment__c,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.CaseNumber,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c = :caseId
                    AND SBQQ__Requiredby__c = null
                    AND SLA_Override_Reason__c != null
                    LIMIT 1
                ];

                if (ql.size() > 0) {
                    String overrideReason = ql[0].SLA_Override_Reason__c;
                    String overrideComment = ql[0].SLA_Override_Comment__c;

                    commentBody = slaOverrideCommentTemplate.Comment__c.replaceAll('<Reason__x>', overrideReason);
                    commentBody = commentBody.replaceAll('<Comment__c>', overrideComment);

                    caseNumber = ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.CaseNumber;
                    if (String.isNotEmpty(ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c)) {
                        trackingNumber = ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c;
                    }
                }
            }

            // Create Comment record (SDT-48501)
            if (String.isNotBlank(commentBody)) {
                Comment__c comment = new Comment__c();
                comment.RecordTypeId = recordTypeId;
                comment.Comment__c = commentBody;
                comment.is_Log__c = true;
                comment.Workflow_TeamUser__c = System.UserInfo.getName();
                comment.Communication_Log_Type_Name__c = 'Internal';
                comment.Case__c = caseId;
                comment.Type__c = Constant_Util.OBJECT_CASE;
                comment.Case_Number__c = caseNumber;
                comment.Acorn_Tracking_Number__c = trackingNumber;

                insert comment;
            }

        } catch (Exception ex) {
            // SDT-48086 - Log handled exception
            UTIL_LoggingService.logHandledExceptionWithClass(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
                System.LoggingLevel.ERROR,
                'SLAManagementService',
                'addCommentForSLAOverride',
                null
            );
        }
    }

    /**
     * @description Validate SLA override fields
     * @param quoteLine Quote line with SLA override details
     * @return Validation result
     */
    public ValidationResult validateSLAOverride(SBQQ__QuoteLine__c quoteLine) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;

        if (String.isNotEmpty(quoteLine.SLA_Override_Reason__c)) {
            if (String.isEmpty(quoteLine.SLA_Override_Comment__c)) {
                result.isValid = false;
                result.errorMessage = 'SLA Override Comment is required when SLA Override Reason is specified';
            }
        }

        return result;
    }

    /**
     * @description Calculate SLA date for quote line
     * @param quoteLineId Quote line ID
     * @return SLA date
     */
    public Date calculateSLADate(String quoteLineId) {
        // Phase 11a: Updated to call local determineSLA() method
        DateTime slaDateTime = determineSLA(quoteLineId);
        if (slaDateTime != null) {
            return slaDateTime.date();
        }
        return null;
    }

    /**
     * @description Check if service is backdated (SLA date before today)
     * @param quoteLine Quote line with SLA date
     * @return True if backdated, false otherwise
     */
    public Boolean isBackdatedService(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.Quote_SLA_Date__c != null && quoteLine.Quote_SLA_Date__c < System.today()) {
            return true;
        }
        return false;
    }

    /**************************************************************
    * Method name : determineSLAForAlternateProducts
    * Description :
    * Returns :  Date for input product (QLI wrapper)
    * Developer : Satnam Singh
    * User Story : SDT-29961
    * Phase 11a: Extracted from QuoteFavoritesController
    ****************************************************************/
    public Map<String,Date> determineSLAForAlternateProducts(Id parentQuoteLineId,List<String> equipmentSizes){
        Map<String,Date> slaDates = new Map<String,Date>();
        Map<String,String> checkDuration= new Map<String,String>
                                        {'TEMP'=>'Temporary','PERM'=>'Permanent','SEAS'=>'Seasonal'};
        try {
            DateTime SLADate;
            List<BusinessHours> locationBusinessHours;
            BusinessHours businessHourId;
			String locTimeZone;

            SBQQ__QuoteLine__c parentLine = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__ProductFamily__c, Duration__c,
                                                SBQQ__Quote__r.SBQQ__Account__r.ParentId, SBQQ__Quote__r.Project__c, SBQQ__ProductName__c,
                                                Equipment_Size__c, SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
                                                FROM SBQQ__QuoteLine__c WHERE Id =: parentQuoteLineId];

            if(parentLine != null) {
                locTimeZone = parentLine.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c;
            }

            BusinessHours defaultHours = [SELECT Id FROM BusinessHours WHERE isDefault = true LIMIT 1];

            if(!getSLASwitch())
            {
                //Get the Business Hours as per quote account timezone or use default Business Hours
                //For SDT-39637 and SDT-45007
                locationBusinessHours = getBusinessIdByTimeZone(locTimeZone);
                if(locationBusinessHours != null && locationBusinessHours.size() > 0)
                    businessHourId = locationBusinessHours[0];
                else
                    businessHourId = defaultHours;
                //
            }
            else{
                businessHourId = defaultHours;
            }

            //Check related Entitlement
            Entitlement relEntitlement = QuoteFavoritesController.getRelatedEntitleMent(parentLine.SBQQ__Quote__c, parentLine.Id);
            System.debug('relEntitlement^^'  +relEntitlement);
            if (relEntitlement == null || relEntitlement.id==null) {
                String serviceFilter ='New Service_'+checkDuration.get(parentLine.Duration__c);

                List<Industry_Standard_SLA__mdt> industryStandards = [SELECT Id, Service__c, After__c, Before__c
                                                                        FROM Industry_Standard_SLA__mdt
                                                                        WHERE Service__c LIKE :(serviceFilter+'%')];
                Map<String, Industry_Standard_SLA__mdt> industryStandardMap = new Map<String, Industry_Standard_SLA__mdt>();
                for(Industry_Standard_SLA__mdt ind : [SELECT Id, Service__c, After__c, Before__c
                FROM Industry_Standard_SLA__mdt
                WHERE Service__c LIKE :(serviceFilter+'%')]) {
                    industryStandardMap.put(ind.Service__c,ind);
                }
                //If if product is Compactor
                if(parentLine.SBQQ__ProductName__c.contains('Compactor')){
                    for(String size : equipmentSizes){
                        Integer equipmentSize = Integer.ValueOf(size.replace('YRDS','').replace('-',''));
                        // size less than 10 = Commercial else Roloff
                        String lob = (equipmentSize <= 10) ? Constant_Util.COMMERCIAL : Constant_Util.ROLLOFF;
                        Industry_Standard_SLA__mdt indStand = industryStandardMap.get(serviceFilter+'_'+lob);
                        if(indStand!=null){
                            if(!getSLASwitch()){
                                slaDates.put(size,calculateISSLA_LocTimezone(indStand, businessHourId, parentLine, locTimeZone).date());
                            }
                            else{
                                slaDates.put(size,calculateISSLA(indStand, defaultHours).date());
                            }
                        }
                    }
                }
                else{
                    if(!getSLASwitch()){
                        SLADate = calculateISSLA_LocTimezone(industryStandardMap.get(serviceFilter+'_'+parentLine.SBQQ__ProductFamily__c), businessHourId, parentLine, locTimeZone);
                    }
                    else{
                        SLADate = calculateISSLA(industryStandardMap.get(serviceFilter+'_'+parentLine.SBQQ__ProductFamily__c), defaultHours);
                    }
                }
            } else {
                    if(!getSLASwitch()){
                        SLADate = calculateEntitlementSLA_LocTimezone(relEntitlement, businessHourId, locTimeZone);
                    }
                    else{
                        SLADate = calculateEntitlementSLA(relEntitlement, defaultHours);
                    }
            }
            if(SLADate!=null && slaDates.size()==0){
                for(String size : equipmentSizes){
                    slaDates.put(size,SLADate.date());
                }
            }
        } catch (Exception e) {
            System.debug('Error '+e);
        }
        return slaDates;
    }

    //Determine SLA for the quote line.  This is not invoked from the Lightning ComponentD
    //Phase 11a: Extracted from QuoteFavoritesController
    public DateTime determineSLA(Id parentQuoteLineId) {
        DateTime SLADate = system.now();
        SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c();
        Entitlement relEntitlement = new Entitlement();
        String duration;
        List<BusinessHours> locationBusinessHours;
        BusinessHours businessHourId;
        BusinessHours defaultHours = [SELECT Id FROM BusinessHours WHERE isDefault = true LIMIT 1];
        String locTimeZone;

        List<SBQQ__QuoteLine__c> bundle = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.SBQQ__Account__c, SBQQ__ProductFamily__c, Duration__c,
                                           SBQQ__Quote__r.SBQQ__Account__r.ParentId, SBQQ__Quote__r.Project__c, SBQQ__ProductName__c, Equipment_Size__c,
                                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.SLA_Service_DateTime__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c,
                                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Is_Haul_Away_Service__c, SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
                                           FROM SBQQ__QuoteLine__c
                                           WHERE Id =: parentQuoteLineId];

        parentLine = bundle.size() == 1 ? bundle[0] : null;

        if (parentLine == null) {
            system.debug('Could not determine parent row.');
            return SLADate;
        }

        locTimeZone = parentLine.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c;


        //SDT-41473 SDT-42045
        Id caseId = bundle[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c;

        Boolean IsHaulAway =  HaulAwayService.getIsHaulAwayService(caseId);

        if(IsHaulAway){
            return system.now();
        }

        if(!getSLASwitch()){
            //Get the Business Hours as per quote account timezone or use default Business Hours
            //For SDT-39637 and SDT-45007
            locationBusinessHours = getBusinessIdByTimeZone(locTimeZone);
            if(locationBusinessHours != null && locationBusinessHours.size() > 0)
                businessHourId = locationBusinessHours[0];
            else
                businessHourId = defaultHours;
            //
        }
        else{
            businessHourId = defaultHours;
        }

        switch on parentLine.Duration__c {
            when 'TEMP' {
                duration = 'Temporary';
            }
            when 'PERM' {
                duration = 'Permanent';
            }
            when 'SEAS' {
                duration = 'Seasonal';
            }
            when else {
                return system.now();
            }
        }
        relEntitlement = QuoteFavoritesController.getRelatedEntitleMent(parentLine.SBQQ__Quote__c, parentLine.Id);
        system.debug('jatan test '+ relEntitlement);

        if (relEntitlement == null || relEntitlement.id == null) {
            // system.debug('No account entitlements.  Using Industry Standards');
            Industry_Standard_SLA__mdt IndStSLA = new Industry_Standard_SLA__mdt();

            List<Industry_Standard_SLA__mdt> industryStandards = [SELECT Id, Service__c, After__c, Before__c
                                                                  FROM Industry_Standard_SLA__mdt
                                                                  WHERE Service__c LIKE 'New Service%'];

            // system.debug('Number of industryStandards returned:' + industryStandards.size());
            for(Industry_Standard_SLA__mdt ind : industryStandards) {
                // system.debug('parentLine>>'+ parentLine);
                // Compactor Logic for SDT-24088
                if(parentLine.SBQQ__ProductName__c.contains('Compactor') && !String.isBlank(parentLine.Equipment_Size__c) && parentLine.Equipment_Size__c != null)
                {
                    Double equipmentSize= Double.ValueOf(parentLine.Equipment_Size__c.replace('YRDS','').replace('-',''));
                    // system.debug('equipmentSize>>>'+ equipmentSize);
                    // if product is Compactor and size less than 10 = Commercial
                    if(equipmentSize <= 10 && ind.Service__c.contains(Constant_Util.COMMERCIAL) && ind.Service__c.contains(duration))
                    {
                        IndStSLA = ind;
                        system.debug('inside #4>>'+ IndStSLA);
                    }// if product is Compactor and size greater than 10 yard = Roll Off
                    else if(equipmentSize > 10 && ind.Service__c.contains(Constant_Util.ROLLOFF) && ind.Service__c.contains(duration)){
                        IndStSLA = ind;
                        system.debug('inside #5>>'+ IndStSLA);
                    }
                }
                else if (ind.Service__c.contains(parentLine.SBQQ__ProductFamily__c) && ind.Service__c.contains(duration)) {
                    IndStSLA = ind;
                    system.debug('inside #1>>'+ IndStSLA);
                } else if (ind.Service__c.contains('Service') && ind.Service__c.contains(duration) && IndStSLA == null) {
                    IndStSLA = ind;
                    system.debug('inside #2>>'+ IndStSLA);
                }
                else if (ind.Service__c.contains('Service') && ind.Service__c.contains(duration) && parentLine.SBQQ__ProductFamily__c == 'None') {
                    IndStSLA = ind;
                    system.debug('inside #3>>'+ IndStSLA);
                }
            }
            // system.debug('Industry standard is: ' + IndStSLA.Service__c);
            if(!getSLASwitch()){
                //Changes for SDT-39637
                SLADate = calculateISSLA_LocTimezone(IndStSLA, businessHourId, parentLine, locTimeZone);
                // system.debug('Industry Standard SLA is -->'+SLADate);
            }
            else{
                SLADate = calculateISSLA(IndStSLA, defaultHours);
                system.debug('Industry Standard SLA is -->'+SLADate);
            }
        }
        else {
            if(!getSLASwitch()){
                //Changes for SDT-45007
                SLADate = calculateEntitlementSLA_LocTimezone(relEntitlement, businessHourId, locTimeZone);
            }
            else{
                SLADate = calculateEntitlementSLA(relEntitlement, defaultHours);
            }
        }

        //Iterate through the returned entitlements to match appropriately
         /* adding for SDT-33378 */
        if(parentLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c != null && (parentLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' || parentLine.SBQQ__Quote__r.SBQQ__Type__c == 'Correction' || parentLine.SBQQ__Quote__r.SBQQ__Type__c == 'Exception'))
        {
            Date dateObj = parentLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c;
            Integer d = dateObj.day();
            Integer mo = dateObj.month();
            Integer yr = dateObj.year();
            SLADate = DateTime.newInstance(yr, mo, d);
        }

        // system.debug('Calculated SLA Date is: ' + SLADate);
        return SLADate;

    }

    //Use entitlement to calculate SLA date
    //Phase 11a: Extracted from QuoteFavoritesController
    public DateTime calculateEntitlementSLA(Entitlement e, BusinessHours bh) {
        DateTime additionalDate;
        Date targetDate;
        Time targetTime;
        currentDateTime currDateTime = new currentDateTime();
        integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        Long milliseconds = 0;
        DateTime productSLA;

        switch on e.Service_Guarantee_Category__c {
            when 'Hours' {
                milliseconds = Integer.valueOf(e.Service_Guarantee_Category_Value__c) * 3600000;
            }
            when 'Days' {
                integer serviceGuaranteeCategoryValue = Integer.valueOf(e.Service_Guarantee_Category_Value__c);
                //For Same Day and Next Day Entitlements SDT-24917, In Before Logic one extra Day shouldn't get added
                if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour < 9){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue==1){
                         serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue + 1;
                     }
                }
                else if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour >= 10){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue-1;
                    }
                }
                else if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour < 10){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                         serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue;
                         system.debug('serviceGuaranteeCategoryValue for else if Before 10 in before condition==>'+serviceGuaranteeCategoryValue);
                    }
                }
                //'After' 14:00 Scenarios for Entitlements to get picked up
                else if(e.Before_After__c!='' && (Constant_Util.AFTER).equalsIgnorecase(e.Before_After__c) && (e.Call_Time__c == '14:00' || e.Call_Time__c == '15:00' || e.Call_Time__c == '23:59')){
                    serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue;
                }
                 //'After' and before 14:00 Scenarios for Entitlements to get picked up
                else if(e.Before_After__c!='' && (Constant_Util.AFTER).equalsIgnorecase(e.Before_After__c) && e.Call_Time__c == '13:00' || e.Call_Time__c == '12:00' || e.Call_Time__c == '10:00' ){
                    if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue-1;
                    }
                 }
                milliseconds = serviceGuaranteeCategoryValue * 16 * 3600000;
            }
        }
        productSLA = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
        system.debug('productSLA From QF Controllers calculateEntitlementSLA-->'+productSLA);
        return productSLA;
    }

    //Use entitlement to calculate SLA date using location timezone
    //Phase 11a: Extracted from QuoteFavoritesController
    public DateTime calculateEntitlementSLA_LocTimezone(Entitlement e, BusinessHours bh, string locTimeZone) {
        DateTime additionalDate;
        Date targetDate;
        Time targetTime;
        currentDateTime currDateTime;
        Long milliseconds = 0;
        DateTime productSLA;
        Integer offset;
        //Changes for SDT-45007
        if(String.isNotEmpty(locTimeZone))
        {
            // system.debug('calculateEntitlementSLA - When have parent quoteline');
            currDateTime = new currentDateTime(locTimeZone);
            Datetime now = Datetime.now();
            Timezone timeZone = Timezone.getTimeZone(locTimeZone);
            offset = timeZone.getOffset(now);
        }
        else
        {
            // system.debug('calculateEntitlementSLA - When donot have parent quoteline');
            currDateTime = new currentDateTime();
        }
        integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);

        switch on e.Service_Guarantee_Category__c {
            when 'Hours' {
                milliseconds = Integer.valueOf(e.Service_Guarantee_Category_Value__c) * 3600000;
            }
            when 'Days' {
                System.debug('inside ent2^^^^');
                integer serviceGuaranteeCategoryValue = Integer.valueOf(e.Service_Guarantee_Category_Value__c);
                system.debug('serviceGuaranteeCategoryValue in line 347==>'+serviceGuaranteeCategoryValue);
                //For Same Day and Next Day Entitlements SDT-24917, In Before Logic one extra Day shouldn't get added
                /*if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour < 9){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue==1){
                        // system.debug('In currentHour < 9 - where SG+1');
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue + 1;
                     }
                }
                //commented by av4 as part of SDT-39637
                else if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour >= 10){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                        // system.debug('In currentHour >= 10 - where SG-1');
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue-1;
                    }
                }
                else if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour < 10){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue;
                        // system.debug('In currentHour < 10 - where SG');
                        // system.debug('serviceGuaranteeCategoryValue for else if Before 10 in before condition==>'+serviceGuaranteeCategoryValue);
                    }
                }

                //'After' 14:00 Scenarios for Entitlements to get picked up
                else if(e.Before_After__c!='' && (Constant_Util.AFTER).equalsIgnorecase(e.Before_After__c) && (e.Call_Time__c == '14:00' || e.Call_Time__c == '15:00' || e.Call_Time__c == '23:59')){
                        // system.debug('In After 14, 15, 23:59 - SG');
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue;
                }
                 //'After' and before 14:00 Scenarios for Entitlements to get picked up
                else if(e.Before_After__c!='' && (Constant_Util.AFTER).equalsIgnorecase(e.Before_After__c) && e.Call_Time__c == '13:00' || e.Call_Time__c == '12:00' || e.Call_Time__c == '10:00' ){
                    if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue!=1){
                        // system.debug('In After 13, 12, 10 - SG-1');
                        //serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue-1;
                        // Change for SDT-47963 SGC = SGC
                        serviceGuaranteeCategoryValue = serviceGuaranteeCategoryValue;
                    }
                }*/
                //added by av4 as part of testing 39637
                //same day and next day doesnt depend on before and after. we take servicegurantee as 0 and 1 respectively.
                if((serviceGuaranteeCategoryValue == 0 || serviceGuaranteeCategoryValue == 1)) {
                    system.debug('same day and next day scenario');
                }
                //other before scenarios //
                else if(e.Before_After__c!=Constant_Util.EMPTY_STRING && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c)){
                    // system.debug('In currentHour < 9 - where SG+1');
                    serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue - 1;
                }
				//other after scenarios
                else if(e.Before_After__c!=Constant_Util.EMPTY_STRING && (Constant_Util.AFTER).equalsIgnorecase(e.Before_After__c)){
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue;
                }

                //morning 12(00:00AM) to 5
                if(currentHour >= 0 && currentHour < 5) {
                    serviceGuaranteeCategoryValue = serviceGuaranteeCategoryValue + 1;
                }


                //ends here
                system.debug('serviceGuaranteeCategoryValue==> '+ serviceGuaranteeCategoryValue);
                milliseconds = serviceGuaranteeCategoryValue * 16 * 3600000;
            }
        }
        if(locTimeZone != null)
        {
            //modified by av4 for 39637
            //productSLA = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            //productSLA = productSLA.addSeconds(offset/1000);
            //milliseconds = milliseconds - difference;
            productSLA = getBusinessHoursInAccountTimeZone(bh.Id, System.now(), milliseconds, locTimeZone);
        }
        else{
            productSLA = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
        }
        // system.debug('productSLA From QF Controllers calculateEntitlementSLA--> ' + productSLA);
        return productSLA;
    }

    //Use industry standard to calculate SLA date
    //Phase 11a: Extracted from QuoteFavoritesController
    public DateTime calculateISSLA(Industry_Standard_SLA__mdt indStand, BusinessHours bh) {
        system.debug('bh==>'+bh);
        DateTime targetSLADate;
        Long milliseconds = 0;
        currentDateTime currDateTime = new currentDateTime();
        integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        system.debug('currentHour==>'+currentHour);
        if(currentHour >= 14){
            if( indStand.After__c != null){
                milliseconds = (indStand.After__c.intValue() * 16 * 3600000);
            }
            system.debug('if milliseconds==>'+(milliseconds));
            system.debug('if milliseconds 2==>'+(milliseconds+57600000));
            targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            System.debug('After Value==>'+targetSLADate);
        }else if(currentHour >= 10 && currentHour < 14){
            if( indStand.Before__c != null){
                milliseconds = (indStand.Before__c.intValue() * 16 * 3600000)-57600000;
            }
            system.debug('else milliseconds==>'+(milliseconds-57600000));
            targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            System.debug('Before Value==>'+targetSLADate);
        }else{
            if( indStand.Before__c != null){
                milliseconds = (indStand.Before__c.intValue() * 16 * 3600000);
            }
            system.debug('else milliseconds==>'+milliseconds);
            targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            System.debug('Before Value==>'+targetSLADate);
        }
        return targetSLADate;
    }

    //Use industry standard to calculate SLA date using location timezone
    //Phase 11a: Extracted from QuoteFavoritesController
    public DateTime calculateISSLA_LocTimezone(Industry_Standard_SLA__mdt indStand, BusinessHours bh, SBQQ__QuoteLine__c parentQL, String locTimeZone) {
        DateTime targetSLADate;
        Long milliseconds = 0;
        integer daysAdd = 0;
        currentDateTime currDateTime;
        Boolean isQuoteSLA = false;
        Integer offset;
        //Changes for SDT-39637
        if(locTimeZone != null)
        {
            isQuoteSLA = parentQL!=null?true:false;
            currDateTime = new currentDateTime(locTimeZone);
            Datetime now = Datetime.now();
            Timezone timeZone = Timezone.getTimeZone(locTimeZone);
            offset = timeZone.getOffset(now);
             system.debug('Location offset==> '+ offset);
             system.debug('When have parent quoteline ' +currDateTime);
        }
        else
        {
            // system.debug('When donot have parent quoteline');
            currDateTime = new currentDateTime();
            system.debug('No parent quoteline ' +currDateTime);

        }
        integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
         system.debug('bh==>'+bh);
         system.debug('currentHour==> '+currentHour);
        // system.debug('currDateTime.local==> '+currDateTime.local);
        system.debug('indStand.After__c==> '+indStand.After__c.intValue());
        system.debug('indStand.Before__c==> '+indStand.Before__c.intValue());
        //currentHour = 9;
        if(currentHour >= 12){

             system.debug('When currentHour > 12');
            if(indStand.After__c != null){
                daysAdd = indStand.After__c.intValue();
                milliseconds = (daysAdd * 16 * 60 * 60 * 1000);
            }
            // system.debug('After milliseconds==>'+(milliseconds));
            // modified by av4
            // targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            targetSLADate = getBusinessHoursInAccountTimeZone(bh.Id, System.now(), milliseconds, locTimeZone);
            //targetSLADate = targetSLADate.addSeconds(offset/1000);
            // System.debug('After Value targetSLADate==> '+targetSLADate);
        }
        //morning 12(00:00AM) to 5 - //added by av4 for SDT-39637
        else if(currentHour >=0 && currentHour < 5) {
            if( indStand.Before__c != null){
                milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000);
                targetSLADate = getBusinessHoursInAccountTimeZone(bh.Id, System.now(), milliseconds, locTimeZone);
            }
        }
       // else if(currentHour >= 10 && currentHour < 12){
        else if(currentHour < 12){
            //modified by av4
            /*if(locTimeZone != null && locTimeZone.contains('Pacific/Honolulu'))
            {
                daysAdd = indStand.Before__c.intValue() - 1;
                milliseconds = (daysAdd * 16 * 60 * 60 * 1000);
                system.debug('currDateTime.local'+currDateTime.local);
                targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
                system.debug('Final HAST Time '+targetSLADate);
            }*/
            if( indStand.Before__c != null){
                //modified by av4 for SDT-39637
                milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000) - 57600000 ; //(57600000 = 16Hrs)
                //milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000);// - 57600000 ;
                // system.debug('Before milliseconds==>'+milliseconds);
                // modified by av4
                // targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
                targetSLADate = getBusinessHoursInAccountTimeZone(bh.Id, System.now(), milliseconds, locTimeZone);
            }
        }
        /*else{
             system.debug('When currentHour < 10');
            if( indStand.Before__c != null){

                ///This logic is return to handle the Friday SLA calculation scenarion
                //in which weekend date is coming when have Indus. SLA 7 days.
                //To correct that first add 7 days in Business Hours then deducte the hours
                //As per time zone offset.
                //modified by av4
                /*if(isQuoteSLA && currDateTime.dayOfWeek == 'Fri' && indStand.Before__c.intValue() == 7)
                {
                    milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000);
                    // system.debug('Before milliseconds==>'+milliseconds);
                    targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);

                    // system.debug('targetSLADate ==>'+targetSLADate);

                    targetSLADate = targetSLADate.addSeconds(offset/1000);
                    system.debug('Friday Scenario ' +targetSLADate);
                }*/
                //else{
                    //modified by av4
                    //daysAdd = indStand.Before__c.intValue() - 1;
                    //milliseconds = (daysAdd * 16 * 60 * 60 * 1000);
                	/*milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000) - 57600000 ;
                	//milliseconds = (indStand.Before__c.intValue() * 16 * 60 * 60 * 1000);// - 57600000 ;
                    system.debug('currDateTime.local'+currDateTime.local);
                    //modified by av4
                    // targetSLADate = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
                	targetSLADate = getBusinessHoursInAccountTimeZone(bh.Id, System.now(), milliseconds, locTimeZone);
                    system.debug('Timezone '+targetSLADate);
                    //targetSLADate = BusinessHours.add(bh.Id, currDateTime.local, milliseconds);
                    system.debug('local '+targetSLADate);
               // }
            }
            System.debug('Before Value targetSLADate==> '+targetSLADate);
        }*/

        return targetSLADate;
    }

    //this switch was created for switching off of new sla functionality(added as part of SDT-39637, SDT-45007, SDT-47970, SDT-47975), without actually
    //rolling back the code changes done.
    //Phase 11a: Extracted from QuoteFavoritesController
    //Phase 11b: Made public for EntitlementMatchingService
    public static boolean getSLASwitch(){
        Code_Switch__c codeSwitchSetting = Code_Switch__c.getValues('SLA Logic Switch');
        return codeSwitchSetting.Switch_Off__c;
    }

    /*******************************************************************************************************
    * @description Utility Method to add business hours using business id
    * @param businessHoursId of type Id
    * @param startDate of type DateTime
    * @param intervalMilliseconds of type Long
    * @return Datetime
    * @example
    * Phase 11a: Extracted from QuoteFavoritesController
    */
    private static DateTime getBusinessHours(Id businessHoursId,DateTime startDate, Long intervalMilliseconds){
        return BusinessHours.addGmt(businessHoursId, startDate, intervalMilliseconds);
    }

    //added by av4
    //Phase 11a: Extracted from QuoteFavoritesController
    private static DateTime getBusinessHoursInAccountTimeZone(Id businessHoursId,DateTime utcStartDateTime, Long intervalMilliseconds, String accTimeZone){
        // Get the TimeZone object from the provided ID
        TimeZone tz = TimeZone.getTimeZone(accTimeZone);

        // Get the offset from GMT for this time zone at the given datetime
        Integer offsetMillis = tz.getOffset(utcStartDateTime);

        // Add the offset to the given UTC
        //DateTime convertedStartDateTime = utcDateTime.addSeconds(offsetMillis/1000);
        //System.debug('convertedStartDateTime => ' + convertedStartDateTime + 'desiredTimeZone => ' + desiredTimeZone);

        //Adding additional date or hours to based on business hours
        DateTime utcEndDateTime = BusinessHours.add(businessHoursId, utcStartDateTime, intervalMilliseconds);

        // Add the offset to the convert to desired timezone
        DateTime convertedEndDateTime = utcEndDateTime.addSeconds(offsetMillis/1000);

        return convertedEndDateTime;
    }


    /*******************************************************************************************************
    * @description Utility Method to get location business hours using location timezone
    * @param timeZone of type String
    * @return Businesshours
    * @example
    * Phase 11a: Extracted from QuoteFavoritesController
    */
    private static List<Businesshours> getBusinessIdByTimeZone(string timeZone)
    {
        timeZone = 'WM SBS - ' + timeZone; //WM SBS - America/Los_Angeles
        List<Businesshours> businessHours = [SELECT Id, Name, TimeZoneSidKey, isActive FROM Businesshours WHERE isActive = True
                                    AND Name =: timeZone LIMIT 1];
        // system.debug('Fetching local time Picked Businesshours==>' + businessHours);
        return businessHours;
    }

    //Phase 11a: Extracted from QuoteFavoritesController
    //Phase 11b: Made public for EntitlementMatchingService
    public class currentDateTime{
        public string dayOfWeek;
        public string hours;
        public Datetime local;
        public currentDateTime(){
            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            local = now.addSeconds(offset/1000);
            dayOfWeek = local.formatGmt('EEE');
            hours = local.formatGmt('HH:mm');
            // system.debug('Current dayOfWeek==>'+ dayOfWeek);
            // system.debug('Current Date time hours==>'+hours);
        }

        public currentDateTime(String locationTimeZone){
            Datetime now = Datetime.now();
            Timezone timeZone = Timezone.getTimeZone(locationTimeZone);
            Integer offset = timeZone.getOffset(now);
            local = now.addSeconds(offset/1000);

            dayOfWeek = local.formatGmt('EEE');
            hours = local.formatGmt('HH:mm');
            system.debug('Current dayOfWeek==>'+ dayOfWeek);
            system.debug('Current Date time hours==>'+ hours);
        }
    }

    /**
     * @description Validation result wrapper class
     */
    public class ValidationResult {
        public Boolean isValid;
        public String errorMessage;
        public List<String> warnings;

        public ValidationResult() {
            this.isValid = false;
            this.warnings = new List<String>();
        }
    }
}
