/**
 * @description Test class for PricingRequestRepository
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class PricingRequestRepositoryTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001',
            IsPricingEligible__c = true,
            Customer_Code__c = 'CUST001',
            Primary_Segment__c = 'Commercial'
        );
        insert testAccount;

        // Create test location
        Account testLocation = new Account(
            Name = 'Test Location',
            AccountNumber = 'LOC001',
            ParentId = testAccount.Id,
            Location_Code__c = 'LOC001'
        );
        insert testLocation;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Create test case
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test Case',
            CaseNumber = 'CASE001',
            Price_Quote_Identifier__c = 'PQI001'
        );
        insert testCase;

        testOpp.Case__c = testCase.Id;
        update testOpp;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Rolloff Container',
            ProductCode = 'ROLL001',
            Family = 'Rolloff',
            IsActive = true,
            Is_Pricing_Eligible__c = true
        );
        insert testProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            Name = 'Q-00001',
            QuoteProcuredStatus__c = 'Pending',
            Quote_Only__c = false
        );
        insert testQuote;

        // Create bundle quote line
        SBQQ__QuoteLine__c bundleLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__ProductCode__c = 'ROLL001',
            Equipment_Size__c = '20YRDS',
            Availability_Flag__c = true
        );
        insert bundleLine;

        // Create pricing requests with different types
        List<Pricing_Request__c> pricingRequests = new List<Pricing_Request__c>{
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Quote_Line_Bundle__c = bundleLine.Id,
                Case__c = testCase.Id,
                Account__c = testAccount.Id,
                Location__c = testLocation.Id,
                Pricing_Type__c = 'AM',
                Container_Type__c = 'Rolloff',
                Container_Size__c = '20YRDS',
                Vendor_Code__c = 'WM001',
                Vendor_Name__c = 'WM',
                isAPIResult__c = true,
                APIRequestOutput__c = 'Success',
                IsCaseError__c = false,
                Is_Multi_Vendor__c = false,
                Haul_Cost__c = 100,
                Disposal_Cost__c = 50,
                Pickup_Cost__c = 25,
                Haul_Price__c = 150,
                Disposal_Price__c = 75,
                Pickup_Price__c = 35
            ),
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Quote_Line_Bundle__c = bundleLine.Id,
                Case__c = testCase.Id,
                Pricing_Type__c = 'AMCO',
                Container_Type__c = 'Rolloff',
                Container_Size__c = '20YRDS',
                Vendor_Code__c = 'WM001',
                Vendor_Name__c = 'WM',
                isAPIResult__c = true,
                APIRequestOutput__c = 'Success',
                IsCaseError__c = false,
                Is_Multi_Vendor__c = false
            ),
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Quote_Line_Bundle__c = bundleLine.Id,
                Case__c = testCase.Id,
                Pricing_Type__c = 'AMPO',
                Container_Type__c = 'Rolloff',
                Container_Size__c = '20YRDS',
                Vendor_Code__c = 'WM001',
                Vendor_Name__c = 'WM',
                isAPIResult__c = true,
                APIRequestOutput__c = 'Success',
                IsCaseError__c = false,
                Is_Multi_Vendor__c = false
            ),
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Quote_Line_Bundle__c = bundleLine.Id,
                Case__c = testCase.Id,
                Pricing_Type__c = 'AM',
                Container_Type__c = 'Rolloff',
                Container_Size__c = '30YRDS',
                Vendor_Code__c = 'WM002',
                Vendor_Name__c = 'WM Multi',
                isAPIResult__c = true,
                APIRequestOutput__c = 'Success',
                IsCaseError__c = false,
                Is_Multi_Vendor__c = true
            )
        };
        insert pricingRequests;
    }

    /**
     * @description Test getPriceOnlyRequests with valid inputs
     */
    @isTest
    static void testGetPriceOnlyRequests_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.getPriceOnlyRequests(testQuote.Id, 10);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 AMPO pricing request');
        System.assertEquals('AMPO', results[0].Pricing_Type__c, 'Should return AMPO type only');
    }

    /**
     * @description Test getPriceOnlyRequests with null inputs
     */
    @isTest
    static void testGetPriceOnlyRequests_NullInputs() {
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results1 = repo.getPriceOnlyRequests(null, 10);
        List<Pricing_Request__c> results2 = repo.getPriceOnlyRequests([SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id, null);
        List<Pricing_Request__c> results3 = repo.getPriceOnlyRequests([SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id, 0);
        Test.stopTest();

        System.assertEquals(0, results1.size(), 'Null quote ID should return empty list');
        System.assertEquals(0, results2.size(), 'Null limit should return empty list');
        System.assertEquals(0, results3.size(), 'Zero limit should return empty list');
    }

    /**
     * @description Test getStandardRequests
     */
    @isTest
    static void testGetStandardRequests_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.getStandardRequests(testQuote.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 AM pricing requests');
        for (Pricing_Request__c pr : results) {
            System.assertEquals('AM', pr.Pricing_Type__c, 'Should return AM type only');
        }
    }

    /**
     * @description Test getStandardOrCostOverrideRequests
     */
    @isTest
    static void testGetStandardOrCostOverrideRequests_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.getStandardOrCostOverrideRequests(testQuote.Id, 10);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 AM/AMCO pricing requests');
        for (Pricing_Request__c pr : results) {
            System.assert(
                pr.Pricing_Type__c == 'AM' || pr.Pricing_Type__c == 'AMCO',
                'Should return AM or AMCO types only'
            );
        }
    }

    /**
     * @description Test findByIds with valid IDs
     */
    @isTest
    static void testFindByIds_Success() {
        List<Pricing_Request__c> allPRs = [SELECT Id FROM Pricing_Request__c];
        Set<Id> prIds = new Set<Id>();
        for (Pricing_Request__c pr : allPRs) {
            prIds.add(pr.Id);
        }

        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.findByIds(prIds);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'Should return all pricing requests');
        System.assertNotEquals(null, results[0].Account__r.Customer_Code__c, 'Should include account fields');
    }

    /**
     * @description Test findByIds with empty set
     */
    @isTest
    static void testFindByIds_EmptySet() {
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.findByIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty set should return empty list');
    }

    /**
     * @description Test findByCaseIdWithTypes
     */
    @isTest
    static void testFindByCaseIdWithTypes_Success() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Set<String> pricingTypes = new Set<String>{'AM', 'AMCO'};
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.findByCaseIdWithTypes(testCase.Id, pricingTypes);
        Test.stopTest();

        System.assert(results.size() > 0, 'Should return pricing requests for case');
        System.assertNotEquals(null, results[0].Quote__r.QuoteProcuredStatus__c, 'Should include quote status');
    }

    /**
     * @description Test findByQuoteId
     */
    @isTest
    static void testFindByQuoteId_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.findByQuoteId(testQuote.Id);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'Should return all pricing requests for quote');
    }

    /**
     * @description Test findByBundleIds
     */
    @isTest
    static void testFindByBundleIds_Success() {
        SBQQ__QuoteLine__c bundleLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        Set<Id> bundleIds = new Set<Id>{bundleLine.Id};
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.findByBundleIds(bundleIds);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'Should return all pricing requests for bundle');
    }

    /**
     * @description Test getMultiVendorRequests
     */
    @isTest
    static void testGetMultiVendorRequests_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Pricing_Request__c> results = repo.getMultiVendorRequests(testQuote.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 multi-vendor pricing request');
        System.assertEquals(true, results[0].Is_Multi_Vendor__c, 'Should return multi-vendor only');
    }

    /**
     * @description Test updatePricingRequests
     */
    @isTest
    static void testUpdatePricingRequests_Success() {
        List<Pricing_Request__c> prs = [SELECT Id, Vendor_Comments__c FROM Pricing_Request__c];
        for (Pricing_Request__c pr : prs) {
            pr.Vendor_Comments__c = 'Updated Comment';
        }

        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Database.SaveResult> results = repo.updatePricingRequests(prs);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'Should return results for all records');
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'Update should succeed');
        }
    }

    /**
     * @description Test updatePricingRequests with null input
     */
    @isTest
    static void testUpdatePricingRequests_NullInput() {
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Database.SaveResult> results = repo.updatePricingRequests(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Null input should return empty results');
    }

    /**
     * @description Test insertPricingRequests
     */
    @isTest
    static void testInsertPricingRequests_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c bundleLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        List<Pricing_Request__c> newPRs = new List<Pricing_Request__c>{
            new Pricing_Request__c(
                Quote__c = testQuote.Id,
                Quote_Line_Bundle__c = bundleLine.Id,
                Pricing_Type__c = 'AM',
                Vendor_Code__c = 'WM003'
            )
        };

        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Database.SaveResult> results = repo.insertPricingRequests(newPRs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for all records');
        System.assert(results[0].isSuccess(), 'Insert should succeed');
    }

    /**
     * @description Test deletePricingRequests
     */
    @isTest
    static void testDeletePricingRequests_Success() {
        List<Pricing_Request__c> prs = [SELECT Id FROM Pricing_Request__c LIMIT 1];
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Database.DeleteResult> results = repo.deletePricingRequests(prs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for all records');
        System.assert(results[0].isSuccess(), 'Delete should succeed');
    }

    /**
     * @description Test deletePricingRequests with empty list
     */
    @isTest
    static void testDeletePricingRequests_EmptyList() {
        PricingRequestRepository repo = new PricingRequestRepository();

        Test.startTest();
        List<Database.DeleteResult> results = repo.deletePricingRequests(new List<Pricing_Request__c>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty list should return empty results');
    }
}
