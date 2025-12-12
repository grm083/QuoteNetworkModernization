/**
 * @description Test class for QuoteDataMapperService
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 10.1 - Data Mapping & Transformation
 */
@isTest
private class QuoteDataMapperServiceTest {

    /**
     * @description Setup test data for all tests
     */
    @testSetup
    static void setupTestData() {
        // Create test Account with parent
        Account parentAccount = new Account(
            Name = 'Test Parent Account',
            AccountNumber = 'TEST001'
        );
        insert parentAccount;

        Account testAccount = new Account(
            Name = 'Test Account',
            ParentId = parentAccount.Id,
            Division__c = 'Test Division',
            Geography__c = 'Test Geography',
            Location_Type__c = 'Test Location',
            Brand__c = 'Test Brand'
        );
        insert testAccount;

        // Create Opportunity and Case
        Case testCase = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id,
            Origin = 'Web',
            Case_Type__c = 'New Service',
            Status = 'New'
        );
        insert testCase;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Case__c = testCase.Id
        );
        insert testOpportunity;

        // Create Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Equipment',
            ProductCode = 'TEST',
            Family = 'Commercial',
            IsActive = true,
            SBQQ__QuantityEditable__c = true
        );
        insert testProduct;

        // Create Vendor Account
        Account vendorAccount = new Account(
            Name = 'Test Vendor',
            AccountNumber = 'VEND001',
            Vendor_Business_Unit__c = 'BU001',
            Parent_Vendor_Id__c = 'PARENT001',
            FacilityCode__c = 'FAC001',
            Contact_Manually_Vendor__c = true,
            Prepayment_Required__c = 'Yes',
            Vendor_Status__c = 'Active'
        );
        insert vendorAccount;

        // Create Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__PrimaryContact__c = testContact.Id,
            SBQQ__Status__c = 'Draft',
            Case_Type__c = 'New Service',
            Case_Sub_Type__c = 'Addition',
            Case_Reason__c = 'Test Reason',
            Quote_Only__c = false,
            SBQQ__Type__c = 'Quote',
            STP__c = false
        );
        insert testQuote;

        // Create Parent Quote Line
        SBQQ__QuoteLine__c parentQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today().addDays(7),
            SBQQ__EndDate__c = Date.today().addDays(37),
            Equipment_Size__c = '30 Yard',
            Duration__c = 'Temporary',
            Occurrence_Type__c = 'SCH',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'Monday',
            Vendor__c = vendorAccount.Id,
            Account__c = testAccount.Id,
            CompanyCategoryCode__c = 'CC001',
            CompanyCategoryName__c = 'Test Category',
            MaterialGrade__c = 'Grade A',
            Certificate_of_Destruction__c = true,
            BundleProcuredStatus__c = 'Procured',
            MASLibrary__c = 'LIB01',
            MASCompany__c = 'COMP01',
            MASAccount__c = 123456,
            MASCustomerUniqueId__c = 789,
            MASServiceLine__c = 1,
            MASBox__c = 'BOX01',
            SetupComment__c = 'Test setup comment',
            BypassPriceReview__c = true,
            DoNotCreateMASTicket__c = false,
            DoNotCreateTaskGridTickets__c = false,
            VCRCode__c = 'VCR001',
            sCode__c = 'SC01',
            Service_Schedule__c = 'Weekly',
            Description_of_Waste__c = 'Test waste',
            SLA_Override_Reason__c = 'Test Override',
            SLA_Override_Comment__c = 'Override comment',
            AAV_Delivery_Override_Reason__c = 'Delivery override',
            AAV_Delivery_Override_Comment__c = 'Delivery comment',
            AAV_Service_Override_Reason__c = 'Service override',
            AAV_Service_Day_Override_Comment__c = 'Service comment',
            CustomerApproval__c = 'Approved'
        );
        insert parentQuoteLine;

        // Create Waste Stream child quote line
        Product2 wasteProduct = new Product2(
            Name = 'Test Waste Stream',
            ProductCode = 'WASTE01',
            Family = 'Waste Stream',
            IsActive = true
        );
        insert wasteProduct;

        SBQQ__QuoteLine__c wasteQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = wasteProduct.Id,
            SBQQ__RequiredBy__c = parentQuoteLine.Id,
            SBQQ__Quantity__c = 1
        );
        insert wasteQuoteLine;

        // Create Service Charge child quote line
        Product2 serviceProduct = new Product2(
            Name = 'Hauling Charge',
            ProductCode = 'H',
            Family = 'Service Charge',
            IsActive = true
        );
        insert serviceProduct;

        SBQQ__QuoteLine__c serviceQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = serviceProduct.Id,
            SBQQ__RequiredBy__c = parentQuoteLine.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__UnitCost__c = 100,
            SBQQ__ListPrice__c = 150,
            Cost_Unit_of_Measure__c = 'Per Service',
            CostMinQuantity__c = 1,
            PriceUOM__c = 'Per Service',
            PriceMinQuantity__c = 1,
            Occurrence_Type__c = 'OCC',
            Schedule_Frequency__c = null,
            Service_Days__c = null,
            SBQQ__StartDate__c = Date.today().addDays(7),
            SBQQ__EndDate__c = Date.today().addDays(37),
            ErrorComments__c = null,
            Cost_Compare_Message__c = 'Cost comparison message'
        );
        insert serviceQuoteLine;

        // Create Quote Order (Work Order)
        Quote_Order__c quoteOrder = new Quote_Order__c(
            Quote_Line__c = parentQuoteLine.Id,
            Service_Date__c = Date.today().addDays(7),
            Service_Type__c = 'Delivery',
            Acorn_Instructions__c = 'Test instructions'
        );
        insert quoteOrder;
    }

    /**
     * @description Test buildQuoteWrapper - simple wrapper builder
     */
    @isTest
    static void testBuildQuoteWrapper_Success() {
        // Given: Test quote with configured products
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildQuoteWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertNotEquals(null, result.configuredProducts, 'Configured products should not be null');
        System.assert(result.configuredProducts.size() > 0, 'Should have at least one configured product');

        // Verify header wrapper mapping
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assertEquals('New Service', header.caseType, 'Case type should match');
        System.assertEquals('Addition', header.caseSubType, 'Case sub type should match');
        System.assertEquals('Test Reason', header.caseReason, 'Case reason should match');
        System.assertEquals('Commercial', header.productFamily, 'Product family should match');
        System.assertEquals('Grade A', header.selectedMaterialGrade, 'Material grade should match');
        System.assertEquals('Test Waste Stream', header.materialType, 'Material type should be set from child line');
        System.assertEquals('WASTE01', header.materialTypeCode, 'Material type code should match');
        System.assertEquals('Test Vendor', header.vendorName, 'Vendor name should match');
    }

    /**
     * @description Test buildWrapper - comprehensive wrapper builder
     */
    @isTest
    static void testBuildWrapper_Success() {
        // Given: Test quote with full configuration
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals(true, result.disableMAS, 'MAS should be disabled by default');
        System.assertEquals(true, result.disableCost, 'Cost should be disabled by default');
        System.assertEquals(true, result.disablePrice, 'Price should be disabled by default');
        System.assertNotEquals(null, result.configuredProducts, 'Configured products should not be null');
        System.assert(result.configuredProducts.size() > 0, 'Should have configured products');

        // Verify header wrapper
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];

        // Verify quote information
        System.assertEquals('New Service', header.caseType, 'Case type should match');
        System.assertEquals('Draft', header.quoteStatus, 'Quote status should match');
        System.assertEquals('Quote', header.quoteType, 'Quote type should match');

        // Verify product information
        System.assertEquals('Test Equipment', header.equipmentType, 'Equipment type should match');
        System.assertEquals('30 Yard', header.equipmentSize, 'Equipment size should match');
        System.assertEquals('Temporary', header.duration, 'Duration should match');

        // Verify vendor information
        System.assertEquals('Test Vendor', header.vendorName, 'Vendor name should match');
        System.assertEquals('VEND001', header.vendorNumber, 'Vendor number should match');
        System.assertEquals('BU001', header.vendorBU, 'Vendor BU should match');
        System.assertEquals('FAC001', header.vendorFacilityCode, 'Vendor facility code should match');
        System.assertEquals('Yes', header.vendorManualDispatch, 'Vendor manual dispatch should be Yes');
        System.assertEquals('Yes', header.vendorPrepayment, 'Vendor prepayment should be Yes');

        // Verify MAS wrapper
        System.assertNotEquals(null, header.MAS, 'MAS wrapper should not be null');
        System.assertEquals('LIB01', header.MAS.MASLibrary, 'MAS library should match');
        System.assertEquals('COMP01', header.MAS.MASCompany, 'MAS company should match');
        System.assertEquals(123456, header.MAS.MASAccount, 'MAS account should match');
        System.assertEquals('VCR001', header.MAS.VCRCode, 'VCR code should match');

        // Verify work orders
        System.assertNotEquals(null, header.workOrders, 'Work orders should not be null');
        System.assert(header.workOrders.size() > 0, 'Should have work orders');
        System.assertEquals('Delivery', header.workOrders[0].serviceType, 'Work order service type should match');

        // Verify detail wrappers
        System.assertNotEquals(null, header.details, 'Details should not be null');
        System.assert(header.details.size() > 0, 'Should have detail records');

        QuoteProcurementController.DetailWrapper detail = header.details[0];
        System.assertEquals('Hauling Charge', detail.componentType, 'Component type should match');
        System.assertEquals(100, detail.vendorCost, 'Vendor cost should match');
        System.assertEquals(150, detail.customerPrice, 'Customer price should match');
        System.assertEquals('utility:check', detail.iconName, 'Icon should be check (no errors)');
    }

    /**
     * @description Test buildWrapper with no quote lines
     */
    @isTest
    static void testBuildWrapper_NoQuoteLines() {
        // Given: Quote with no quote lines
        SBQQ__Quote__c emptyQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        delete [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :emptyQuote.Id];

        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(emptyQuote.Id);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Wrapper should not be null');
        System.assertEquals(emptyQuote.Id, result.singleQuoteId, 'Should set singleQuoteId when no lines');
        System.assert(result.configuredProducts == null || result.configuredProducts.size() == 0,
                     'Should have no configured products');
    }

    /**
     * @description Test header wrapper mapping with COD flag
     */
    @isTest
    static void testHeaderWrapperMapping_CODFlag() {
        // Given: Quote line with Certificate of Destruction
        SBQQ__QuoteLine__c quoteLine = [
            SELECT Id, Certificate_of_Destruction__c, Certificate_of_Disposal__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
            LIMIT 1
        ];

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assertEquals(true, header.isCOD, 'Should be marked as COD when Certificate of Destruction is true');
    }

    /**
     * @description Test detail wrapper mapping with error comments
     */
    @isTest
    static void testDetailWrapperMapping_WithErrors() {
        // Given: Service charge with error comments
        SBQQ__QuoteLine__c serviceLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__ProductCode__c = 'H'
            LIMIT 1
        ];
        serviceLine.ErrorComments__c = 'Test error message';
        update serviceLine;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        QuoteProcurementController.DetailWrapper detail = header.details[0];
        System.assertEquals('utility:warning', detail.iconName, 'Icon should be warning when errors exist');
        System.assertEquals('Test error message', detail.errorMessage, 'Error message should match');
    }

    /**
     * @description Test MAS wrapper mapping
     */
    @isTest
    static void testMASWrapperMapping_AllFields() {
        // Given: Quote with full MAS configuration
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        QuoteProcurementController.MASWrapper mas = header.MAS;

        System.assertEquals('LIB01', mas.MASLibrary, 'MAS library should match');
        System.assertEquals('COMP01', mas.MASCompany, 'MAS company should match');
        System.assertEquals(123456, mas.MASAccount, 'MAS account should match');
        System.assertEquals(789, mas.MASUniqueId, 'MAS unique ID should match');
        System.assertEquals(1, mas.MASServiceLine, 'MAS service line should match');
        System.assertEquals('BOX01', mas.MASBox, 'MAS box should match');
        System.assertEquals('Test setup comment', mas.MASComment, 'MAS comment should match');
        System.assertEquals(true, mas.MASBypassPrice, 'Bypass price review should be true');
        System.assertEquals(false, mas.MASDoNotCreate, 'Do not create MAS ticket should be false');
        System.assertEquals(false, mas.DoNotCreateTaskGridTickets, 'Do not create task grid tickets should be false');
        System.assertEquals('VCR001', mas.VCRCode, 'VCR code should match');
    }

    /**
     * @description Test work order wrapper mapping
     */
    @isTest
    static void testWorkOrderWrapperMapping() {
        // Given: Quote with work orders
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assert(header.workOrders != null && header.workOrders.size() > 0,
                     'Should have work orders');

        QuoteProcurementController.WOWrapper wo = header.workOrders[0];
        System.assertEquals('Delivery', wo.serviceType, 'Service type should match');
        System.assertEquals('Test instructions', wo.instructions, 'Instructions should match');
        System.assertEquals(Date.today().addDays(7), wo.serviceDate, 'Service date should match');
    }

    /**
     * @description Test vendor flag mapping - No manual dispatch
     */
    @isTest
    static void testVendorFlagMapping_NoManualDispatch() {
        // Given: Vendor without manual dispatch
        Account vendor = [SELECT Id FROM Account WHERE Name = 'Test Vendor' LIMIT 1];
        vendor.Contact_Manually_Vendor__c = false;
        vendor.Prepayment_Required__c = 'No';
        update vendor;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assertEquals('No', header.vendorManualDispatch, 'Manual dispatch should be No');
        System.assertEquals('No', header.vendorPrepayment, 'Prepayment should be No');
    }

    /**
     * @description Test cost compare message concatenation
     */
    @isTest
    static void testCostCompareMessageConcatenation() {
        // Given: Quote line with procurement error and cost compare message
        SBQQ__QuoteLine__c parentLine = [
            SELECT Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__RequiredBy__c = null
            LIMIT 1
        ];
        parentLine.ProcurementErrorMessage__c = 'Existing error';
        update parentLine;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assert(header.procurementErrorMessage.contains('Existing error'),
                     'Should contain existing error');
        System.assert(header.procurementErrorMessage.contains('Cost comparison message'),
                     'Should contain cost compare message');
    }

    /**
     * @description Test material type extraction from child lines
     */
    @isTest
    static void testMaterialTypeExtraction() {
        // Given: Quote with waste stream child line
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        QuoteDataMapperService mapperService = new QuoteDataMapperService();

        // When
        Test.startTest();
        QuoteProcurementController.ProductsWrapper result = mapperService.buildWrapper(testQuote.Id);
        Test.stopTest();

        // Then
        QuoteProcurementController.HeaderWrapper header = result.configuredProducts[0];
        System.assertEquals('Test Waste Stream', header.materialType,
                           'Material type should be extracted from waste stream child');
        System.assertEquals('WASTE01', header.materialTypeCode,
                           'Material type code should be extracted from waste stream child');
    }

    /**
     * @description Test service instance creation
     */
    @isTest
    static void testServiceInstantiation() {
        // When
        Test.startTest();
        QuoteDataMapperService mapperService = new QuoteDataMapperService();
        Test.stopTest();

        // Then
        System.assertNotEquals(null, mapperService, 'Service should be instantiated');
    }
}
