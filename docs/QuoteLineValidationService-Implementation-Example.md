# QuoteLineValidationService - Implementation Example
**Quote Network Modernization Project**

This document provides a detailed implementation example for the `QuoteLineValidationService`, demonstrating how to refactor validation logic from the monolithic `QuoteProcurementController` into a SOLID-compliant service class.

---

## Overview

**Current State:**
- Validation logic scattered across `vFStage()`, `vSStage()`, `vTStage()`, `validateOccurence()`, `validateRemovalAndSwapoutSize()` methods
- ~400 lines of deeply nested conditional logic
- Hard to test, extend, or maintain

**Proposed State:**
- Centralized `QuoteLineValidationService` with clear validation pipeline
- Strategy pattern for extensible validation rules
- Fully testable with comprehensive unit tests

---

## Class Diagram

```
┌─────────────────────────────────────────────────────┐
│         IQuoteLineValidationService                 │
│         (Interface)                                 │
├─────────────────────────────────────────────────────┤
│ + validate(quoteLine, context): ValidationResult   │
│ + validateByStage(quoteLine, stage): ValidationResult │
└─────────────────────────────┬───────────────────────┘
                              │
                              │ implements
                              │
┌─────────────────────────────▼───────────────────────┐
│         QuoteLineValidationService                  │
├─────────────────────────────────────────────────────┤
│ - validators: Map<Stage, IStageValidator>          │
│ - ruleFactory: ValidationRuleFactory               │
├─────────────────────────────────────────────────────┤
│ + validate(quoteLine, context): ValidationResult   │
│ + validateByStage(quoteLine, stage): ValidationResult │
│ - buildValidationContext(quoteLine): Context       │
└─────────────────────────────┬───────────────────────┘
                              │
                              │ uses
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌────────────────┐   ┌────────────────┐
│ IStageValidator│   │ IValidationRule│   │ValidationResult│
└───────────────┘   └────────────────┘   └────────────────┘
```

---

## Core Classes

### 1. ValidationResult.cls

```apex
/**
 * @description Encapsulates the result of a validation operation
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 */
public class ValidationResult {
    private Boolean isValid;
    private List<String> errorMessages;
    private List<String> warningMessages;
    private Map<String, Object> metadata;

    /**
     * @description Constructor for successful validation
     */
    public ValidationResult() {
        this(true, new List<String>(), new List<String>());
    }

    /**
     * @description Constructor with validation status and messages
     */
    public ValidationResult(Boolean isValid, List<String> errors, List<String> warnings) {
        this.isValid = isValid;
        this.errorMessages = errors != null ? errors : new List<String>();
        this.warningMessages = warnings != null ? warnings : new List<String>();
        this.metadata = new Map<String, Object>();
    }

    // Fluent API for building validation results
    public ValidationResult addError(String message) {
        this.errorMessages.add(message);
        this.isValid = false;
        return this;
    }

    public ValidationResult addWarning(String message) {
        this.warningMessages.add(message);
        return this;
    }

    public ValidationResult addMetadata(String key, Object value) {
        this.metadata.put(key, value);
        return this;
    }

    // Getters
    public Boolean isValid() {
        return this.isValid;
    }

    public Boolean hasErrors() {
        return !this.errorMessages.isEmpty();
    }

    public Boolean hasWarnings() {
        return !this.warningMessages.isEmpty();
    }

    public String getErrorMessage() {
        return String.join(this.errorMessages, '\n');
    }

    public List<String> getErrorMessages() {
        return this.errorMessages;
    }

    public List<String> getWarningMessages() {
        return this.warningMessages;
    }

    public Object getMetadata(String key) {
        return this.metadata.get(key);
    }

    /**
     * @description Combines multiple validation results
     */
    public static ValidationResult combine(List<ValidationResult> results) {
        ValidationResult combined = new ValidationResult();
        for (ValidationResult result : results) {
            if (result.hasErrors()) {
                combined.isValid = false;
                combined.errorMessages.addAll(result.getErrorMessages());
            }
            if (result.hasWarnings()) {
                combined.warningMessages.addAll(result.getWarningMessages());
            }
        }
        return combined;
    }
}
```

### 2. ValidationContext.cls

```apex
/**
 * @description Context for validation operations
 */
public class ValidationContext {
    public enum Stage {
        DRAFT,
        PRODUCT_CONFIGURED,
        COST_CONFIGURED,
        PRICE_CONFIGURED
    }

    public Stage currentStage { get; private set; }
    public String quoteType { get; private set; }
    public Boolean isSTP { get; private set; }
    public String caseRecordType { get; private set; }
    public Boolean isNewService { get; private set; }

    public ValidationContext(SBQQ__QuoteLine__c quoteLine) {
        this.currentStage = determineStage(quoteLine.SBQQ__Quote__r.SBQQ__Status__c);
        this.quoteType = quoteLine.SBQQ__Quote__r.SBQQ__Type__c;
        this.isSTP = quoteLine.SBQQ__Quote__r.STP__c;
        this.caseRecordType = quoteLine.SBQQ__Quote__r.Case_record_Type__c;
        this.isNewService = (this.caseRecordType == Constant_Util.New_Service_Case);
    }

    private Stage determineStage(String quoteStatus) {
        if (quoteStatus == 'Draft') {
            return Stage.DRAFT;
        } else if (quoteStatus == 'Product Configured') {
            return Stage.PRODUCT_CONFIGURED;
        } else if (quoteStatus == 'Cost Configured') {
            return Stage.COST_CONFIGURED;
        } else if (quoteStatus == 'Price Configured') {
            return Stage.PRICE_CONFIGURED;
        }
        return Stage.DRAFT;
    }

    // Builder methods for test scenarios
    public ValidationContext withStage(Stage stage) {
        this.currentStage = stage;
        return this;
    }

    public ValidationContext withQuoteType(String quoteType) {
        this.quoteType = quoteType;
        return this;
    }

    public ValidationContext withSTP(Boolean isSTP) {
        this.isSTP = isSTP;
        return this;
    }
}
```

### 3. IValidationRule Interface

```apex
/**
 * @description Interface for validation rules (Strategy Pattern)
 */
public interface IValidationRule {
    /**
     * @description Execute validation rule
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context);

    /**
     * @description Rule name for logging/debugging
     */
    String getRuleName();

    /**
     * @description Check if rule applies to current context
     */
    Boolean appliesTo(ValidationContext context);
}
```

### 4. Concrete Validation Rules

#### ScheduleFrequencyRule.cls

```apex
/**
 * @description Validates schedule frequency for scheduled/SOC services
 * Replaces logic from vFStage() lines 925-933
 */
public class ScheduleFrequencyRule implements IValidationRule {

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Check if this is a scheduled or SOC service
        if (quoteLine.Occurrence_Type__c == 'SOC' || quoteLine.Occurrence_Type__c == 'SCH') {

            // Frequency is required
            if (String.isBlank(quoteLine.Schedule_Frequency__c)) {
                result.addError('Scheduled service missing a service frequency (weekly, monthly, etc.)');
                return result;
            }

            // Weekly frequency requires service days
            if (quoteLine.Schedule_Frequency__c == 'W' && String.isBlank(quoteLine.Service_Days__c)) {
                result.addError('Weekly scheduled service missing day(s) of the week');
            }
        }

        return result;
    }

    public String getRuleName() {
        return 'ScheduleFrequencyRule';
    }

    public Boolean appliesTo(ValidationContext context) {
        // Applies to all stages
        return true;
    }
}
```

#### VendorActiveStatusRule.cls

```apex
/**
 * @description Validates vendor active status
 * Replaces logic from vFStage() lines 936-946
 */
public class VendorActiveStatusRule implements IValidationRule {

    private static final String ERROR_VENDOR_INACTIVE = 'Selected vendor is not active';

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Check if validation applies to this quote type
        if (!shouldValidateVendorStatus(context, quoteLine)) {
            return result;
        }

        // Validate vendor is active
        if (quoteLine.Vendor__c != null && quoteLine.Vendor__r.Status__c == 'Inactive') {
            result.addError(ERROR_VENDOR_INACTIVE);
        }

        return result;
    }

    private Boolean shouldValidateVendorStatus(ValidationContext context, SBQQ__QuoteLine__c quoteLine) {
        // Validate for Amendment, Exception, Correction, or Quote (non-STP)
        return (context.quoteType == 'Amendment'
            || context.quoteType == 'Exception'
            || context.quoteType == 'Correction'
            || (context.quoteType == 'Quote' && !context.isSTP));
    }

    public String getRuleName() {
        return 'VendorActiveStatusRule';
    }

    public Boolean appliesTo(ValidationContext context) {
        return true; // Applies to all stages
    }
}
```

#### VendorRequiredRule.cls

```apex
/**
 * @description Validates vendor is assigned
 * Replaces logic from vSStage() lines 955-957
 */
public class VendorRequiredRule implements IValidationRule {

    private static final String ERROR_VENDOR_MISSING = 'Vendor missing';

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate if quote line has changed for non-new service cases
        if (!QuoteLineServices.isQuoteLineChangedforNonNs(quoteLine)) {
            return result;
        }

        if (quoteLine.Vendor__c == null) {
            result.addError(ERROR_VENDOR_MISSING);
        }

        return result;
    }

    public String getRuleName() {
        return 'VendorRequiredRule';
    }

    public Boolean appliesTo(ValidationContext context) {
        // Applies from Product Configured stage onwards
        return context.currentStage != ValidationContext.Stage.DRAFT;
    }
}
```

#### MASLibraryRequiredRule.cls

```apex
/**
 * @description Validates MAS Library and Company Code for WM vendors
 * Replaces logic from vSStage() lines 973-995
 */
public class MASLibraryRequiredRule implements IValidationRule {

    private static final String ERROR_MAS_LIBRARY_CODE = 'Missing MAS Library, Company Code';
    private static final String ERROR_SETUP_COMMENT = 'Missing Setup Comment';
    private static final String ERROR_SETUP_COMMENT_OR = ' or Setup Comment';

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for WM vendors
        if (!isWMVendor(quoteLine)) {
            return result;
        }

        // Validate MAS Library and Company Code
        if (String.isBlank(quoteLine.MASLibrary__c) || String.isBlank(quoteLine.MASCompany__c)) {
            result.addError(ERROR_MAS_LIBRARY_CODE);
        }

        // Validate Setup Comment (unless TaskGrid tickets are bypassed)
        if (String.isBlank(quoteLine.SetupComment__c) && quoteLine.DoNotCreateTaskGridTickets__c == false) {
            String errorMsg = result.hasErrors() ? ERROR_SETUP_COMMENT_OR : ERROR_SETUP_COMMENT;
            result.addError(errorMsg);
        }

        return result;
    }

    private Boolean isWMVendor(SBQQ__QuoteLine__c quoteLine) {
        String vendorId = quoteLine.Vendor__r.Parent_Vendor_ID__c;
        return (vendorId == Constant_Util.WM_US_VENDOR || vendorId == Constant_Util.WM_CANADA_VENDOR);
    }

    public String getRuleName() {
        return 'MASLibraryRequiredRule';
    }

    public Boolean appliesTo(ValidationContext context) {
        // Applies from Product Configured stage onwards
        return context.currentStage != ValidationContext.Stage.DRAFT;
    }
}
```

#### CostUOMRequiredRule.cls

```apex
/**
 * @description Validates Cost UOM and Cost Model Type
 * Replaces logic from vSStage() lines 1020-1064
 */
public class CostUOMRequiredRule implements IValidationRule {

    private static final String ERROR_COST_UOM_TYPE = 'Missing Cost Unit of Measure or Model Type';
    private static final String ERROR_COST_MODEL_STP = 'You must enter 2 stepped cost if Cost model type is Stepped.';
    private static final String ERROR_COST_MODEL_REBATE = 'Cost Model Type of Rebate must have a Cost of $0.00';
    private static final String ERROR_COST_MISSING = 'Cost Missing';
    private static final String ERROR_MANAGEMENT_FEE = 'Unit cost should be $0.00 and vendor name should start with WM Fee if product name is Management Fee';
    private static final String ERROR_WM_FEE_COST = 'WM Fee charges should have a cost of 0$';

    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Cost UOM and Model Type required
        if (String.isBlank(quoteLine.Cost_Unit_of_Measure__c) || String.isBlank(quoteLine.CostModelType__c)) {
            result.addError(ERROR_COST_UOM_TYPE);
            return result;
        }

        // Validate based on Cost Model Type
        if (quoteLine.CostModelType__c == 'STP') {
            // Stepped pricing requires 2 cost prices
            if (quoteLine.CostPrice1__c == null || quoteLine.CostPrice2__c == null) {
                result.addError(ERROR_COST_MODEL_STP);
            }
        } else if (quoteLine.CostModelType__c == 'REB') {
            // Rebate must have $0 cost
            if (quoteLine.SBQQ__UnitCost__c != 0) {
                result.addError(ERROR_COST_MODEL_REBATE);
            }
        } else {
            // Standard cost model - cost is required
            if (quoteLine.SBQQ__UnitCost__c == null) {
                result.addError(ERROR_COST_MISSING);
            } else {
                // Special validation for Management Fee
                if (quoteLine.SBQQ__ProductName__c == 'Management Fee') {
                    String vendorName = quoteLine.Vendor__r.Name;
                    if (quoteLine.SBQQ__UnitCost__c != 0 || !vendorName.startsWithIgnoreCase('WM Fee')) {
                        result.addError(ERROR_MANAGEMENT_FEE);
                    }
                }
                // Validate WM Fee vendors
                else if (isWMFeeVendor(quoteLine, context)) {
                    if (quoteLine.SBQQ__UnitCost__c != 0) {
                        result.addError(ERROR_WM_FEE_COST);
                    }
                }
            }
        }

        return result;
    }

    private Boolean isWMFeeVendor(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        String vendorName = quoteLine.Vendor__r.Name;
        return (context.quoteType == 'Amendment'
            || context.quoteType == 'Quote')
            && !context.isSTP
            && vendorName != null
            && vendorName.startsWithIgnoreCase('WM Fee');
    }

    public String getRuleName() {
        return 'CostUOMRequiredRule';
    }

    public Boolean appliesTo(ValidationContext context) {
        // Applies from Cost Configured stage onwards
        return context.currentStage == ValidationContext.Stage.COST_CONFIGURED
            || context.currentStage == ValidationContext.Stage.PRICE_CONFIGURED;
    }
}
```

### 5. QuoteLineValidationService.cls

```apex
/**
 * @description Service for validating quote lines
 * Replaces validation logic from QuoteProcurementController (vFStage, vSStage, vTStage)
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 */
public class QuoteLineValidationService implements IQuoteLineValidationService {

    private Map<ValidationContext.Stage, List<IValidationRule>> rulesByStage;

    /**
     * @description Constructor - initializes validation rules
     */
    public QuoteLineValidationService() {
        initializeValidationRules();
    }

    /**
     * @description Validate a quote line based on its current context
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        List<ValidationResult> results = new List<ValidationResult>();

        // Get rules for current stage
        List<IValidationRule> rules = getRulesForStage(context.currentStage);

        // Execute each applicable rule
        for (IValidationRule rule : rules) {
            if (rule.appliesTo(context)) {
                try {
                    ValidationResult ruleResult = rule.validate(quoteLine, context);
                    results.add(ruleResult);
                } catch (Exception ex) {
                    // Log exception and continue with other rules
                    UTIL_LoggingService.logException(ex, rule.getRuleName());
                }
            }
        }

        // Combine all validation results
        return ValidationResult.combine(results);
    }

    /**
     * @description Validate by specific stage (convenience method)
     */
    public ValidationResult validateByStage(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationContext context = new ValidationContext(quoteLine).withStage(stage);
        return validate(quoteLine, context);
    }

    /**
     * @description Initialize validation rules by stage
     * This method maps rules to stages, implementing the cascading validation logic:
     * - Draft stage: Basic rules
     * - Product Configured: Draft + Vendor rules
     * - Cost Configured: Product Configured + Cost rules
     * - Price Configured: Cost Configured + Price rules
     */
    private void initializeValidationRules() {
        rulesByStage = new Map<ValidationContext.Stage, List<IValidationRule>>();

        // Draft stage rules
        List<IValidationRule> draftRules = new List<IValidationRule>{
            new ScheduleFrequencyRule(),
            new VendorActiveStatusRule()
        };
        rulesByStage.put(ValidationContext.Stage.DRAFT, draftRules);

        // Product Configured stage: Draft + Vendor rules
        List<IValidationRule> productConfiguredRules = new List<IValidationRule>();
        productConfiguredRules.addAll(draftRules);
        productConfiguredRules.addAll(new List<IValidationRule>{
            new VendorRequiredRule(),
            new VendorActiveStatusRule(),
            new MASLibraryRequiredRule(),
            new VCRCodeRequiredRule(),
            new VendorCommitDateRule()
        });
        rulesByStage.put(ValidationContext.Stage.PRODUCT_CONFIGURED, productConfiguredRules);

        // Cost Configured stage: Product Configured + Cost rules
        List<IValidationRule> costConfiguredRules = new List<IValidationRule>();
        costConfiguredRules.addAll(productConfiguredRules);
        costConfiguredRules.addAll(new List<IValidationRule>{
            new CostUOMRequiredRule(),
            new OccurrenceTypeRule(),
            new RemovalSwapoutSizeRule()
        });
        rulesByStage.put(ValidationContext.Stage.COST_CONFIGURED, costConfiguredRules);

        // Price Configured stage: Cost Configured + Price rules
        List<IValidationRule> priceConfiguredRules = new List<IValidationRule>();
        priceConfiguredRules.addAll(costConfiguredRules);
        priceConfiguredRules.addAll(new List<IValidationRule>{
            new MASUniqueIdRequiredRule(),
            new PricingMethodRequiredRule(),
            new PriceUOMRequiredRule(),
            new ListPriceRequiredRule(),
            new ManagementFeePriceRule(),
            new SteppedPriceRule(),
            new WMFeePriceRule()
        });
        rulesByStage.put(ValidationContext.Stage.PRICE_CONFIGURED, priceConfiguredRules);
    }

    /**
     * @description Get validation rules for a specific stage
     */
    private List<IValidationRule> getRulesForStage(ValidationContext.Stage stage) {
        List<IValidationRule> rules = rulesByStage.get(stage);
        return rules != null ? rules : new List<IValidationRule>();
    }

    /**
     * @description Batch validate multiple quote lines
     * @param quoteLines List of quote lines to validate
     * @return Map of quote line ID to validation result
     */
    public Map<Id, ValidationResult> validateBatch(List<SBQQ__QuoteLine__c> quoteLines) {
        Map<Id, ValidationResult> resultMap = new Map<Id, ValidationResult>();

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            ValidationContext context = new ValidationContext(quoteLine);
            ValidationResult result = validate(quoteLine, context);
            resultMap.put(quoteLine.Id, result);
        }

        return resultMap;
    }
}
```

---

## Unit Tests

### QuoteLineValidationServiceTest.cls

```apex
/**
 * @description Test class for QuoteLineValidationService
 * Demonstrates comprehensive unit testing with mocked dependencies
 */
@isTest
private class QuoteLineValidationServiceTest {

    /**
     * Test: Draft stage validation - scheduled service missing frequency
     */
    @isTest
    static void testValidateDraftStage_ScheduledService_MissingFrequency() {
        // Given: Quote line with scheduled service but no frequency
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Occurrence_Type__c' => 'SCH',
                'Schedule_Frequency__c' => null,
                'Service_Days__c' => 'Monday'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine).withStage(ValidationContext.Stage.DRAFT);

        // When: Validation is performed
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then: Validation should fail with appropriate message
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('service frequency'),
            'Error message should mention frequency');
    }

    /**
     * Test: Draft stage validation - weekly service missing service days
     */
    @isTest
    static void testValidateDraftStage_WeeklyService_MissingServiceDays() {
        // Given: Weekly scheduled service without service days
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Occurrence_Type__c' => 'SCH',
                'Schedule_Frequency__c' => 'W',
                'Service_Days__c' => null
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine).withStage(ValidationContext.Stage.DRAFT);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('day(s) of the week'),
            'Error message should mention service days');
    }

    /**
     * Test: Product Configured stage - vendor required
     */
    @isTest
    static void testValidateProductConfigured_VendorMissing() {
        // Given: Quote line without vendor in Product Configured stage
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Vendor__c' => null,
                'SBQQ__Quote__r.SBQQ__Status__c' => 'Product Configured'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Vendor missing'),
            'Error message should indicate missing vendor');
    }

    /**
     * Test: Product Configured stage - inactive vendor
     */
    @isTest
    static void testValidateProductConfigured_InactiveVendor() {
        // Given: Quote line with inactive vendor
        Account vendor = TestDataFactory.createVendor(new Map<String, Object>{
            'Status__c' => 'Inactive'
        });

        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Vendor__c' => vendor.Id,
                'Vendor__r' => vendor,
                'SBQQ__Quote__r.SBQQ__Status__c' => 'Product Configured',
                'SBQQ__Quote__r.SBQQ__Type__c' => 'Amendment'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('not active'),
            'Error message should indicate vendor is inactive');
    }

    /**
     * Test: Cost Configured stage - WM vendor missing MAS details
     */
    @isTest
    static void testValidateCostConfigured_WMVendor_MissingMASDetails() {
        // Given: WM vendor without MAS library/company
        Account vendor = TestDataFactory.createWMVendor();

        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Vendor__c' => vendor.Id,
                'Vendor__r' => vendor,
                'MASLibrary__c' => null,
                'MASCompany__c' => null,
                'SetupComment__c' => null,
                'DoNotCreateTaskGridTickets__c' => false,
                'SBQQ__Quote__r.SBQQ__Status__c' => 'Cost Configured'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('MAS Library'),
            'Error message should mention MAS Library');
        System.assert(result.getErrorMessage().contains('Setup Comment'),
            'Error message should mention Setup Comment');
    }

    /**
     * Test: Cost Configured stage - missing cost UOM
     */
    @isTest
    static void testValidateCostConfigured_MissingCostUOM() {
        // Given: Quote line without cost UOM
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Cost_Unit_of_Measure__c' => null,
                'CostModelType__c' => 'STD',
                'SBQQ__Quote__r.SBQQ__Status__c' => 'Cost Configured'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('Cost Unit of Measure'),
            'Error message should mention Cost UOM');
    }

    /**
     * Test: Cost Configured stage - stepped cost without 2 prices
     */
    @isTest
    static void testValidateCostConfigured_SteppedCost_MissingPrices() {
        // Given: Stepped cost model without both prices
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(
            new Map<String, Object>{
                'Cost_Unit_of_Measure__c' => 'EA',
                'CostModelType__c' => 'STP',
                'CostPrice1__c' => 100,
                'CostPrice2__c' => null,
                'SBQQ__Quote__r.SBQQ__Status__c' => 'Cost Configured'
            }
        );

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('2 stepped cost'),
            'Error message should mention 2 stepped costs');
    }

    /**
     * Test: Price Configured stage - missing pricing method
     */
    @isTest
    static void testValidatePriceConfigured_MissingPricingMethod() {
        // Given: Quote line without pricing method
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createValidQuoteLine();
        quoteLine.SBQQ__PricingMethod__c = null;
        quoteLine.SBQQ__Quote__r.SBQQ__Status__c = 'Price Configured';
        quoteLine.SBQQ__Quote__r.SBQQ__Type__c = 'Amendment';
        quoteLine.SBQQ__Quote__r.STP__c = false;

        QuoteLineValidationService service = new QuoteLineValidationService();
        ValidationContext context = new ValidationContext(quoteLine);

        // When
        Test.startTest();
        ValidationResult result = service.validate(quoteLine, context);
        Test.stopTest();

        // Then
        System.assert(!result.isValid(), 'Validation should fail');
        System.assert(result.getErrorMessage().contains('pricing method'),
            'Error message should mention pricing method');
    }

    /**
     * Test: Batch validation
     */
    @isTest
    static void testValidateBatch_MultipleQuoteLines() {
        // Given: Multiple quote lines with different validation states
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>{
            TestDataFactory.createValidQuoteLine(),
            TestDataFactory.createQuoteLine(new Map<String, Object>{
                'Vendor__c' => null // Invalid - missing vendor
            }),
            TestDataFactory.createQuoteLine(new Map<String, Object>{
                'Schedule_Frequency__c' => null, // Invalid - missing frequency
                'Occurrence_Type__c' => 'SCH'
            })
        };

        QuoteLineValidationService service = new QuoteLineValidationService();

        // When
        Test.startTest();
        Map<Id, ValidationResult> results = service.validateBatch(quoteLines);
        Test.stopTest();

        // Then
        System.assertEquals(3, results.size(), 'Should have 3 validation results');
        System.assert(results.get(quoteLines[0].Id).isValid(), 'First quote line should be valid');
        System.assert(!results.get(quoteLines[1].Id).isValid(), 'Second quote line should be invalid');
        System.assert(!results.get(quoteLines[2].Id).isValid(), 'Third quote line should be invalid');
    }

    /**
     * Test: Valid quote line passes all validations
     */
    @isTest
    static void testValidate_ValidQuoteLine_PassesAllValidations() {
        // Given: Fully valid quote line
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createValidQuoteLine();

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
}
```

---

## Usage Examples

### Example 1: Controller Integration

```apex
// In QuoteProcurementController.cls
public class QuoteProcurementController {

    @TestVisible
    private static QuoteLineValidationService validationService = new QuoteLineValidationService();

    /**
     * @description Get quote details with validation
     * Replaces: buildWrapper()
     */
    @AuraEnabled
    public static ProductsWrapper buildWrapper(String quoteId) {
        // Retrieve data
        List<SBQQ__QuoteLine__c> quoteLines = QuoteLineSelector.getQuoteLines(quoteId);

        // Validate each quote line
        Map<Id, ValidationResult> validationResults = validationService.validateBatch(quoteLines);

        // Transform to wrapper with validation errors
        ProductsWrapper wrapper = new ProductsWrapper();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            HeaderWrapper header = transformToHeader(quoteLine);

            // Add validation errors to header
            ValidationResult validationResult = validationResults.get(quoteLine.Id);
            if (validationResult.hasErrors()) {
                header.lineError = true;
                header.errorMessage = validationResult.getErrorMessage();
            }

            wrapper.configuredProducts.add(header);
        }

        return wrapper;
    }

    /**
     * @description Update quote status with validation
     * Replaces: updateStatus()
     */
    @AuraEnabled
    public static Boolean updateStatus(Id quoteId, String newStatus, Boolean quoteOnly) {
        List<SBQQ__QuoteLine__c> quoteLines = QuoteLineSelector.getQuoteLines(quoteId);

        // Validate all quote lines before status change
        Map<Id, ValidationResult> validationResults = validationService.validateBatch(quoteLines);

        // Check if any validations failed
        for (ValidationResult result : validationResults.values()) {
            if (!result.isValid()) {
                throw new AuraHandledException('Cannot update status. Validation errors exist: ' + result.getErrorMessage());
            }
        }

        // Proceed with status update
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId, SBQQ__Status__c = newStatus);
        update quote;

        return true;
    }
}
```

### Example 2: Trigger Integration

```apex
// QuoteLineTriggerHandler.cls
public class QuoteLineTriggerHandler {

    private QuoteLineValidationService validationService;

    public QuoteLineTriggerHandler() {
        this.validationService = new QuoteLineValidationService();
    }

    public void beforeUpdate(List<SBQQ__QuoteLine__c> newQuoteLines, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        // Validate quote lines before update
        Map<Id, ValidationResult> validationResults = validationService.validateBatch(newQuoteLines);

        // Apply validation errors to records
        for (SBQQ__QuoteLine__c quoteLine : newQuoteLines) {
            ValidationResult result = validationResults.get(quoteLine.Id);
            if (result.hasErrors()) {
                quoteLine.ErrorComments__c = result.getErrorMessage();
            } else {
                quoteLine.ErrorComments__c = 'All validations passed';
            }
        }
    }
}
```

### Example 3: Batch Job Integration

```apex
// QuoteLineValidationBatch.cls
public class QuoteLineValidationBatch implements Database.Batchable<sObject> {

    private QuoteLineValidationService validationService;

    public QuoteLineValidationBatch() {
        this.validationService = new QuoteLineValidationService();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Vendor__c, Schedule_Frequency__c, /* ... all fields ... */
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__r.SBQQ__Status__c = 'Cost Configured'
            AND ErrorComments__c = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SBQQ__QuoteLine__c> quoteLines) {
        // Validate batch of quote lines
        Map<Id, ValidationResult> validationResults = validationService.validateBatch(quoteLines);

        // Update error comments
        List<SBQQ__QuoteLine__c> toUpdate = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            ValidationResult result = validationResults.get(quoteLine.Id);
            quoteLine.ErrorComments__c = result.isValid() ? 'Valid' : result.getErrorMessage();
            toUpdate.add(quoteLine);
        }

        update toUpdate;
    }

    public void finish(Database.BatchableContext bc) {
        // Send notification
    }
}
```

---

## Benefits Demonstrated

### 1. Single Responsibility
Each validation rule has one clear purpose:
- ✅ `ScheduleFrequencyRule` - validates schedule frequency
- ✅ `VendorRequiredRule` - validates vendor presence
- ✅ `MASLibraryRequiredRule` - validates MAS requirements

### 2. Open/Closed Principle
- ✅ Can add new validation rules without modifying existing code
- ✅ New rules implement `IValidationRule` interface
- ✅ Register new rules in `initializeValidationRules()`

### 3. Liskov Substitution
- ✅ All rules implement `IValidationRule` interface
- ✅ Rules are interchangeable
- ✅ Service treats all rules uniformly

### 4. Interface Segregation
- ✅ `IValidationRule` has minimal interface (3 methods)
- ✅ No forced dependencies on unused methods
- ✅ Clear contract for implementers

### 5. Dependency Inversion
- ✅ Service depends on `IValidationRule` interface, not concrete implementations
- ✅ Easy to mock for testing
- ✅ Can inject different rule implementations

### Additional Benefits
- ✅ **Testability:** Each rule can be tested independently
- ✅ **Reusability:** Service usable in controllers, triggers, batch jobs, APIs
- ✅ **Maintainability:** Validation logic centralized and organized
- ✅ **Extensibility:** New rules added without touching existing code
- ✅ **Performance:** Batch validation reduces SOQL queries
- ✅ **Clear errors:** ValidationResult provides structured error information

---

## Migration Path

### Step 1: Deploy Service (Week 1)
1. Deploy `ValidationResult`, `ValidationContext`, interfaces
2. Deploy `QuoteLineValidationService`
3. Deploy initial validation rules
4. Comprehensive unit tests (95% coverage)
5. No changes to controller yet

### Step 2: Parallel Run (Week 2)
1. Add validation service calls to controller (behind feature flag)
2. Compare results: old logic vs. new service
3. Log discrepancies for analysis
4. Fix any differences

### Step 3: Cutover (Week 3)
1. Enable feature flag for all users
2. Monitor for issues
3. Remove old validation methods (`vFStage`, `vSStage`, `vTStage`)
4. Update `assignQuoteLineErrorMEssage()` to call service

### Step 4: Optimization (Week 4)
1. Performance testing and tuning
2. Add additional validation rules as needed
3. Documentation and training
4. Retrospective and lessons learned

---

**Document Version:** 1.0
**Date:** 2025-12-09
**Author:** Quote Network Modernization Team
**Status:** Implementation Example
