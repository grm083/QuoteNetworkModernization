/**
 * @description Validates pricing method is specified for non-STP quotes
 * Replaces logic from QuoteProcurementController.vTStage() lines 1159-1165
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class PricingMethodRequiredRule implements IValidationRule {

    private static final String ERROR_PRICING_METHOD_MISSING = 'Price Model type (pricing method) must be specified';

    /**
     * @description Validate pricing method is specified
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for non-STP quotes
        if (context.isSTP()) {
            return result;
        }

        // Only validate for Amendment or Quote types
        if (context.getQuoteType() != 'Amendment' && context.getQuoteType() != 'Quote') {
            return result;
        }

        // Pricing method is required
        if (String.isBlank(quoteLine.SBQQ__PricingMethod__c)) {
            result.addError(ERROR_PRICING_METHOD_MISSING);
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'PricingMethodRequiredRule';
    }

    /**
     * @description Check if rule applies to context
     * Applies only at Price Configured stage
     * @param context Validation context
     * @return True if applies
     */
    public Boolean appliesTo(ValidationContext context) {
        return context.getCurrentStage() == ValidationContext.Stage.PRICE_CONFIGURED;
    }
}
