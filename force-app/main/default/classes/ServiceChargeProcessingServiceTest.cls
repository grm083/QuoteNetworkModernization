/**
 * @description Test class for ServiceChargeProcessingService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class ServiceChargeProcessingServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Customer',
            AccountNumber = 'CUST001'
        );
        insert testAccount;

        // Create vendor account
        Account vendor = new Account(
            Name = 'WM US Vendor',
            Vendor_ID__c = 'WM_US',
            Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR,
            Status__c = 'Active',
            Customer_Code__c = 'WM001'
        );
        insert vendor;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        // Create test products
        List<Product2> products = new List<Product2>{
            new Product2(
                Name = 'Rolloff Container',
                ProductCode = 'ROLL001',
                Family = 'Rolloff',
                IsActive = true
            ),
            new Product2(
                Name = 'Delivery Service',
                ProductCode = 'DLV',
                Family = 'Service',
                IsActive = true,
                SBQQ__PricingMethod__c = 'List'
            ),
            new Product2(
                Name = Constant_Util.ENERGY_SURCHARGE,
                ProductCode = 'ESC',
                Family = 'Service',
                IsActive = true
            )
        };
        insert products;

        // Create product option
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = products[0].Id,
            SBQQ__OptionalSKU__c = products[1].Id,
            Occurrence_Type__c = 'SCH',
            Schedule_Frequency__c = 'Weekly',
            Frequency_Interval__c = 1,
            Cost_Unit_of_Measure__c = 'EA',
            PriceUOM__c = 'EA',
            CostModelType__c = 'List'
        );
        insert productOption;

        // Create quote lines
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[0].Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = vendor.Id,
                Equipment_Size__c = '10YD',
                Duration__c = 12,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addMonths(12)
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[1].Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = vendor.Id,
                SBQQ__ProductCode__c = 'DLV',
                SBQQ__UnitCost__c = 100,
                SBQQ__ListPrice__c = 150
            )
        };
        insert quoteLines;

        // Set parent relationship
        quoteLines[1].SBQQ__RequiredBy__c = quoteLines[0].Id;
        update quoteLines[1];
    }

    /**
     * @description Test getting active service charge configs
     */
    @isTest
    static void testGetActiveServiceChargeConfigs() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        List<ServiceChargeProcessingService.ServiceChargeConfig> configs = service.getActiveServiceChargeConfigs();
        Test.stopTest();

        System.assertNotEquals(null, configs, 'Should return configs list');
        // Note: Actual count depends on metadata in org
    }

    /**
     * @description Test process Allow action with new quote line
     */
    @isTest
    static void testProcessServiceChargeAction_AllowCreateNew() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.serviceChargeCode = 'DLV';
        config.actionName = 'Allow';
        config.isCreateQuoteLine = true;
        config.isDeleteQuoteLine = false;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Allow',
            100.00,
            150.00,
            null, // No existing quote line
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.createNewLine, 'Should create new line');
        System.assertEquals(false, result.updateExisting, 'Should not update existing');
        System.assertEquals(false, result.deleteExisting, 'Should not delete');
        System.assertEquals(false, result.skipProcessing, 'Should not skip');
    }

    /**
     * @description Test process Allow action with existing quote line
     */
    @isTest
    static void testProcessServiceChargeAction_AllowUpdateExisting() {
        SBQQ__QuoteLine__c existingLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'DLV' LIMIT 1];

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.serviceChargeCode = 'DLV';
        config.actionName = 'Allow';
        config.isCreateQuoteLine = true;
        config.isDeleteQuoteLine = false;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Allow',
            100.00,
            150.00,
            existingLine,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(false, result.createNewLine, 'Should not create new line');
        System.assertEquals(true, result.updateExisting, 'Should update existing');
        System.assertEquals(false, result.deleteExisting, 'Should not delete');
    }

    /**
     * @description Test process Adjust action (same as Allow)
     */
    @isTest
    static void testProcessServiceChargeAction_Adjust() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Adjust';
        config.isCreateQuoteLine = true;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Adjust',
            100.00,
            150.00,
            null,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.createNewLine, 'Adjust should behave like Allow');
    }

    /**
     * @description Test process null action (treated as Allow)
     */
    @isTest
    static void testProcessServiceChargeAction_NullAction() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = null;
        config.isCreateQuoteLine = true;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            null,
            100.00,
            150.00,
            null,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.createNewLine, 'Null action should behave like Allow');
    }

    /**
     * @description Test process Exclude action with delete
     */
    @isTest
    static void testProcessServiceChargeAction_ExcludeWithDelete() {
        SBQQ__QuoteLine__c existingLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'DLV' LIMIT 1];

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Exclude';
        config.isCreateQuoteLine = false;
        config.isDeleteQuoteLine = true;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Exclude',
            null,
            null,
            existingLine,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(false, result.createNewLine, 'Should not create');
        System.assertEquals(false, result.updateExisting, 'Should not update');
        System.assertEquals(true, result.deleteExisting, 'Should delete existing line');
    }

    /**
     * @description Test process Exclude action with zero out
     */
    @isTest
    static void testProcessServiceChargeAction_ExcludeWithZero() {
        SBQQ__QuoteLine__c existingLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'DLV' LIMIT 1];

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Exclude';
        config.isCreateQuoteLine = false;
        config.isDeleteQuoteLine = false; // Don't delete, just zero out
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Exclude',
            null,
            null,
            existingLine,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(false, result.createNewLine, 'Should not create');
        System.assertEquals(true, result.updateExisting, 'Should update to zero');
        System.assertEquals(false, result.deleteExisting, 'Should not delete');
    }

    /**
     * @description Test process Manual Review action
     */
    @isTest
    static void testProcessServiceChargeAction_ManualReview() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Manual Review';

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Manual Review',
            100.00,
            150.00,
            null,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.skipProcessing, 'Manual Review should skip processing');
        System.assertNotEquals(null, result.skipReason, 'Should have skip reason');
    }

    /**
     * @description Test skip when both cost and price are null
     */
    @isTest
    static void testProcessServiceChargeAction_NullCostAndPrice() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Allow';
        config.isCreateQuoteLine = true;
        config.additionalProcessingNeeded = false;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Allow',
            null, // Null cost
            null, // Null price
            null,
            config,
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.skipProcessing, 'Should skip when both cost and price are null');
    }

    /**
     * @description Test additional processing needed with override false
     */
    @isTest
    static void testProcessServiceChargeAction_AdditionalProcessingNoOverride() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        ServiceChargeProcessingService.ServiceChargeConfig config = new ServiceChargeProcessingService.ServiceChargeConfig();
        config.serviceChargeName = 'Delivery';
        config.actionName = 'Allow';
        config.isCreateQuoteLine = true;
        config.additionalProcessingNeeded = true;

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeActionResult result = service.processServiceChargeAction(
            'Delivery Service',
            'Allow',
            100.00,
            150.00,
            null,
            config,
            false // Override is false
        );
        Test.stopTest();

        System.assertEquals(true, result.skipProcessing, 'Should skip when additional processing needed but no override');
    }

    /**
     * @description Test apply cost and price with fixed values
     */
    @isTest
    static void testApplyCostAndPrice_FixedValues() {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyCostAndPrice(
            quoteLine,
            100.00,
            150.00,
            null, // Fixed value type
            null, // Fixed value type
            'EA',
            'EA'
        );
        Test.stopTest();

        System.assertEquals(100.00, result.SBQQ__UnitCost__c, 'Should set unit cost');
        System.assertEquals(150.00, result.SBQQ__ListPrice__c, 'Should set list price');
        System.assertEquals('EA', result.Cost_Unit_of_Measure__c, 'Should set cost UOM');
        System.assertEquals('EA', result.PriceUOM__c, 'Should set price UOM');
    }

    /**
     * @description Test apply cost and price with percentage values
     */
    @isTest
    static void testApplyCostAndPrice_PercentageValues() {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyCostAndPrice(
            quoteLine,
            10.00,
            15.00,
            Constant_Util.PERCENT,
            Constant_Util.PERCENT,
            'PCT',
            'PCT'
        );
        Test.stopTest();

        System.assertEquals(10.00, result.SBQQ__SubscriptionPercent__c, 'Should set subscription percent');
        System.assertEquals(0.00, result.SBQQ__UnitCost__c, 'Should set unit cost to zero');
        System.assertEquals(15.00, result.SBQQ__MarkupRate__c, 'Should set markup rate');
        System.assertEquals(0.00, result.SBQQ__ListPrice__c, 'Should set list price to zero');
    }

    /**
     * @description Test set zero cost and price
     */
    @isTest
    static void testSetZeroCostAndPrice() {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__UnitCost__c = 100.00,
            SBQQ__ListPrice__c = 150.00
        );
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.setZeroCostAndPrice(quoteLine, 'EA', 'EA');
        Test.stopTest();

        System.assertEquals(0.00, result.SBQQ__UnitCost__c, 'Should set cost to zero');
        System.assertEquals(0.00, result.SBQQ__ListPrice__c, 'Should set price to zero');
        System.assertEquals('EA', result.Cost_Unit_of_Measure__c, 'Should set cost UOM');
    }

    /**
     * @description Test find matching config
     */
    @isTest
    static void testFindMatchingConfig() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        List<ServiceChargeProcessingService.ServiceChargeConfig> configs = new List<ServiceChargeProcessingService.ServiceChargeConfig>();
        ServiceChargeProcessingService.ServiceChargeConfig config1 = new ServiceChargeProcessingService.ServiceChargeConfig();
        config1.serviceChargeName = 'Delivery';
        config1.actionName = 'Allow';
        configs.add(config1);

        ServiceChargeProcessingService.ServiceChargeConfig config2 = new ServiceChargeProcessingService.ServiceChargeConfig();
        config2.serviceChargeName = 'Pickup';
        config2.actionName = 'Exclude';
        configs.add(config2);

        Test.startTest();
        ServiceChargeProcessingService.ServiceChargeConfig result1 = service.findMatchingConfig(
            'Delivery Service',
            'Allow',
            configs
        );
        ServiceChargeProcessingService.ServiceChargeConfig result2 = service.findMatchingConfig(
            'Pickup Service',
            'Exclude',
            configs
        );
        ServiceChargeProcessingService.ServiceChargeConfig result3 = service.findMatchingConfig(
            'Unknown',
            'Allow',
            configs
        );
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Should find Delivery config');
        System.assertEquals('Delivery', result1.serviceChargeName, 'Should match Delivery');
        System.assertNotEquals(null, result2, 'Should find Pickup config');
        System.assertEquals(null, result3, 'Should not find unknown config');
    }

    /**
     * @description Test find existing service line
     */
    @isTest
    static void testFindExistingServiceLine() {
        List<SBQQ__QuoteLine__c> serviceLines = [SELECT Id, SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c];

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result1 = service.findExistingServiceLine(serviceLines, 'DLV');
        SBQQ__QuoteLine__c result2 = service.findExistingServiceLine(serviceLines, 'UNKNOWN');
        Test.stopTest();

        System.assertNotEquals(null, result1, 'Should find existing DLV line');
        System.assertEquals(null, result2, 'Should not find unknown product code');
    }

    /**
     * @description Test create ancillary service line
     */
    @isTest
    static void testCreateAncillaryServiceLine() {
        SBQQ__Quote__c quote = [SELECT Id, CurrencyIsoCode FROM SBQQ__Quote__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'DLV' LIMIT 1];
        SBQQ__QuoteLine__c bundle = [SELECT Id, Equipment_Size__c, Duration__c, SBQQ__StartDate__c, SBQQ__EndDate__c
                                      FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.createAncillaryServiceLine(
            quote.Id,
            product.Id,
            bundle.Id,
            bundle.Equipment_Size__c,
            bundle.Duration__c,
            vendor.Id,
            quote.CurrencyIsoCode,
            bundle.SBQQ__StartDate__c,
            bundle.SBQQ__EndDate__c,
            1
        );
        Test.stopTest();

        System.assertEquals(quote.Id, result.SBQQ__Quote__c, 'Should set quote ID');
        System.assertEquals(product.Id, result.SBQQ__Product__c, 'Should set product ID');
        System.assertEquals(bundle.Id, result.SBQQ__RequiredBy__c, 'Should set parent bundle');
        System.assertEquals(vendor.Id, result.Vendor__c, 'Should set vendor');
        System.assertEquals(1, result.SBQQ__OptionLevel__c, 'Should set option level');
        System.assertEquals(true, result.SBQQ__CostEditable__c, 'Should be cost editable');
        System.assertEquals(true, result.SBQQ__PriceEditable__c, 'Should be price editable');
    }

    /**
     * @description Test apply product option details
     */
    @isTest
    static void testApplyProductOptionDetails() {
        SBQQ__ProductOption__c productOption = [SELECT Id, Occurrence_Type__c, Schedule_Frequency__c,
                                                 Frequency_Interval__c, Cost_Unit_of_Measure__c,
                                                 PriceUOM__c, CostModelType__c
                                                 FROM SBQQ__ProductOption__c LIMIT 1];
        SBQQ__QuoteLine__c serviceLine = new SBQQ__QuoteLine__c();

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyProductOptionDetails(
            serviceLine,
            productOption,
            null, // Use product option UOM
            null  // Use product option UOM
        );
        Test.stopTest();

        System.assertEquals(productOption.Id, result.SBQQ__ProductOption__c, 'Should set product option');
        System.assertEquals(productOption.Occurrence_Type__c, result.Occurrence_Type__c, 'Should set occurrence type');
        System.assertEquals(productOption.Schedule_Frequency__c, result.Schedule_Frequency__c, 'Should set schedule frequency');
        System.assertEquals(productOption.Frequency_Interval__c, result.Frequency_Interval__c, 'Should set frequency interval');
        System.assertEquals(productOption.Cost_Unit_of_Measure__c, result.Cost_Unit_of_Measure__c, 'Should use product option cost UOM');
        System.assertEquals(productOption.PriceUOM__c, result.PriceUOM__c, 'Should use product option price UOM');
    }

    /**
     * @description Test apply product option with UOM overrides
     */
    @isTest
    static void testApplyProductOptionDetails_WithOverrides() {
        SBQQ__ProductOption__c productOption = [SELECT Id, Occurrence_Type__c, CostModelType__c
                                                 FROM SBQQ__ProductOption__c LIMIT 1];
        SBQQ__QuoteLine__c serviceLine = new SBQQ__QuoteLine__c();

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyProductOptionDetails(
            serviceLine,
            productOption,
            'TN', // Override cost UOM
            'TN'  // Override price UOM
        );
        Test.stopTest();

        System.assertEquals('TN', result.Cost_Unit_of_Measure__c, 'Should use override cost UOM');
        System.assertEquals('TN', result.PriceUOM__c, 'Should use override price UOM');
    }

    /**
     * @description Test delete service charge lines
     */
    @isTest
    static void testDeleteServiceChargeLines() {
        SBQQ__QuoteLine__c lineToDelete = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = 'DLV' LIMIT 1];
        List<Id> idsToDelete = new List<Id>{ lineToDelete.Id };

        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        List<Database.DeleteResult> results = service.deleteServiceChargeLines(idsToDelete);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one delete result');
        System.assertEquals(true, results[0].isSuccess(), 'Delete should succeed');

        List<SBQQ__QuoteLine__c> remainingLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id = :lineToDelete.Id];
        System.assertEquals(0, remainingLines.size(), 'Quote line should be deleted');
    }

    /**
     * @description Test delete with empty list
     */
    @isTest
    static void testDeleteServiceChargeLines_EmptyList() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        List<Database.DeleteResult> results = service.deleteServiceChargeLines(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty results for empty input');
    }

    /**
     * @description Test null safety in applyCostAndPrice
     */
    @isTest
    static void testApplyCostAndPrice_NullQuoteLine() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.applyCostAndPrice(null, 100, 150, null, null, 'EA', 'EA');
        Test.stopTest();

        System.assertEquals(null, result, 'Null quote line should return null');
    }

    /**
     * @description Test null safety in setZeroCostAndPrice
     */
    @isTest
    static void testSetZeroCostAndPrice_NullQuoteLine() {
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result = service.setZeroCostAndPrice(null, 'EA', 'EA');
        Test.stopTest();

        System.assertEquals(null, result, 'Null quote line should return null');
    }

    /**
     * @description Test null safety in applyProductOptionDetails
     */
    @isTest
    static void testApplyProductOptionDetails_NullInputs() {
        SBQQ__QuoteLine__c serviceLine = new SBQQ__QuoteLine__c();
        ServiceChargeProcessingService service = new ServiceChargeProcessingService();

        Test.startTest();
        SBQQ__QuoteLine__c result1 = service.applyProductOptionDetails(null, null, null, null);
        SBQQ__QuoteLine__c result2 = service.applyProductOptionDetails(serviceLine, null, null, null);
        Test.stopTest();

        System.assertEquals(null, result1, 'Null service line should return null');
        System.assertNotEquals(null, result2, 'Null product option should return service line unchanged');
    }
}
