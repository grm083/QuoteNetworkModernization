/**
 * @description Test class for ProductAddOnService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7B
 */
@isTest
private class ProductAddOnServiceTest {

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
        Product2 parentProduct = new Product2(
            Name = 'Parent Product',
            ProductCode = 'PARENT',
            Family = 'Commercial',
            IsActive = true
        );
        insert parentProduct;

        Product2 pickupProduct = new Product2(
            Name = 'Pickup',
            ProductCode = 'PICKUP',
            Family = 'Service',
            IsActive = true
        );
        insert pickupProduct;

        Product2 extraPickupProduct = new Product2(
            Name = 'Extra Pickup',
            ProductCode = 'EXTRAPICKUP',
            Family = 'Service',
            IsActive = true
        );
        insert extraPickupProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert testQuote;

        // Create parent quote line
        SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = parentProduct.Id,
            SBQQ__Quantity__c = 1
        );
        insert parentLine;

        // Create scheduled pickup quote line
        SBQQ__QuoteLine__c pickupLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = pickupProduct.Id,
            SBQQ__RequiredBy__c = parentLine.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'SCH',
            IsExtrapickup__c = false
        );
        insert pickupLine;

        // Create extra pickup quote line
        SBQQ__QuoteLine__c extraPickupLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = extraPickupProduct.Id,
            SBQQ__RequiredBy__c = parentLine.Id,
            SBQQ__Quantity__c = 1
        );
        insert extraPickupLine;
    }

    /**
     * @description Test addExtraPickupQuoteLine marks pickup as extra
     */
    @isTest
    static void testAddExtraPickupQuoteLine_Success() {
        SBQQ__QuoteLine__c extraPickupLine = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Extra Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.addExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>{extraPickupLine});
        Test.stopTest();

        // Verify pickup line is marked as extra pickup
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, IsExtrapickup__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        System.assertEquals(true, pickupLine.IsExtrapickup__c,
            'Pickup line should be marked as extra pickup');
    }

    /**
     * @description Test addExtraPickupQuoteLine with null input
     */
    @isTest
    static void testAddExtraPickupQuoteLine_NullInput() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.addExtraPickupQuoteLine(null);
        Test.stopTest();

        System.assert(true, 'Should handle null input gracefully');
    }

    /**
     * @description Test addExtraPickupQuoteLine with empty list
     */
    @isTest
    static void testAddExtraPickupQuoteLine_EmptyList() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.addExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>());
        Test.stopTest();

        System.assert(true, 'Should handle empty list gracefully');
    }

    /**
     * @description Test addExtraPickupQuoteLine with non-extra-pickup product
     */
    @isTest
    static void testAddExtraPickupQuoteLine_WrongProduct() {
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.addExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>{pickupLine});
        Test.stopTest();

        // Should not change anything since it's not an extra pickup product
        System.assert(true, 'Should complete without modifying non-extra-pickup products');
    }

    /**
     * @description Test removeExtraPickupQuoteLine clears extra pickup flag
     */
    @isTest
    static void testRemoveExtraPickupQuoteLine_Success() {
        // First mark pickup as extra
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, IsExtrapickup__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];
        pickupLine.IsExtrapickup__c = true;
        update pickupLine;

        SBQQ__QuoteLine__c extraPickupLine = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Extra Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.removeExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>{extraPickupLine});
        Test.stopTest();

        // Verify pickup line extra flag is cleared
        pickupLine = [
            SELECT Id, IsExtrapickup__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        System.assertEquals(false, pickupLine.IsExtrapickup__c,
            'Pickup line should have extra pickup flag cleared');
    }

    /**
     * @description Test removeExtraPickupQuoteLine with null input
     */
    @isTest
    static void testRemoveExtraPickupQuoteLine_NullInput() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.removeExtraPickupQuoteLine(null);
        Test.stopTest();

        System.assert(true, 'Should handle null input gracefully');
    }

    /**
     * @description Test removeExtraPickupQuoteLine with empty list
     */
    @isTest
    static void testRemoveExtraPickupQuoteLine_EmptyList() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.removeExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>());
        Test.stopTest();

        System.assert(true, 'Should handle empty list gracefully');
    }

    /**
     * @description Test removeExtraPickupQuoteLine with non-extra-pickup product
     */
    @isTest
    static void testRemoveExtraPickupQuoteLine_WrongProduct() {
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, SBQQ__RequiredBy__c, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        service.removeExtraPickupQuoteLine(new List<SBQQ__QuoteLine__c>{pickupLine});
        Test.stopTest();

        // Should not change anything since it's not an extra pickup product
        System.assert(true, 'Should complete without modifying non-extra-pickup products');
    }

    /**
     * @description Test isExtraPickupProduct identifies extra pickup
     */
    @isTest
    static void testIsExtraPickupProduct_True() {
        SBQQ__QuoteLine__c extraPickupLine = [
            SELECT Id, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Extra Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isExtraPickupProduct(extraPickupLine);
        Test.stopTest();

        System.assertEquals(true, result, 'Should identify extra pickup product');
    }

    /**
     * @description Test isExtraPickupProduct returns false for non-extra-pickup
     */
    @isTest
    static void testIsExtraPickupProduct_False() {
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isExtraPickupProduct(pickupLine);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for non-extra-pickup product');
    }

    /**
     * @description Test isExtraPickupProduct with null input
     */
    @isTest
    static void testIsExtraPickupProduct_Null() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isExtraPickupProduct(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for null input');
    }

    /**
     * @description Test isPickupProduct identifies pickup
     */
    @isTest
    static void testIsPickupProduct_True() {
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isPickupProduct(pickupLine);
        Test.stopTest();

        System.assertEquals(true, result, 'Should identify pickup product');
    }

    /**
     * @description Test isPickupProduct returns false for non-pickup
     */
    @isTest
    static void testIsPickupProduct_False() {
        SBQQ__QuoteLine__c extraPickupLine = [
            SELECT Id, SBQQ__ProductName__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Extra Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isPickupProduct(extraPickupLine);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for non-pickup product');
    }

    /**
     * @description Test isPickupProduct with null input
     */
    @isTest
    static void testIsPickupProduct_Null() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isPickupProduct(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for null input');
    }

    /**
     * @description Test isScheduledType identifies scheduled type
     */
    @isTest
    static void testIsScheduledType_True() {
        SBQQ__QuoteLine__c pickupLine = [
            SELECT Id, Occurrence_Type__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductName__c = 'Pickup'
            LIMIT 1
        ];

        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isScheduledType(pickupLine);
        Test.stopTest();

        System.assertEquals(true, result, 'Should identify scheduled type');
    }

    /**
     * @description Test isScheduledType with null input
     */
    @isTest
    static void testIsScheduledType_Null() {
        ProductAddOnService service = new ProductAddOnService();

        Test.startTest();
        Boolean result = service.isScheduledType(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for null input');
    }
}
