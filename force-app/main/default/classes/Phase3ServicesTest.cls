/**
 * @description Test class for Phase 3 Services
 * Tests PositionManagementService, ProductConfigurationService, and WorkOrderService
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
@isTest
private class Phase3ServicesTest {

    // ==================================================================================
    // TEST DATA SETUP
    // ==================================================================================

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer'
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'New',
            SBQQ__StartDate__c = Date.today()
        );
        insert testQuote;

        // Create test quote line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today()
        );
        insert testQuoteLine;
    }

    // ==================================================================================
    // POSITION MANAGEMENT SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testPositionManagementService_GetAllPositions() {
        // Given: Account with no positions initially
        Account account = [SELECT Id FROM Account LIMIT 1];
        PositionManagementService service = new PositionManagementService();

        // Create test positions
        List<Account_Position__c> positions = new List<Account_Position__c>{
            new Account_Position__c(
                AccountId__c = account.Id,
                Container_Position__c = 'Default'
            ),
            new Account_Position__c(
                AccountId__c = account.Id,
                Container_Position__c = 'Loading Dock'
            )
        };
        insert positions;

        // When: Get all positions
        Test.startTest();
        List<Account_Position__c> result = service.getAllPositions(account.Id);
        Test.stopTest();

        // Then: Should return positions with Default first
        System.assertEquals(2, result.size(), 'Should return 2 positions');
        System.assertEquals('Default', result[0].Container_Position__c, 'First position should be Default');
    }

    @isTest
    static void testPositionManagementService_CreateOnsitePosition_Success() {
        // Given: Valid position details
        Account account = [SELECT Id FROM Account LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        PositionDetails details = new PositionDetails(account.Id, 'Rear Entrance');
        details.quoteLineId = quoteLine.Id;

        PositionManagementService service = new PositionManagementService();

        // When: Create onsite position
        Test.startTest();
        PositionOperationResult result = service.createOnsitePosition(details);
        Test.stopTest();

        // Then: Should succeed
        System.assert(result.isSuccess, 'Operation should succeed');
        System.assertNotEquals(null, result.position, 'Position should be created');
        System.assertEquals('Rear Entrance', result.position.Container_Position__c, 'Position name should match');
    }

    @isTest
    static void testPositionManagementService_CreateOnsitePosition_Duplicate() {
        // Given: Existing position
        Account account = [SELECT Id FROM Account LIMIT 1];

        Account_Position__c existingPosition = new Account_Position__c(
            AccountId__c = account.Id,
            Container_Position__c = 'Loading Dock'
        );
        insert existingPosition;

        PositionDetails details = new PositionDetails(account.Id, 'Loading Dock');
        PositionManagementService service = new PositionManagementService();

        // When: Try to create duplicate position
        Test.startTest();
        PositionOperationResult result = service.createOnsitePosition(details);
        Test.stopTest();

        // Then: Should return duplicate status
        System.assertEquals(PositionOperationResult.Status.DUPLICATE, result.status, 'Should detect duplicate');
        System.assertEquals('Duplicate', result.getStatusString(), 'Status string should be Duplicate');
    }

    @isTest
    static void testPositionManagementService_CreateOffsitePosition() {
        // Given: Valid offsite position details
        Account account = [SELECT Id FROM Account LIMIT 1];

        PositionDetails details = new PositionDetails();
        details.accountId = account.Id;
        details.containerPosition = 'Warehouse';
        details.isOffsite = true;
        details.alternateStreet = '123 Main St';
        details.alternateCity = 'Springfield';
        details.alternateState = 'IL';
        details.alternatePostalCode = '62701';

        PositionManagementService service = new PositionManagementService();

        // When: Create offsite position
        Test.startTest();
        PositionOperationResult result = service.createOffsitePosition(details);
        Test.stopTest();

        // Then: Should succeed with formatted name
        System.assert(result.isSuccess, 'Operation should succeed');
        System.assert(
            result.position.Container_Position__c.contains('Offsite:'),
            'Position should have Offsite prefix'
        );
        System.assert(
            result.position.Container_Position__c.contains('123 Main St'),
            'Position should contain street address'
        );
    }

    @isTest
    static void testPositionManagementService_ValidatePosition() {
        // Given: Account with existing position
        Account account = [SELECT Id FROM Account LIMIT 1];

        Account_Position__c position = new Account_Position__c(
            AccountId__c = account.Id,
            Container_Position__c = 'Test Position'
        );
        insert position;

        PositionManagementService service = new PositionManagementService();

        // When/Then: Validate unique and duplicate positions
        Test.startTest();
        Boolean isUnique = service.validatePositionUnique(account.Id, 'New Position');
        Boolean isDuplicate = service.validatePositionUnique(account.Id, 'Test Position');
        Test.stopTest();

        System.assert(isUnique, 'New position should be unique');
        System.assert(!isDuplicate, 'Existing position should not be unique');
    }

    @isTest
    static void testPositionManagementService_SearchPositions() {
        // Given: Account with positions
        Account account = [SELECT Id FROM Account LIMIT 1];

        Account_Position__c position = new Account_Position__c(
            AccountId__c = account.Id,
            Container_Position__c = 'Front Entrance'
        );
        insert position;

        PositionManagementService service = new PositionManagementService();

        // When: Search with blank string
        Test.startTest();
        List<Account_Position__c> results = service.searchPositions(account.Id, '');
        Test.stopTest();

        // Then: Should return all positions (delegates to getAllPositions)
        System.assertNotEquals(null, results, 'Should return results');
    }

    // ==================================================================================
    // PRODUCT CONFIGURATION SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testProductConfigurationService_GetAccessories() {
        // Given: Product with accessories (would need product options setup)
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductConfigurationService service = new ProductConfigurationService();

        // When: Get accessories
        Test.startTest();
        List<SBQQ__ProductOption__c> accessories = service.getAccessories(product.Id);
        Test.stopTest();

        // Then: Should return empty list (no accessories in test data)
        System.assertNotEquals(null, accessories, 'Should return list');
    }

    @isTest
    static void testProductConfigurationService_GetConfigAttributes() {
        // Given: Product and quote line
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        ProductConfigurationService service = new ProductConfigurationService();

        // When: Get configuration attributes
        Test.startTest();
        List<SBQQ__ConfigurationAttribute__c> attributes = service.getConfigurationAttributes(
            product.Id,
            quoteLine.Id
        );
        Test.stopTest();

        // Then: Should return attributes (empty in test data)
        System.assertNotEquals(null, attributes, 'Should return list');
    }

    @isTest
    static void testProductConfigurationService_UpdateConfigAttribute_InvalidRequest() {
        // Given: Invalid request
        ProductConfigRequest request = new ProductConfigRequest();
        ProductConfigurationService service = new ProductConfigurationService();

        // When: Update with invalid request
        Test.startTest();
        String result = service.updateConfigurationAttribute(request);
        Test.stopTest();

        // Then: Should return error
        System.assertEquals('Invalid request', result, 'Should return error message');
    }

    @isTest
    static void testProductConfigurationService_AddProductOption_InvalidRequest() {
        // Given: Invalid request
        ProductConfigRequest request = new ProductConfigRequest();
        ProductConfigurationService service = new ProductConfigurationService();

        // When: Add option with invalid request
        Test.startTest();
        String result = service.addProductOption(request);
        Test.stopTest();

        // Then: Should return error
        System.assertEquals('Invalid request', result, 'Should return error message');
    }

    @isTest
    static void testProductConfigurationService_RemoveProductOption_InvalidRequest() {
        // Given: Invalid request
        ProductConfigRequest request = new ProductConfigRequest();
        ProductConfigurationService service = new ProductConfigurationService();

        // When: Remove option with invalid request
        Test.startTest();
        String result = service.removeProductOption(request);
        Test.stopTest();

        // Then: Should return error
        System.assertEquals('Invalid request', result, 'Should return error message');
    }

    // ==================================================================================
    // WORK ORDER SERVICE TESTS
    // ==================================================================================

    @isTest
    static void testWorkOrderService_GetOrdersForQuoteLine() {
        // Given: Quote line
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        WorkOrderService service = new WorkOrderService();

        // When: Get orders
        Test.startTest();
        List<Quote_Order__c> orders = service.getOrdersForQuoteLine(quoteLine.Id);
        Test.stopTest();

        // Then: Should return empty list (no orders in test data)
        System.assertNotEquals(null, orders, 'Should return list');
        System.assertEquals(0, orders.size(), 'Should be empty');
    }

    @isTest
    static void testWorkOrderService_DeleteOrders_Success() {
        // Given: Quote order
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        Quote_Order__c quoteOrder = new Quote_Order__c(
            Quote_Line__c = quoteLine.Id,
            Service_Type__c = 'Delivery',
            Work_Order_Date__c = Date.today()
        );
        insert quoteOrder;

        WorkOrderService service = new WorkOrderService();

        // When: Delete orders
        Test.startTest();
        String result = service.deleteOrders(new List<Quote_Order__c>{quoteOrder});
        Test.stopTest();

        // Then: Should succeed
        System.assertEquals('SUCCESS', result, 'Deletion should succeed');

        // Verify deletion
        List<Quote_Order__c> remaining = [SELECT Id FROM Quote_Order__c WHERE Id = :quoteOrder.Id];
        System.assertEquals(0, remaining.size(), 'Order should be deleted');
    }

    @isTest
    static void testWorkOrderService_DeleteOrders_EmptyList() {
        // Given: Empty list
        WorkOrderService service = new WorkOrderService();

        // When: Delete empty list
        Test.startTest();
        String result = service.deleteOrders(new List<Quote_Order__c>());
        Test.stopTest();

        // Then: Should succeed
        System.assertEquals('SUCCESS', result, 'Should handle empty list');
    }

    @isTest
    static void testWorkOrderService_ValidateDeliveryRequest_Invalid() {
        // Given: Invalid request
        WorkOrderRequest request = new WorkOrderRequest();
        WorkOrderService service = new WorkOrderService();

        // When: Validate invalid request
        Test.startTest();
        ValidationResult result = service.validateDeliveryRequest(request);
        Test.stopTest();

        // Then: Should have errors
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Quote ID'), 'Should mention Quote ID');
    }

    @isTest
    static void testWorkOrderService_ValidateDeliveryRequest_Valid() {
        // Given: Valid request
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];

        WorkOrderRequest request = new WorkOrderRequest(
            quote.Id,
            quoteLine.Id,
            Date.today(),
            'Delivery'
        );

        WorkOrderService service = new WorkOrderService();

        // When: Validate valid request
        Test.startTest();
        ValidationResult result = service.validateDeliveryRequest(request);
        Test.stopTest();

        // Then: Should be valid
        System.assert(result.isValid(), 'Validation should pass');
    }

    @isTest
    static void testWorkOrderService_CreateQuoteOrder() {
        // Given: Quote line and order details
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        WorkOrderService service = new WorkOrderService();

        // When: Create quote order
        Test.startTest();
        Quote_Order__c order = service.createQuoteOrder(
            quoteLine.Id,
            'Delivery',
            Date.today(),
            'VSN123',
            'Place at rear entrance'
        );
        Test.stopTest();

        // Then: Should be created
        System.assertNotEquals(null, order.Id, 'Order should be created');
        System.assertEquals('Delivery', order.Service_Type__c, 'Service type should match');
        System.assertEquals('VSN123', order.Vendor_Service_Number__c, 'VSN should match');
    }

    // ==================================================================================
    // DTO TESTS
    // ==================================================================================

    @isTest
    static void testPositionDetails_BuildOffsiteDisplayName() {
        // Given: Position details with address
        PositionDetails details = new PositionDetails();
        details.containerPosition = 'Warehouse';
        details.alternateStreet = '123 Main St';
        details.alternateCity = 'Springfield';
        details.alternateState = 'IL';
        details.alternatePostalCode = '62701';

        // When: Build display name
        String displayName = details.buildOffsiteDisplayName();

        // Then: Should be formatted correctly
        System.assert(displayName.contains('Offsite:'), 'Should start with Offsite:');
        System.assert(displayName.contains('Warehouse'), 'Should contain position name');
        System.assert(displayName.contains('123 Main St'), 'Should contain street');
    }

    @isTest
    static void testPositionDetails_IsValid() {
        // Given: Valid and invalid position details
        PositionDetails validOnsite = new PositionDetails(UserInfo.getUserId(), 'Test Position');

        PositionDetails invalidOnsite = new PositionDetails();
        invalidOnsite.accountId = null;

        PositionDetails validOffsite = new PositionDetails();
        validOffsite.accountId = UserInfo.getUserId();
        validOffsite.containerPosition = 'Test';
        validOffsite.isOffsite = true;
        validOffsite.alternateStreet = '123 Main';

        PositionDetails invalidOffsite = new PositionDetails();
        invalidOffsite.accountId = UserInfo.getUserId();
        invalidOffsite.containerPosition = 'Test';
        invalidOffsite.isOffsite = true;

        // When/Then: Validate
        System.assert(validOnsite.isValid(), 'Valid onsite should pass');
        System.assert(!invalidOnsite.isValid(), 'Invalid onsite should fail');
        System.assert(validOffsite.isValid(), 'Valid offsite should pass');
        System.assert(!invalidOffsite.isValid(), 'Invalid offsite should fail');
    }

    @isTest
    static void testWorkOrderRequest_IsValid() {
        // Given: Valid and invalid requests
        WorkOrderRequest validRequest = new WorkOrderRequest(
            UserInfo.getUserId(),
            UserInfo.getUserId(),
            Date.today(),
            'Delivery'
        );

        WorkOrderRequest invalidRequest = new WorkOrderRequest();

        // When/Then: Validate
        System.assert(validRequest.isValid(), 'Valid request should pass');
        System.assert(!invalidRequest.isValid(), 'Invalid request should fail');
    }

    @isTest
    static void testWorkOrderRequest_OrderTypeChecks() {
        // Given: Different order types
        WorkOrderRequest deliveryRequest = new WorkOrderRequest();
        deliveryRequest.orderType = Constant_Util.ServiceType_Delivery;

        WorkOrderRequest removalRequest = new WorkOrderRequest();
        removalRequest.orderType = Constant_Util.ServiceType_Removal;

        WorkOrderRequest haulRequest = new WorkOrderRequest();
        haulRequest.orderType = Constant_Util.Haul_Away_Service;

        // When/Then: Check order types
        System.assert(deliveryRequest.isDeliveryOrder(), 'Should be delivery');
        System.assert(removalRequest.isRemovalOrder(), 'Should be removal');
        System.assert(haulRequest.isHaulAwayOrder(), 'Should be haul away');
    }

    @isTest
    static void testWorkOrderResult_CreateSuccess() {
        // When: Create success result
        WorkOrderResult result = WorkOrderResult.createSuccess();

        // Then: Should be successful
        System.assert(result.success, 'Should be successful');
        System.assertNotEquals(null, result.quoteOrders, 'Should have empty list');
    }

    @isTest
    static void testWorkOrderResult_CreateError() {
        // When: Create error result
        WorkOrderResult result = WorkOrderResult.createError('Test error');

        // Then: Should have error
        System.assert(!result.success, 'Should not be successful');
        System.assertEquals('Test error', result.errorMessage, 'Should have error message');
    }

    @isTest
    static void testWorkOrderResult_AddWarning() {
        // Given: Work order result
        WorkOrderResult result = new WorkOrderResult();

        // When: Add warnings
        result.addWarning('Warning 1');
        result.addWarning('Warning 2');

        // Then: Should have warnings
        System.assert(result.hasWarnings(), 'Should have warnings');
        System.assert(result.getWarningsText().contains('Warning 1'), 'Should contain warning 1');
        System.assert(result.getWarningsText().contains('Warning 2'), 'Should contain warning 2');
    }

    @isTest
    static void testProductConfigRequest_Validation() {
        // Given: Various requests
        ProductConfigRequest addOptionRequest = new ProductConfigRequest(
            UserInfo.getUserId(),
            UserInfo.getUserId()
        );

        ProductConfigRequest configUpdateRequest = new ProductConfigRequest(
            UserInfo.getUserId(),
            'TestField__c',
            'TestValue',
            UserInfo.getUserId()
        );

        ProductConfigRequest invalidRequest = new ProductConfigRequest();

        // When/Then: Validate
        System.assert(addOptionRequest.isValidForAddOption(), 'Should be valid for add option');
        System.assert(addOptionRequest.isValidForRemoveOption(), 'Should be valid for remove option');
        System.assert(configUpdateRequest.isValidForConfigUpdate(), 'Should be valid for config update');
        System.assert(!invalidRequest.isValidForAddOption(), 'Invalid request should fail');
    }
}
