/**
 * @description Comprehensive test class for Phase 9 Quote Lifecycle Services
 * Tests all repositories, services, and orchestrator
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Quote Lifecycle Refactoring
 */
@isTest
private class QuoteLifecycleServicesTest {

    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Customer',
            AccountNumber = 'CUST001',
            Geography__c = 'US'
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
            SBQQ__StartDate__c = Date.today().addDays(10)
        );
        insert testQuote;

        // Create vendor account
        Account vendor = new Account(
            Name = 'WM Vendor',
            Vendor_ID__c = 'WM001'
        );
        insert vendor;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Container',
            ProductCode = 'CONT001',
            IsActive = true
        );
        insert testProduct;

        // Create quote line
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Vendor__c = vendor.Id
        );
        insert quoteLine;
    }

    /**
     * REPOSITORY TESTS
     */

    @isTest
    static void testQuoteTeamsFrameworkRepository() {
        QuoteTeamsFrameworkRepository repo = new QuoteTeamsFrameworkRepository();

        Test.startTest();
        Quote_Teams_Framework__mdt framework = repo.getTeamForAssignment(
            'Core Customer',
            'Draft',
            'Quote',
            null
        );
        List<Quote_Teams_Framework__mdt> frameworks = repo.getFrameworksByCustomerGroup('Core Customer');
        Test.stopTest();

        // Verify repository methods execute without error
        System.assertNotEquals(null, frameworks, 'Should return list');
    }

    @isTest
    static void testQuoteActionFrameworkRepository() {
        QuoteActionFrameworkRepository repo = new QuoteActionFrameworkRepository();

        Test.startTest();
        Quote_Action_Framework__mdt framework = repo.getFrameworkByStatus('Draft');
        QuoteActionFrameworkRepository.VendorDelayConfig config = repo.getVendorDelays('Draft');
        Decimal wmDelay = repo.getWMDelay('Draft');
        Test.stopTest();

        // Verify repository methods execute
        System.assertNotEquals(null, config, 'Should return config');
    }

    @isTest
    static void testCodeSwitchRepository() {
        // Create test code switch
        Code_Switch__c testSwitch = new Code_Switch__c(
            Name = 'Test_Switch',
            Switch_Off__c = false
        );
        insert testSwitch;

        CodeSwitchRepository repo = new CodeSwitchRepository();

        Test.startTest();
        Boolean enabled = repo.isSwitchEnabled('Test_Switch');
        Boolean haulAwayEnabled = repo.isHaulAwayEnabled();
        CodeSwitchRepository.QuoteFeatureFlags flags = repo.getQuoteFeatureFlags();
        Test.stopTest();

        System.assertEquals(true, enabled, 'Test switch should be enabled');
        System.assertNotEquals(null, flags, 'Should return flags');
    }

    /**
     * SERVICE TESTS
     */

    @isTest
    static void testQuotePriorityService() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__StartDate__c, Priority__c FROM SBQQ__Quote__c LIMIT 1];

        QuotePriorityService service = new QuotePriorityService();

        Test.startTest();
        String priority = service.determinePriority(quote);
        Integer days = service.getDaysUntilStartDate(quote.SBQQ__StartDate__c);
        QuotePriorityService.PriorityResult result = service.calculatePriorityWithDetails(quote);
        Test.stopTest();

        System.assertNotEquals(null, priority, 'Should return priority');
        System.assert(days > 0, 'Should return positive days');
        System.assertEquals(true, result.success, 'Should succeed');
    }

    @isTest
    static void testNextActionSchedulingService() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__StartDate__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        NextActionSchedulingService service = new NextActionSchedulingService();

        Test.startTest();
        DateTime nextAction = service.calculateNextActionDate(60, quote.SBQQ__StartDate__c, quote.SBQQ__Status__c);
        NextActionSchedulingService.SchedulingResult result = service.calculateCompleteScheduling(quote, 'WM001');
        Test.stopTest();

        System.assertNotEquals(null, nextAction, 'Should return next action date');
        System.assertNotEquals(null, result, 'Should return result');
    }

    @isTest
    static void testQuoteAssignmentService() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__Type__c, SBQQ__Account__r.Geography__c,
                                       Project__c, Project_Services_Request__c, Quote_Only__c,
                                       Special_Handling__c, QuoteProcuredStatus__c,
                                       Assigned_To__c, SBQQ__Opportunity2__r.Case__r.Is_Haul_Away_Service__c
                                FROM SBQQ__Quote__c LIMIT 1];

        QuoteAssignmentService service = new QuoteAssignmentService();

        Test.startTest();
        QuoteAssignmentService.AssignmentResult result = service.determineAssignee(quote, 'WM001');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result');
    }

    @isTest
    static void testQuoteChangeDetectorService() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, Assigned_To__c, SBQQ__StartDate__c,
                                       Action_Type__c, Pending_Information__c
                                FROM SBQQ__Quote__c LIMIT 1];

        SBQQ__Quote__c oldQuote = quote.clone(true, true, false, false);

        // Make changes
        quote.SBQQ__Status__c = 'Product Configured';
        quote.SBQQ__StartDate__c = Date.today().addDays(5);

        QuoteChangeDetectorService service = new QuoteChangeDetectorService();

        Test.startTest();
        QuoteChangeDetectorService.ChangeDetectionResult changes = service.detectChanges(quote, oldQuote);
        String primaryChange = service.getPrimaryChangeType(changes);
        Boolean requiresStatus = service.requiresStatusTransition(changes);
        Boolean requiresPriority = service.requiresPriorityRecalculation(changes);
        Test.stopTest();

        System.assertEquals(true, changes.statusChanged, 'Should detect status change');
        System.assertEquals(true, changes.startDateChanged, 'Should detect start date change');
        System.assertEquals('STATUS_CHANGE', primaryChange, 'Primary change should be status');
        System.assertEquals(true, requiresStatus, 'Should require status transition');
        System.assertEquals(true, requiresPriority, 'Should require priority recalculation');
    }

    /**
     * ORCHESTRATOR TESTS
     */

    @isTest
    static void testQuoteLifecycleOrchestrator_StatusChange() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__StartDate__c, SBQQ__Type__c,
                                       Action_Type__c, Last_Action_Performed__c, Priority__c,
                                       Next_Action_Start_Date__c, Next_Action_Due_Date__c,
                                       Assigned_To__c, SBQQ__Account__r.Geography__c
                                FROM SBQQ__Quote__c LIMIT 1];

        SBQQ__Quote__c oldQuote = quote.clone(true, true, false, false);

        // Change status
        quote.SBQQ__Status__c = 'Product Configured';

        QuoteLifecycleOrchestrator orchestrator = new QuoteLifecycleOrchestrator();

        Test.startTest();
        QuoteLifecycleOrchestrator.ProcessingResult result = orchestrator.processQuoteChange(quote, oldQuote);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Processing should succeed');
        System.assertEquals('STATUS_CHANGE', result.changeType, 'Should identify status change');
        System.assertEquals(true, result.statusProcessed, 'Should process status');
        System.assertEquals('Status Change', quote.Action_Type__c, 'Should set action type');
    }

    @isTest
    static void testQuoteLifecycleOrchestrator_StartDateChange() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, SBQQ__StartDate__c, Priority__c,
                                       Assing_To_Me_Action__c
                                FROM SBQQ__Quote__c LIMIT 1];

        SBQQ__Quote__c oldQuote = quote.clone(true, true, false, false);

        // Change start date
        quote.SBQQ__StartDate__c = Date.today().addDays(3);

        QuoteLifecycleOrchestrator orchestrator = new QuoteLifecycleOrchestrator();

        Test.startTest();
        QuoteLifecycleOrchestrator.ProcessingResult result = orchestrator.processQuoteChange(quote, oldQuote);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Processing should succeed');
        System.assertEquals(true, result.priorityRecalculated, 'Should recalculate priority');
        System.assertNotEquals(null, quote.Priority__c, 'Should set priority');
        System.assertEquals(true, quote.Assing_To_Me_Action__c, 'Should set assign to me flag');
    }

    @isTest
    static void testQuoteLifecycleOrchestrator_NoChanges() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__Quote__c oldQuote = quote.clone(true, true, false, false);

        QuoteLifecycleOrchestrator orchestrator = new QuoteLifecycleOrchestrator();

        Test.startTest();
        QuoteLifecycleOrchestrator.ProcessingResult result = orchestrator.processQuoteChange(quote, oldQuote);
        Test.stopTest();

        System.assertEquals(true, result.noChangesDetected, 'Should detect no changes');
    }

    @isTest
    static void testQuoteLifecycleOrchestrator_PendingInformation() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c, Pending_Information__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__Quote__c oldQuote = quote.clone(true, true, false, false);

        // Change pending information
        quote.Pending_Information__c = true;

        QuoteLifecycleOrchestrator orchestrator = new QuoteLifecycleOrchestrator();

        Test.startTest();
        QuoteLifecycleOrchestrator.ProcessingResult result = orchestrator.processQuoteChange(quote, oldQuote);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Processing should succeed');
        System.assertEquals(true, result.pendingInfoProcessed, 'Should process pending info');
        System.assertEquals(false, quote.Pending_Information__c, 'Should set pending info to false');
    }

    /**
     * EDGE CASE TESTS
     */

    @isTest
    static void testRepositoryCacheClear() {
        Test.startTest();
        QuoteTeamsFrameworkRepository.clearCache();
        QuoteActionFrameworkRepository.clearCache();
        CodeSwitchRepository.clearCache();
        Test.stopTest();

        // Should execute without error
        System.assert(true, 'Cache clear should succeed');
    }

    @isTest
    static void testPriorityService_NullQuote() {
        QuotePriorityService service = new QuotePriorityService();

        Test.startTest();
        String priority = service.determinePriority(null);
        Test.stopTest();

        System.assertEquals('P4', priority, 'Should default to P4 for null');
    }

    @isTest
    static void testSchedulingService_NullQuote() {
        NextActionSchedulingService service = new NextActionSchedulingService();

        Test.startTest();
        NextActionSchedulingService.SchedulingResult result = service.calculateCompleteScheduling(null, 'WM001');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail for null quote');
    }

    @isTest
    static void testChangeDetector_NullOldQuote() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        QuoteChangeDetectorService service = new QuoteChangeDetectorService();

        Test.startTest();
        QuoteChangeDetectorService.ChangeDetectionResult result = service.detectChanges(quote, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result for null old quote');
    }
}
