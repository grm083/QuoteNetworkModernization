public class QuoteFavoritesController {
    
    //Product Methods Start
    //getProducts() returns all products in the catalog that are CPQ eligible
    @AuraEnabled
    public static List<Product2> getProducts() {
        // Phase 12: Delegate to ProductConfigurationService
        ProductConfigurationService service = new ProductConfigurationService();
        return service.getProducts();
    }
    //searchProducts(queryString) returns all products based on a SOSL search of a query string
    @AuraEnabled
    public static List<Product2> searchProducts(String queryString){
        // Phase 12: Delegate to ProductConfigurationService
        ProductConfigurationService service = new ProductConfigurationService();
        return service.searchProducts(queryString);
    }
    @AuraEnabled
    public static Product2 getPreselectedProduct(string selectedProductName){
        // Phase 12: Delegate to ProductConfigurationService
        ProductConfigurationService service = new ProductConfigurationService();
        return service.getPreselectedProduct(selectedProductName);
    }
    //Product Methods End
    
    //Material Methods Starts
    //getWasteStreams(productId) returns the waste streams registered to the container type
    @AuraEnabled
    public static List<SBQQ__ProductOption__c> getWasteStreams(Id productId) {
        // Phase 12: Delegate to ProductConfigurationService
        ProductConfigurationService service = new ProductConfigurationService();
        return service.getWasteStreams(productId);
    }
    //Material Methods End
    

    // Changes by - Toshender Kumar
    // Correction in logic to match the picklist values with shown and hidden values. Earlier the logic was to check the string contains (LIKE logic),
    // It is now amended to do exact match of equipment size. SDT-21768
    @AuraEnabled
    public static Map<String, String> getSizes(Id productId, Boolean returnAll) {
        // Phase 12: Delegate to ProductConfigurationService
        ProductConfigurationService service = new ProductConfigurationService();
        return service.getSizes(productId, returnAll);
    }
    
    //Get Favorites given the context of a product
    //Phase 13: Delegate to FavoritesService
    @AuraEnabled(cacheable=true)
    public static List<FavoritesService.FavoriteWrapper> getFavorites(Id productId){
        // Phase 13: Delegate to FavoritesService
        FavoritesService service = new FavoritesService();
        return service.getFavorites(productId);
    }

    //Call to centralized favorites method to write quote lines
    //Phase 13: Delegate to FavoritesService
    @AuraEnabled
    public static String addQuoteFavorite(Id favoriteId, Id quoteId) {
        // Phase 13: Delegate to FavoritesService
        FavoritesService service = new FavoritesService();
        return service.addQuoteFavorite(favoriteId, quoteId);
    }
    
    //Phase 13: Delegate to FavoritesService
    @AuraEnabled
    public static String createNonFavoriteLine(Id quoteId, Id productId, Id wasteStream, String equipmentSize) {
        // Phase 13: Delegate to FavoritesService
        FavoritesService service = new FavoritesService();
        return service.createNonFavoriteLine(quoteId, productId, wasteStream, equipmentSize);
    }
     /**************************************************************
    * Method name : determineSLAForAlternateProducts
    * Description :
    * Returns :  Date for input product (QLI wrapper)
    * Developer : Satnam Singh
    * User Story : SDT-29961
    * Phase 11a: Delegate to SLAManagementService
    ****************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String,Date> determineSLAForAlternateProducts(Id parentQuoteLineId,List<String> equipmentSizes){
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.determineSLAForAlternateProducts(parentQuoteLineId, equipmentSizes);
    }
    //Determine SLA for the quote line.  This is not invoked from the Lightning ComponentD
    //Phase 11a: Delegate to SLAManagementService
    public static DateTime determineSLA(Id parentQuoteLineId) {
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.determineSLA(parentQuoteLineId);
    }

    //Use entitlement to calculate SLA date
    /*public static DateTime calculateEntitlementSLA(Entitlement e, BusinessHours bh, SBQQ__QuoteLine__c parentQL) {
        DateTime additionalDate;
        Date targetDate;
        Time targetTime;
        currentDateTime currDateTime;
        Long milliseconds = 0;
        DateTime productSLA;
        Integer offset;
        //Changes for SDT-45007
        if(parentQL != null)
        {
            // system.debug('calculateEntitlementSLA - When have parent quoteline');
            currDateTime = new currentDateTime(parentQL.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c);
            Datetime now = Datetime.now();
            Timezone timeZone = Timezone.getTimeZone(parentQL.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c);
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
                if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c) && currentHour < 9){
                     if(serviceGuaranteeCategoryValue!=0 && serviceGuaranteeCategoryValue==1){
                        // system.debug('In currentHour < 9 - where SG+1');
                        serviceGuaranteeCategoryValue=serviceGuaranteeCategoryValue + 1;
                     }
                }
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
                }
                system.debug('serviceGuaranteeCategoryValue==> '+ serviceGuaranteeCategoryValue);
                milliseconds = serviceGuaranteeCategoryValue * 16 * 3600000;
                /*if(e.Before_After__c!='' && (Constant_Util.BEFORE).equalsIgnorecase(e.Before_After__c)){
                    targetDate = Date.newInstance((SlaStartDate).yearGmt(), (SlaStartDate).monthGmt(), (SlaStartDate).dayGmt());
                    targetTime = Time.newInstance(5, 0, 0, 0);
                    additionalDate = getadditionalDate(targetDate,targetTime,timeZone);
                }else {
                    targetDate = Date.newInstance((SlaStartDate).yearGmt(), (SlaStartDate).monthGmt(), ((SlaStartDate).dayGmt())+1);
                    targetTime = Time.newInstance(5, 0, 0, 0);
                    additionalDate = getadditionalDate(targetDate,targetTime,timeZone);
                }*/
                
                //milliseconds = Integer.valueOf(e.Service_Guarantee_Category_Value__c) * 24 * 3600000;
           /* }
        }*/
        /*if(milliseconds==0){
            productSLA = additionalDate;
        }else{
            productSLA = BusinessHours.add(bh.Id, system.now(), milliseconds);   
        }*/
        // system.debug('Business Hours==> '+ bh.Id);
        // system.debug('currDateTime.local==> '+ currDateTime.local);
        // system.debug('milliseconds==> '+ milliseconds);
       /* if(parentQL != null)
        {
            productSLA = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
            productSLA = productSLA.addSeconds(offset/1000);
        }
        else{
            productSLA = getBusinessHours(bh.Id, currDateTime.local, milliseconds);
        }
        // system.debug('productSLA From QF Controllers calculateEntitlementSLA--> ' + productSLA);
        return productSLA;
        
    }*/

    //Use entitlement to calculate SLA date
    //Phase 11a: Delegate to SLAManagementService
    public static DateTime calculateEntitlementSLA(Entitlement e, BusinessHours bh) {
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.calculateEntitlementSLA(e, bh);
    }

    //Use entitlement to calculate SLA date using location timezone
    //Phase 11a: Delegate to SLAManagementService
    public static DateTime calculateEntitlementSLA_LocTimezone(Entitlement e, BusinessHours bh, string locTimeZone) {
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.calculateEntitlementSLA_LocTimezone(e, bh, locTimeZone);
    }
    
    //Use industry standard to calculate SLA date
    //Phase 11a: Delegate to SLAManagementService
    public static DateTime calculateISSLA(Industry_Standard_SLA__mdt indStand, BusinessHours bh) {
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.calculateISSLA(indStand, bh);
    }

    //Use industry standard to calculate SLA date using location timezone
    //Phase 11a: Delegate to SLAManagementService
    public static DateTime calculateISSLA_LocTimezone(Industry_Standard_SLA__mdt indStand, BusinessHours bh, SBQQ__QuoteLine__c parentQL, String locTimeZone) {
        // Phase 11a: Delegate to SLAManagementService
        SLAManagementService service = new SLAManagementService();
        return service.calculateISSLA_LocTimezone(indStand, bh, parentQL, locTimeZone);
    }
    
    //this switch was created for switching off of new sla functionality(added as part of SDT-39637, SDT-45007, SDT-47970, SDT-47975), without actually
    //rolling back the code changes done.
    //Phase 11a: Delegate to SLAManagementService (kept as public for backward compatibility)
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
    * Phase 11a: Kept for backward compatibility - SLA logic now in SLAManagementService
    */
    private static DateTime getBusinessHours(Id businessHoursId,DateTime startDate, Long intervalMilliseconds){
        return BusinessHours.addGmt(businessHoursId, startDate, intervalMilliseconds);
    }
    
    //added by av4
    //Phase 11a: Kept for backward compatibility - SLA logic now in SLAManagementService
    public static DateTime getBusinessHoursInAccountTimeZone(Id businessHoursId,DateTime utcStartDateTime, Long intervalMilliseconds, String accTimeZone){
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
    * Phase 11a: Kept for backward compatibility - SLA logic now in SLAManagementService
    */
    public static List<Businesshours> getBusinessIdByTimeZone(string timeZone)
    {
        timeZone = 'WM SBS - ' + timeZone; //WM SBS - America/Los_Angeles
        List<Businesshours> businessHours = [SELECT Id, Name, TimeZoneSidKey, isActive FROM Businesshours WHERE isActive = True
                                    AND Name =: timeZone LIMIT 1];
        // system.debug('Fetching local time Picked Businesshours==>' + businessHours);
        return businessHours;
    }
    
    
    //Phase 11b: Delegate to EntitlementMatchingService
    public static Entitlement getRelatedEntitleMent(string quoteId, string parentqLineId){
        EntitlementMatchingService service = new EntitlementMatchingService();
        return service.getRelatedEntitleMent(quoteId, parentqLineId);
    }

    // Phase 11a: currentDateTime inner class moved to SLAManagementService
    // Phase 13: FavoriteWrapper inner class moved to FavoritesService
}
