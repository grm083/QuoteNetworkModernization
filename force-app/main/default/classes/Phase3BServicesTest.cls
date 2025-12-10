/**
 * @description Test class for Phase 3B Services
 * Tests AssetComparisonResult, ServiceDateManager, QuoteOrderFactory
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3B
 */
@isTest
private class Phase3BServicesTest {

    // ==================================================================================
    // TEST DATA SETUP
    // ==================================================================================

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'New',
            SBQQ__StartDate__c = Date.today()
        );
        insert testQuote;

        // Create test quote line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__ProductName__c = 'Test Product',
            SBQQ__ProductFamily__c = 'Commercial'
        );
        insert testQuoteLine;
    }

    // ==================================================================================
    // ASSET COMPARISON RESULT TESTS
    // ==================================================================================

    @isTest
    static void testAssetComparisonResult_CreateMatched() {
        // When: Create matched result
        Test.startTest();
        AssetComparisonResult result = AssetComparisonResult.createMatched();
        Test.stopTest();

        // Then: Should be matched
        System.assert(result.isMatched, 'Should be matched');
        System.assert(!result.requiresUpdate(), 'Should not require updates');
        System.assertEquals('Matched', result.getComparisonType(), 'Type should be Matched');
    }

    @isTest
    static void testAssetComparisonResult_CreateEndAndExtend() {
        // Given: Changed fields list
        List<String> changedFields = new List<String>{'Field1', 'Field2'};

        // When: Create End and Extend result
        Test.startTest();
        AssetComparisonResult result = AssetComparisonResult.createEndAndExtend(changedFields);
        Test.stopTest();

        // Then: Should be End and Extend
        System.assert(!result.isMatched, 'Should not be matched');
        System.assert(result.isEndAndExtendBaseline, 'Should be End and Extend');
        System.assert(!result.isUpdateBaseline, 'Should not be Update Baseline');
        System.assert(result.requiresUpdate(), 'Should require updates');
        System.assertEquals(2, result.changedFields.size(), 'Should have 2 changed fields');
        System.assertEquals('End and Extend Baseline', result.getComparisonType(), 'Type should be End and Extend');
    }

    @isTest
    static void testAssetComparisonResult_CreateUpdateBaseline() {
        // Given: Changed fields list
        List<String> changedFields = new List<String>{'Field1'};

        // When: Create Update Baseline result
        Test.startTest();
        AssetComparisonResult result = AssetComparisonResult.createUpdateBaseline(changedFields);
        Test.stopTest();

        // Then: Should be Update Baseline
        System.assert(!result.isMatched, 'Should not be matched');
        System.assert(!result.isEndAndExtendBaseline, 'Should not be End and Extend');
        System.assert(result.isUpdateBaseline, 'Should be Update Baseline');
        System.assertEquals('Update Baseline', result.getComparisonType(), 'Type should be Update Baseline');
    }

    // ==================================================================================
    // SERVICE DATE MANAGER TESTS
    // ==================================================================================

    @isTest
    static void testServiceDateManager_CalculateEndDate_Delivery() {
        // Given: Delivery product
        ServiceDateManager manager = new ServiceDateManager();
        Date serviceDate = Date.today();
        Date serviceEndDate = Date.today().addDays(30);

        // When: Calculate end date for delivery
        Test.startTest();
        Date endDate = manager.calculateEndDate(
            Constant_Util.ServiceType_Delivery,
            serviceDate,
            serviceEndDate,
            null
        );
        Test.stopTest();

        // Then: Should use service date for delivery
        System.assertEquals(serviceDate, endDate, 'Delivery should use service date as end date');
    }

    @isTest
    static void testServiceDateManager_CalculateEndDate_OngoingService() {
        // Given: Ongoing service
        ServiceDateManager manager = new ServiceDateManager();
        Date serviceDate = Date.today();
        Date serviceEndDate = Date.today().addDays(30);

        // When: Calculate end date for ongoing service
        Test.startTest();
        Date endDate = manager.calculateEndDate(
            'Service',
            serviceDate,
            serviceEndDate,
            null
        );
        Test.stopTest();

        // Then: Should use service end date
        System.assertEquals(serviceEndDate, endDate, 'Should use service end date');
    }

    @isTest
    static void testServiceDateManager_UpdateDatesForNewService() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__ProductName__c, SBQQ__ProductFamily__c FROM SBQQ__QuoteLine__c LIMIT 1];
        ServiceDateManager manager = new ServiceDateManager();

        // When: Update dates for new service
        Test.startTest();
        manager.updateDatesForNewService(quoteLine, Date.today(), Date.today().addDays(30));
        Test.stopTest();

        // Then: Dates should be updated
        System.assertEquals(Date.today(), quoteLine.SBQQ__StartDate__c, 'Start date should be updated');
        System.assertNotEquals(null, quoteLine.SBQQ__EndDate__c, 'End date should be set');
    }

    @isTest
    static void testServiceDateManager_UpdateDatesForAllLines() {
        // Given: List of quote lines
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__ProductName__c FROM SBQQ__QuoteLine__c];
        ServiceDateManager manager = new ServiceDateManager();

        // When: Update all lines
        Test.startTest();
        manager.updateDatesForAllLines(quoteLines, Date.today(), Date.today().addDays(30));
        Test.stopTest();

        // Then: All lines should have dates updated
        for (SBQQ__QuoteLine__c ql : quoteLines) {
            System.assertEquals(Date.today(), ql.SBQQ__StartDate__c, 'Start date should be updated');
        }
    }

    @isTest
    static void testServiceDateManager_UpdateExtraPickupStartDate() {
        // Given: Extra pickup line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        ServiceDateManager manager = new ServiceDateManager();
        Date pickupDate = Date.today().addDays(5);

        // When: Update extra pickup start date
        Test.startTest();
        manager.updateExtraPickupStartDate(quoteLine, pickupDate);
        Test.stopTest();

        // Then: Start date should match pickup date
        System.assertEquals(pickupDate, quoteLine.SBQQ__StartDate__c, 'Start date should match pickup date');
    }

    @isTest
    static void testServiceDateManager_FormatServiceDate() {
        // Given: Service date
        ServiceDateManager manager = new ServiceDateManager();
        Date testDate = Date.today();

        // When: Format date
        Test.startTest();
        String formatted = manager.formatServiceDate(testDate);
        Test.stopTest();

        // Then: Should return formatted string
        System.assertNotEquals(null, formatted, 'Should return formatted date');
        System.assertNotEquals('', formatted, 'Formatted date should not be empty');
    }

    @isTest
    static void testServiceDateManager_FormatServiceDate_Null() {
        // Given: Null date
        ServiceDateManager manager = new ServiceDateManager();

        // When: Format null date
        Test.startTest();
        String formatted = manager.formatServiceDate(null);
        Test.stopTest();

        // Then: Should return empty string
        System.assertEquals(Constant_Util.EMPTY_STRING, formatted, 'Should return empty string for null');
    }

    // ==================================================================================
    // QUOTE ORDER FACTORY TESTS
    // ==================================================================================

    @isTest
    static void testQuoteOrderFactory_CreateDeliveryOrder() {
        // Given: Order wrapper and quote line
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c, SBQQ__ProductName__c,
                   SBQQ__ProductFamily__c, Occurrence_Type__c, Location_Position_Name__c,
                   Location_Position_Name__r.Container_Position__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        QuoteProcurementController.OrderWrapper ow = new QuoteProcurementController.OrderWrapper();
        ow.parentQuoteLine = quoteLine.Id;
        ow.serviceType = 'Delivery';
        ow.serviceDate = Date.today();
        ow.quantity = 1;
        ow.instructions = 'Test instructions';
        ow.acornInstructions = 'Test acorn instructions';

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Create delivery order
        Test.startTest();
        Quote_Order__c order = factory.createDeliveryOrder(
            ow,
            quoteLine,
            'Test Position',
            'Test placement',
            'VSN123',
            null
        );
        Test.stopTest();

        // Then: Order should be created with correct values
        System.assertNotEquals(null, order, 'Order should be created');
        System.assertEquals(quoteLine.Id, order.Service_Quote_Line__c, 'Service quote line should match');
        System.assertEquals('Delivery', order.Service_Type__c, 'Service type should be Delivery');
        System.assertEquals(Date.today(), order.Service_Date__c, 'Service date should match');
    }

    @isTest
    static void testQuoteOrderFactory_CreateRemovalOrder() {
        // Given: Order wrapper and quote line
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__ProductName__c, SBQQ__EndDate__c, Occurrence_Type__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        quoteLine.SBQQ__EndDate__c = Date.today().addDays(30);

        QuoteProcurementController.OrderWrapper ow = new QuoteProcurementController.OrderWrapper();
        ow.parentQuoteLine = quoteLine.Id;
        ow.quantity = 1;
        ow.instructions = 'Test instructions';
        ow.acornInstructions = 'Test acorn instructions';
        ow.vendorServiceId = 'VSN456';

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Create removal order
        Test.startTest();
        Quote_Order__c order = factory.createRemovalOrder(
            ow,
            quoteLine,
            'Test Position',
            'Test placement',
            null
        );
        Test.stopTest();

        // Then: Order should be created with removal type
        System.assertNotEquals(null, order, 'Order should be created');
        System.assertEquals('Removal', order.Service_Type__c, 'Service type should be Removal');
        System.assertEquals(quoteLine.SBQQ__EndDate__c, order.Service_Date__c, 'Should use end date for removal');
    }

    @isTest
    static void testQuoteOrderFactory_UpsertOrders_Success() {
        // Given: Quote order
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        Quote_Order__c order = new Quote_Order__c(
            Quote_Line__c = quoteLine.Id,
            Service_Type__c = 'Delivery',
            Service_Date__c = Date.today()
        );

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Upsert orders
        Test.startTest();
        String result = factory.upsertOrders(new List<Quote_Order__c>{order});
        Test.stopTest();

        // Then: Should succeed
        System.assertEquals('SUCCESS', result, 'Upsert should succeed');
        System.assertNotEquals(null, order.Id, 'Order should be inserted');
    }

    @isTest
    static void testQuoteOrderFactory_UpsertOrders_EmptyList() {
        // Given: Empty list
        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Upsert empty list
        Test.startTest();
        String result = factory.upsertOrders(new List<Quote_Order__c>());
        Test.stopTest();

        // Then: Should succeed
        System.assertEquals('SUCCESS', result, 'Should handle empty list');
    }

    @isTest
    static void testQuoteOrderFactory_BuildServiceTypeOrderIdMap() {
        // Given: Existing quote orders
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        List<Quote_Order__c> existingOrders = new List<Quote_Order__c>{
            new Quote_Order__c(
                Quote_Line__c = quoteLine.Id,
                Service_Type__c = 'Delivery',
                Service_Date__c = Date.today()
            ),
            new Quote_Order__c(
                Quote_Line__c = quoteLine.Id,
                Service_Type__c = 'Removal',
                Service_Date__c = Date.today().addDays(30)
            )
        };
        insert existingOrders;

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Build map
        Test.startTest();
        Map<String, Id> serviceTypeMap = factory.buildServiceTypeOrderIdMap(existingOrders);
        Test.stopTest();

        // Then: Map should contain both service types
        System.assertEquals(2, serviceTypeMap.size(), 'Should have 2 service types');
        System.assert(serviceTypeMap.containsKey('Delivery'), 'Should contain Delivery');
        System.assert(serviceTypeMap.containsKey('Removal'), 'Should contain Removal');
    }

    @isTest
    static void testQuoteOrderFactory_HasServiceTypeOrder() {
        // Given: Existing quote orders
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        List<Quote_Order__c> existingOrders = new List<Quote_Order__c>{
            new Quote_Order__c(
                Quote_Line__c = quoteLine.Id,
                Service_Type__c = 'Delivery',
                Service_Date__c = Date.today()
            )
        };
        insert existingOrders;

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When/Then: Check for service types
        Test.startTest();
        Boolean hasDelivery = factory.hasServiceTypeOrder(existingOrders, 'Delivery');
        Boolean hasRemoval = factory.hasServiceTypeOrder(existingOrders, 'Removal');
        Test.stopTest();

        System.assert(hasDelivery, 'Should have Delivery order');
        System.assert(!hasRemoval, 'Should not have Removal order');
    }

    @isTest
    static void testQuoteOrderFactory_CreateDeliveryOrders_Multiple() {
        // Given: Multiple delivery quote lines
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c, SBQQ__ProductName__c,
                   SBQQ__ProductFamily__c, Occurrence_Type__c, Location_Position_Name__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        List<SBQQ__QuoteLine__c> deliveryLines = new List<SBQQ__QuoteLine__c>{quoteLine};

        QuoteProcurementController.OrderWrapper ow = new QuoteProcurementController.OrderWrapper();
        ow.parentQuoteLine = quoteLine.Id;
        ow.serviceType = 'Delivery';
        ow.serviceDate = Date.today();
        ow.quantity = 1;
        ow.instructions = 'Test';
        ow.acornInstructions = 'Test';

        QuoteOrderFactory factory = new QuoteOrderFactory();

        // When: Create multiple delivery orders
        Test.startTest();
        List<Quote_Order__c> orders = factory.createDeliveryOrders(
            ow,
            deliveryLines,
            'Position',
            'Instructions',
            'VSN123',
            new Map<String, Id>()
        );
        Test.stopTest();

        // Then: Should create orders for all lines
        System.assertEquals(1, orders.size(), 'Should create 1 order');
    }
}
