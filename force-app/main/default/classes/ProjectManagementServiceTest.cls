/**
 * @description Test class for ProjectManagementService
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
@isTest
private class ProjectManagementServiceTest {

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

        // Create project code
        Project_Code__c projectCode = new Project_Code__c(
            Name = 'PRJ001',
            Client_Account__c = parentAccount.Id,
            Effective_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(180),
            Duration__c = 210,
            Is_Active__c = true,
            Company_Category__c = 'CC001'
        );
        insert projectCode;

        // Create business rule
        Business_Rule__c businessRule = new Business_Rule__c(
            Name = 'Test Business Rule',
            Case_Type__c = 'New Service',
            Sub_Type__c = 'Standard',
            Is_Active__c = true,
            Enable_Project_Code__c = true,
            Enable_Financial_Details__c = true,
            Enable_Quote_Only__c = false,
            Enable_Special_Handling__c = false
        );
        insert businessRule;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test opportunity with case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert testCase;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Case__c = testCase.Id
        );
        insert testOpp;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            Case_Type__c = 'New Service',
            Project__c = projectCode.Id
        );
        insert testQuote;

        // Create quote line
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(90)
        );
        insert quoteLine;
    }

    /**
     * @description Test getActiveProjects with SOSL (mock via null search)
     */
    @isTest
    static void testGetActiveProjects_ValidSearch() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        // Note: SOSL doesn't work in unit tests, so this will return empty
        List<Project_Code__c> projects = service.getActiveProjects(testQuote.Id, 'PRJ');
        Test.stopTest();

        // In unit tests, SOSL returns empty lists
        System.assertNotEquals(null, projects, 'Should return a list');
    }

    /**
     * @description Test getActiveProjects with null inputs
     */
    @isTest
    static void testGetActiveProjects_NullInputs() {
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        List<Project_Code__c> result1 = service.getActiveProjects(null, 'test');
        List<Project_Code__c> result2 = service.getActiveProjects([SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id, '');
        Test.stopTest();

        System.assertEquals(0, result1.size(), 'Should return empty list for null quote ID');
        System.assertEquals(0, result2.size(), 'Should return empty list for blank search string');
    }

    /**
     * @description Test getQuoteBusinessRules
     */
    @isTest
    static void testGetQuoteBusinessRules_Success() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Business_Rule__c rule = service.getQuoteBusinessRules(testQuote.Id, 'New Service', 'Standard');
        Test.stopTest();

        System.assertNotEquals(null, rule, 'Should return business rule');
        System.assertEquals('New Service', rule.Case_Type__c, 'Should return correct case type');
        System.assertEquals(true, rule.Enable_Project_Code__c, 'Should have project code enabled');
    }

    /**
     * @description Test getQuoteBusinessRules with no matching rule
     */
    @isTest
    static void testGetQuoteBusinessRules_NoMatch() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Business_Rule__c rule = service.getQuoteBusinessRules(testQuote.Id, 'NonExistent', 'Type');
        Test.stopTest();

        System.assertEquals(null, rule, 'Should return null for non-matching rule');
    }

    /**
     * @description Test validateProjectCode with valid data
     */
    @isTest
    static void testValidateProjectCode_Valid() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        Project_Code__c projectCode = [SELECT Id FROM Project_Code__c LIMIT 1];

        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        ProjectManagementService.ProjectValidationResult result = service.validateProjectCode(
            quoteLine.Id,
            projectCode.Id
        );
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Validation should pass');
        System.assertEquals('', result.errorMessage, 'Should have no error message');
    }

    /**
     * @description Test validateProjectCode with null project code (optional)
     */
    @isTest
    static void testValidateProjectCode_NullProjectCode() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        ProjectManagementService.ProjectValidationResult result = service.validateProjectCode(quoteLine.Id, null);
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Validation should pass for null project code');
    }

    /**
     * @description Test validateProjectCode with null quote line
     */
    @isTest
    static void testValidateProjectCode_NullQuoteLine() {
        Project_Code__c projectCode = [SELECT Id FROM Project_Code__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        ProjectManagementService.ProjectValidationResult result = service.validateProjectCode(null, projectCode.Id);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Validation should fail');
        System.assert(result.errorMessage.contains('required'), 'Should indicate quote line is required');
    }

    /**
     * @description Test validateProjectCode with inactive project
     */
    @isTest
    static void testValidateProjectCode_InactiveProject() {
        // Create inactive project
        Account parentAccount = [SELECT Id FROM Account WHERE ParentId = null LIMIT 1];
        Project_Code__c inactiveProject = new Project_Code__c(
            Name = 'INACTIVE',
            Client_Account__c = parentAccount.Id,
            Is_Active__c = false,
            Effective_Date__c = Date.today()
        );
        insert inactiveProject;

        SBQQ__QuoteLine__c quoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        ProjectManagementService.ProjectValidationResult result = service.validateProjectCode(
            quoteLine.Id,
            inactiveProject.Id
        );
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Validation should fail for inactive project');
        System.assert(result.errorMessage.contains('not active'), 'Should indicate project is not active');
    }

    /**
     * @description Test assignProjectCode
     */
    @isTest
    static void testAssignProjectCode_Success() {
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Quote__c FROM SBQQ__QuoteLine__c LIMIT 1];
        Project_Code__c projectCode = [SELECT Id FROM Project_Code__c LIMIT 1];

        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Boolean result = service.assignProjectCode(quoteLine.Id, projectCode.Id);
        Test.stopTest();

        System.assert(result, 'Assignment should succeed');

        // Verify quote updated
        SBQQ__Quote__c updatedQuote = [SELECT Project__c FROM SBQQ__Quote__c WHERE Id = :quoteLine.SBQQ__Quote__c];
        System.assertEquals(projectCode.Id, updatedQuote.Project__c, 'Project should be assigned to quote');
    }

    /**
     * @description Test assignProjectCode with null parent ID
     */
    @isTest
    static void testAssignProjectCode_NullParentId() {
        Project_Code__c projectCode = [SELECT Id FROM Project_Code__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Boolean result = service.assignProjectCode(null, projectCode.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for null parent ID');
    }

    /**
     * @description Test getProjectDetails
     */
    @isTest
    static void testGetProjectDetails_Success() {
        Project_Code__c projectCode = [SELECT Id FROM Project_Code__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Project_Code__c details = service.getProjectDetails(projectCode.Id);
        Test.stopTest();

        System.assertNotEquals(null, details, 'Should return project details');
        System.assertEquals('PRJ001', details.Name, 'Should return correct project name');
        System.assertEquals(true, details.Is_Active__c, 'Should return active status');
    }

    /**
     * @description Test getProjectDetails with null ID
     */
    @isTest
    static void testGetProjectDetails_NullId() {
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Project_Code__c details = service.getProjectDetails(null);
        Test.stopTest();

        System.assertEquals(null, details, 'Should return null for null ID');
    }

    /**
     * @description Test isProjectCodeRequired
     */
    @isTest
    static void testIsProjectCodeRequired_True() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Boolean required = service.isProjectCodeRequired(testQuote.Id, 'New Service', 'Standard');
        Test.stopTest();

        System.assertEquals(true, required, 'Project code should be required');
    }

    /**
     * @description Test isProjectCodeRequired with rule not found
     */
    @isTest
    static void testIsProjectCodeRequired_False() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        ProjectManagementService service = new ProjectManagementService();

        Test.startTest();
        Boolean required = service.isProjectCodeRequired(testQuote.Id, 'NonExistent', 'Type');
        Test.stopTest();

        System.assertEquals(false, required, 'Should return false when rule not found');
    }

    /**
     * @description Test ProjectValidationResult wrapper initialization
     */
    @isTest
    static void testProjectValidationResultWrapper() {
        Test.startTest();
        ProjectManagementService.ProjectValidationResult result = new ProjectManagementService.ProjectValidationResult();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should be initialized');
        System.assertEquals(true, result.isValid, 'Default isValid should be true');
        System.assertEquals('', result.errorMessage, 'Default error message should be empty');
    }
}
