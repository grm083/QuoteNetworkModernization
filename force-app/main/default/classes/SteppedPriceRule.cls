/**
 * @description Validates stepped pricing requirements
 * Replaces logic from QuoteProcurementController.vTStage() lines 1184-1191
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class SteppedPriceRule implements IValidationRule {

    private static final String ERROR_STEPPED_PRICE = 'You must enter 2 stepped price if Price unit method is stepped.';

    /**
     * @description Validate stepped pricing
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for stepped pricing method
        if (quoteLine.SBQQ__PricingMethod__c != 'STP') {
            return result;
        }

        // Must have both price tiers
        if (quoteLine.PricePrice1__c == null || quoteLine.PricePrice2__c == null) {
            result.addError(ERROR_STEPPED_PRICE);
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'SteppedPriceRule';
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
