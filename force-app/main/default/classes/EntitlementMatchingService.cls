/**
 * @description Service for Entitlement matching operations
 * Handles complex entitlement priority matching logic for SLA calculations
 * @author Quote Network Modernization Team
 * @date 2025-12-16
 * @story Phase 11b: Entitlement Matching
 */
public class EntitlementMatchingService {

    /**
     * @description Find matching entitlement based on 6-level priority logic
     * @param quoteId Quote ID
     * @param parentqLineId Parent Quote Line ID
     * @return Matched entitlement or null
     * @story SDT-24402, SDT-24917, SDT-24925, SDT-25065, SDT-25078, SDT-26160
     */
    public Entitlement getRelatedEntitleMent(String quoteId, String parentqLineId){
        Entitlement e;
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        SBQQ__QuoteLine__c pqLine = new SBQQ__QuoteLine__c();
        List<Entitlement> entList = new List<Entitlement>();
        List<Entitlement> newList = new List<Entitlement>();
        Map<String,String> statusApiToLabelMap = new Map<String,String>();
        currentDateTime currDateTime;
        quote = [SELECT id, Project__c, SBQQ__Opportunity2__r.Case__c, SBQQ__Account__c, SBQQ__Account__r.ParentId
                 FROM SBQQ__Quote__c
                 WHERE id = : quoteId];

        pqLine = [SELECT id, Name, SBQQ__Quote__c, Duration__c, SBQQ__ProductName__c, CreatedDate,
                    SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
                  FROM SBQQ__QuoteLine__c
                  WHERE Id = : parentqLineId
                  AND SBQQ__RequiredBy__c=null];
        List<Schema.PicklistEntry> values = SBQQ__QuoteLine__c.Duration__c.getDescribe().getPicklistValues();

		For(Schema.PicklistEntry sp : values){
            //Map to hold Picklist API as Key and Picklist Label as Value
            statusApiToLabelMap.put(sp.getValue(), sp.getLabel());
        }

        //Adding Order By Container Condition in the Query for Priority Logic - SDT-24925
        //SDT-25065 - Added a extra filter in the Where condition for Location or Parent Account
        entList = [SELECT Id, Request_Type__c, Service__c, AccountId, Project_Code__c, Container__c,
                Service_Guarantee_Category__c, Service_Guarantee_Category_Value__c, Call_On__c,
                Project__c, Location__c, Schedule_Type__c, Before_After__c,Call_Time__c
                FROM Entitlement
                WHERE Request_Type__c =: Constant_Util.NEW_SERVICE
                AND Status__c =:  Constant_Util.APPROVED
                AND (Container__c =: pqLine.SBQQ__ProductName__c OR Container__c = '' OR Container__c = null )
                AND ((AccountId =: quote.SBQQ__Account__r.ParentId AND Location__c =: quote.SBQQ__Account__c)
                    OR (AccountId =: quote.SBQQ__Account__r.ParentId AND Location__c = null))
                AND StartDate <= TODAY AND (EndDate = null OR EndDate >= TODAY) ORDER BY Container__c DESC];
        system.debug('Orignal List '+ entList);
        system.debug('Orignal List size '+ entList.size());

        if(!getSLASwitch()){
            for(Entitlement e1 : entList){
                currDateTime = new currentDateTime(pqLine.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c);
                //integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
                //integer callTime = Integer.valueOf(e1.Call_Time__c.split(':')[0]);
                If(e1.Before_After__c != null && (Constant_Util.BEFORE).equalsIgnorecase(e1.Before_After__c)){
                    if(currDateTime.hours <= e1.Call_Time__c)
                    {
                        newList.add(e1);
                    }
                }
                else If(e1.Before_After__c != null && (Constant_Util.AFTER).equalsIgnorecase(e1.Before_After__c)){
                    if(currDateTime.hours >= e1.Call_Time__c)
                    {
                        newList.add(e1);
                    }
                }
            }
        }
        else{
            newList = entList;
        }
        system.debug('Filter List '+ newList);
        system.debug('Orignal List size '+ newList.size());
        if(newList.size()>0){
            for(Entitlement ent: newList){
                //Projects for Locations - Priority 1
                //Adding Null Check for Project Code on Quote and Entitlement as part of SDT-26160
                if(quote.Project__c != null && ent.Project_Code__c != null){
                    if(quote.Project__c == ent.Project_Code__c &&
                        quote.SBQQ__Account__c == ent.Location__c)
                    {
                        system.debug('Priority 1 selected where Project Code and Location matched.');
                        e = ent;
                        break;
                    }
                    //Projects for Location's Parent Account - Priority 2
                    else if(quote.Project__c == ent.Project_Code__c &&
                            quote.SBQQ__Account__r.ParentId == ent.AccountId)
                    {
                        system.debug('Priority 2 selected where Project Code and Account matched.');
                        e = ent;
                        break;
                    }
                }
                //Duration and Container Match for Location - Priority 3
                else if(statusApiToLabelMap.get(pqLine.Duration__c) == ent.Schedule_Type__c &&
                        pqLine.SBQQ__ProductName__c == ent.Container__c &&
                        quote.SBQQ__Account__c  == ent.Location__c)
                {
                    system.debug('Priority 3 selected where ScheduleType, Container and Location matched.');
                    e = ent;
                    break;
                }
                //Duration Match for Location - - Priority 4
                else if(statusApiToLabelMap.get(pqLine.Duration__c) == ent.Schedule_Type__c &&
                        quote.SBQQ__Account__c == ent.Location__c)
                {
                    system.debug('Priority 4 selected where Duration and Location matched.');
                    e = ent;
                    break;
                }
                //Commenting Below logic as a part of SDT-24402 Discussion's to eliminate Priority 5 and 6 Logic
                //Container Match for Location
                /**else if(pqLine.SBQQ__ProductName__c == ent.Container__c &&
                        quote.SBQQ__Account__c == ent.Location__c)
                {
                    e = ent;
                    break;
                }
                //Entitlement for Location
                else if(quote.SBQQ__Account__c == ent.Location__c){
                    e = ent;
                    break;
                }*/
                //Duration and Container Match for Location's Parent Account -  Priority 5
                else if(statusApiToLabelMap.get(pqLine.Duration__c) == ent.Schedule_Type__c &&
                        pqLine.SBQQ__ProductName__c == ent.Container__c &&
                        quote.SBQQ__Account__r.ParentId == ent.AccountId)
                {
                    system.debug('Priority 5 selected where Duration, Container and Account matched.');
                    e = ent;
                    break;
                }
                //Duration Match for Location's Parent Account - Priority 6
                else if(statusApiToLabelMap.get(pqLine.Duration__c) == ent.Schedule_Type__c &&
                        quote.SBQQ__Account__r.ParentId == ent.AccountId)
                {
                    system.debug('Priority 6 selected where Duration and Account matched.');
                    e = ent;
                    break;
                }
                //Commenting Below logic as a part of SDT-25078 to eliminate Priority 9 Logic
                /*Entitlement for Location's Parent Account
                else if(quote.SBQQ__Account__r.ParentId == ent.AccountId)
                {
                    e = ent;
                    break;
                }*/
            }
        }
        return e;
    }

    /**
     * @description Get SLA switch status
     * Delegates to SLAManagementService
     * @return SLA switch status
     */
    private Boolean getSLASwitch() {
        SLAManagementService slaService = new SLAManagementService();
        return slaService.getSLASwitch();
    }

    /**
     * @description Inner class for current datetime calculations
     * Uses SLAManagementService.currentDateTime
     */
    private class currentDateTime {
        public String hours;

        public currentDateTime(String locationTimeZone) {
            // Delegate to SLAManagementService.currentDateTime
            SLAManagementService.currentDateTime slaDateTime = new SLAManagementService.currentDateTime(locationTimeZone);
            this.hours = slaDateTime.hours;
        }
    }
}
