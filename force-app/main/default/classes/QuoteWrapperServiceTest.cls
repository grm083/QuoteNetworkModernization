/**
 * @description Test class for QuoteWrapperService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 6
 */
@isTest
private class QuoteWrapperServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account hierarchy
        Account parentAccount = new Account(
            Name = 'Parent Account',
            AccountNumber = 'PAR001'
        );
        insert parentAccount;

        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001',
            ParentId = parentAccount.Id
        );
        insert testAccount;

        // Create test vendor
        Account testVendor = new Account(
            Name = 'Test Vendor',
            AccountNumber = 'VEND001',
            Vendor_Business_Unit__c = 'BU001',
            FacilityCode__c = 'FAC001',
            Contact_Manually_Vendor__c = true,
            Prepayment_Required__c = 'Yes',
            Parent_Vendor_Id__c = 'PV001'
        );
        insert testVendor;

        // Create test products
        Product2 parentProduct = new Product2(
            Name = 'Parent Product',
            ProductCode = 'PARENT',
            Family = 'Commercial',
            IsActive = true
        );
        insert parentProduct;

        Product2 componentProduct = new Product2(
            Name = 'Component Product',
            ProductCode = 'H',
            Family = 'Service',
            IsActive = true
        );
        insert componentProduct;

        Product2 wasteProduct = new Product2(
            Name = 'Waste Product',
            ProductCode = 'WASTE',
            Family = 'Waste Stream',
            IsActive = true
        );
        insert wasteProduct;

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

        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__PrimaryContact__c = testContact.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            Quote_Only__c = false,
            Case_Type__c = 'New Service'
        );
        insert testQuote;

        // Create parent quote line
        SBQQ__QuoteLine__c parentLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = parentProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Number__c = 1,
            Equipment_Size__c = '20 YD',
            Duration__c = '1MO',
            Account__c = testAccount.Id,
            Vendor__c = testVendor.Id,
            CompanyCategoryCode__c = 'CC001',
            CompanyCategoryName__c = 'Category 001',
            Description_of_Waste__c = 'Test Waste',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addMonths(1),
            ProcurementErrorMessage__c = 'Test Error',
            BundleProcuredStatus__c = 'Success',
            MASLibrary__c = 'LIB001',
            MASCompany__c = 'COMP001',
            Certificate_of_Destruction__c = true,
            Quote_Only_Copy_of__c = 'Test Copy',
            MaterialGrade__c = 'Grade A',
            CustomerApproval__c = 'Approved'
        );
        insert parentLine;

        // Create child component line
        SBQQ__QuoteLine__c componentLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = componentProduct.Id,
            SBQQ__RequiredBy__c = parentLine.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__UnitCost__c = 100.00,
            SBQQ__ListPrice__c = 150.00,
            Cost_Unit_of_Measure__c = 'EACH',
            CostMinQuantity__c = 1,
            PriceUOM__c = 'EACH',
            PriceMinQuantity__c = 1,
            ErrorComments__c = 'Test validation error',
            Cost_Compare_Message__c = 'Cost comparison message'
        );
        insert componentLine;

        // Create waste stream line
        SBQQ__QuoteLine__c wasteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = wasteProduct.Id,
            SBQQ__RequiredBy__c = parentLine.Id,
            SBQQ__Quantity__c = 1
        );
        insert wasteLine;

        // Create quote order
        Quote_Order__c quoteOrder = new Quote_Order__c(
            Quote_Line__c = parentLine.Id,
            Service_Date__c = Date.today().addDays(7),
            Service_Type__c = 'Delivery',
            Acorn_Instructions__c = 'Test instructions'
        );
        insert quoteOrder;
    }

    /**
     * @description Test buildQuoteProductsWrapper with valid quote
     */
    @isTest
    static void testBuildQuoteProductsWrapper_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return wrapper');
        System.assertEquals(testQuote.Id, wrapper.singleQuoteId, 'Should set quote ID');
        System.assertEquals(true, wrapper.disableMAS, 'Should disable MAS');
        System.assertEquals(true, wrapper.disableCost, 'Should disable cost');
        System.assertEquals(true, wrapper.disablePrice, 'Should disable price');
        System.assertNotEquals(null, wrapper.configuredProducts, 'Should have configured products');
        System.assert(wrapper.configuredProducts.size() > 0, 'Should have at least one product');
    }

    /**
     * @description Test buildQuoteProductsWrapper validates header wrapper fields
     */
    @isTest
    static void testBuildQuoteProductsWrapper_HeaderFields() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        System.assert(wrapper.configuredProducts.size() > 0, 'Should have products');

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];

        // Verify basic fields
        System.assertNotEquals(null, header.parentId, 'Should have parent ID');
        System.assertNotEquals(null, header.quoteLineName, 'Should have quote line name');
        System.assertEquals('20 YD', header.equipmentSize, 'Should have equipment size');
        System.assertEquals('1MO', header.duration, 'Should have duration');

        // Verify quote fields
        System.assertEquals(testQuote.Id, header.quoteID, 'Should have quote ID');
        System.assertEquals('Draft', header.quoteStatus, 'Should have quote status');
        System.assertEquals(false, header.quoteOnly, 'Should have quote only flag');
        System.assertEquals('Quote', header.quoteType, 'Should have quote type');
        System.assertEquals('Test Copy', header.quoteOnlyCopyOf, 'Should have quote only copy of');

        // Verify vendor fields
        System.assertEquals('Test Vendor', header.vendorName, 'Should have vendor name');
        System.assertEquals('VEND001', header.vendorNumber, 'Should have vendor number');
        System.assertEquals('BU001', header.vendorBU, 'Should have vendor business unit');
        System.assertEquals('FAC001', header.vendorFacilityCode, 'Should have facility code');
        System.assertEquals('Yes', header.vendorManualDispatch, 'Should have vendor manual dispatch');
        System.assertEquals('Yes', header.vendorPrepayment, 'Should have vendor prepayment');

        // Verify company category
        System.assertEquals('CC001', header.companyCategory, 'Should have company category');
        System.assertEquals('Category 001', header.companyCategoryName, 'Should have company category name');

        // Verify material grade and approval
        System.assertEquals('Grade A', header.selectedMaterialGrade, 'Should have material grade');
        System.assertEquals('Approved', header.customerApproval, 'Should have customer approval');

        // Verify COD flag
        System.assertEquals(true, header.isCOD, 'Should have COD flag set');
    }

    /**
     * @description Test buildQuoteProductsWrapper validates MAS wrapper
     */
    @isTest
    static void testBuildQuoteProductsWrapper_MASWrapper() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];
        QuoteProcurementController.MASWrapper masWrapper = header.MAS;

        System.assertNotEquals(null, masWrapper, 'Should have MAS wrapper');
        System.assertEquals('LIB001', masWrapper.MASLibrary, 'Should have MAS library');
        System.assertEquals('COMP001', masWrapper.MASCompany, 'Should have MAS company');
    }

    /**
     * @description Test buildQuoteProductsWrapper validates work orders
     */
    @isTest
    static void testBuildQuoteProductsWrapper_WorkOrders() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];

        System.assertNotEquals(null, header.workOrders, 'Should have work orders');
        System.assertEquals(1, header.workOrders.size(), 'Should have one work order');

        QuoteProcurementController.WOWrapper workOrder = header.workOrders[0];
        System.assertEquals('Delivery', workOrder.serviceType, 'Should have service type');
        System.assertEquals('Test instructions', workOrder.instructions, 'Should have instructions');
    }

    /**
     * @description Test buildQuoteProductsWrapper validates detail wrappers
     */
    @isTest
    static void testBuildQuoteProductsWrapper_DetailWrappers() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];

        System.assertNotEquals(null, header.details, 'Should have details');
        // Should have component line but not waste stream line
        System.assertEquals(1, header.details.size(), 'Should have one detail');

        QuoteProcurementController.DetailWrapper detail = header.details[0];
        System.assertEquals('H', detail.componentType.right(1), 'Should be component product');
        System.assertEquals(100.00, detail.vendorCost, 'Should have vendor cost');
        System.assertEquals(150.00, detail.customerPrice, 'Should have customer price');
        System.assertEquals('utility:warning', detail.iconName, 'Should have warning icon for errors');
        System.assertEquals(true, header.lineError, 'Header should flag line error');
    }

    /**
     * @description Test buildQuoteProductsWrapper with null quote ID
     */
    @isTest
    static void testBuildQuoteProductsWrapper_NullQuoteId() {
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(null);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return wrapper');
        System.assertEquals(null, wrapper.singleQuoteId, 'Should not set quote ID');
    }

    /**
     * @description Test buildQuoteProductsWrapper with invalid quote ID
     */
    @isTest
    static void testBuildQuoteProductsWrapper_InvalidQuoteId() {
        Id fakeId = SBQQ__Quote__c.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(15);
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(fakeId);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return wrapper');
        System.assertEquals(fakeId, wrapper.singleQuoteId, 'Should set quote ID');
    }

    /**
     * @description Test buildQuoteProductsWrapper validates procurement error message
     */
    @isTest
    static void testBuildQuoteProductsWrapper_ProcurementError() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];

        // Should include cost compare message from haul component
        System.assertNotEquals(null, header.procurementErrorMessage, 'Should have procurement error message');
        System.assert(
            header.procurementErrorMessage.contains('Cost comparison'),
            'Should include cost comparison message'
        );
    }

    /**
     * @description Test buildQuoteProductsWrapper with quote without parent account
     */
    @isTest
    static void testBuildQuoteProductsWrapper_NoParentAccount() {
        // Create standalone account without parent
        Account standaloneAccount = new Account(
            Name = 'Standalone Account',
            AccountNumber = 'STAND001'
        );
        insert standaloneAccount;

        SBQQ__Quote__c standaloneQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = standaloneAccount.Id,
            SBQQ__Status__c = 'Draft'
        );
        insert standaloneQuote;

        Product2 product = [SELECT Id FROM Product2 WHERE Family = 'Commercial' LIMIT 1];

        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = standaloneQuote.Id,
            SBQQ__Product__c = product.Id,
            SBQQ__Quantity__c = 1
        );
        insert quoteLine;

        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(standaloneQuote.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return wrapper');
        System.assert(wrapper.configuredProducts.size() > 0, 'Should have products');
    }

    /**
     * @description Test error handling in wrapper building
     */
    @isTest
    static void testBuildQuoteProductsWrapper_ErrorHandling() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        // Should handle gracefully even if some data is missing
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return wrapper even with errors');
    }

    /**
     * @description Test NTE warning flags initialization
     */
    @isTest
    static void testBuildQuoteProductsWrapper_NTEFlags() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteWrapperService service = new QuoteWrapperService();

        Test.startTest();
        QuoteProcurementController.ProductsWrapper wrapper = service.buildQuoteProductsWrapper(testQuote.Id);
        Test.stopTest();

        QuoteProcurementController.HeaderWrapper header = wrapper.configuredProducts[0];
        System.assertEquals(false, header.nteWarnning, 'NTE warning should be false by default');
        System.assertEquals('', header.nteWarnningMessage, 'NTE warning message should be empty by default');
    }
}
