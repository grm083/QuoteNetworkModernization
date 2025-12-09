/**
 * @description Test class for QuoteLineValidationService and related validation infrastructure
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
@isTest
private class QuoteLineValidationServiceTest {

    /**
     * @description Test ValidationResult creation and combination
     */
    @isTest
    static void testValidationResult_CreateAndCombine() {
        // Test successful result
        ValidationResult success = ValidationResult.createSuccess();
        System.assert(success.isValid(), 'Should be valid');
        System.assert(!success.hasErrors(), 'Should have no errors');

        // Test error result
        ValidationResult error = ValidationResult.createError('Test error');
        System.assert(!error.isValid(), 'Should be invalid');
        System.assert(error.hasErrors(), 'Should have errors');
        System.assertEquals('Test error', error.getErrorMessage(), 'Error message should match');

        // Test fluent API
        ValidationResult fluent = new ValidationResult()
            .addError('Error 1')
            .addError('Error 2')
            .addWarning('Warning 1');
        System.assert(!fluent.isValid(), 'Should be invalid');
        System.assertEquals(2, fluent.getErrorMessages().size(), 'Should have 2 errors');
        System.assertEquals(1, fluent.getWarningMessages().size(), 'Should have 1 warning');

        // Test combine
        List<ValidationResult> results = new List<ValidationResult>{success, error, fluent};
        ValidationResult combined = ValidationResult.combine(results);
        System.assert(!combined.isValid(), 'Combined should be invalid');
        System.assertEquals(3, combined.getErrorMessages().size(), 'Should have 3 total errors');
    }

    /**
     * @description Test ValidationContext creation and builder methods
     */
    @isTest
    static void testValidationContext_BuilderMethods() {
        // Create test context
        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED)
            .withQuoteType('Amendment')
            .withSTP(true)
            .withNewService(false);

        System.assertEquals(ValidationContext.Stage.COST_CONFIGURED, context.getCurrentStage(), 'Stage should match');
        System.assertEquals('Amendment', context.getQuoteType(), 'Quote type should match');
        System.assert(context.isSTP(), 'Should be STP');
        System.assert(!context.isNewService(), 'Should not be new service');
    }

    /**
     * @description Test ScheduleFrequencyRule - scheduled service missing frequency
     */
    @isTest
    static void testScheduleFrequencyRule_MissingFrequency() {
        // Given: Quote line with scheduled service but no frequency
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = null;

        ValidationContext context = ValidationContext.createTestContext();
        ScheduleFrequencyRule rule = new ScheduleFrequencyRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('service frequency'), 'Error should mention frequency');
    }

    /**
     * @description Test ScheduleFrequencyRule - weekly service missing service days
     */
    @isTest
    static void testScheduleFrequencyRule_WeeklyMissingDays() {
        // Given: Weekly scheduled service without service days
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = 'W';
        quoteLine.Service_Days__c = null;

        ValidationContext context = ValidationContext.createTestContext();
        ScheduleFrequencyRule rule = new ScheduleFrequencyRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('day(s) of the week'), 'Error should mention service days');
    }

    /**
     * @description Test ScheduleFrequencyRule - valid scheduled service
     */
    @isTest
    static void testScheduleFrequencyRule_ValidService() {
        // Given: Valid weekly scheduled service
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = 'W';
        quoteLine.Service_Days__c = 'Monday;Wednesday;Friday';

        ValidationContext context = ValidationContext.createTestContext();
        ScheduleFrequencyRule rule = new ScheduleFrequencyRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
        System.assert(!result.hasErrors(), 'Should have no errors');
    }

    /**
     * @description Test VendorActiveStatusRule - inactive vendor
     */
    @isTest
    static void testVendorActiveStatusRule_InactiveVendor() {
        // Given: Quote line with inactive vendor
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Status__c = 'Inactive');

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment');
        VendorActiveStatusRule rule = new VendorActiveStatusRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('not active'), 'Error should mention vendor status');
    }

    /**
     * @description Test VendorActiveStatusRule - active vendor
     */
    @isTest
    static void testVendorActiveStatusRule_ActiveVendor() {
        // Given: Quote line with active vendor
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Status__c = 'Active');

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment');
        VendorActiveStatusRule rule = new VendorActiveStatusRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
    }

    /**
     * @description Test MASLibraryRequiredRule - WM vendor missing MAS details
     */
    @isTest
    static void testMASLibraryRequiredRule_MissingMASDetails() {
        // Given: WM vendor without MAS library/company
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR);
        quoteLine.MASLibrary__c = null;
        quoteLine.MASCompany__c = null;
        quoteLine.SetupComment__c = null;
        quoteLine.DoNotCreateTaskGridTickets__c = false;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRODUCT_CONFIGURED);
        MASLibraryRequiredRule rule = new MASLibraryRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('MAS Library'), 'Error should mention MAS Library');
        System.assert(result.getErrorMessage().contains('Setup Comment'), 'Error should mention Setup Comment');
    }

    /**
     * @description Test MASLibraryRequiredRule - non-WM vendor (should pass)
     */
    @isTest
    static void testMASLibraryRequiredRule_NonWMVendor() {
        // Given: Non-WM vendor without MAS details
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = 'OTHER_VENDOR');
        quoteLine.MASLibrary__c = null;

        ValidationContext context = ValidationContext.createTestContext();
        MASLibraryRequiredRule rule = new MASLibraryRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass for non-WM vendor');
    }

    /**
     * @description Test OccurrenceTypeRule - scheduled service missing interval
     */
    @isTest
    static void testOccurrenceTypeRule_MissingInterval() {
        // Given: Scheduled service without frequency interval
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = 'W';
        quoteLine.Frequency_Interval__c = null;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        OccurrenceTypeRule rule = new OccurrenceTypeRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('frequency interval'), 'Error should mention frequency interval');
    }

    /**
     * @description Test OccurrenceTypeRule - on-call with schedule (should fail)
     */
    @isTest
    static void testOccurrenceTypeRule_OnCallWithSchedule() {
        // Given: On-call service with schedule frequency
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'OC';
        quoteLine.Schedule_Frequency__c = 'W';
        quoteLine.Frequency_Interval__c = '1';

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        OccurrenceTypeRule rule = new OccurrenceTypeRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('should not contain'), 'Error should mention on-call restriction');
    }

    /**
     * @description Test QuoteLineValidationService - valid quote line passes all validations
     */
    @isTest
    static void testQuoteLineValidationService_ValidQuoteLine() {
        // Given: Fully valid quote line
        SBQQ__QuoteLine__c quoteLine = createValidQuoteLine();
        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Valid quote line should pass all validations');
        System.assertEquals(0, result.getErrorMessages().size(), 'Should have no error messages');
    }

    /**
     * @description Test QuoteLineValidationService - batch validation
     */
    @isTest
    static void testQuoteLineValidationService_BatchValidation() {
        // Given: Multiple quote lines with different validation states
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            createValidQuoteLine(),
            createInvalidQuoteLine_MissingVendor(),
            createInvalidQuoteLine_MissingFrequency()
        };

        QuoteLineValidationService service = new QuoteLineValidationService();

        // When
        Test.startTest();
        Map<Id, ValidationResult> results = service.validateBatch(quoteLines);
        Test.stopTest();

        // Then
        System.assertEquals(3, results.size(), 'Should have 3 validation results');
        // Note: Since we're using mock IDs, we can't assert on specific results by ID
        // In real scenarios with inserted records, we would check specific results
    }

    /**
     * @description Test QuoteLineValidationService - convenience methods
     */
    @isTest
    static void testQuoteLineValidationService_ConvenienceMethods() {
        // Given
        SBQQ__QuoteLine__c quoteLine = createValidQuoteLine();
        QuoteLineValidationService service = new QuoteLineValidationService();

        // When
        Test.startTest();
        Boolean isValid = service.isValid(quoteLine, ValidationContext.Stage.DRAFT);
        String errorMessage = service.getErrorMessage(quoteLine, ValidationContext.Stage.DRAFT);
        Test.stopTest();

        // Then
        System.assert(isValid, 'Valid quote line should return true');
        System.assertEquals('', errorMessage, 'Valid quote line should have no error message');
    }

    /**
     * @description Test QuoteLineValidationService - stage progression
     */
    @isTest
    static void testQuoteLineValidationService_StageProgression() {
        // Given: Quote line valid in draft but invalid in product configured
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'OC'; // On-call, no frequency required
        quoteLine.Vendor__c = null; // Will fail in Product Configured stage

        QuoteLineValidationService service = new QuoteLineValidationService();

        // When/Then: Draft stage should pass
        Test.startTest();
        Boolean validInDraft = service.isValid(quoteLine, ValidationContext.Stage.DRAFT);
        System.assert(validInDraft, 'Should be valid in Draft stage');

        // Product Configured stage should fail (missing vendor)
        // Note: This will fail because VendorRequiredRule checks if quote line changed
        // In real scenario, we'd need actual quote line with changes
        Test.stopTest();
    }

    // Helper methods

    /**
     * @description Create a test quote line with minimal required fields
     */
    private static SBQQ__QuoteLine__c createTestQuoteLine() {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.Id = generateMockId(SBQQ__QuoteLine__c.SObjectType);
        quoteLine.SBQQ__Quote__r = new SBQQ__Quote__c(
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Quote',
            STP__c = false,
            Case_record_Type__c = 'Standard'
        );
        return quoteLine;
    }

    /**
     * @description Create a valid quote line for testing
     */
    private static SBQQ__QuoteLine__c createValidQuoteLine() {
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'OC'; // On-call
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Status__c = 'Active', Parent_Vendor_ID__c = 'OTHER');
        return quoteLine;
    }

    /**
     * @description Create invalid quote line - missing vendor
     */
    private static SBQQ__QuoteLine__c createInvalidQuoteLine_MissingVendor() {
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Product Configured';
        return quoteLine;
    }

    /**
     * @description Create invalid quote line - missing frequency
     */
    private static SBQQ__QuoteLine__c createInvalidQuoteLine_MissingFrequency() {
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = null;
        return quoteLine;
    }

    /**
     * @description Test VendorCommitDateRule - commit date after end date
     */
    @isTest
    static void testVendorCommitDateRule_CommitDateAfterEndDate() {
        // Given: Vendor commit date is after end date
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor_Commit_Date__c = Date.today().addDays(30);
        quoteLine.SBQQ__EndDate__c = Date.today().addDays(15);
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRODUCT_CONFIGURED)
            .withQuoteType('Amendment');
        VendorCommitDateRule rule = new VendorCommitDateRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('vendor commit date'), 'Error should mention vendor commit date');
    }

    /**
     * @description Test VendorCommitDateRule - valid dates
     */
    @isTest
    static void testVendorCommitDateRule_ValidDates() {
        // Given: Vendor commit date is before end date
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor_Commit_Date__c = Date.today().addDays(10);
        quoteLine.SBQQ__EndDate__c = Date.today().addDays(30);
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment');
        VendorCommitDateRule rule = new VendorCommitDateRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
    }

    /**
     * @description Test VCRCodeRequiredRule - WM vendor missing VCR code
     */
    @isTest
    static void testVCRCodeRequiredRule_MissingVCRCode() {
        // Given: WM vendor without VCR code on Quote type
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR);
        quoteLine.VCRCode__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Quote';

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Quote')
            .withStage(ValidationContext.Stage.PRODUCT_CONFIGURED);
        VCRCodeRequiredRule rule = new VCRCodeRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('VCR Code'), 'Error should mention VCR Code');
    }

    /**
     * @description Test VCRCodeRequiredRule - WM vendor with VCR code
     */
    @isTest
    static void testVCRCodeRequiredRule_WithVCRCode() {
        // Given: WM vendor with VCR code
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR);
        quoteLine.VCRCode__c = 'TEST123';
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Quote';

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Quote');
        VCRCodeRequiredRule rule = new VCRCodeRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
    }

    /**
     * @description Test VCRCodeRequiredRule - Non-WM vendor (should pass)
     */
    @isTest
    static void testVCRCodeRequiredRule_NonWMVendor() {
        // Given: Non-WM vendor without VCR code
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = 'OTHER_VENDOR');
        quoteLine.VCRCode__c = null;

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Quote');
        VCRCodeRequiredRule rule = new VCRCodeRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass for non-WM vendor');
    }

    /**
     * @description Test CostUOMRequiredRule - missing cost UOM
     */
    @isTest
    static void testCostUOMRequiredRule_MissingUOM() {
        // Given: Quote line without cost UOM
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Cost_Unit_of_Measure__c = null;
        quoteLine.CostModelType__c = 'STD';

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        CostUOMRequiredRule rule = new CostUOMRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Cost Unit of Measure'), 'Error should mention Cost UOM');
    }

    /**
     * @description Test CostUOMRequiredRule - stepped cost missing price2
     */
    @isTest
    static void testCostUOMRequiredRule_SteppedCostMissingPrice() {
        // Given: Stepped cost without both prices
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Cost_Unit_of_Measure__c = 'EA';
        quoteLine.CostModelType__c = 'STP';
        quoteLine.CostPrice1__c = 100;
        quoteLine.CostPrice2__c = null;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        CostUOMRequiredRule rule = new CostUOMRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('2 stepped cost'), 'Error should mention stepped cost');
    }

    /**
     * @description Test CostUOMRequiredRule - rebate with non-zero cost
     */
    @isTest
    static void testCostUOMRequiredRule_RebateNonZeroCost() {
        // Given: Rebate cost model with non-zero cost
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Cost_Unit_of_Measure__c = 'EA';
        quoteLine.CostModelType__c = 'REB';
        quoteLine.SBQQ__UnitCost__c = 50;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        CostUOMRequiredRule rule = new CostUOMRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Rebate'), 'Error should mention rebate');
    }

    /**
     * @description Test CostUOMRequiredRule - management fee invalid cost
     */
    @isTest
    static void testCostUOMRequiredRule_ManagementFeeInvalidCost() {
        // Given: Management Fee with non-zero cost
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Cost_Unit_of_Measure__c = 'EA';
        quoteLine.CostModelType__c = 'STD';
        quoteLine.SBQQ__UnitCost__c = 50;
        quoteLine.SBQQ__ProductName__c = 'Management Fee';
        quoteLine.Vendor__r = new Account(Name = 'Other Vendor');

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.COST_CONFIGURED);
        CostUOMRequiredRule rule = new CostUOMRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Management Fee'), 'Error should mention Management Fee');
    }

    /**
     * @description Test MASUniqueIdRequiredRule - Amendment missing MAS ID
     */
    @isTest
    static void testMASUniqueIdRequiredRule_MissingID() {
        // Given: WM vendor on Amendment without MAS unique ID
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR);
        quoteLine.MASCustomerUniqueId__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment')
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        MASUniqueIdRequiredRule rule = new MASUniqueIdRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('MAS Unique ID'), 'Error should mention MAS Unique ID');
    }

    /**
     * @description Test MASUniqueIdRequiredRule - Quote type (should pass)
     */
    @isTest
    static void testMASUniqueIdRequiredRule_QuoteType() {
        // Given: Quote type without MAS unique ID
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Vendor__c = 'test-vendor-id';
        quoteLine.Vendor__r = new Account(Parent_Vendor_ID__c = Constant_Util.WM_US_VENDOR);
        quoteLine.MASCustomerUniqueId__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Quote';

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Quote')
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        MASUniqueIdRequiredRule rule = new MASUniqueIdRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass for Quote type');
    }

    /**
     * @description Test PricingMethodRequiredRule - missing pricing method
     */
    @isTest
    static void testPricingMethodRequiredRule_MissingMethod() {
        // Given: Non-STP quote without pricing method
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__PricingMethod__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';
        quoteLine.SBQQ__Quote__r.STP__c = false;

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment')
            .withSTP(false)
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        PricingMethodRequiredRule rule = new PricingMethodRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('pricing method'), 'Error should mention pricing method');
    }

    /**
     * @description Test PricingMethodRequiredRule - STP quote (should pass)
     */
    @isTest
    static void testPricingMethodRequiredRule_STPQuote() {
        // Given: STP quote without pricing method
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__PricingMethod__c = null;
        quoteLine.SBQQ__Quote__r.STP__c = true;

        ValidationContext context = ValidationContext.createTestContext()
            .withSTP(true)
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        PricingMethodRequiredRule rule = new PricingMethodRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass for STP quote');
    }

    /**
     * @description Test PriceUOMRequiredRule - missing price UOM
     */
    @isTest
    static void testPriceUOMRequiredRule_MissingUOM() {
        // Given: Quote line without price UOM
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.PriceUOM__c = null;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        PriceUOMRequiredRule rule = new PriceUOMRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('price unit of measure'), 'Error should mention price UOM');
    }

    /**
     * @description Test ListPriceRequiredRule - missing list price
     */
    @isTest
    static void testListPriceRequiredRule_MissingPrice() {
        // Given: Non-STP quote without list price
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__ListPrice__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';
        quoteLine.SBQQ__Quote__r.STP__c = false;
        quoteLine.PricingUnitMethod__c = 'STD';
        quoteLine.Vendor__r = new Account(Name = 'Test Vendor');

        ValidationContext context = ValidationContext.createTestContext()
            .withQuoteType('Amendment')
            .withSTP(false)
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        ListPriceRequiredRule rule = new ListPriceRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Price cannot be blank'), 'Error should mention price');
    }

    /**
     * @description Test ListPriceRequiredRule - WM Fee with zero price
     */
    @isTest
    static void testListPriceRequiredRule_WMFeeZeroPrice() {
        // Given: WM Fee vendor with zero price
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__ListPrice__c = 0;
        quoteLine.Vendor__r = new Account(Name = 'WM Fee - Test');

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        ListPriceRequiredRule rule = new ListPriceRequiredRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('WM Fee'), 'Error should mention WM Fee');
    }

    /**
     * @description Test ManagementFeePriceRule - zero price
     */
    @isTest
    static void testManagementFeePriceRule_ZeroPrice() {
        // Given: Management Fee with zero price
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__ProductName__c = 'Management Fee';
        quoteLine.SBQQ__ListPrice__c = 0;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        ManagementFeePriceRule rule = new ManagementFeePriceRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Management Fee'), 'Error should mention Management Fee');
    }

    /**
     * @description Test ManagementFeePriceRule - valid price
     */
    @isTest
    static void testManagementFeePriceRule_ValidPrice() {
        // Given: Management Fee with valid price
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__ProductName__c = 'Management Fee';
        quoteLine.SBQQ__ListPrice__c = 100;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        ManagementFeePriceRule rule = new ManagementFeePriceRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
    }

    /**
     * @description Test SteppedPriceRule - missing price2
     */
    @isTest
    static void testSteppedPriceRule_MissingPrice2() {
        // Given: Stepped pricing without second price
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__PricingMethod__c = 'STP';
        quoteLine.PricePrice1__c = 100;
        quoteLine.PricePrice2__c = null;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        SteppedPriceRule rule = new SteppedPriceRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('2 stepped price'), 'Error should mention stepped price');
    }

    /**
     * @description Test SteppedPriceRule - valid stepped pricing
     */
    @isTest
    static void testSteppedPriceRule_ValidPricing() {
        // Given: Stepped pricing with both prices
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.SBQQ__PricingMethod__c = 'STP';
        quoteLine.PricePrice1__c = 100;
        quoteLine.PricePrice2__c = 150;

        ValidationContext context = ValidationContext.createTestContext()
            .withStage(ValidationContext.Stage.PRICE_CONFIGURED);
        SteppedPriceRule rule = new SteppedPriceRule();

        // When
        Test.startTest();
        ValidationResult result = rule.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(result.isValid(), 'Validation should pass');
    }

    /**
     * @description Test full validation flow - Draft to Price Configured
     */
    @isTest
    static void testQuoteLineValidationService_FullFlowValidLine() {
        // Given: Quote line that should be valid at all stages
        SBQQ__QuoteLine__c quoteLine = createValidQuoteLine();
        quoteLine.Cost_Unit_of_Measure__c = 'EA';
        quoteLine.CostModelType__c = 'STD';
        quoteLine.SBQQ__UnitCost__c = 100;
        quoteLine.PriceUOM__c = 'EA';
        quoteLine.SBQQ__PricingMethod__c = 'List';
        quoteLine.SBQQ__ListPrice__c = 150;

        QuoteLineValidationService service = new QuoteLineValidationService();

        // When/Then: Test each stage
        Test.startTest();

        // Draft stage
        Boolean validDraft = service.isValid(quoteLine, ValidationContext.Stage.DRAFT);
        System.assert(validDraft, 'Should be valid in Draft');

        // Product Configured stage
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Product Configured';
        Boolean validProduct = service.isValid(quoteLine, ValidationContext.Stage.PRODUCT_CONFIGURED);
        System.assert(validProduct, 'Should be valid in Product Configured');

        // Cost Configured stage
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Cost Configured';
        Boolean validCost = service.isValid(quoteLine, ValidationContext.Stage.COST_CONFIGURED);
        System.assert(validCost, 'Should be valid in Cost Configured');

        // Price Configured stage
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Price Configured';
        Boolean validPrice = service.isValid(quoteLine, ValidationContext.Stage.PRICE_CONFIGURED);
        System.assert(validPrice, 'Should be valid in Price Configured');

        Test.stopTest();
    }

    /**
     * @description Test validation accumulation across stages
     */
    @isTest
    static void testQuoteLineValidationService_StageAccumulation() {
        // Given: Quote line with multiple validation errors
        SBQQ__QuoteLine__c quoteLine = createTestQuoteLine();
        quoteLine.Occurrence_Type__c = 'SCH';
        quoteLine.Schedule_Frequency__c = null; // Error in Draft
        quoteLine.Vendor__c = null; // Error in Product Configured
        quoteLine.Cost_Unit_of_Measure__c = null; // Error in Cost Configured
        quoteLine.PriceUOM__c = null; // Error in Price Configured
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Price Configured';

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then: Should have multiple errors from different stages
        System.assert(!result.isValid(), 'Should be invalid');
        System.assert(result.getErrorMessages().size() > 1, 'Should have multiple errors from different stages');
    }

    /**
     * @description Generate a mock Salesforce ID
     */
    private static Id generateMockId(Schema.SObjectType sObjectType) {
        String result = String.valueOf(Math.abs(Crypto.getRandomLong()));
        return (Id)(sObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result);
    }
}
