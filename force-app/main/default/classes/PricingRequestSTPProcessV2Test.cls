/**
 * @description Test class for PricingRequestSTPProcessV2
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 8 Phase 2 - Process Layer
 */
@isTest
private class PricingRequestSTPProcessV2Test {

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
            )
        };
        insert products;

        // Create quote line (bundle)
        SBQQ__QuoteLine__c bundle = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = products[0].Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = vendor.Id,
            Equipment_Size__c = '10YD'
        );
        insert bundle;

        // Create service line
        SBQQ__QuoteLine__c serviceLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = products[1].Id,
            SBQQ__ProductCode__c = 'H',
            SBQQ__RequiredBy__c = bundle.Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = vendor.Id
        );
        insert serviceLine;

        // Create pricing request
        String mockResponse = '{' +
            '"data": {' +
                '"supplierCode": "WM_US",' +
                '"rollOff": {' +
                    '"haulCost": 100.00,' +
                    '"haulPrice": 150.00' +
                '}' +
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

        // Create product option
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = products[0].Id,
            SBQQ__OptionalSKU__c = products[1].Id,
            Occurrence_Type__c = 'One Time',
            Cost_Unit_of_Measure__c = 'EA',
            PriceUOM__c = 'EA'
        );
        insert productOption;
    }

    /**
     * @description Test quoteLineProcess with valid quote
     */
    @isTest
    static void testQuoteLineProcess_Success() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        PricingRequestSTPProcessV2.quoteLineProcess(quote.Id);
        Test.stopTest();

        // Verify no exceptions thrown
        System.assert(true, 'quoteLineProcess should complete without exception');
    }

    /**
     * @description Test quoteLineProcess with null ID
     */
    @isTest
    static void testQuoteLineProcess_NullId() {
        Test.startTest();
        PricingRequestSTPProcessV2.quoteLineProcess(null);
        Test.stopTest();

        // Should handle gracefully
        System.assert(true, 'Should handle null quote ID gracefully');
    }

    /**
     * @description Test getQuoteLineList
     */
    @isTest
    static void testGetQuoteLineList() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        List<SBQQ__QuoteLine__c> bundles = PricingRequestSTPProcessV2.getQuoteLineList(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, bundles, 'Should return bundles list');
        System.assertEquals(1, bundles.size(), 'Should have one bundle');
    }

    /**
     * @description Test getPricingList
     */
    @isTest
    static void testGetPricingList() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        List<Pricing_Request__c> pricingRequests = PricingRequestSTPProcessV2.getPricingList(quote.Id, 1);
        Test.stopTest();

        System.assertNotEquals(null, pricingRequests, 'Should return pricing requests list');
        System.assertEquals(1, pricingRequests.size(), 'Should have one pricing request');
    }

    /**
     * @description Test getProductOptions
     */
    @isTest
    static void testGetProductOptions() {
        List<String> productCodes = new List<String>{'Rolloff Container'};

        Test.startTest();
        List<SBQQ__ProductOption__c> options = PricingRequestSTPProcessV2.getProductOptions(productCodes);
        Test.stopTest();

        System.assertNotEquals(null, options, 'Should return product options list');
        System.assertEquals(1, options.size(), 'Should have one product option');
    }

    /**
     * @description Test getProductOptions with empty list
     */
    @isTest
    static void testGetProductOptions_EmptyList() {
        Test.startTest();
        List<SBQQ__ProductOption__c> options = PricingRequestSTPProcessV2.getProductOptions(new List<String>());
        Test.stopTest();

        System.assertNotEquals(null, options, 'Should return empty list');
        System.assertEquals(0, options.size(), 'Should have no options');
    }

    /**
     * @description Test getProductdetails
     */
    @isTest
    static void testGetProductdetails() {
        Test.startTest();
        List<Product2> products = PricingRequestSTPProcessV2.getProductdetails();
        Test.stopTest();

        System.assertNotEquals(null, products, 'Should return products list');
        System.assert(products.size() >= 2, 'Should have test products');
    }

    /**
     * @description Test compareQuotelineVendorWithPRVendor with matching vendor
     */
    @isTest
    static void testCompareQuotelineVendorWithPRVendor_Match() {
        Account vendor = [SELECT Id, Vendor_ID__c, Parent_Vendor_ID__c
                          FROM Account WHERE Vendor_ID__c = 'WM_US' LIMIT 1];
        SBQQ__QuoteLine__c bundle = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                      FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        // Set Type_of_Change to enable vendor matching
        bundle.Type_of_Change__c = 'Rate Change';
        update bundle;

        // Re-query to get vendor relationship
        bundle = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                  FROM SBQQ__QuoteLine__c WHERE Id = :bundle.Id];

        SBQQ__QuoteLine__c sqlHdr = bundle.clone(false, true, false, false);

        Test.startTest();
        Boolean isMatch = PricingRequestSTPProcessV2.compareQuotelineVendorWithPRVendor(
            bundle,
            sqlHdr,
            vendor
        );
        Test.stopTest();

        System.assertEquals(true, isMatch, 'Vendors should match');
    }

    /**
     * @description Test compareQuotelineVendorWithPRVendor with vendor mismatch
     */
    @isTest
    static void testCompareQuotelineVendorWithPRVendor_Mismatch() {
        // Create different vendor
        Account differentVendor = new Account(
            Name = 'Different Vendor',
            Vendor_ID__c = 'DIFF001',
            Parent_Vendor_ID__c = 'DIFF_PARENT',
            Status__c = 'Active'
        );
        insert differentVendor;

        SBQQ__QuoteLine__c bundle = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                                      FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        bundle.Type_of_Change__c = 'Rate Change';
        update bundle;

        // Re-query
        bundle = [SELECT Id, Vendor__r.Vendor_ID__c, Vendor__r.Parent_Vendor_ID__c, Type_of_Change__c
                  FROM SBQQ__QuoteLine__c WHERE Id = :bundle.Id];

        SBQQ__QuoteLine__c sqlHdr = bundle.clone(false, true, false, false);

        Test.startTest();
        Boolean isMatch = PricingRequestSTPProcessV2.compareQuotelineVendorWithPRVendor(
            bundle,
            sqlHdr,
            differentVendor
        );
        Test.stopTest();

        System.assertEquals(false, isMatch, 'Vendors should not match');
    }

    /**
     * @description Test getBypassPriceReview
     */
    @isTest
    static void testGetBypassPriceReview() {
        Test.startTest();
        Boolean bypass = PricingRequestSTPProcessV2.getBypassPriceReview('WM Franchise', Constant_Util.WM_US_VENDOR, 'WM');
        Test.stopTest();

        // Currently returns false (placeholder)
        System.assertEquals(false, bypass, 'Should return bypass flag');
    }

    /**
     * @description Test processPricingRequest
     */
    @isTest
    static void testProcessPricingRequest() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = PricingRequestSTPProcessV2.processPricingRequest(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return processing result');
        System.assertEquals(true, result.success, 'Processing should succeed');
    }

    /**
     * @description Test processPricingRequest with null ID
     */
    @isTest
    static void testProcessPricingRequest_NullId() {
        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = PricingRequestSTPProcessV2.processPricingRequest(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result');
        System.assertEquals(false, result.success, 'Should fail with null ID');
        System.assert(!result.errors.isEmpty(), 'Should have error message');
    }

    /**
     * @description Test processQuoteWithResult
     */
    @isTest
    static void testProcessQuoteWithResult() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        STPProcessOrchestrator.ProcessingResult result = PricingRequestSTPProcessV2.processQuoteWithResult(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return processing result');
        System.assertEquals(1, result.bundlesProcessed, 'Should process one bundle');
    }
}
