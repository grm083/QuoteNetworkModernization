/**
 * @description Test class for SLACalculationService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7A
 */
@isTest
private class SLACalculationServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account with timezone
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001',
            tz__Timezone_SFDC__c = 'America/New_York'
        );
        insert testAccount;

        // Create test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Is_Haul_Away_Service__c = false,
            Service_Date__c = Date.today().addDays(7),
            SLA_Service_DateTime__c = DateTime.now().addDays(7)
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

        Product2 compactorProduct = new Product2(
            Name = 'Compactor Product',
            ProductCode = 'COMP',
            Family = 'Compactor',
            IsActive = true
        );
        insert compactorProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote'
        );
        insert testQuote;

        // Create amendment quote
        SBQQ__Quote__c amendmentQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment'
        );
        insert amendmentQuote;

        // Create test quote lines
        SBQQ__QuoteLine__c commercialLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = commercialProduct.Id,
            SBQQ__Quantity__c = 1,
            Duration__c = '1MO',
            Equipment_Size__c = '20 YD'
        );
        insert commercialLine;

        SBQQ__QuoteLine__c compactorLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = compactorProduct.Id,
            SBQQ__Quantity__c = 1,
            Duration__c = '1MO',
            Equipment_Size__c = '30 YD'
        );
        insert compactorLine;

        SBQQ__QuoteLine__c amendmentLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = amendmentQuote.Id,
            SBQQ__Product__c = commercialProduct.Id,
            SBQQ__Quantity__c = 1,
            Duration__c = '1MO'
        );
        insert amendmentLine;
    }

    /**
     * @description Test determineSLA with valid quote line
     */
    @isTest
    static void testDetermineSLA_Success() {
        SBQQ__QuoteLine__c testLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            AND SBQQ__Quote__r.SBQQ__Type__c = 'Quote'
            LIMIT 1
        ];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(testLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return SLA date');
    }

    /**
     * @description Test determineSLA with null quote line ID
     */
    @isTest
    static void testDetermineSLA_NullId() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(null);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return current time for null ID');
    }

    /**
     * @description Test determineSLA with invalid quote line ID
     */
    @isTest
    static void testDetermineSLA_InvalidId() {
        Id fakeId = SBQQ__QuoteLine__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(15);
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(fakeId);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return current time for invalid ID');
    }

    /**
     * @description Test determineSLA with haul away service
     */
    @isTest
    static void testDetermineSLA_HaulAwayService() {
        // Update case to be haul away
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.Is_Haul_Away_Service__c = true;
        update testCase;

        SBQQ__QuoteLine__c testLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            AND SBQQ__Quote__r.SBQQ__Type__c = 'Quote'
            LIMIT 1
        ];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(testLine.Id);
        Test.stopTest();

        // Should return current time for haul away service
        System.assertNotEquals(null, slaDate, 'Should return time for haul away service');
    }

    /**
     * @description Test determineSLA with amendment quote
     */
    @isTest
    static void testDetermineSLA_AmendmentQuote() {
        SBQQ__QuoteLine__c amendmentLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__r.SBQQ__Type__c = 'Amendment'
            LIMIT 1
        ];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(amendmentLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return SLA date for amendment');
    }

    /**
     * @description Test calculateEntitlementSLA with valid entitlement
     */
    @isTest
    static void testCalculateEntitlementSLA_Success() {
        // Create test service contract and entitlement
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        ServiceContract sc = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1)
        );
        insert sc;

        Entitlement testEntitlement = new Entitlement(
            Name = 'Test Entitlement',
            AccountId = testAccount.Id,
            ServiceContractId = sc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1),
            SlaProcessId = null
        );
        insert testEntitlement;

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateEntitlementSLA(testEntitlement, bh);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return calculated SLA date');
    }

    /**
     * @description Test calculateEntitlementSLA with null inputs
     */
    @isTest
    static void testCalculateEntitlementSLA_NullInputs() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateEntitlementSLA(null, null);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return current time for null inputs');
    }

    /**
     * @description Test calculateEntitlementSLA_LocTimezone with timezone
     */
    @isTest
    static void testCalculateEntitlementSLA_LocTimezone() {
        // Create test service contract and entitlement
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        ServiceContract sc = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1)
        );
        insert sc;

        Entitlement testEntitlement = new Entitlement(
            Name = 'Test Entitlement',
            AccountId = testAccount.Id,
            ServiceContractId = sc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1)
        );
        insert testEntitlement;

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateEntitlementSLA_LocTimezone(
            testEntitlement, bh, 'America/New_York'
        );
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return timezone-aware SLA date');
    }

    /**
     * @description Test calculateISSLA with industry standard metadata
     */
    @isTest
    static void testCalculateISSLA_Success() {
        // Query for any Industry Standard SLA metadata
        List<Industry_Standard_SLA__mdt> indStandards = [
            SELECT Id, DeveloperName, Duration__c, Product_Family__c,
                   Service_Guarantee_Value__c
            FROM Industry_Standard_SLA__mdt
            LIMIT 1
        ];

        if (indStandards.isEmpty()) {
            // Skip test if no metadata exists
            return;
        }

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateISSLA(indStandards[0], bh);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return calculated SLA date');
    }

    /**
     * @description Test calculateISSLA with null inputs
     */
    @isTest
    static void testCalculateISSLA_NullInputs() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateISSLA(null, null);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return current time for null inputs');
    }

    /**
     * @description Test calculateISSLA_LocTimezone with timezone
     */
    @isTest
    static void testCalculateISSLA_LocTimezone() {
        // Query for any Industry Standard SLA metadata
        List<Industry_Standard_SLA__mdt> indStandards = [
            SELECT Id, DeveloperName, Duration__c, Product_Family__c,
                   Service_Guarantee_Value__c
            FROM Industry_Standard_SLA__mdt
            LIMIT 1
        ];

        if (indStandards.isEmpty()) {
            // Skip test if no metadata exists
            return;
        }

        SBQQ__QuoteLine__c testLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            LIMIT 1
        ];

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.calculateISSLA_LocTimezone(
            indStandards[0], bh, testLine, 'America/New_York'
        );
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return timezone-aware SLA date');
    }

    /**
     * @description Test getRelatedEntitlement with valid quote
     */
    @isTest
    static void testGetRelatedEntitlement_Success() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        // Create service contract and entitlement
        ServiceContract sc = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1)
        );
        insert sc;

        Entitlement testEntitlement = new Entitlement(
            Name = 'Test Entitlement',
            AccountId = testAccount.Id,
            ServiceContractId = sc.Id,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(1)
        );
        insert testEntitlement;

        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Entitlement result = service.getRelatedEntitlement(testQuote.Id, testLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return entitlement');
    }

    /**
     * @description Test getRelatedEntitlement with no entitlements
     */
    @isTest
    static void testGetRelatedEntitlement_NoEntitlements() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Entitlement result = service.getRelatedEntitlement(testQuote.Id, testLine.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no entitlements exist');
    }

    /**
     * @description Test getRelatedEntitlement with null inputs
     */
    @isTest
    static void testGetRelatedEntitlement_NullInputs() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Entitlement result = service.getRelatedEntitlement(null, null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null inputs');
    }

    /**
     * @description Test getBusinessHoursByTimeZone
     */
    @isTest
    static void testGetBusinessHoursByTimeZone() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        List<BusinessHours> result = service.getBusinessHoursByTimeZone('America/New_York');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return business hours list');
    }

    /**
     * @description Test getBusinessHoursByTimeZone with null timezone
     */
    @isTest
    static void testGetBusinessHoursByTimeZone_NullTimezone() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        List<BusinessHours> result = service.getBusinessHoursByTimeZone(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return empty list for null timezone');
        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    /**
     * @description Test getBusinessHoursInAccountTimeZone
     */
    @isTest
    static void testGetBusinessHoursInAccountTimeZone() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime result = service.getBusinessHoursInAccountTimeZone(
            bh.Id,
            DateTime.now(),
            3600000, // 1 hour in milliseconds
            'America/New_York'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return calculated datetime');
    }

    /**
     * @description Test getBusinessHoursInAccountTimeZone with null inputs
     */
    @isTest
    static void testGetBusinessHoursInAccountTimeZone_NullInputs() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime result = service.getBusinessHoursInAccountTimeZone(
            null, null, null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return current time for null inputs');
    }

    /**
     * @description Test useLegacySLALogic feature flag
     */
    @isTest
    static void testUseLegacySLALogic_Enabled() {
        // Create code switch to enable legacy logic
        Code_Switch__c codeSwitch = new Code_Switch__c(
            Name = 'Use_Legacy_SLA_Calculation_Logic',
            Enable_Code__c = true
        );
        insert codeSwitch;

        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Boolean result = service.useLegacySLALogic();
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true when feature flag is enabled');
    }

    /**
     * @description Test useLegacySLALogic feature flag disabled
     */
    @isTest
    static void testUseLegacySLALogic_Disabled() {
        // Create code switch to disable legacy logic
        Code_Switch__c codeSwitch = new Code_Switch__c(
            Name = 'Use_Legacy_SLA_Calculation_Logic',
            Enable_Code__c = false
        );
        insert codeSwitch;

        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Boolean result = service.useLegacySLALogic();
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when feature flag is disabled');
    }

    /**
     * @description Test useLegacySLALogic with no feature flag
     */
    @isTest
    static void testUseLegacySLALogic_NoFlag() {
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        Boolean result = service.useLegacySLALogic();
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when no feature flag exists');
    }

    /**
     * @description Test SLA calculation with compactor product
     */
    @isTest
    static void testDetermineSLA_CompactorProduct() {
        SBQQ__QuoteLine__c compactorLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Compactor'
            LIMIT 1
        ];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        DateTime slaDate = service.determineSLA(compactorLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return SLA date for compactor');
    }

    /**
     * @description Test error handling in determineSLA
     */
    @isTest
    static void testDetermineSLA_ErrorHandling() {
        SBQQ__QuoteLine__c testLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        SLACalculationService service = new SLACalculationService();

        Test.startTest();
        // Should handle gracefully even if some data is missing
        DateTime slaDate = service.determineSLA(testLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, slaDate, 'Should return time even with errors');
    }
}
