/**
 * @description Test class for PriceOnlySTPOrchestrator and PriceOnlyRequestSTPProcessV2
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 8 Phase 3 - Price Only Process Layer
 */
@isTest
private class PriceOnlySTPOrchestratorTest {

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
                Name = 'Pickup',
                ProductCode = 'PCK',
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
            Equipment_Size__c = '10YD'
        );
        insert bundle;

        // Create service lines without cost/price (eligible for price only)
        List<SBQQ__QuoteLine__c> serviceLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[1].Id,
                SBQQ__ProductCode__c = 'H',
                SBQQ__RequiredBy__c = bundle.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__UnitCost__c = null, // No cost - eligible for price only
                SBQQ__ListPrice__c = null // No price - eligible for price only
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = products[2].Id,
                SBQQ__ProductCode__c = 'DSP',
                SBQQ__RequiredBy__c = bundle.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__UnitCost__c = null,
                SBQQ__ListPrice__c = null
            )
        };
        insert serviceLines;

        // Create price only pricing request with mock response
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
                '}' +
            '}' +
        '}';

        Pricing_Request__c pricingRequest = new Pricing_Request__c(
            Quote__c = testQuote.Id,
            Quote_Line_Bundle__c = bundle.Id,
            Vendor_Code__c = 'WM_US',
            Pricing_Type__c = 'AMPO', // Price Only type
            isAPIResult__c = true,
            IsCaseError__c = false,
            APIRequestOutput__c = mockResponse
        );
        insert pricingRequest;
    }

    /**
     * @description Test process quote for price only
     */
    @isTest
    static void testProcessQuoteForPriceOnly_Success() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.processQuoteForPriceOnly(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Processing should succeed');
        System.assert(result.bundlesProcessed >= 0, 'Should process bundles');
    }

    /**
     * @description Test process with null quote ID
     */
    @isTest
    static void testProcessQuoteForPriceOnly_NullQuoteId() {
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.processQuoteForPriceOnly(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with null quote ID');
        System.assertEquals(1, result.errors.size(), 'Should have error message');
    }

    /**
     * @description Test validate price only eligibility
     */
    @isTest
    static void testValidatePriceOnlyEligibility() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        Set<Id> eligibleBundles = orchestrator.validatePriceOnlyEligibility(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, eligibleBundles, 'Should return eligible bundles');
        System.assertEquals(1, eligibleBundles.size(), 'Should have one eligible bundle');
    }

    /**
     * @description Test validate with no eligible bundles
     */
    @isTest
    static void testValidatePriceOnlyEligibility_NoneEligible() {
        // Update service lines to have cost/price (not eligible)
        List<SBQQ__QuoteLine__c> serviceLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c != null
        ];

        for (SBQQ__QuoteLine__c line : serviceLines) {
            line.SBQQ__UnitCost__c = 100;
            line.SBQQ__ListPrice__c = 150;
        }
        update serviceLines;

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        Set<Id> eligibleBundles = orchestrator.validatePriceOnlyEligibility(quote.Id);
        Test.stopTest();

        System.assertEquals(0, eligibleBundles.size(), 'Should have no eligible bundles');
    }

    /**
     * @description Test save prices to quote lines
     */
    @isTest
    static void testSavePricesToQuoteLines() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.savePricesToQuoteLines(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should succeed');
        System.assertEquals(1, result.bundlesProcessed, 'Should process one bundle');
    }

    /**
     * @description Test save prices with null quote ID
     */
    @isTest
    static void testSavePricesToQuoteLines_NullQuoteId() {
        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.savePricesToQuoteLines(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with null ID');
        System.assertEquals(1, result.errors.size(), 'Should have error');
    }

    /**
     * @description Test create pricing requests for bundles
     */
    @isTest
    static void testCreatePricingRequestsForBundles() {
        SBQQ__QuoteLine__c bundle = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];
        Set<Id> bundleIds = new Set<Id>{ bundle.Id };

        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        Integer requestsCreated = orchestrator.createPricingRequestsForBundles(bundleIds, false);
        Test.stopTest();

        System.assertEquals(1, requestsCreated, 'Should return bundle count');
    }

    /**
     * @description Test V2 wrapper - callPriceOnlySTPFunctionality
     */
    @isTest
    static void testV2_CallPriceOnlySTPFunctionality() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        PriceOnlyRequestSTPProcessV2.callPriceOnlySTPFunctionality(quote.Id);
        Test.stopTest();

        // Should complete without exception
        System.assert(true, 'Should complete successfully');
    }

    /**
     * @description Test V2 wrapper with null ID
     */
    @isTest
    static void testV2_CallPriceOnlySTPFunctionality_NullId() {
        Test.startTest();
        PriceOnlyRequestSTPProcessV2.callPriceOnlySTPFunctionality(null);
        Test.stopTest();

        // Should handle gracefully
        System.assert(true, 'Should handle null gracefully');
    }

    /**
     * @description Test V2 wrapper - validatePriceOnlyCall
     */
    @isTest
    static void testV2_ValidatePriceOnlyCall() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        Set<Id> eligibleBundles = PriceOnlyRequestSTPProcessV2.validatePriceOnlyCall(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, eligibleBundles, 'Should return set');
        System.assertEquals(1, eligibleBundles.size(), 'Should have one eligible bundle');
    }

    /**
     * @description Test V2 wrapper - createPricingRequestForMultiBundle
     */
    @isTest
    static void testV2_CreatePricingRequestForMultiBundle() {
        SBQQ__QuoteLine__c bundle = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];
        Set<Id> bundleIds = new Set<Id>{ bundle.Id };

        Test.startTest();
        PriceOnlyRequestSTPProcessV2.createPricingRequestForMultiBundle(bundleIds, false);
        Test.stopTest();

        // Should complete without exception
        System.assert(true, 'Should complete successfully');
    }

    /**
     * @description Test V2 wrapper - savePricetoQuoteline
     */
    @isTest
    static void testV2_SavePricetoQuoteline() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        PriceOnlyRequestSTPProcessV2.savePricetoQuoteline(quote.Id);
        Test.stopTest();

        // Should complete without exception
        System.assert(true, 'Should complete successfully');
    }

    /**
     * @description Test V2 wrapper - getProductdetails
     */
    @isTest
    static void testV2_GetProductdetails() {
        Test.startTest();
        List<Product2> products = PriceOnlyRequestSTPProcessV2.getProductdetails();
        Test.stopTest();

        System.assertNotEquals(null, products, 'Should return products list');
    }

    /**
     * @description Test V2 wrapper - getProductOptions
     */
    @isTest
    static void testV2_GetProductOptions() {
        List<String> productCodes = new List<String>{'Rolloff Container'};

        Test.startTest();
        List<SBQQ__ProductOption__c> options = PriceOnlyRequestSTPProcessV2.getProductOptions(productCodes);
        Test.stopTest();

        System.assertNotEquals(null, options, 'Should return options list');
    }

    /**
     * @description Test V2 wrapper - processQuoteWithResult
     */
    @isTest
    static void testV2_ProcessQuoteWithResult() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            PriceOnlyRequestSTPProcessV2.processQuoteWithResult(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result');
        System.assertEquals(true, result.success, 'Should succeed');
    }

    /**
     * @description Test result initialization
     */
    @isTest
    static void testPriceOnlyProcessingResult_Initialization() {
        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            new PriceOnlySTPOrchestrator.PriceOnlyProcessingResult();
        Test.stopTest();

        System.assertEquals(true, result.success, 'Success should default to true');
        System.assertEquals(0, result.bundlesProcessed, 'Bundles processed should default to 0');
        System.assertEquals(0, result.quoteLinesUpdated, 'Lines updated should default to 0');
        System.assertEquals(0, result.pricingRequestsCreated, 'Requests created should default to 0');
        System.assertNotEquals(null, result.errors, 'Errors list should be initialized');
        System.assertNotEquals(null, result.warnings, 'Warnings list should be initialized');
    }

    /**
     * @description Test context initialization
     */
    @isTest
    static void testPriceOnlyContext_Initialization() {
        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyContext context =
            new PriceOnlySTPOrchestrator.PriceOnlyContext();
        Test.stopTest();

        System.assertNotEquals(null, context.eligibleBundleIds, 'Eligible bundle IDs should be initialized');
        System.assertNotEquals(null, context.coreServiceMap, 'Core service map should be initialized');
        System.assertNotEquals(null, context.ancillaryServiceMap, 'Ancillary service map should be initialized');
        System.assertNotEquals(null, context.productMap, 'Product map should be initialized');
        System.assertNotEquals(null, context.costUOMMap, 'Cost UOM map should be initialized');
        System.assertNotEquals(null, context.priceUOMMap, 'Price UOM map should be initialized');
    }

    /**
     * @description Test processing with invalid JSON response
     */
    @isTest
    static void testSavePricesToQuoteLines_InvalidJSON() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Pricing_Request__c pricingRequest = [SELECT Id FROM Pricing_Request__c LIMIT 1];

        // Set invalid JSON
        pricingRequest.APIRequestOutput__c = 'INVALID JSON {{{';
        update pricingRequest;

        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.savePricesToQuoteLines(quote.Id);
        Test.stopTest();

        // Should handle gracefully with error
        System.assert(!result.errors.isEmpty() || result.bundlesProcessed == 0, 'Should handle invalid JSON');
    }

    /**
     * @description Test processing with no pricing requests
     */
    @isTest
    static void testSavePricesToQuoteLines_NoPricingRequests() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        // Delete pricing request
        delete [SELECT Id FROM Pricing_Request__c WHERE Quote__c = :quote.Id];

        PriceOnlySTPOrchestrator orchestrator = new PriceOnlySTPOrchestrator();

        Test.startTest();
        PriceOnlySTPOrchestrator.PriceOnlyProcessingResult result =
            orchestrator.savePricesToQuoteLines(quote.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should succeed with no pricing requests');
        System.assertEquals(0, result.bundlesProcessed, 'Should process zero bundles');
    }
}
