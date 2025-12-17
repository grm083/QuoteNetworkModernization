/**
 * @description Test class for DataAggregationService
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
@isTest
private class DataAggregationServiceTest {

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

        // Create test vendor
        Account testVendor = new Account(
            Name = 'Test Vendor',
            AccountNumber = 'VEND001',
            Vendor_Business_Unit__c = 'BU001',
            FacilityCode__c = 'FAC001'
        );
        insert testVendor;

        // Create MAS setup details
        List<MAS_Setup_Detail__c> masSetups = new List<MAS_Setup_Detail__c>();

        // Facility-based setup
        masSetups.add(new MAS_Setup_Detail__c(
            MAS_Library__c = 'LIB001',
            MAS_Company_Code__c = 'COMP001',
            MAS_Line_of_Business__c = 'Commercial',
            Facility_Id__c = 'FAC001',
            Business_Unit_Number__c = 'BU001',
            Valid_For_New_Service__c = true,
            Bypass_Price_Review__c = false,
            Is_Active__c = true
        ));

        // Business unit-based setup
        masSetups.add(new MAS_Setup_Detail__c(
            MAS_Library__c = 'LIB002',
            MAS_Company_Code__c = 'COMP002',
            MAS_Line_of_Business__c = 'Commercial',
            Business_Unit_Number__c = 'BU001',
            Valid_For_New_Service__c = false,
            Bypass_Price_Review__c = true,
            Is_Active__c = true
        ));

        // Industrial setup
        masSetups.add(new MAS_Setup_Detail__c(
            MAS_Library__c = 'LIB003',
            MAS_Company_Code__c = 'COMP003',
            MAS_Line_of_Business__c = 'Industrial',
            Business_Unit_Number__c = 'BU002',
            Valid_For_New_Service__c = false,
            Bypass_Price_Review__c = false,
            Is_Active__c = true
        ));

        insert masSetups;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        Product2 industrialProduct = new Product2(
            Name = 'Industrial Product',
            ProductCode = 'INDPROD',
            Family = 'Industrial Services',
            IsActive = true
        );
        insert industrialProduct;

        // Create test case and record type
        RecordType newServiceRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND DeveloperName = 'New_Service'
            LIMIT 1
        ];

        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            RecordTypeId = newServiceRT.Id
        );
        insert testCase;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Case__c = testCase.Id
        );
        insert testOpp;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            Case_Type__c = 'New Service'
        );
        insert testQuote;

        // Create quote line
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = testVendor.Id,
            SBQQ__NetTotal__c = 1000,
            SBQQ__ListTotal__c = 1200,
            SBQQ__CustomerTotal__c = 1100
        );
        insert quoteLine;

        // Create additional quote lines for aggregation tests
        List<SBQQ__QuoteLine__c> additionalLines = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < 3; i++) {
            additionalLines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Quantity__c = 1,
                Vendor__c = testVendor.Id,
                SBQQ__NetTotal__c = 500 * (i + 1),
                SBQQ__ListTotal__c = 600 * (i + 1),
                SBQQ__CustomerTotal__c = 550 * (i + 1)
            ));
        }
        insert additionalLines;
    }

    /**
     * @description Test getUniqueMASDetails with facility match
     */
    @isTest
    static void testGetUniqueMASDetails_FacilityMatch() {
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
            LIMIT 1
        ];

        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.getUniqueMASDetails(quoteLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return results');
        // Facility-based query should return the facility-specific setup
        System.assert(results.size() > 0, 'Should find MAS details by facility');
    }

    /**
     * @description Test getUniqueMASDetails with null quote line ID
     */
    @isTest
    static void testGetUniqueMASDetails_NullId() {
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.getUniqueMASDetails(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null ID');
    }

    /**
     * @description Test getUniqueMASDetails with industrial product
     */
    @isTest
    static void testGetUniqueMASDetails_IndustrialProduct() {
        // Create quote line with industrial product
        Product2 industrialProduct = [SELECT Id FROM Product2 WHERE Family = 'Industrial Services' LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Account vendor = [SELECT Id FROM Account WHERE FacilityCode__c = 'FAC001' LIMIT 1];

        SBQQ__QuoteLine__c industrialLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = industrialProduct.Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = vendor.Id
        );
        insert industrialLine;

        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.getUniqueMASDetails(industrialLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return results');
    }

    /**
     * @description Test aggregateQuoteLinesByProduct
     */
    @isTest
    static void testAggregateQuoteLinesByProduct() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.aggregateQuoteLinesByProduct(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return results');
        System.assert(results.size() > 0, 'Should have aggregated data');

        // Verify aggregation structure
        AggregateResult firstResult = results[0];
        System.assertNotEquals(null, firstResult.get('lineCount'), 'Should have line count');
        System.assertNotEquals(null, firstResult.get('totalNet'), 'Should have total net');
    }

    /**
     * @description Test aggregateQuoteLinesByProduct with null quote ID
     */
    @isTest
    static void testAggregateQuoteLinesByProduct_NullId() {
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.aggregateQuoteLinesByProduct(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null ID');
    }

    /**
     * @description Test aggregateQuoteLinesByVendor
     */
    @isTest
    static void testAggregateQuoteLinesByVendor() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.aggregateQuoteLinesByVendor(quote.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return results');
        System.assert(results.size() > 0, 'Should have aggregated vendor data');

        // Verify aggregation structure
        AggregateResult firstResult = results[0];
        System.assertNotEquals(null, firstResult.get('lineCount'), 'Should have line count');
        System.assertNotEquals(null, firstResult.get('totalCustomer'), 'Should have customer total');
    }

    /**
     * @description Test aggregateQuoteLinesByVendor with null quote ID
     */
    @isTest
    static void testAggregateQuoteLinesByVendor_NullId() {
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.aggregateQuoteLinesByVendor(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for null ID');
    }

    /**
     * @description Test getMASSetupStatistics
     */
    @isTest
    static void testGetMASSetupStatistics() {
        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        DataAggregationService.MASSetupStatistics stats = service.getMASSetupStatistics();
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Should return statistics');
        System.assert(stats.totalActiveSetups > 0, 'Should have active setups');
        System.assertNotEquals(null, stats.businessUnitCounts, 'Should have business unit counts');
        System.assertNotEquals(null, stats.lineOfBusinessCounts, 'Should have line of business counts');

        // Verify counts
        System.assert(stats.businessUnitCounts.size() > 0, 'Should have business unit data');
        System.assert(stats.lineOfBusinessCounts.size() > 0, 'Should have line of business data');
    }

    /**
     * @description Test MASSetupStatistics wrapper initialization
     */
    @isTest
    static void testMASSetupStatisticsWrapper() {
        Test.startTest();
        DataAggregationService.MASSetupStatistics stats = new DataAggregationService.MASSetupStatistics();
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Wrapper should be initialized');
        System.assertEquals(0, stats.totalActiveSetups, 'Default total should be 0');
        System.assertNotEquals(null, stats.businessUnitCounts, 'Map should be initialized');
        System.assertNotEquals(null, stats.lineOfBusinessCounts, 'Map should be initialized');
    }

    /**
     * @description Test error handling in getUniqueMASDetails
     */
    @isTest
    static void testGetUniqueMASDetails_ErrorHandling() {
        // Create a quote line without required relationships to trigger error
        SBQQ__QuoteLine__c orphanLine = new SBQQ__QuoteLine__c(
            SBQQ__Quantity__c = 1
        );

        DataAggregationService service = new DataAggregationService();

        Test.startTest();
        List<AggregateResult> results = service.getUniqueMASDetails(orphanLine.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list on error');
    }
}
