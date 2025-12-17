/**
 * @description Service for Quote Line CRUD operations
 * Centralizes quote line creation, querying, and management logic
 * @author Quote Network Modernization Team
 * @date 2025-12-13
 * @story Phase 10.4: Quote Line Operations
 */
public class QuoteLineOperationsService {

    // ========================================================================
    // Phase 10.4: Quote Line Creation Operations
    // ========================================================================

    /**
     * @description Create quote lines from product configuration with waste stream
     * @param quoteId Quote ID
     * @param productId Product ID
     * @param wasteStream Waste stream product option ID
     * @param equipmentSize Equipment size
     * @return Success message with parent quote line ID or error message
     */
    public String createQuoteLines(Id quoteId, Id productId, Id wasteStream, String equipmentSize) {
        String successMessage;
        List<SBQQ__ErrorCondition__c> errorConditions = new List<SBQQ__ErrorCondition__c>();
        Set<Id> actionIds = new Set<Id>();
        Set<Id> addProducts = new Set<Id>();
        List<SBQQ__QuoteLine__c> insertQuoteLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> updateQuoteLines = new List<SBQQ__QuoteLine__c>();
        Map<String,Id> relationshipMap = new Map<String,Id>();

        SBQQ__ProductOption__c materialOption = getMaterialOption(wasteStream);
        SBQQ__ProductOption__c categoryOption = getCategoryOption(materialOption.SBQQ__ConfiguredSKU__c, productId);

        Decimal quoteLineNumber = getMaxQuoteLineNumber(quoteId);
        Decimal parentLineNumber = quoteLineNumber;

        SBQQ__QuoteLine__c parentQLine = QuoteLineServices.returnParentQuoteline(
            quoteId,
            productId,
            equipmentSize,
            'OC',
            true,
            1,
            quoteLineNumber
        );

        quoteLineNumber = quoteLineNumber + 3;

        try {
            insertQuoteLines.add(parentQLine);
        } catch (Exception e) {
           System.debug(e.getMessage());
        }

        // Get configuration rules
        errorConditions = SBQQConfigurationRuleService.getProductRules(productId);
        if (errorConditions.size() > 0) {
            actionIds = SBQQConfigurationRuleService.getActions(errorConditions, parentQLine);
            addProducts = SBQQConfigurationRuleService.getAddRuleProducts(actionIds);
        }

        // Query product options
        List<SBQQ__ProductOption__c> productOptions = [
            SELECT Id, Name, SBQQ__Quantity__c, Occurrence_Type__c, CostModelType__c,
                   Cost_Unit_of_Measure__c, PriceUOM__c, Schedule_Frequency__c, Frequency_Interval__c,
                   SBQQ__OptionalSKU__c, Equipment_Size__c, SBQQ__ProductFamily__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__ConfiguredSKU__c = :productId
            AND (SBQQ__Selected__c = true OR SBQQ__OptionalSKU__c IN :addProducts)
            AND SBQQ__ProductFamily__c != 'Waste Category'
            AND SBQQ__ProductFamily__c != 'Waste Stream'
        ];

        productOptions.add(categoryOption);
        productOptions.add(materialOption);

        // Create quote lines from product options
        for (SBQQ__ProductOption__c po : productOptions) {
            if (po.SBQQ__ProductFamily__c == 'Waste Category') {
                SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quoteId,
                    SBQQ__Product__c = po.SBQQ__OptionalSKU__c,
                    Equipment_Size__c = equipmentSize,
                    SBQQ__StartDate__c = NULL,
                    SBQQ__ProductOption__c = po.Id,
                    SBQQ__OptionLevel__c = 1,
                    SBQQ__Quantity__c = po.SBQQ__Quantity__c,
                    SBQQ__Number__c = parentLineNumber + 1,
                    SBQQ__CostEditable__c = false,
                    SBQQ__PriceEditable__c = true,
                    Occurrence_Type__c = po.Occurrence_Type__c,
                    CostModelType__c = po.CostModelType__c,
                    Cost_Unit_of_Measure__c = po.Cost_Unit_of_Measure__c,
                    PriceUOM__c = po.PriceUOM__c,
                    Schedule_Frequency__c = po.Schedule_Frequency__c,
                    Frequency_Interval__c = po.Frequency_Interval__c
                );

                try {
                    insertQuoteLines.add(qLine);
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
            } else {
                SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quoteId,
                    SBQQ__Product__c = po.SBQQ__OptionalSKU__c,
                    Equipment_Size__c = equipmentSize,
                    SBQQ__ProductOption__c = po.Id,
                    SBQQ__OptionLevel__c = po.SBQQ__ProductFamily__c == 'Waste Stream' ? 2 : 1,
                    SBQQ__Number__c = po.SBQQ__ProductFamily__c == 'Waste Stream' ? parentLineNumber + 2 : quoteLineNumber,
                    SBQQ__CostEditable__c = po.SBQQ__ProductFamily__c == 'Waste Stream' ? false : true,
                    SBQQ__PriceEditable__c = po.SBQQ__ProductFamily__c == 'Waste Stream' ? false : true,
                    SBQQ__Quantity__c = po.SBQQ__Quantity__c,
                    SBQQ__StartDate__c = parentQLine.SBQQ__StartDate__c,
                    Occurrence_Type__c = po.Occurrence_Type__c,
                    CostModelType__c = po.CostModelType__c,
                    Cost_Unit_of_Measure__c = po.Cost_Unit_of_Measure__c,
                    PriceUOM__c = po.PriceUOM__c,
                    Schedule_Frequency__c = po.Schedule_Frequency__c,
                    Frequency_Interval__c = po.Frequency_Interval__c
                );

                insertQuoteLines.add(qLine);
                quoteLineNumber = quoteLineNumber + 1;
            }
        }

        try {
            insert insertQuoteLines;

            // Get all inserted IDs
            Set<Id> allInsertedIds = new Set<Id>();
            for (SBQQ__QuoteLine__c quoteLineObj : insertQuoteLines) {
                allInsertedIds.add(quoteLineObj.Id);
            }

            List<SBQQ__QuoteLine__c> insertedLines = QuoteLineServices.getQuoteLinesByIds(allInsertedIds);

            // Haul Away Service (SDT-44574)
            Id haulAwayVendorId;
            Boolean isHaulAway = HaulAwayService.getIsHaulAwayServiceForQuote(quoteId);

            if (isHaulAway) {
                for (SBQQ__QuoteLine__c quoteLineObj : insertedLines) {
                    if (quoteLineObj.SBQQ__RequiredBy__c == null && haulAwayVendorId == null) {
                        String vendor = quoteLineObj.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Haul_Away_Vendor__c;
                        String location = quoteLineObj.SBQQ__Quote__r.SBQQ__ShippingCountry__c;
                        String hVendor = HaulAwayService.getHaulAwayVendorByLocation(vendor, location);
                        haulAwayVendorId = HaulAwayService.getHaulAwayVendor(hVendor);
                        quoteLineObj.Vendor__c = haulAwayVendorId;
                    }
                }
            }

            // Build relationship map
            for (SBQQ__QuoteLine__c quoteLineObj : insertedLines) {
                if (isHaulAway && haulAwayVendorId != null) {
                    quoteLineObj.Vendor__c = haulAwayVendorId;
                }

                if (quoteLineObj.SBQQ__Bundle__c) {
                    relationshipMap.put('ParentQuote', quoteLineObj.Id);
                }

                if (quoteLineObj.SBQQ__ProductFamily__c == 'Waste Category') {
                    relationshipMap.put('WasteCategory', quoteLineObj.Id);
                }
            }

            Boolean isExtraPickup = false;

            // Update relationships
            for (SBQQ__QuoteLine__c quoteLineObj : insertedLines) {
                if (quoteLineObj.SBQQ__Bundle__c) {
                    updateQuoteLines.add(quoteLineObj);
                }
                if (quoteLineObj.SBQQ__ProductFamily__c == 'Waste Stream') {
                    quoteLineObj.SBQQ__RequiredBy__c = relationshipMap.get('WasteCategory');
                    updateQuoteLines.add(quoteLineObj);
                } else if (quoteLineObj.SBQQ__Bundle__c != true && quoteLineObj.SBQQ__ProductFamily__c != 'Waste Stream') {
                    quoteLineObj.SBQQ__RequiredBy__c = relationshipMap.get('ParentQuote');
                    updateQuoteLines.add(quoteLineObj);

                    if (quoteLineObj.SBQQ__RequiredBy__c != null && quoteLineObj.SBQQ__ProductName__c == Constant_Util.EXTRA_PICKUP) {
                        isExtraPickup = true;
                    }
                }
            }

            // Handle extra pickup flag
            if (isExtraPickup) {
                for (SBQQ__QuoteLine__c quotePickupLine : updateQuoteLines) {
                    if (quotePickupLine.SBQQ__ProductName__c == Constant_Util.PICKUP_CSTYPE &&
                        quotePickupLine.Occurrence_Type__c == Constant_Util.SCHEDULED_TYPE) {
                        quotePickupLine.IsExtraPickup__c = true;
                    }
                }
            }

            update updateQuoteLines;
            successMessage = relationshipMap.get('ParentQuote');

        } catch (Exception e) {
            successMessage = e.getMessage();
        }

        return successMessage;
    }

    /**
     * @description Add quote and quote lines from favorite products
     * @param favoriteId Favorite product ID
     * @param caseId Case ID
     * @param quoteID Quote ID (optional, created if not provided)
     * @param quoteScreen Boolean indicating if called from quote screen
     * @return Quote ID
     */
    public String addQuoteAndQuoteLine(String favoriteId, String caseId, String quoteID, Boolean quoteScreen) {
        Decimal parentLineNumber;

        System.debug('FavoriteId, CaseId: ' + favoriteId + ' ' + caseId);

        List<SBQQ__FavoriteProduct__c> favorites = [
            SELECT Id, Name, SBQQ__ConfigurationAttributes__c, SBQQ__Favorite__c, SBQQ__Product__c,
                   SBQQ__Product__r.Name, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, SBQQ__Quantity__c,
                   SBQQ__ProductOption__c, SBQQ__ProductOption__r.SBQQ__Type__c, SBQQ__ProductOption__r.Occurrence_Type__c,
                   SBQQ__ProductOption__r.CostModelType__c, SBQQ__ProductOption__r.Cost_Unit_of_Measure__c, SBQQ__ProductOption__r.PriceUOM__c,
                   SBQQ__ProductOption__r.Schedule_Frequency__c, SBQQ__ProductOption__r.Frequency_Interval__c, SBQQ__ProductOption__r.SBQQ__Quantity__c, SBQQ__ProductOption__r.SBQQ__ProductFamily__c
            FROM SBQQ__FavoriteProduct__c
            WHERE SBQQ__Favorite__c = :favoriteId
            ORDER BY SBQQ__Favorite__c, SBQQ__RequiredBy__c
        ];

        System.debug('favorites: ' + favorites);

        SBQQ__Quote__c quote;

        if (!quoteScreen) {
            quoteID = GetCaseInformation.createOppQuote(caseId);
            System.debug('quoteID: ' + quoteID);
            quote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id = :quoteID];
            parentLineNumber = 1;
        } else {
            quote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id = :quoteID];
        }

        List<SBQQ__QuoteLine__c> maxQL = [
            SELECT SBQQ__Number__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteID
            ORDER BY SBQQ__Number__c DESC
            LIMIT 1
        ];

        parentLineNumber = maxQL.size() > 0 ? maxQL[0].SBQQ__Number__c : 1;

        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        Map<String, Object> plAttributes = (Map<String, Object>)JSON.deserializeUntyped(favorites[0].SBQQ__ConfigurationAttributes__c);
        System.debug('plAttributes: ' + plAttributes);

        String equipmentPql = String.valueOf(plAttributes.get('Equipment_Size__c'));
        String occurrenceType = String.valueOf(plAttributes.get('Occurrence_Type__c'));
        System.debug('equipmentPql: ' + equipmentPql);

        SBQQ__QuoteLine__c parentQLine = QuoteLineServices.returnParentQuoteline(
            quote.Id,
            favorites[0].SBQQ__Product__c,
            equipmentPql,
            occurrenceType,
            true,
            favorites[0].SBQQ__ProductOption__r.SBQQ__Quantity__c,
            parentLineNumber
        );

        Product2 product = [SELECT ID, SBQQ__PricingMethod__c FROM Product2 WHERE ID = :parentQLine.SBQQ__Product__c];
        System.debug('parentQLine: ' + parentQLine);
        insert parentQLine;
        System.debug('parentQLine after insert: ' + parentQLine);

        String qLineID = parentQLine.Id;
        Double currLineNumber = parentLineNumber + 3;
        String wasteCategoryId;
        System.debug('qLineID: ' + qLineID);

        Date SLADate = null;

        parentQLine.SBQQ__StartDate__c = SLADate;
        quoteLineList.add(parentQLine);

        if (qLineID != '') {
            for (Integer i = 1; i < favorites.size(); i++) {
                System.debug('favorites[i]: ' + favorites[i].SBQQ__Product__c);
                Map<String, Object> attributes = (Map<String, Object>)JSON.deserializeUntyped(favorites[i].SBQQ__ConfigurationAttributes__c);
                String equipmentSize = String.valueOf(attributes.get('Equipment_Size__c'));
                String productFamily = favorites[i].SBQQ__ProductOption__r.SBQQ__ProductFamily__c;

                if (productFamily == 'Waste Category') {
                    SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = favorites[i].SBQQ__Product__c,
                        Equipment_Size__c = equipmentSize,
                        SBQQ__RequiredBy__c = parentQLine.Id,
                        SBQQ__ProductOption__c = favorites[i].SBQQ__ProductOption__c,
                        SBQQ__Favorite__c = favorites[i].SBQQ__Favorite__c,
                        SBQQ__OptionLevel__c = 1,
                        SBQQ__Quantity__c = favorites[i].SBQQ__ProductOption__r.SBQQ__Quantity__c,
                        SBQQ__Number__c = parentLineNumber + 1,
                        Occurrence_Type__c = favorites[i].SBQQ__ProductOption__r.Occurrence_Type__c,
                        CostModelType__c = favorites[i].SBQQ__ProductOption__r.CostModelType__c,
                        Cost_Unit_of_Measure__c = favorites[i].SBQQ__ProductOption__r.Cost_Unit_of_Measure__c,
                        PriceUOM__c = favorites[i].SBQQ__ProductOption__r.PriceUOM__c,
                        Schedule_Frequency__c = favorites[i].SBQQ__ProductOption__r.Schedule_Frequency__c,
                        Frequency_Interval__c = favorites[i].SBQQ__ProductOption__r.Frequency_Interval__c,
                        SBQQ__StartDate__c = SLADate,
                        SBQQ__EndDate__c = SLADate
                    );

                    try {
                        insert qLine;
                        wasteCategoryId = qLine.Id;
                    } catch (Exception e) {
                        System.debug('An error occurred during waste category insert. Error is: ' + e.getMessage());
                    }
                } else {
                    SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = favorites[i].SBQQ__Product__c,
                        Equipment_Size__c = equipmentSize,
                        SBQQ__RequiredBy__c = productFamily == 'Waste Stream' ? wasteCategoryId : parentQLine.Id,
                        SBQQ__ProductOption__c = favorites[i].SBQQ__ProductOption__c,
                        SBQQ__Favorite__c = favorites[i].SBQQ__Favorite__c,
                        SBQQ__OptionLevel__c = productFamily == 'Waste Stream' ? 2 : 1,
                        SBQQ__Number__c = productFamily == 'Waste Stream' ? parentLineNumber + 2 : currLineNumber,
                        SBQQ__CostEditable__c = productFamily == 'Waste Stream' ? false : true,
                        SBQQ__PriceEditable__c = productFamily == 'Waste Stream' ? false : true,
                        SBQQ__Quantity__c = favorites[i].SBQQ__ProductOption__r.SBQQ__Quantity__c,
                        Occurrence_Type__c = favorites[i].SBQQ__ProductOption__r.Occurrence_Type__c,
                        CostModelType__c = favorites[i].SBQQ__ProductOption__r.CostModelType__c,
                        Cost_Unit_of_Measure__c = favorites[i].SBQQ__ProductOption__r.Cost_Unit_of_Measure__c,
                        PriceUOM__c = favorites[i].SBQQ__ProductOption__r.PriceUOM__c,
                        Schedule_Frequency__c = favorites[i].SBQQ__ProductOption__r.Schedule_Frequency__c,
                        Frequency_Interval__c = favorites[i].SBQQ__ProductOption__r.Frequency_Interval__c,
                        SBQQ__StartDate__c = SLADate,
                        SBQQ__EndDate__c = SLADate
                    );

                    quoteLineList.add(qLine);
                    currLineNumber = currLineNumber + 1;
                    System.debug('equipmentSize: ' + equipmentSize);
                }
            }

            upsert quoteLineList;
            System.debug('quoteLineList: ' + quoteLineList);
        }

        System.debug('quoteID final: ' + quoteID);
        return quoteID;
    }

    // ========================================================================
    // Phase 10.4: Quote Line Query Operations
    // ========================================================================

    /**
     * @description Get quote products (header records) for a quote
     * @param quoteId Quote ID
     * @return List of quote line header records
     */
    public List<SBQQ__QuoteLine__c> getQuoteProducts(Id quoteId) {
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id,PricingUnitMethod__c, SBQQ__Quote__c,Vendor__r.Status__c,Vendor_Commit_Date__c ,SBQQ__Quote__r.STP__c, SBQQ__ListPrice__c, SBQQ__UnitCost__c, SBQQ__ProductName__c, SBQQ__ProductFamily__c, SBQQ__ProductCode__c,
                   Vendor__c, Vendor__r.Vendor_Business_Unit__c, Vendor__r.Parent_Vendor_Id__c, Vendor__r.Name, Vendor__r.AccountNumber,
                   Occurrence_Type__c, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c, SBQQ__Quantity__c, Name,
                   PriceUOM__c, PriceMinQuantity__c, SBQQ__PricingMethod__c, CostModelType__c, Cost_Unit_of_Measure__c, Account__c,
                   CostMinQuantity__c, MASLibrary__c, MASCompany__c, MASAccount__c, MASCustomerUniqueId__c, MASServiceLine__c,
                   MASBox__c, BypassPriceReview__c, BypassMASServiceChange__c, SetupComment__c, DoNotCreateMASTicket__c, DoNotCreateTaskGridTickets__c, Location_Position_Name__c,
                   SBQQ__RequiredBy__c, toLabel(Equipment_Size__c), toLabel(Duration__c), SBQQ__StartDate__c, SBQQ__EndDate__c, sCode__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                   Vendor__r.Contact_Manually_Vendor__c, Vendor__r.Prepayment_Required__c, SBQQ__Quote__r.Case_Type__c, SBQQ__Quote__r.SBQQ__Status__c, CompanyCategoryCode__c,MaterialGrade__c,CompanyCategoryName__c,
                   SBQQ__Quote__r.SBQQ__Account__r.Parent.AccountNumber, SBQQ__Quote__r.Name, SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name,
                   SBQQ__Quote__r.SBQQ__PrimaryContact__r.Id, Certificate_of_Destruction__c, Certificate_of_Disposal__c, VCRCode__c, Service_Schedule__c,
                   SBQQ__Number__c, SBQQ__Quote__r.Quote_Only__c, Profile_Number__c, Description_of_Waste__c, SBQQ__Product__c, SBQQ__Product__r.SBQQ__QuantityEditable__c,
                   SLA_Override_Reason__c, SLA_Override_Comment__c,ProcurementErrorMessage__c,BundleProcuredStatus__c, CurrencyIsoCode,
                   SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Recordtype.Name,AAV_Delivery_Override_Comment__c,AAV_Delivery_Override_Reason__c,
                   AAV_Service_Override_Reason__c,AAV_Service_Day_Override_Comment__c,
                   AAV_Requested_AdditionalServicesAccessor__c,AAV_Delivery_Availability__c,AAV_Service_Availability__c,Availability_Flag__c,
                   AAV_Asset_Availability_API_Errors__c,
                   Vendor__r.FacilityCode__c
                   ,Quote_Only_Copy_of__c,SBQQ__Quote__r.SBQQ__Type__c,CustomerApproval__c
                   ,Day_of_Month__c,Month_Relative_Interval__c,Month_Relative__c,
                   SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Is_Haul_Away_Service__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            AND SBQQ__RequiredBy__c = null
        ];

        System.debug('Quote lines returned: ' + quoteLines.size());
        return quoteLines;
    }

    /**
     * @description Get quote line MAS details
     * @param quoteLineId Quote line ID
     * @return List of quote lines with MAS details
     */
    public List<SBQQ__QuoteLine__c> getQuoteLineMASDetails(Id quoteLineId) {
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id,Vendor__r.Status__c,PricingUnitMethod__c,Vendor_Commit_Date__c,SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Case_Type__c,SBQQ__Quote__r.STP__c,MASLibrary__c, MASCompany__c, MASAccount__c, MASCustomerUniqueId__c, MASServiceLine__c,
                   MASBox__c, BypassPriceReview__c, BypassMASServiceChange__c, SetupComment__c, DoNotCreateMASTicket__c
                   ,DoNotCreateTaskGridTickets__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name
                   ,Vendor__c,Vendor__r.FacilityCode__c, Vendor__r.Vendor_Business_Unit__c,
                   SBQQ__Product__R.family
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLineId
        ];

        return quoteLines;
    }

    /**
     * @description Get quote line details (child records)
     * @param quoteLineId Parent quote line ID
     * @return List of detail quote lines
     */
    public List<SBQQ__QuoteLine__c> getQuoteDetails(Id quoteLineId) {
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id, SBQQ__Quote__c,PricingUnitMethod__c,Vendor__r.Status__c,Vendor_Commit_Date__c, SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Case_Type__c,SBQQ__Quote__r.STP__c,
                   SBQQ__ListPrice__c, SBQQ__UnitCost__c, SBQQ__ProductName__c, SBQQ__ProductCode__c, SBQQ__ProductFamily__c,
                   Vendor__c,Vendor__r.Vendor_Business_Unit__c, Vendor__r.Parent_Vendor_Id__c, Vendor__r.Name, Vendor__r.AccountNumber,
                   Occurrence_Type__c, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c,SBQQ__Cost__c, SBQQ__Quantity__c, Name,
                   PriceUOM__c, PriceMinQuantity__c, SBQQ__PricingMethod__c, CostModelType__c, Cost_Unit_of_Measure__c, ErrorComments__c,
                   CostMinQuantity__c, MASLibrary__c, MASCompany__c, MASAccount__c, MASCustomerUniqueId__c, MASServiceLine__c,
                   MASBox__c, BypassPriceReview__c, BypassMASServiceChange__c, SetupComment__c, DoNotCreateMASTicket__c, Location_Position_Name__c,
                   SBQQ__RequiredBy__c, Equipment_Size__c, Duration__c, SBQQ__StartDate__c, SBQQ__EndDate__c, sCode__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                   SBQQ__Quote__r.SBQQ__Status__c,Bypass_Acorn_Integration__c, VCRCode__c, SBQQ__Product__c, SBQQ__Product__r.SBQQ__QuantityEditable__c,
                   Pricing_API_Method__c, CurrencyIsoCode, Cost_Compare_Message__c,IsAssetQuotelineDifferent__c,SBQQ__Quote__r.Case_record_Type__c,
                   SBQQ__RequiredBy__r.SBQQ__ProductName__c, SBQQ__Product__R.Name, SBQQ__RequiredBy__r.Equipment_Size__c, SBQQ__RequiredBy__r.AssetId__r.Equipment_Size__c,
                   SBQQ__RequiredBy__r.SBQQ__ProductFamily__c, AssetId__c,
                   DoNotCreateTaskGridTickets__c, CostPrice1__c, CostPrice2__c, PricePrice1__c, PricePrice2__c
            FROM SBQQ__QuoteLine__c
            WHERE (SBQQ__RequiredBy__c = :quoteLineId OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :quoteLineId)
            AND SBQQ__ProductFamily__c != 'Waste Category'
        ];

        // Assign error messages
        if (quoteLines.size() > 0) {
            for (SBQQ__QuoteLine__c qLine : quoteLines) {
                if (!(QuoteProcurementController.wasteCategorySet.contains(qLine.SBQQ__ProductFamily__c)) &&
                    qLine.SBQQ__RequiredBy__c != null &&
                    qLine.Bypass_Acorn_Integration__c == false) {
                    qLine.ErrorComments__c = QuoteProcurementController.assignQuoteLineErrorMEssage(qLine);
                }
            }
        }

        return quoteLines;
    }

    // ========================================================================
    // Phase 10.4: Supporting Methods
    // ========================================================================

    /**
     * @description Get material option (waste stream) product option
     * @param wasteStream Waste stream product option ID
     * @return Material option record
     */
    public SBQQ__ProductOption__c getMaterialOption(String wasteStream) {
        SBQQ__ProductOption__c materialOption = [
            SELECT Id, Name, SBQQ__Quantity__c, Occurrence_Type__c, CostModelType__c,
                   Cost_Unit_of_Measure__c, PriceUOM__c, Schedule_Frequency__c, Frequency_Interval__c,
                   SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c, Equipment_Size__c, SBQQ__ProductFamily__c
            FROM SBQQ__ProductOption__c
            WHERE Id = :wasteStream
            LIMIT 1
        ];
        return materialOption;
    }

    /**
     * @description Get category option (waste category) product option
     * @param materialParentSKU Material parent SKU
     * @param productId Product ID
     * @return Category option record
     */
    public SBQQ__ProductOption__c getCategoryOption(String materialParentSKU, String productId) {
        SBQQ__ProductOption__c categoryOption = [
            SELECT Id, Name, SBQQ__Quantity__c, Occurrence_Type__c, CostModelType__c,
                   Cost_Unit_of_Measure__c, PriceUOM__c, Schedule_Frequency__c, Frequency_Interval__c,
                   SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c, Equipment_Size__c, SBQQ__ProductFamily__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__OptionalSKU__c = :materialParentSKU
            AND SBQQ__ConfiguredSKU__c = :productId
            LIMIT 1
        ];
        return categoryOption;
    }

    /**
     * @description Get next available quote line number for a quote
     * @param quoteId Quote ID
     * @return Next quote line number (max + 1)
     */
    private Decimal getMaxQuoteLineNumber(String quoteId) {
        List<SBQQ__QuoteLine__c> maxQL = [
            SELECT SBQQ__Number__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            ORDER BY SBQQ__Number__c DESC
            LIMIT 1
        ];

        Decimal quoteLineNumber = (maxQL.size() > 0) ? maxQL[0].SBQQ__Number__c + 1 : 1;
        return quoteLineNumber;
    }
}
