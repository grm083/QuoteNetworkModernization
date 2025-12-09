/**
 * @description Validates Management Fee pricing requirements
 * Replaces logic from QuoteProcurementController.vTStage() lines 1179-1182
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class ManagementFeePriceRule implements IValidationRule {

    private static final String ERROR_MANAGEMENT_FEE_PRICE = 'Price of Management Fee product option must be greater than $0.00';

    /**
     * @description Validate Management Fee pricing
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for Management Fee products
        if (quoteLine.SBQQ__ProductName__c != 'Management Fee') {
            return result;
        }

        // Price must be greater than $0
        if (quoteLine.SBQQ__ListPrice__c == null || quoteLine.SBQQ__ListPrice__c <= 0) {
            result.addError(ERROR_MANAGEMENT_FEE_PRICE);
        }

        return result;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'ManagementFeePriceRule';
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
