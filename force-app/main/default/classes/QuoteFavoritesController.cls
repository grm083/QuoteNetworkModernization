public class QuoteFavoritesController {
    
    //Product Methods Start
    //getProducts() returns all products in the catalog that are CPQ eligible
    @AuraEnabled
    public static List<Product2> getProducts() {
        List<Product2> productList = [SELECT Id, Name, ProductCode, Family, Description, Container_Size__c
                                      FROM Product2
                                      WHERE ProductCode != Null AND SBQQ__Component__c = false AND
                                      SBQQ__PricingMethod__c != Null
                                      ORDER BY Name];
        return productList;
    }
    //searchProducts(queryString) returns all products based on a SOSL search of a query string
    @AuraEnabled
    public static List<Product2> searchProducts(String queryString){
        List<List<SObject>> queryResult = new List<List<SObject>>();
        List<Product2> queriedProducts = new List<Product2>();
        queryResult = [FIND :queryString IN ALL FIELDS
                       RETURNING Product2 (Id, Name, ProductCode, Family, Container_Size__c
                                           WHERE ProductCode != Null AND SBQQ__Component__c = false AND
                                           SBQQ__PricingMethod__c != Null)];
        
        queriedProducts = queryResult[0];
        
        return queriedProducts;
    }
    @AuraEnabled
    public static Product2 getPreselectedProduct(string selectedProductName){
        List<Product2> productList = new List<Product2>();
        productList = [SELECT Id, Name, ProductCode, Family 
                       FROM Product2  
                       WHERE ProductCode != Null 
                       AND SBQQ__Component__c = false 
                       AND SBQQ__PricingMethod__c != Null 
                       AND Name =:selectedProductName LIMIT 1];
        if(productList.size()>0){
            return productList[0];
        }
        return null;
    }
    //Product Methods End
    
    //Material Methods Starts
    //getWasteStreams(productId) returns the waste streams registered to the container type
    @AuraEnabled
    public static List<SBQQ__ProductOption__c> getWasteStreams(Id productId) {
        List<SBQQ__ProductOption__c> eligibleStreams = [SELECT Id, Name, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name, SBQQ__OptionalSKU__r.ProductCode
                                                        FROM SBQQ__ProductOption__c
                                                        WHERE SBQQ__ConfiguredSKU__c =: productId AND SBQQ__ProductFamily__c = 'Waste Category' And SBQQ__OptionalSKU__r.IsActive = true];
        Set<Id> categoryIds = new Set<Id>();
        for (SBQQ__ProductOption__c po : eligibleStreams) {
            categoryIds.add(po.SBQQ__OptionalSKU__c);
        }
        List<SBQQ__ProductOption__c> eligibleMaterials = [SELECT Id, Name, SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c, SBQQ__OptionalSKU__r.Name, 
                                                          SBQQ__OptionalSKU__r.ProductCode
                                                          FROM SBQQ__ProductOption__c
                                                          WHERE SBQQ__ConfiguredSKU__c IN :categoryIds
                                                          ORDER BY SBQQ__OptionalSKU__r.Name];
        return eligibleMaterials;
    }
    //Material Methods End
    
   
    // Changes by - Toshender Kumar
    // Correction in logic to match the picklist values with shown and hidden values. Earlier the logic was to check the string contains (LIKE logic), 
    // It is now amended to do exact match of equipment size. SDT-21768
    @AuraEnabled
    public static Map<String, String> getSizes(Id productId, Boolean returnAll) {
        Map<String, String> sizeMap = new Map<String, String>();
        List<SBQQ__ConfigurationAttribute__c> containerAtt = [SELECT Id, SBQQ__TargetField__c, SBQQ__Product__c, SBQQ__ShownValues__c, SBQQ__HiddenValues__c
                                                              FROM SBQQ__ConfigurationAttribute__c
                                                              WHERE SBQQ__Product__c =: productId AND SBQQ__TargetField__c = 'Equipment_Size__c'];
        List<Schema.PicklistEntry> sizePicklist = SBQQ__QuoteLine__c.Equipment_Size__c.getDescribe().getPicklistValues();
        if (returnAll){
            for (Schema.PicklistEntry ple: sizePicklist) {
                sizeMap.put(ple.value, ple.label);
            }
            return sizeMap;
        } else if (containerAtt.size() != 1) {
            sizeMap.put('UNK', 'Unknown');
            return sizeMap;
        } else {
            
            // The values in SBQQ__ShownValues__c and SBQQ__HiddenValues__c are stored with newline character separated.
            string SPLIT_KEY = '\n';
  
            String shownValues = containerAtt[0].SBQQ__ShownValues__c;
            List<String> lstShowValues = new List<String>();
            lstShowValues = Split(SPLIT_KEY,shownValues);   // Split by newline character

            system.debug('Shown Values are: ' + shownValues);
            String hiddenValues = containerAtt[0].SBQQ__HiddenValues__c;
            List<String> lsthiddenValues = new List<string>(); 
            lsthiddenValues = Split(SPLIT_KEY,hiddenValues); // Split by newline character
            
            for (Schema.PicklistEntry ple: sizePicklist) {
                if (!lstShowValues.isEmpty() && lstShowValues.contains(ple.value)) {
                    sizeMap.put(ple.value, ple.label);
                } else  if (!lsthiddenValues.isEmpty() && !lsthiddenValues.contains(ple.value)) {
                    sizeMap.put(ple.value, ple.label);
                } else if (lsthiddenValues.isEmpty() && lstShowValues.isEmpty()){
                    sizeMap.put(ple.value, ple.label);
                }
            }
            return sizeMap;
        }
    }

        // Splits the string based on the key provided
        // Changes by - Toshender Kumar
        // SDT-21768 
       private static List<String>  Split(string key, string stringToSplit ){
            
            if(stringToSplit!=null && !string.isEmpty(stringToSplit)){
               return stringToSplit.split(key); 
            }

            return new List<String>();
       }
    
    //Get Favorites given the context of a product
    @AuraEnabled(cacheable=true)
    public static List<FavoriteWrapper> getFavorites(Id productId){
        List<FavoriteWrapper> productFavorites = new List<FavoriteWrapper>();
        
        List<SBQQ__FavoriteProduct__c> productFavoriteDetails = [SELECT Id, SBQQ__Favorite__r.Name, SBQQ__Favorite__c, SBQQ__ConfigurationAttributes__c,
                                                                SBQQ__Product__r.Family, SBQQ__Product__r.Name, SBQQ__Quantity__c
                                                                FROM SBQQ__FavoriteProduct__c
                                                                WHERE SBQQ__Product__c =: productId OR
                                                                SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c =: productId
                                                                ORDER BY SBQQ__Favorite__c ASC];
        
        if(productFavoriteDetails.size() == 0) {
            return productFavorites;
        }
		/*
 		String favoriteIndex = '';
        FavoriteWrapper favoriteConfig = new FavoriteWrapper();
        for (SBQQ__FavoriteProduct__c fp : productFavoriteDetails) {
            favoriteIndex = (favoriteIndex == '') ? fp.SBQQ__Favorite__c : favoriteIndex;
 		*/
        
        Id favoriteIndex;
        FavoriteWrapper favoriteConfig = new FavoriteWrapper();
        system.debug('productFavoriteDetails--->'+ productFavoriteDetails);
        for (SBQQ__FavoriteProduct__c fp : productFavoriteDetails) {
            system.debug('favoriteIndex--->'+ favoriteIndex);
            system.debug('favoriteIndex2--->'+ favoriteIndex);
            if (favoriteIndex != fp.SBQQ__Favorite__c){
                productFavorites.add(favoriteConfig);
                favoriteConfig = new FavoriteWrapper();
                favoriteIndex = fp.SBQQ__Favorite__c;
                favoriteConfig.favoriteId = fp.SBQQ__Favorite__c;
            }
            if (fp.SBQQ__Product__r.Family == 'Waste Stream') {
                favoriteConfig.materialType = fp.SBQQ__Product__r.Name;
            }
            if (fp.SBQQ__Product__c == productId) {
                favoriteConfig.containerType = fp.SBQQ__Product__r.Name;
                favoriteConfig.quantity = fp.SBQQ__Quantity__c;
                String confAttributes = fp.SBQQ__ConfigurationAttributes__c;
                Map<String, Object> attributes = (Map<String, Object>) JSON.deserializeUntyped(confAttributes);
                favoriteConfig.equipmentSize = (String)attributes.get('Equipment_Size__c');
                favoriteConfig.ownership = (String)attributes.get('Ownership__c');
            }
        }
        productFavorites.add(favoriteConfig);

        return productFavorites;
    }

    //Call to centralized favorites method to write quote lines
    @AuraEnabled
    public static String addQuoteFavorite(Id favoriteId, Id quoteId) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = [SELECT Id, SBQQ__Opportunity2__r.Case__c
                FROM SBQQ__Quote__c
                WHERE Id =: quoteId];
        
        //Ref: QuoteProcurementController for documentation
        String returnedId = QuoteProcurementController.addQuoteandQuoteine(favoriteId, quote.SBQQ__Opportunity2__r.Case__c, quoteId, true);

        SBQQ__QuoteLine__c newQL = [SELECT Id, SBQQ__StartDate__c
                                    FROM SBQQ__QuoteLine__c
                                    WHERE SBQQ__ProductOption__c = null
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];

        //Date SLADateTime = NULL;//determineSLA(newQL.Id);
        //sdt-27107
        //newQL.SBQQ__StartDate__c = SLADateTime;
        //newQL.SBQQ__EndDate__c = SLADateTime;//added by seema
        //sdt-27107 end
        try {
            //update newQL;
            return newQL.Id;
        } catch (exception e) {
            system.debug(e.getMessage());
            return newQL.Id;
        }

    }
    
    @AuraEnabled
    public static String createNonFavoriteLine(Id quoteId, Id productId, Id wasteStream, String equipmentSize) {

        String successMessage;

        successMessage = QuoteProcurementController.createQuoteLines(quoteId, productId, wasteStream, equipmentSize);

        return successMessage;

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
    
    public class FavoriteWrapper{
        @AuraEnabled public String favoriteId {get; set;}
        @AuraEnabled public String containerType {get; set;}
        @AuraEnabled public String equipmentSize {get; set;}
        @AuraEnabled public String materialType {get; set;}
        @AuraEnabled public Decimal quantity {get; set;}
        @AuraEnabled public String ownership {get; set;}
        @AuraEnabled public Boolean quantityEditable {get; set;}
    }

    // Phase 11a: currentDateTime inner class moved to SLAManagementService
}
