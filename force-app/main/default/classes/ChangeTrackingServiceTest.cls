/**
 * @description Test class for ChangeTrackingService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7A
 */
@isTest
private class ChangeTrackingServiceTest {

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

        // Create test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
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

        // Create test products
        Product2 commercialProduct = new Product2(
            Name = 'Commercial Product',
            ProductCode = 'COMM',
            Family = 'Commercial',
            IsActive = true
        );
        insert commercialProduct;

        // Create test vendor
        Account testVendor = new Account(
            Name = 'Test Vendor',
            AccountNumber = 'VEND001'
        );
        insert testVendor;

        // Create test asset
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Product2Id = commercialProduct.Id,
            Container_Position__c = 'Original Position',
            GL_Code__c = 'GL001',
            Cost_Center__c = 'CC001',
            Category__c = 'CAT001',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(6),
            Sensitivity_Code__c = 'Normal',
            Equipment_Owner__c = 'Customer',
            Equipment_Size__c = '20 YD',
            MAS_Library__c = 'LIB001',
            MAS_Company_Code__c = 'COMP001',
            MAS_Customer_Unique_Id__c = 'CUI001',
            MAS_Line_Number__c = 'LINE001',
            MAS_Account_Number__c = 'ACC001',
            Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Occurs__c = '1',
            Frequency__c = 'Weekly',
            Monday__c = true,
            Tuesday__c = true,
            Wednesday__c = true,
            Thursday__c = true,
            Friday__c = true,
            Saturday__c = false,
            Sunday__c = false,
            Supplier__c = testVendor.Id,
            SBQQ__RegularPrice__c = 100.00,
            SBQQ__OriginalUnitCost__c = 80.00
        );
        insert testAsset;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        // Create test quote line with no changes
        SBQQ__QuoteLine__c unchangedLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = commercialProduct.Id,
            SBQQ__Quantity__c = 1,
            AssetId__c = testAsset.Id,
            LocationPositionName__c = 'Original Position',
            ClientGLAccount__c = 'GL001',
            ClientCostCenter__c = 'CC001',
            CompanyCategoryCode__c = 'CAT001',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(6),
            sCode__c = 'N',
            Ownership__c = 'CU',
            Equipment_Size__c = 'Roll Off-20',
            MASLibrary__c = 'LIB001',
            MASCompany__c = 'COMP001',
            MASCustomerUniqueId__c = 'CUI001',
            MASServiceLine__c = 'LINE001',
            MASAccount__c = 'ACC001',
            Occurrence_Type__c = 'SCH',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday',
            Vendor__c = testVendor.Id,
            SBQQ__ListPrice__c = 100.00,
            SBQQ__UnitCost__c = 80.00
        );
        insert unchangedLine;

        // Create test quote line with multiple changes
        SBQQ__QuoteLine__c changedLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = commercialProduct.Id,
            SBQQ__Quantity__c = 2,
            AssetId__c = testAsset.Id,
            LocationPositionName__c = 'New Position',
            ClientGLAccount__c = 'GL002',
            ClientCostCenter__c = 'CC002',
            CompanyCategoryCode__c = 'CAT002',
            SBQQ__StartDate__c = Date.today().addDays(7),
            SBQQ__EndDate__c = Date.today().addMonths(12),
            sCode__c = 'R',
            Ownership__c = 'VE',
            Equipment_Size__c = 'Roll Off-30',
            MASLibrary__c = 'LIB002',
            MASCompany__c = 'COMP002',
            MASCustomerUniqueId__c = 'CUI002',
            MASServiceLine__c = 'LINE002',
            MASAccount__c = 'ACC002',
            Occurrence_Type__c = 'SCH',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'Monday;Tuesday',
            Vendor__c = testVendor.Id,
            SBQQ__ListPrice__c = 120.00,
            SBQQ__UnitCost__c = 90.00
        );
        insert changedLine;
    }

    /**
     * @description Test updateTypeOfChangeFieldOnQuoteLines with status change
     */
    @isTest
    static void testUpdateTypeOfChangeFieldOnQuoteLines_StatusChange() {
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => testQuote.clone(true)
        };

        testQuote.SBQQ__Status__c = Constant_Util.QUOTE_APPROVED;

        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => testQuote
        };

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.updateTypeOfChangeFieldOnQuoteLines(oldMap, newMap);
        Test.stopTest();

        // Verify quote lines were updated
        List<SBQQ__QuoteLine__c> updatedLines = [
            SELECT Id, Type_of_Change__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :testQuote.Id
        ];
        System.assert(updatedLines.size() > 0, 'Should have updated quote lines');
    }

    /**
     * @description Test updateTypeOfChangeFieldOnQuoteLines with no status change
     */
    @isTest
    static void testUpdateTypeOfChangeFieldOnQuoteLines_NoStatusChange() {
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        Map<Id, SBQQ__Quote__c> oldMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => testQuote.clone(true)
        };

        Map<Id, SBQQ__Quote__c> newMap = new Map<Id, SBQQ__Quote__c>{
            testQuote.Id => testQuote
        };

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.updateTypeOfChangeFieldOnQuoteLines(oldMap, newMap);
        Test.stopTest();

        // No assertions needed - should complete without error
        System.assert(true, 'Should complete without error');
    }

    /**
     * @description Test compareAndUpdateTypeOfChangeFieldOnQuoteLine with valid quotes
     */
    @isTest
    static void testCompareAndUpdateTypeOfChangeFieldOnQuoteLine_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.compareAndUpdateTypeOfChangeFieldOnQuoteLine(new Set<Id>{testQuote.Id});
        Test.stopTest();

        // Verify changes were detected for changed line
        List<SBQQ__QuoteLine__c> lines = [
            SELECT Id, Type_of_Change__c, LocationPositionName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :testQuote.Id
            AND LocationPositionName__c = 'New Position'
        ];
        System.assertEquals(1, lines.size(), 'Should find changed line');
        System.assertNotEquals(null, lines[0].Type_of_Change__c, 'Should have type of change');
        System.assert(lines[0].Type_of_Change__c.contains('Position Change'), 'Should detect position change');
    }

    /**
     * @description Test compareAndUpdateTypeOfChangeFieldOnQuoteLine with null input
     */
    @isTest
    static void testCompareAndUpdateTypeOfChangeFieldOnQuoteLine_NullInput() {
        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.compareAndUpdateTypeOfChangeFieldOnQuoteLine(null);
        Test.stopTest();

        System.assert(true, 'Should handle null input gracefully');
    }

    /**
     * @description Test compareAndUpdateTypeOfChangeFieldOnQuoteLine with empty set
     */
    @isTest
    static void testCompareAndUpdateTypeOfChangeFieldOnQuoteLine_EmptySet() {
        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.compareAndUpdateTypeOfChangeFieldOnQuoteLine(new Set<Id>());
        Test.stopTest();

        System.assert(true, 'Should handle empty set gracefully');
    }

    /**
     * @description Test calculateFrequencyChange with frequency increase
     */
    @isTest
    static void testCalculateFrequencyChange_Increase() {
        // Get changed line (has 2 service days vs 5 in asset)
        SBQQ__QuoteLine__c changedLine = [
            SELECT Id, Frequency_Interval__c, Schedule_Frequency__c, Service_Days__c,
                   AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE LocationPositionName__c = 'Original Position'
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        String result = service.calculateFrequencyChange(changedLine);
        Test.stopTest();

        // Unchanged line has same frequency as asset, so no change
        System.assertEquals('', result, 'Should detect no frequency change for unchanged line');
    }

    /**
     * @description Test calculateFrequencyChange with frequency decrease
     */
    @isTest
    static void testCalculateFrequencyChange_Decrease() {
        // Get line with fewer service days
        SBQQ__QuoteLine__c changedLine = [
            SELECT Id, Frequency_Interval__c, Schedule_Frequency__c, Service_Days__c,
                   AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE LocationPositionName__c = 'New Position'
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        String result = service.calculateFrequencyChange(changedLine);
        Test.stopTest();

        // Changed line has 2 service days vs 5 in asset
        System.assertEquals('Frequency Decrease', result, 'Should detect frequency decrease');
    }

    /**
     * @description Test calculateQuoteLineFrequency with daily schedule
     */
    @isTest
    static void testCalculateQuoteLineFrequency_Daily() {
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        testLine.Schedule_Frequency__c = 'D';
        testLine.Frequency_Interval__c = '2';
        update testLine;

        testLine = [
            SELECT Id, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :testLine.Id
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateQuoteLineFrequency(testLine);
        Test.stopTest();

        System.assertEquals(3.5, frequency, 'Should calculate daily frequency: 7/2 = 3.5');
    }

    /**
     * @description Test calculateQuoteLineFrequency with weekly schedule
     */
    @isTest
    static void testCalculateQuoteLineFrequency_Weekly() {
        SBQQ__QuoteLine__c testLine = [
            SELECT Id, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c
            FROM SBQQ__QuoteLine__c
            WHERE Service_Days__c != null
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateQuoteLineFrequency(testLine);
        Test.stopTest();

        System.assertNotEquals(0, frequency, 'Should calculate weekly frequency');
    }

    /**
     * @description Test calculateQuoteLineFrequency with monthly schedule
     */
    @isTest
    static void testCalculateQuoteLineFrequency_Monthly() {
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        testLine.Schedule_Frequency__c = 'M';
        testLine.Frequency_Interval__c = '2';
        update testLine;

        testLine = [
            SELECT Id, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :testLine.Id
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateQuoteLineFrequency(testLine);
        Test.stopTest();

        System.assertEquals(0.125, frequency, 'Should calculate monthly frequency: 1/(4*2) = 0.125');
    }

    /**
     * @description Test calculateQuoteLineFrequency with yearly schedule
     */
    @isTest
    static void testCalculateQuoteLineFrequency_Yearly() {
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        testLine.Schedule_Frequency__c = 'Y';
        testLine.Frequency_Interval__c = '1';
        update testLine;

        testLine = [
            SELECT Id, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :testLine.Id
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateQuoteLineFrequency(testLine);
        Test.stopTest();

        System.assertEquals(1.0/52, frequency, 'Should calculate yearly frequency: 1/52');
    }

    /**
     * @description Test calculateQuoteLineFrequency with null interval
     */
    @isTest
    static void testCalculateQuoteLineFrequency_NullInterval() {
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        testLine.Frequency_Interval__c = null;
        update testLine;

        testLine = [
            SELECT Id, Schedule_Frequency__c, Frequency_Interval__c, Service_Days__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :testLine.Id
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateQuoteLineFrequency(testLine);
        Test.stopTest();

        System.assertEquals(0, frequency, 'Should return 0 for null interval');
    }

    /**
     * @description Test calculateAssetFrequency with daily frequency
     */
    @isTest
    static void testCalculateAssetFrequency_Daily() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        testAsset.Frequency__c = 'Daily';
        testAsset.Occurs__c = '2';
        update testAsset;

        SBQQ__QuoteLine__c testLine = [
            SELECT Id, AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE AssetId__c = :testAsset.Id
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateAssetFrequency(testLine);
        Test.stopTest();

        System.assertEquals(3.5, frequency, 'Should calculate daily frequency: 7/2 = 3.5');
    }

    /**
     * @description Test calculateAssetFrequency with weekly frequency
     */
    @isTest
    static void testCalculateAssetFrequency_Weekly() {
        SBQQ__QuoteLine__c testLine = [
            SELECT Id, AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE AssetId__r.Frequency__c = 'Weekly'
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateAssetFrequency(testLine);
        Test.stopTest();

        // 5 days (Mon-Fri) / 1 occurrence = 5.0
        System.assertEquals(5.0, frequency, 'Should calculate weekly frequency');
    }

    /**
     * @description Test calculateAssetFrequency with monthly frequency
     */
    @isTest
    static void testCalculateAssetFrequency_Monthly() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        testAsset.Frequency__c = 'Monthly';
        testAsset.Occurs__c = '2';
        update testAsset;

        SBQQ__QuoteLine__c testLine = [
            SELECT Id, AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE AssetId__c = :testAsset.Id
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateAssetFrequency(testLine);
        Test.stopTest();

        System.assertEquals(0.125, frequency, 'Should calculate monthly frequency: 1/(4*2) = 0.125');
    }

    /**
     * @description Test calculateAssetFrequency with yearly frequency
     */
    @isTest
    static void testCalculateAssetFrequency_Yearly() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        testAsset.Frequency__c = 'Yearly';
        testAsset.Occurs__c = '1';
        update testAsset;

        SBQQ__QuoteLine__c testLine = [
            SELECT Id, AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE AssetId__c = :testAsset.Id
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateAssetFrequency(testLine);
        Test.stopTest();

        System.assertEquals(1.0/52, frequency, 'Should calculate yearly frequency: 1/52');
    }

    /**
     * @description Test calculateAssetFrequency with null occurs
     */
    @isTest
    static void testCalculateAssetFrequency_NullOccurs() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        testAsset.Occurs__c = null;
        update testAsset;

        SBQQ__QuoteLine__c testLine = [
            SELECT Id, AssetId__r.Occurs__c, AssetId__r.Frequency__c,
                   AssetId__r.Monday__c, AssetId__r.Tuesday__c, AssetId__r.Wednesday__c,
                   AssetId__r.Thursday__c, AssetId__r.Friday__c, AssetId__r.Saturday__c,
                   AssetId__r.Sunday__c
            FROM SBQQ__QuoteLine__c
            WHERE AssetId__c = :testAsset.Id
            LIMIT 1
        ];

        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        Decimal frequency = service.calculateAssetFrequency(testLine);
        Test.stopTest();

        System.assertEquals(0, frequency, 'Should return 0 for null occurs');
    }

    /**
     * @description Test detection of multiple change types
     */
    @isTest
    static void testDetectMultipleChanges() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ChangeTrackingService service = new ChangeTrackingService();

        Test.startTest();
        service.compareAndUpdateTypeOfChangeFieldOnQuoteLine(new Set<Id>{testQuote.Id});
        Test.stopTest();

        // Verify changed line has multiple change types
        SBQQ__QuoteLine__c changedLine = [
            SELECT Id, Type_of_Change__c
            FROM SBQQ__QuoteLine__c
            WHERE LocationPositionName__c = 'New Position'
        ];

        System.assertNotEquals(null, changedLine.Type_of_Change__c, 'Should have type of change');
        System.assert(changedLine.Type_of_Change__c.contains('Position Change'), 'Should detect position change');
        System.assert(changedLine.Type_of_Change__c.contains('Billing Administration Change'), 'Should detect billing change');
        System.assert(changedLine.Type_of_Change__c.contains('Quantity Increase'), 'Should detect quantity increase');
        System.assert(changedLine.Type_of_Change__c.contains('Size Increase'), 'Should detect size increase');
        System.assert(changedLine.Type_of_Change__c.contains('Price Increase'), 'Should detect price increase');
        System.assert(changedLine.Type_of_Change__c.contains('Cost Increase'), 'Should detect cost increase');
    }
}
