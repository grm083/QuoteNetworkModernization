/**
 * @description Validates Price UOM is specified
 * Replaces logic from QuoteProcurementController.vTStage() lines 1176-1182
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class PriceUOMRequiredRule implements IValidationRule {

    private static final String ERROR_PRICE_UOM_MISSING = 'Missing price unit of measure';

    /**
     * @description Validate price UOM is specified
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Price UOM is required
        if (String.isBlank(quoteLine.PriceUOM__c)) {
            result.addError(ERROR_PRICE_UOM_MISSING);
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'PriceUOMRequiredRule';
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
