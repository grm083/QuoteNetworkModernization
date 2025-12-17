/**
 * @description Test class for QuoteLineRepository
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class QuoteLineRepositoryTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001'
        );
        insert testAccount;

        Account parentAccount = new Account(
            Name = 'Parent Account',
            AccountNumber = 'PARENT001',
            IsPricingEligible__c = true,
            Primary_Segment__c = 'Commercial'
        );
        insert parentAccount;

        testAccount.ParentId = parentAccount.Id;
        update testAccount;

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
            Reference_Number__c = 'REF001'
        );
        insert testCase;

        testOpp.Case__c = testCase.Id;
        update testOpp;

        // Create test products
        List<Product2> testProducts = new List<Product2>{
            new Product2(
                Name = 'Rolloff Container',
                ProductCode = 'ROLL001',
                Family = 'Rolloff',
                IsActive = true,
                Is_Pricing_Eligible__c = true
            ),
            new Product2(
                Name = 'Commercial Container',
                ProductCode = 'COMM001',
                Family = 'Commercial',
                IsActive = true,
                Is_Pricing_Eligible__c = true
            ),
            new Product2(
                Name = 'Waste Stream Product',
                ProductCode = 'WASTE001',
                Family = 'Waste Stream',
                IsActive = true
            ),
            new Product2(
                Name = 'Waste Category Product',
                ProductCode = 'CAT001',
                Family = 'Waste Category',
                IsActive = true
            )
        };
        insert testProducts;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment',
            Name = 'Q-00001',
            Case_Number__c = 'CASE001',
            STP__c = true,
            Special_Handling__c = false,
            SBQQ__ShippingCountry__c = 'USA'
        );
        insert testQuote;

        // Create pricing request
        Pricing_Request__c pricingReq = new Pricing_Request__c(
            Quote__c = testQuote.Id,
            IsCaseError__c = false,
            APIRequestOutput__c = 'Success',
            Customer_Price_Type__c = 'Standard'
        );
        insert pricingReq;

        // Create bundle quote lines (parent lines)
        List<SBQQ__QuoteLine__c> bundleLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProducts[0].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ProductName__c = 'Rolloff Container',
                SBQQ__ProductCode__c = 'ROLL001',
                SBQQ__ProductFamily__c = 'Rolloff',
                Equipment_Size__c = '20YRDS',
                Duration__c = 'PERM',
                Pricing_Request__c = pricingReq.Id,
                BundleProcuredStatus__c = 'Success',
                BypassPriceReview__c = false,
                Core_Service__c = false,
                SBQQ__Number__c = 1
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProducts[1].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ProductName__c = 'Commercial Container',
                SBQQ__ProductCode__c = 'COMM001',
                SBQQ__ProductFamily__c = 'Commercial',
                Equipment_Size__c = '2YRDS',
                Duration__c = 'TEMP',
                Pricing_Request__c = pricingReq.Id,
                BundleProcuredStatus__c = 'Pending',
                BypassPriceReview__c = false,
                Core_Service__c = false,
                SBQQ__Number__c = 2
            )
        };
        insert bundleLines;

        // Create service quote lines (child lines)
        List<SBQQ__QuoteLine__c> serviceLines = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProducts[0].Id,
                SBQQ__RequiredBy__c = bundleLines[0].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ProductName__c = 'Delivery Service',
                SBQQ__ProductCode__c = 'DLV',
                SBQQ__ProductFamily__c = 'Services',
                Occurrence_Type__c = 'Scheduled',
                Schedule_Frequency__c = 'W',
                Frequency_Interval__c = '1',
                Service_Days__c = 'M;T;W;T1;F',
                Core_Service__c = true,
                SBQQ__UnitCost__c = 100,
                Cost_Unit_of_Measure__c = 'Months',
                SBQQ__ListPrice__c = 150,
                PriceUOM__c = 'Months',
                SBQQ__Number__c = 3
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProducts[2].Id,
                SBQQ__RequiredBy__c = bundleLines[0].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ProductName__c = 'MSW',
                SBQQ__ProductCode__c = 'MSW001',
                SBQQ__ProductFamily__c = 'Waste Stream',
                SBQQ__Number__c = 4
            ),
            new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProducts[3].Id,
                SBQQ__RequiredBy__c = bundleLines[0].Id,
                SBQQ__Quantity__c = 1,
                SBQQ__ProductName__c = 'Waste Category',
                SBQQ__ProductCode__c = 'CAT001',
                SBQQ__ProductFamily__c = 'Waste Category',
                material_type__c = 'C',
                materialGrade__c = 'Grade A',
                SBQQ__Number__c = 5
            )
        };
        insert serviceLines;
    }

    /**
     * @description Test getQuoteBundles with valid quote ID
     */
    @isTest
    static void testGetQuoteBundles_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> bundles = repo.getQuoteBundles(testQuote.Id);
        Test.stopTest();

        System.assertEquals(2, bundles.size(), 'Should return 2 bundle lines');
        for (SBQQ__QuoteLine__c bundle : bundles) {
            System.assertEquals(null, bundle.SBQQ__RequiredBy__c, 'Should only return parent lines');
        }
    }

    /**
     * @description Test getQuoteBundles with null quote ID
     */
    @isTest
    static void testGetQuoteBundles_NullInput() {
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> bundles = repo.getQuoteBundles(null);
        Test.stopTest();

        System.assertEquals(0, bundles.size(), 'Null input should return empty list');
    }

    /**
     * @description Test getServiceLinesByBundles with valid bundle IDs
     */
    @isTest
    static void testGetServiceLinesByBundles_Success() {
        List<SBQQ__QuoteLine__c> bundles = [
            SELECT Id FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
        ];
        Set<Id> bundleIds = new Set<Id>();
        for (SBQQ__QuoteLine__c bundle : bundles) {
            bundleIds.add(bundle.Id);
        }

        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> serviceLines = repo.getServiceLinesByBundles(bundleIds);
        Test.stopTest();

        System.assert(serviceLines.size() > 0, 'Should return service lines');
        System.assertEquals(5, serviceLines[0].SBQQ__Number__c, 'Should order by number DESC');
    }

    /**
     * @description Test getServiceLinesByBundles with empty set
     */
    @isTest
    static void testGetServiceLinesByBundles_EmptyInput() {
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> serviceLines = repo.getServiceLinesByBundles(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, serviceLines.size(), 'Empty input should return empty list');
    }

    /**
     * @description Test getServiceLinesByProductFamily with filters
     */
    @isTest
    static void testGetServiceLinesByProductFamily_Success() {
        List<SBQQ__QuoteLine__c> bundles = [
            SELECT Id FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
        ];
        Set<Id> bundleIds = new Set<Id>();
        for (SBQQ__QuoteLine__c bundle : bundles) {
            bundleIds.add(bundle.Id);
        }

        Set<String> productFamilies = new Set<String>{'Services', 'Waste Stream'};
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> serviceLines =
            repo.getServiceLinesByProductFamily(bundleIds, productFamilies);
        Test.stopTest();

        System.assert(serviceLines.size() > 0, 'Should return filtered service lines');
        for (SBQQ__QuoteLine__c line : serviceLines) {
            System.assert(
                productFamilies.contains(line.SBQQ__ProductFamily__c),
                'Should only return lines in specified product families'
            );
        }
    }

    /**
     * @description Test getAllQuoteLines with valid quote ID
     */
    @isTest
    static void testGetAllQuoteLines_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        Map<Id, SBQQ__QuoteLine__c> allLines = repo.getAllQuoteLines(testQuote.Id);
        Test.stopTest();

        System.assertEquals(5, allLines.size(), 'Should return all quote lines (2 bundles + 3 services)');
    }

    /**
     * @description Test getAllQuoteLinesForProductDetail
     */
    @isTest
    static void testGetAllQuoteLinesForProductDetail_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        Map<Id, SBQQ__QuoteLine__c> allLines = repo.getAllQuoteLinesForProductDetail(testQuote.Id);
        Test.stopTest();

        System.assertEquals(5, allLines.size(), 'Should return all quote lines');
    }

    /**
     * @description Test getAllQuoteLinesForSLA
     */
    @isTest
    static void testGetAllQuoteLinesForSLA_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> allLines = repo.getAllQuoteLinesForSLA(testQuote.Id);
        Test.stopTest();

        System.assertEquals(5, allLines.size(), 'Should return all quote lines with SLA fields');
    }

    /**
     * @description Test getWasteStreamLines by quote name
     */
    @isTest
    static void testGetWasteStreamLines_Success() {
        SBQQ__Quote__c testQuote = [SELECT Name FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> wasteLines = repo.getWasteStreamLines(testQuote.Name);
        Test.stopTest();

        System.assertEquals(1, wasteLines.size(), 'Should return 1 waste stream line');
        System.assertEquals('MSW', wasteLines[0].SBQQ__ProductName__c, 'Should return correct waste stream');
    }

    /**
     * @description Test getWasteStreamLines with empty quote name
     */
    @isTest
    static void testGetWasteStreamLines_EmptyInput() {
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> wasteLines = repo.getWasteStreamLines('');
        Test.stopTest();

        System.assertEquals(0, wasteLines.size(), 'Empty input should return empty list');
    }

    /**
     * @description Test getWasteCategoryLines by quote name
     */
    @isTest
    static void testGetWasteCategoryLines_Success() {
        SBQQ__Quote__c testQuote = [SELECT Name FROM SBQQ__Quote__c LIMIT 1];
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> categoryLines = repo.getWasteCategoryLines(testQuote.Name);
        Test.stopTest();

        System.assertEquals(1, categoryLines.size(), 'Should return 1 waste category line');
        System.assertEquals('Grade A', categoryLines[0].materialGrade__c, 'Should return correct grade');
    }

    /**
     * @description Test getCoreServiceLines
     */
    @isTest
    static void testGetCoreServiceLines_Success() {
        List<SBQQ__QuoteLine__c> bundles = [
            SELECT Id FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
        ];
        Set<Id> bundleIds = new Set<Id>();
        for (SBQQ__QuoteLine__c bundle : bundles) {
            bundleIds.add(bundle.Id);
        }

        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<SBQQ__QuoteLine__c> coreLines = repo.getCoreServiceLines(bundleIds);
        Test.stopTest();

        System.assertEquals(1, coreLines.size(), 'Should return 1 core service line');
        System.assertEquals(true, coreLines[0].Core_Service__c, 'Should return core services only');
        System.assertEquals('Scheduled', coreLines[0].Occurrence_Type__c, 'Should return scheduled only');
    }

    /**
     * @description Test updateQuoteLines with valid records
     */
    @isTest
    static void testUpdateQuoteLines_Success() {
        List<SBQQ__QuoteLine__c> bundles = [
            SELECT Id, BundleProcuredStatus__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
        ];

        for (SBQQ__QuoteLine__c bundle : bundles) {
            bundle.BundleProcuredStatus__c = 'Updated';
        }

        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<Database.SaveResult> results = repo.updateQuoteLines(bundles);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return results for all records');
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'Update should succeed');
        }
    }

    /**
     * @description Test updateQuoteLines with null input
     */
    @isTest
    static void testUpdateQuoteLines_NullInput() {
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<Database.SaveResult> results = repo.updateQuoteLines(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Null input should return empty results');
    }

    /**
     * @description Test deleteQuoteLines with valid records
     */
    @isTest
    static void testDeleteQuoteLines_Success() {
        List<SBQQ__QuoteLine__c> serviceLines = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c != null
            LIMIT 1
        ];

        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<Database.DeleteResult> results = repo.deleteQuoteLines(serviceLines);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return results for all records');
        System.assert(results[0].isSuccess(), 'Delete should succeed');
    }

    /**
     * @description Test deleteQuoteLines with empty list
     */
    @isTest
    static void testDeleteQuoteLines_EmptyInput() {
        QuoteLineRepository repo = new QuoteLineRepository();

        Test.startTest();
        List<Database.DeleteResult> results = repo.deleteQuoteLines(new List<SBQQ__QuoteLine__c>());
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty input should return empty results');
    }
}
