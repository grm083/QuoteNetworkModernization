/**
 * @description Test class for DeliveryOrchestrationService
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 10.3: Delivery Orchestration Expansion
 */
@isTest
private class DeliveryOrchestrationServiceTest {

    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST123'
        );
        insert testAccount;

        // Create test products
        Product2 parentProduct = new Product2(
            Name = 'Test Commercial Product',
            ProductCode = 'TEST_COMM_001',
            Family = 'Commercial',
            IsActive = true
        );
        insert parentProduct;

        Product2 removalProduct = new Product2(
            Name = 'Removal',
            ProductCode = 'REMOVAL',
            Family = 'Commercial',
            IsActive = true
        );
        insert removalProduct;

        Product2 haulProduct = new Product2(
            Name = 'Haul',
            ProductCode = 'HAUL',
            Family = 'Rolloff',
            IsActive = true
        );
        insert haulProduct;

        // Create product options
        SBQQ__ProductOption__c removalOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = parentProduct.Id,
            SBQQ__OptionalSKU__c = removalProduct.Id,
            Occurrence_Type__c = 'ONC',
            Cost_Unit_of_Measure__c = 'EA',
            CostModelType__c = 'STP',
            PriceUOM__c = 'EA'
        );
        insert removalOption;

        SBQQ__ProductOption__c haulOption = new SBQQ__ProductOption__c(
            SBQQ__ConfiguredSKU__c = parentProduct.Id,
            SBQQ__OptionalSKU__c = haulProduct.Id,
            Occurrence_Type__c = 'ONC',
            Cost_Unit_of_Measure__c = 'EA',
            CostModelType__c = 'STP',
            PriceUOM__c = 'EA'
        );
        insert haulOption;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(365)
        );
        insert testQuote;

        // Create parent quote line
        SBQQ__QuoteLine__c parentQL = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = parentProduct.Id,
            SBQQ__Quantity__c = 1,
            Account__c = testAccount.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(365),
            Equipment_Size__c = '8 YD',
            Occurrence_Type__c = 'SOC',
            Schedule_Frequency__c = 'W',
            Duration__c = 'TEMP',
            SBQQ__ProductFamily__c = 'Commercial',
            SBQQ__Number__c = 1
        );
        insert parentQL;
    }

    @isTest
    static void testValidateRemoval_CreateNew() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Get test data
        SBQQ__QuoteLine__c parentQL = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, Duration__c,
                   Month_Relative_Interval__c, Month_Relative__c, SBQQ__Product__c,
                   SBQQ__ProductFamily__c, SBQQ__Quote__r.SBQQ__Type__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            LIMIT 1
        ];

        Test.startTest();
        String result = service.validateRemoval(parentQL, '12/31/2025');
        Test.stopTest();

        System.assertEquals('SUCCESS', result, 'Removal validation should succeed');

        // Verify removal quote line was created
        List<SBQQ__QuoteLine__c> removalQLs = [
            SELECT Id, SBQQ__ProductName__c, SBQQ__RequiredBy__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :parentQL.Id
            AND SBQQ__ProductName__c = 'Removal'
        ];
        System.assertEquals(1, removalQLs.size(), 'One removal quote line should be created');
    }

    @isTest
    static void testValidateRemoval_Update() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Get test data
        SBQQ__QuoteLine__c parentQL = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, Duration__c,
                   Month_Relative_Interval__c, Month_Relative__c, SBQQ__Product__c,
                   SBQQ__ProductFamily__c, SBQQ__Quote__r.SBQQ__Type__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            LIMIT 1
        ];

        // Create initial removal quote line
        service.validateRemoval(parentQL, '12/31/2025');

        Test.startTest();
        // Update with new end date
        String result = service.validateRemoval(parentQL, '12/31/2026');
        Test.stopTest();

        System.assertEquals('SUCCESS', result, 'Removal update should succeed');

        // Verify still only one removal quote line
        List<SBQQ__QuoteLine__c> removalQLs = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :parentQL.Id
            AND SBQQ__ProductName__c = 'Removal'
        ];
        System.assertEquals(1, removalQLs.size(), 'Should still have only one removal quote line');
    }

    @isTest
    static void testValidateHaul_CreateNew() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Update parent to Rolloff family
        SBQQ__QuoteLine__c parentQL = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];
        parentQL.SBQQ__ProductFamily__c = 'Rolloff';
        update parentQL;

        // Re-query with all fields
        parentQL = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, Duration__c,
                   Month_Relative_Interval__c, Month_Relative__c, SBQQ__Product__c,
                   SBQQ__ProductFamily__c, SBQQ__Quote__r.SBQQ__Type__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :parentQL.Id
        ];

        Test.startTest();
        String result = service.validateHaul(parentQL, '12/31/2025');
        Test.stopTest();

        System.assertEquals('SUCCESS', result, 'Haul validation should succeed');

        // Verify haul quote line was created
        List<SBQQ__QuoteLine__c> haulQLs = [
            SELECT Id, SBQQ__ProductName__c, SBQQ__RequiredBy__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :parentQL.Id
            AND SBQQ__ProductName__c = 'Haul'
        ];
        System.assertEquals(1, haulQLs.size(), 'One haul quote line should be created');
    }

    @isTest
    static void testAssignParentQLineFields() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Get test data
        SBQQ__QuoteLine__c parentQL = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, Duration__c,
                   Month_Relative_Interval__c, Month_Relative__c
            FROM SBQQ__QuoteLine__c
            LIMIT 1
        ];

        Test.startTest();
        SBQQ__QuoteLine__c childQL = service.assignParentQLineFields(parentQL);
        Test.stopTest();

        System.assertEquals(parentQL.SBQQ__Quote__c, childQL.SBQQ__Quote__c, 'Quote should match');
        System.assertEquals(parentQL.Id, childQL.SBQQ__RequiredBy__c, 'Required by should be parent ID');
        System.assertEquals(parentQL.Account__c, childQL.Account__c, 'Account should match');
        System.assertEquals(parentQL.Equipment_Size__c, childQL.Equipment_Size__c, 'Equipment size should match');
        System.assertEquals(parentQL.Occurrence_Type__c, childQL.Occurrence_Type__c, 'Occurrence type should match');
    }

    @isTest
    static void testGetQLine_Found() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Get parent quote line
        SBQQ__QuoteLine__c parentQL = [
            SELECT Id, SBQQ__Quote__c, Account__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                   Exception_Type__c, Exception_Comments__c, Exception_Reason__c,
                   Equipment_Size__c, Occurrence_Type__c, Schedule_Frequency__c,
                   Frequency_Interval__c, Day_of_Month__c, Service_Days__c, Duration__c,
                   Month_Relative_Interval__c, Month_Relative__c, SBQQ__Product__c,
                   SBQQ__ProductFamily__c, SBQQ__Quote__r.SBQQ__Type__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductFamily__c = 'Commercial'
            LIMIT 1
        ];

        // Create removal quote line
        service.validateRemoval(parentQL, '12/31/2025');

        Test.startTest();
        SBQQ__QuoteLine__c removalQL = service.getQLine(parentQL.Id, 'Removal');
        Test.stopTest();

        System.assertNotEquals(null, removalQL, 'Should find removal quote line');
        System.assertEquals('Removal', removalQL.SBQQ__ProductName__c, 'Product name should be Removal');
    }

    @isTest
    static void testGetQLine_NotFound() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        SBQQ__QuoteLine__c parentQL = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        Test.startTest();
        SBQQ__QuoteLine__c result = service.getQLine(parentQL.Id, 'NonExistent');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for non-existent product');
    }

    @isTest
    static void testGetParentQline() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        SBQQ__QuoteLine__c parentQL = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        Test.startTest();
        SBQQ__QuoteLine__c result = service.getParentQline(parentQL.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should find parent quote line');
        System.assertEquals(parentQL.Id, result.Id, 'IDs should match');
    }

    @isTest
    static void testGetProductId_Found() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        Product2 parentProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Commercial Product' LIMIT 1];

        Test.startTest();
        Id productId = service.getProductId('Removal', parentProduct.Id);
        Test.stopTest();

        System.assertNotEquals(null, productId, 'Should find Removal product ID');
    }

    @isTest
    static void testGetProductId_NotFound() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        Product2 parentProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Commercial Product' LIMIT 1];

        Test.startTest();
        Id productId = service.getProductId('NonExistent', parentProduct.Id);
        Test.stopTest();

        System.assertEquals(null, productId, 'Should return null for non-existent product');
    }

    @isTest
    static void testGetProductOptionId_Found() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        Product2 parentProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Commercial Product' LIMIT 1];
        Product2 removalProduct = [SELECT Id FROM Product2 WHERE Name = 'Removal' LIMIT 1];

        Test.startTest();
        SBQQ__ProductOption__c option = service.getProductOptionId(parentProduct.Id, removalProduct.Id);
        Test.stopTest();

        System.assertNotEquals(null, option.Id, 'Should find product option');
        System.assertEquals('ONC', option.Occurrence_Type__c, 'Occurrence type should match');
    }

    @isTest
    static void testGetProductOptionId_NotFound() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        Product2 parentProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Commercial Product' LIMIT 1];
        Id fakeProductId = '01t000000000000AAA';

        Test.startTest();
        SBQQ__ProductOption__c option = service.getProductOptionId(parentProduct.Id, fakeProductId);
        Test.stopTest();

        System.assertEquals(null, option.Id, 'Should return empty product option');
    }

    @isTest
    static void testGetMaxQuoteLineNumber_WithExisting() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
        Decimal maxNumber = service.getMaxQuoteLineNumber(quote.Id);
        Test.stopTest();

        System.assertEquals(2, maxNumber, 'Should return 2 (max 1 + 1)');
    }

    @isTest
    static void testGetMaxQuoteLineNumber_NoExisting() {
        DeliveryOrchestrationService service = new DeliveryOrchestrationService();

        // Create new quote with no quote lines
        Account acc = [SELECT Id FROM Account LIMIT 1];
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Type__c = 'Quote',
            SBQQ__StartDate__c = Date.today()
        );
        insert newQuote;

        Test.startTest();
        Decimal maxNumber = service.getMaxQuoteLineNumber(newQuote.Id);
        Test.stopTest();

        System.assertEquals(1, maxNumber, 'Should return 1 for first quote line');
    }
}
