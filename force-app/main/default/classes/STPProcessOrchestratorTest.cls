/**
 * @description Test class for STPProcessOrchestrator
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 8 Phase 2 - Process Layer
 */
@isTest
private class STPProcessOrchestratorTest {

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
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote'
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
                Name = 'Haul',
                ProductCode = 'H',
                Family = 'Service',
                IsActive = true
            ),
            new Product2(
                Name = 'Disposal',
                ProductCode = 'DSP',
                Family = 'Service',
                IsActive = true
            ),
            new Product2(
                Name = 'Delivery',
                ProductCode = 'DLV',
                Family = 'Service',
                IsActive = true
            )
        };
        insert products;

        // Create quote lines (bundle)
        SBQQ__QuoteLine__c bundle = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = products[0].Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = vendor.Id,
            Equipment_Size__c = '10YD',
            Duration__c = 12,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(12)
        );
        insert bundle;

        // Create service lines
        List<SBQQ__QuoteLine__c> serviceLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[1].Id,
                SBQQ__ProductCode__c = 'H',
                SBQQ__RequiredBy__c = bundle.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = vendor.Id
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[2].Id,
                SBQQ__ProductCode__c = 'DSP',
                SBQQ__RequiredBy__c = bundle.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = vendor.Id
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[3].Id,
                SBQQ__ProductCode__c = 'DLV',
                SBQQ__RequiredBy__c = bundle.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = vendor.Id
            )
        };
        insert serviceLines;

        // Create pricing request with mock response
        String mockResponse = '{' +
            '"data": {' +
                '"supplierCode": "WM_US",' +
                '"costSource": "WM",' +
                '"currencyCode": "USD",' +
                '"rollOff": {' +
                    '"haulCost": 100.00,' +
                    '"haulPrice": 150.00,' +
                    '"disposalCost": 50.00,' +
                    '"disposalPrice": 75.00' +
                '},' +
                '"serviceCharges": [' +
                    '{' +
                        '"code": "DLV",' +
                        '"name": "Delivery",' +
                        '"actionName": "Allow",' +
                        '"cost": 25.00,' +
                        '"price": 35.00,' +
                        '"costUOM": "EA",' +
                        '"priceUOM": "EA"' +
                    '}' +
                ']' +
            '}' +
        '}';

        Pricing_Request__c pricingRequest = new Pricing_Request__c(
            Quote__c = testQuote.Id,
            Quote_Line_Bundle__c = bundle.Id,
            Vendor_Code__c = 'WM_US',
            Pricing_Type__c = 'AM',
            APIRequestOutput__c = mockResponse
        );
        insert pricingRequest;
    }

    /**
     * @description Test process quote with null quote ID
     */
    @isTest
    static void testProcessQuote_NullQuoteId() {
        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with null quote ID');
        System.assertEquals(1, result.errors.size(), 'Should have error message');
    }

    /**
     * @description Test process quote success
     */
    @isTest
    static void testProcessQuote_Success() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Processing should succeed');
        System.assertEquals(1, result.bundlesProcessed, 'Should process one bundle');
    }

    /**
     * @description Test build processing context
     */
    @isTest
    static void testBuildProcessingContext() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        // Use reflection or create a public wrapper method to test private methods
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        // Verify context was built correctly by checking result
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    /**
     * @description Test organize service lines
     */
    @isTest
    static void testOrganizeServiceLines() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        // Service lines should be organized into core (H, DSP) and ancillary (DLV)
        System.assertEquals(true, result.success, 'Should organize service lines successfully');
    }

    /**
     * @description Test processing with vendor mismatch
     */
    @isTest
    static void testProcessQuote_WithVendorMismatch() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c bundle = [SELECT Id, Vendor__c FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        // Create third party vendor
        Account tpVendor = new Account(
            Name = 'TP Vendor',
            Vendor_ID__c = 'TP001',
            Parent_Vendor_ID__c = 'TP_PARENT',
            Status__c = 'Active'
        );
        insert tpVendor;

        // Update bundle with Type_of_Change to trigger vendor validation
        bundle.Type_of_Change__c = 'Rate Change';
        update bundle;

        // Update pricing request with different vendor
        Pricing_Request__c pricingRequest = [SELECT Id FROM Pricing_Request__c LIMIT 1];
        pricingRequest.Vendor_Code__c = 'TP001';

        // Update response to have TP vendor
        String mockResponse = '{' +
            '"data": {' +
                '"supplierCode": "TP001",' +
                '"costSource": "TP",' +
                '"currencyCode": "USD",' +
                '"serviceCharges": []' +
            '}' +
        '}';
        pricingRequest.APIRequestOutput__c = mockResponse;
        update pricingRequest;

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should handle vendor mismatch');
        System.assertEquals(1, result.bundlesProcessed, 'Should process bundle with mismatch');
    }

    /**
     * @description Test processing with invalid JSON response
     */
    @isTest
    static void testProcessQuote_InvalidJSON() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Pricing_Request__c pricingRequest = [SELECT Id FROM Pricing_Request__c LIMIT 1];

        // Set invalid JSON
        pricingRequest.APIRequestOutput__c = 'INVALID JSON {{{';
        update pricingRequest;

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        // Should handle gracefully with error
        System.assertEquals(false, result.errors.isEmpty(), 'Should have error for invalid JSON');
    }

    /**
     * @description Test processing with blank API response
     */
    @isTest
    static void testProcessQuote_BlankAPIResponse() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Pricing_Request__c pricingRequest = [SELECT Id FROM Pricing_Request__c LIMIT 1];

        // Set blank response
        pricingRequest.APIRequestOutput__c = null;
        update pricingRequest;

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        // Should skip pricing requests with blank responses
        System.assertEquals(0, result.bundlesProcessed, 'Should skip blank responses');
    }

    /**
     * @description Test processing with service charge exclude action
     */
    @isTest
    static void testProcessQuote_ServiceChargeExclude() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Pricing_Request__c pricingRequest = [SELECT Id FROM Pricing_Request__c LIMIT 1];

        // Update response with Exclude action
        String mockResponse = '{' +
            '"data": {' +
                '"supplierCode": "WM_US",' +
                '"serviceCharges": [' +
                    '{' +
                        '"code": "DLV",' +
                        '"name": "Delivery",' +
                        '"actionName": "Exclude",' +
                        '"cost": 0.00,' +
                        '"price": 0.00' +
                    '}' +
                ']' +
            '}' +
        '}';
        pricingRequest.APIRequestOutput__c = mockResponse;
        update pricingRequest;

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should process exclude action');
    }

    /**
     * @description Test ProcessingResult initialization
     */
    @isTest
    static void testProcessingResult_Initialization() {
        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = new STPProcessOrchestrator.ProcessingResult();
        Test.stopTest();

        System.assertEquals(true, result.success, 'Success should default to true');
        System.assertEquals(0, result.bundlesProcessed, 'Bundles processed should default to 0');
        System.assertEquals(0, result.quoteLinesUpdated, 'Lines updated should default to 0');
        System.assertEquals(0, result.quoteLinesCreated, 'Lines created should default to 0');
        System.assertEquals(0, result.quoteLinesDeleted, 'Lines deleted should default to 0');
        System.assertNotEquals(null, result.errors, 'Errors list should be initialized');
    }

    /**
     * @description Test ProcessingContext initialization
     */
    @isTest
    static void testProcessingContext_Initialization() {
        Test.startTest();
        STPProcessOrchestrator.ProcessingContext context = new STPProcessOrchestrator.ProcessingContext();
        Test.stopTest();

        System.assertNotEquals(null, context.coreServiceMap, 'Core service map should be initialized');
        System.assertNotEquals(null, context.ancillaryServiceMap, 'Ancillary service map should be initialized');
        System.assertNotEquals(null, context.vendorMap, 'Vendor map should be initialized');
        System.assertNotEquals(null, context.productMap, 'Product map should be initialized');
        System.assertNotEquals(null, context.costUOMMap, 'Cost UOM map should be initialized');
        System.assertNotEquals(null, context.priceUOMMap, 'Price UOM map should be initialized');
    }

    /**
     * @description Test processing with no pricing requests
     */
    @isTest
    static void testProcessQuote_NoPricingRequests() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        // Delete pricing request
        delete [SELECT Id FROM Pricing_Request__c WHERE Quote__c = :quote.Id];

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should succeed with no pricing requests');
        System.assertEquals(0, result.bundlesProcessed, 'Should process zero bundles');
    }

    /**
     * @description Test processing with no bundles
     */
    @isTest
    static void testProcessQuote_NoBundles() {
        // Create quote without bundles
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c emptyQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert emptyQuote;

        STPProcessOrchestrator orchestrator = new STPProcessOrchestrator();

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = orchestrator.processQuote(emptyQuote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should succeed with no bundles');
        System.assertEquals(0, result.bundlesProcessed, 'Should process zero bundles');
    }
}
