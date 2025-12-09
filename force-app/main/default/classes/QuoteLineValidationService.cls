/**
 * @description Service for validating quote lines using strategy pattern
 * Replaces validation logic from QuoteProcurementController (vFStage, vSStage, vTStage, validateOccurence, etc.)
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class QuoteLineValidationService {

    private Map<ValidationContext.Stage, List<IValidationRule>> rulesByStage;

    /**
     * @description Constructor - initializes validation rules
     */
    public QuoteLineValidationService() {
        initializeValidationRules();
    }

    /**
     * @description Validate a quote line based on its current context
     * @param quoteLine Quote line to validate (must include Quote__r relationship)
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        if (quoteLine == null) {
            return ValidationResult.createError('Quote line cannot be null');
        }

        if (context == null) {
            return ValidationResult.createError('Validation context cannot be null');
        }

        List<ValidationResult> results = new List<ValidationResult>();

        // Get rules for current stage
        List<IValidationRule> rules = getRulesForStage(context.getCurrentStage());

        // Execute each applicable rule
        for (IValidationRule rule : rules) {
            try {
                if (rule.appliesTo(context)) {
                    ValidationResult ruleResult = rule.validate(quoteLine, context);
                    if (ruleResult != null) {
                        results.add(ruleResult);
                    }
                }
            } catch (Exception ex) {
                // Log exception and continue with other rules
                System.debug(LoggingLevel.ERROR, 'Exception in validation rule ' + rule.getRuleName() + ': ' + ex.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + ex.getStackTraceString());

                // Add error to results instead of failing entire validation
                results.add(ValidationResult.createError('Validation rule ' + rule.getRuleName() + ' failed: ' + ex.getMessage()));
            }
        }

        // Combine all validation results
        return ValidationResult.combine(results);
    }

    /**
     * @description Validate by specific stage (convenience method)
     * @param quoteLine Quote line to validate
     * @param stage Specific stage to validate against
     * @return ValidationResult
     */
    public ValidationResult validateByStage(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationContext context = new ValidationContext(quoteLine).withStage(stage);
        return validate(quoteLine, context);
    }

    /**
     * @description Batch validate multiple quote lines
     * @param quoteLines List of quote lines to validate
     * @return Map of quote line ID to validation result
     */
    public Map<Id, ValidationResult> validateBatch(List<SBQQ__QuoteLine__c> quoteLines) {
        Map<Id, ValidationResult> resultMap = new Map<Id, ValidationResult>();

        if (quoteLines == null || quoteLines.isEmpty()) {
            return resultMap;
        }

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            try {
                ValidationContext context = new ValidationContext(quoteLine);
                ValidationResult result = validate(quoteLine, context);
                resultMap.put(quoteLine.Id, result);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Exception validating quote line ' + quoteLine.Id + ': ' + ex.getMessage());
                resultMap.put(quoteLine.Id, ValidationResult.createError('Validation failed: ' + ex.getMessage()));
            }
        }

        return resultMap;
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
            new MASLibraryRequiredRule()
        });
        rulesByStage.put(ValidationContext.Stage.PRODUCT_CONFIGURED, productConfiguredRules);

        // Cost Configured stage: Product Configured + Cost rules
        List<IValidationRule> costConfiguredRules = new List<IValidationRule>();
        costConfiguredRules.addAll(productConfiguredRules);
        costConfiguredRules.addAll(new List<IValidationRule>{
            new OccurrenceTypeRule()
            // Additional cost-related rules can be added here
        });
        rulesByStage.put(ValidationContext.Stage.COST_CONFIGURED, costConfiguredRules);

        // Price Configured stage: Cost Configured + Price rules
        List<IValidationRule> priceConfiguredRules = new List<IValidationRule>();
        priceConfiguredRules.addAll(costConfiguredRules);
        // Additional price-related rules can be added here
        rulesByStage.put(ValidationContext.Stage.PRICE_CONFIGURED, priceConfiguredRules);
    }

    /**
     * @description Get validation rules for a specific stage
     * @param stage Validation stage
     * @return List of validation rules for the stage
     */
    private List<IValidationRule> getRulesForStage(ValidationContext.Stage stage) {
        List<IValidationRule> rules = rulesByStage.get(stage);
        return rules != null ? rules : new List<IValidationRule>();
    }

    /**
     * @description Check if a quote line is valid for a specific stage
     * Convenience method that returns boolean instead of full ValidationResult
     * @param quoteLine Quote line to validate
     * @param stage Validation stage
     * @return True if valid, false otherwise
     */
    public Boolean isValid(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationResult result = validateByStage(quoteLine, stage);
        return result.isValid();
    }

    /**
     * @description Get error message for a quote line at a specific stage
     * Convenience method for getting just the error message
     * @param quoteLine Quote line to validate
     * @param stage Validation stage
     * @return Error message or empty string if valid
     */
    public String getErrorMessage(SBQQ__QuoteLine__c quoteLine, ValidationContext.Stage stage) {
        ValidationResult result = validateByStage(quoteLine, stage);
        return result.hasErrors() ? result.getErrorMessage() : '';
    }
}
