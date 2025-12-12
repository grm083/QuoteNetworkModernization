/**
 * @description Test class for AcornIntegrationService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class AcornIntegrationServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Customer',
            AccountNumber = 'CUST001'
        );
        insert testAccount;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
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
            SBQQ__Type__c = 'Quote',
            Customer_Request_Date__c = Date.today(),
            Vendor_Commit_Date__c = Date.today().addDays(7)
        );
        insert testQuote;
    }

    /**
     * @description Test build ticket assignment payload
     */
    @isTest
    static void testBuildTicketAssignmentPayload() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        String payload = service.buildTicketAssignmentPayload('CS_Team');
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assert(payload.contains('TeamName'), 'Payload should contain TeamName');
        System.assert(payload.contains('CS_Team'), 'Payload should contain team name value');
        System.assert(payload.contains('Comments'), 'Payload should contain Comments');
    }

    /**
     * @description Test execute HTTP request with valid config
     */
    @isTest
    static void testExecuteHttpRequest_Success() {
        AcornIntegrationService service = new AcornIntegrationService();

        AcornIntegrationService.HttpRequestConfig config = new AcornIntegrationService.HttpRequestConfig();
        config.endpoint = 'https://test.example.com/api';
        config.method = 'POST';
        config.contentType = 'application/json';
        config.userId = 'user123';
        config.partnerKey = 'key123';
        config.authorization = 'Bearer token123';
        config.timeout = 120000;
        config.body = '{"test":"value"}';

        Test.startTest();
        AcornIntegrationService.AcornIntegrationResult result = service.executeHttpRequest(config);
        Test.stopTest();

        // In test mode, it simulates success
        System.assertEquals(true, result.success, 'Should succeed in test mode');
        System.assertEquals(200, result.statusCode, 'Should return 200 status code');
    }

    /**
     * @description Test execute HTTP request with null config
     */
    @isTest
    static void testExecuteHttpRequest_NullConfig() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        AcornIntegrationService.AcornIntegrationResult result = service.executeHttpRequest(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with null config');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }

    /**
     * @description Test get logged in user Acorn ID
     */
    @isTest
    static void testGetLoggedInUserAcornId() {
        // Update current user with Acorn ID
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.Acorn_SUser_ID__c = 12345;
        update currentUser;

        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Decimal acornId = service.getLoggedInUserAcornId();
        Test.stopTest();

        System.assertEquals(12345, acornId, 'Should return user Acorn ID');
    }

    /**
     * @description Test determine Acorn team queue for renewal
     */
    @isTest
    static void testDetermineAcornTeamQueue_Renewal() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        String teamQueue = service.determineAcornTeamQueue('Renewal', null, false);
        Test.stopTest();

        System.assertEquals(Constant_Util.AcornTeam_WMSSC_Customer_Service, teamQueue,
                           'Renewal should go to customer service');
    }

    /**
     * @description Test determine Acorn team queue for WM vendor
     */
    @isTest
    static void testDetermineAcornTeamQueue_WMVendor() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        String teamQueue = service.determineAcornTeamQueue('Quote', Constant_Util.WM_US_VENDOR, true);
        Test.stopTest();

        System.assertEquals(Constant_Util.AcornTeam_PS_Vendor_Inquiry, teamQueue,
                           'WM vendor should go to vendor inquiry');
    }

    /**
     * @description Test determine Acorn team queue for third party
     */
    @isTest
    static void testDetermineAcornTeamQueue_ThirdParty() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        String teamQueue = service.determineAcornTeamQueue('Quote', 'TP_VENDOR', false);
        Test.stopTest();

        System.assertEquals(Constant_Util.AcornTeam_CS_Delivery_Vendor_Inquiries, teamQueue,
                           'Third party should go to delivery vendor inquiries');
    }

    /**
     * @description Test create Acorn error task
     */
    @isTest
    static void testCreateAcornErrorTask_Success() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Task errorTask = service.createAcornErrorTask(
            quote.Id,
            'Test error message',
            'Acorn Integration Failed'
        );
        Test.stopTest();

        System.assertNotEquals(null, errorTask, 'Task should be created');
        System.assertEquals(quote.Id, errorTask.WhatId, 'Task should be linked to quote');
        System.assertEquals('Acorn Integration Failed', errorTask.Subject, 'Should have correct subject');
        System.assertEquals('High', errorTask.Priority, 'Should be high priority');

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :quote.Id];
        System.assertEquals(1, tasks.size(), 'Task should be inserted');
    }

    /**
     * @description Test create Acorn error task with null quote
     */
    @isTest
    static void testCreateAcornErrorTask_NullQuote() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Task errorTask = service.createAcornErrorTask(null, 'Error message', 'Subject');
        Test.stopTest();

        System.assertEquals(null, errorTask, 'Should return null for null quote ID');
    }

    /**
     * @description Test create Acorn error task with null error message
     */
    @isTest
    static void testCreateAcornErrorTask_NullError() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Task errorTask = service.createAcornErrorTask(quote.Id, null, 'Subject');
        Test.stopTest();

        System.assertEquals(null, errorTask, 'Should return null for null error message');
    }

    /**
     * @description Test build quote payload
     */
    @isTest
    static void testBuildQuotePayload_WithoutWorkOrders() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> payload = service.buildQuotePayload(quote.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assertEquals(quote.Id, payload.get('QuoteId'), 'Should have quote ID');
        System.assertNotEquals(null, payload.get('QuoteName'), 'Should have quote name');
        System.assertNotEquals(null, payload.get('QuoteType'), 'Should have quote type');
        System.assertEquals(false, payload.containsKey('WorkOrderDetails'), 'Should not include work orders');
    }

    /**
     * @description Test build quote payload with work orders
     */
    @isTest
    static void testBuildQuotePayload_WithWorkOrders() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        quote.Acorn_Work_Order_Details__c = '<table><tr><td>Test</td></tr></table>';
        update quote;

        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> payload = service.buildQuotePayload(quote.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should not be null');
        System.assertEquals(true, payload.containsKey('WorkOrderDetails'), 'Should include work orders');
    }

    /**
     * @description Test build quote payload with null quote ID
     */
    @isTest
    static void testBuildQuotePayload_NullQuoteId() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> payload = service.buildQuotePayload(null, false);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Should return empty map for null ID');
        System.assertEquals(0, payload.size(), 'Map should be empty');
    }

    /**
     * @description Test parse work order response
     */
    @isTest
    static void testParseWorkOrderResponse_Success() {
        String responseBody = '{"TicketNumber":"TKT-001","ChildTicketNumber":"TKT-002","WorkOrderId":"WO-123"}';
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> workOrderDetails = service.parseWorkOrderResponse(responseBody);
        Test.stopTest();

        System.assertNotEquals(null, workOrderDetails, 'Work order details should not be null');
        System.assertEquals('TKT-001', workOrderDetails.get('TicketNumber'), 'Should parse ticket number');
        System.assertEquals('TKT-002', workOrderDetails.get('ChildTicketNumber'), 'Should parse child ticket number');
        System.assertEquals('WO-123', workOrderDetails.get('WorkOrderId'), 'Should parse work order ID');
    }

    /**
     * @description Test parse work order response with null body
     */
    @isTest
    static void testParseWorkOrderResponse_NullBody() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> workOrderDetails = service.parseWorkOrderResponse(null);
        Test.stopTest();

        System.assertNotEquals(null, workOrderDetails, 'Should return empty map for null body');
        System.assertEquals(0, workOrderDetails.size(), 'Map should be empty');
    }

    /**
     * @description Test parse work order response with partial data
     */
    @isTest
    static void testParseWorkOrderResponse_PartialData() {
        String responseBody = '{"TicketNumber":"TKT-001"}';
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Map<String, Object> workOrderDetails = service.parseWorkOrderResponse(responseBody);
        Test.stopTest();

        System.assertEquals(1, workOrderDetails.size(), 'Should have one entry');
        System.assertEquals('TKT-001', workOrderDetails.get('TicketNumber'), 'Should parse available field');
    }

    /**
     * @description Test update quote with work order details
     */
    @isTest
    static void testUpdateQuoteWithWorkOrderDetails_Success() {
        SBQQ__Quote__c quote = [SELECT Id, Acorn_Work_Order_Details__c FROM SBQQ__Quote__c LIMIT 1];
        String workOrderHtml = '<table><tr><td>Work Order 123</td></tr></table>';

        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Database.SaveResult result = service.updateQuoteWithWorkOrderDetails(quote.Id, workOrderHtml);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.isSuccess(), 'Update should succeed');

        SBQQ__Quote__c updatedQuote = [SELECT Acorn_Work_Order_Details__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals(workOrderHtml, updatedQuote.Acorn_Work_Order_Details__c, 'Should update work order details');
    }

    /**
     * @description Test update quote with work order details - null quote ID
     */
    @isTest
    static void testUpdateQuoteWithWorkOrderDetails_NullQuoteId() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        Database.SaveResult result = service.updateQuoteWithWorkOrderDetails(null, '<table></table>');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null quote ID');
    }

    /**
     * @description Test assign queue to Acorn ticket - missing ticket number
     */
    @isTest
    static void testAssignQueueToAcornTicket_MissingTicket() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        AcornIntegrationService.AcornIntegrationResult result = service.assignQueueToAcornTicket(
            null,
            'CS_Team',
            'user123'
        );
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with missing ticket number');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }

    /**
     * @description Test assign queue to Acorn ticket - missing team queue
     */
    @isTest
    static void testAssignQueueToAcornTicket_MissingTeam() {
        AcornIntegrationService service = new AcornIntegrationService();

        Test.startTest();
        AcornIntegrationService.AcornIntegrationResult result = service.assignQueueToAcornTicket(
            'TKT-001',
            null,
            'user123'
        );
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with missing team queue');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }

    /**
     * @description Test HttpRequestConfig initialization
     */
    @isTest
    static void testHttpRequestConfig_Initialization() {
        Test.startTest();
        AcornIntegrationService.HttpRequestConfig config = new AcornIntegrationService.HttpRequestConfig();
        Test.stopTest();

        System.assertNotEquals(null, config, 'Config should be instantiated');
    }

    /**
     * @description Test AcornIntegrationResult initialization
     */
    @isTest
    static void testAcornIntegrationResult_Initialization() {
        Test.startTest();
        AcornIntegrationService.AcornIntegrationResult result = new AcornIntegrationService.AcornIntegrationResult();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should be instantiated');
        System.assertEquals(false, result.success, 'Success should default to false');
    }
}
