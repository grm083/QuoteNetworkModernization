/**
 * @description Test class for FinancialManagementService
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
@isTest
private class FinancialManagementServiceTest {

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

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
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
            Quote_Only__c = false
        );
        insert testQuote;

        // Create parent quote line
        SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            CompanyCategoryCode__c = 'CC001',
            CompanyCategoryName__c = 'Category 001',
            ClientGLAccount__c = 'GL12345',
            ClientCostCenter__c = 'CC12345'
        );
        insert parentLine;

        // Create child quote lines
        List<SBQQ__QuoteLine__c> childLines = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < 3; i++) {
            childLines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__RequiredBy__c = parentLine.Id,
                SBQQ__Quantity__c = 1
            ));
        }
        insert childLines;
    }

    /**
     * @description Test updateFinancialDetail with valid data
     */
    @isTest
    static void testUpdateFinancialDetail_Success() {
        // Get test data
        SBQQ__QuoteLine__c parentLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        String result = service.updateFinancialDetail(
            parentLine.Id,
            true,
            'CC002',
            'Category 002',
            'GL67890',
            'CC67890'
        );
        Test.stopTest();

        System.assertEquals('Success', result, 'Update should succeed');

        // Verify parent line updated
        SBQQ__QuoteLine__c updatedParent = [
            SELECT CompanyCategoryCode__c, CompanyCategoryName__c, ClientGLAccount__c, ClientCostCenter__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :parentLine.Id
        ];

        System.assertEquals('CC002', updatedParent.CompanyCategoryCode__c, 'Company category code should be updated');
        System.assertEquals('Category 002', updatedParent.CompanyCategoryName__c, 'Company category name should be updated');
        System.assertEquals('GL67890', updatedParent.ClientGLAccount__c, 'GL account should be updated');
        System.assertEquals('CC67890', updatedParent.ClientCostCenter__c, 'Cost center should be updated');

        // Verify child lines updated
        List<SBQQ__QuoteLine__c> childLines = [
            SELECT CompanyCategoryCode__c, CompanyCategoryName__c, ClientGLAccount__c, ClientCostCenter__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = :parentLine.Id
        ];

        for (SBQQ__QuoteLine__c child : childLines) {
            System.assertEquals('CC002', child.CompanyCategoryCode__c, 'Child company category code should be updated');
            System.assertEquals('Category 002', child.CompanyCategoryName__c, 'Child company category name should be updated');
        }
    }

    /**
     * @description Test updateFinancialDetail with null quote line ID
     */
    @isTest
    static void testUpdateFinancialDetail_NullQuoteLineId() {
        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        String result = service.updateFinancialDetail(null, false, 'CC001', 'Category 001', 'GL123', 'CC123');
        Test.stopTest();

        System.assert(result.startsWith('Failed'), 'Should return failure message');
    }

    /**
     * @description Test updateCompanyCategories
     */
    @isTest
    static void testUpdateCompanyCategories_Success() {
        SBQQ__QuoteLine__c parentLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        Boolean result = service.updateCompanyCategories(parentLine.Id, 'CC999');
        Test.stopTest();

        System.assert(result, 'Update should succeed');

        // Verify all lines updated
        List<SBQQ__QuoteLine__c> allLines = [
            SELECT CompanyCategoryCode__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :parentLine.Id OR SBQQ__RequiredBy__c = :parentLine.Id
        ];

        for (SBQQ__QuoteLine__c line : allLines) {
            System.assertEquals('CC999', line.CompanyCategoryCode__c, 'Company category should be updated');
        }
    }

    /**
     * @description Test updateCompanyCategories with null parent ID
     */
    @isTest
    static void testUpdateCompanyCategories_NullParentId() {
        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        Boolean result = service.updateCompanyCategories(null, 'CC999');
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for null parent ID');
    }

    /**
     * @description Test validateFinancialDetails with valid data
     */
    @isTest
    static void testValidateFinancialDetails_Valid() {
        Product2 wasteProduct = new Product2(
            Name = 'Waste Product',
            ProductCode = 'WASTE001',
            Family = 'Waste Stream',
            IsActive = true
        );
        insert wasteProduct;

        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Product__c = wasteProduct.Id;
        quoteLine.SBQQ__ProductFamily__c = 'Waste Stream';
        quoteLine.CompanyCategoryCode__c = 'CC001';

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        List<String> errors = service.validateFinancialDetails(quoteLine);
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Should have no validation errors');
    }

    /**
     * @description Test validateFinancialDetails with missing company category
     */
    @isTest
    static void testValidateFinancialDetails_MissingCompanyCategory() {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        List<String> errors = service.validateFinancialDetails(quoteLine);
        Test.stopTest();

        System.assert(errors.size() > 0, 'Should have validation errors');
        System.assert(errors[0].contains('Company category'), 'Should flag missing company category');
    }

    /**
     * @description Test validateFinancialDetails with null quote line
     */
    @isTest
    static void testValidateFinancialDetails_NullQuoteLine() {
        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        List<String> errors = service.validateFinancialDetails(null);
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Should have one error');
        System.assert(errors[0].contains('required'), 'Should indicate quote line is required');
    }

    /**
     * @description Test getFinancialDetails
     */
    @isTest
    static void testGetFinancialDetails_Success() {
        SBQQ__QuoteLine__c parentLine = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null LIMIT 1];

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        FinancialManagementService.FinancialDetails details = service.getFinancialDetails(parentLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, details, 'Should return financial details');
        System.assertEquals('CC001', details.companyCategory, 'Should return correct company category');
        System.assertEquals('Category 001', details.companyCategoryName, 'Should return correct category name');
        System.assertEquals('GL12345', details.generalLedgerAccount, 'Should return correct GL account');
        System.assertEquals('CC12345', details.costCenter, 'Should return correct cost center');
    }

    /**
     * @description Test getFinancialDetails with null ID
     */
    @isTest
    static void testGetFinancialDetails_NullId() {
        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        FinancialManagementService.FinancialDetails details = service.getFinancialDetails(null);
        Test.stopTest();

        System.assertEquals(null, details, 'Should return null for null ID');
    }

    /**
     * @description Test getFinancialDetails with invalid ID
     */
    @isTest
    static void testGetFinancialDetails_InvalidId() {
        // Create a fake ID that doesn't exist
        Id fakeId = SBQQ__QuoteLine__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(15);

        FinancialManagementService service = new FinancialManagementService();

        Test.startTest();
        FinancialManagementService.FinancialDetails details = service.getFinancialDetails(fakeId);
        Test.stopTest();

        System.assertEquals(null, details, 'Should return null for invalid ID');
    }

    /**
     * @description Test FinancialDetails wrapper initialization
     */
    @isTest
    static void testFinancialDetailsWrapper() {
        Test.startTest();
        FinancialManagementService.FinancialDetails details = new FinancialManagementService.FinancialDetails();
        Test.stopTest();

        System.assertNotEquals(null, details, 'Wrapper should be initialized');
        System.assertEquals(false, details.isQuoteOnly, 'Default isQuoteOnly should be false');
    }
}
