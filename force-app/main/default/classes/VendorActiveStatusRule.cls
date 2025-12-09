/**
 * @description Validates vendor active status
 * Replaces logic from QuoteProcurementController.vFStage() lines 936-946
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class VendorActiveStatusRule implements IValidationRule {

    private static final String ERROR_VENDOR_INACTIVE = 'Selected vendor is not active';

    /**
     * @description Validate vendor is active
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Check if validation applies to this quote type
        if (!shouldValidateVendorStatus(context, quoteLine)) {
            return result;
        }

        // Validate vendor is active
        if (quoteLine.Vendor__c != null
            && quoteLine.Vendor__r != null
            && quoteLine.Vendor__r.Status__c == 'Inactive') {
            result.addError(ERROR_VENDOR_INACTIVE);
        }

        return result;
    }

    /**
     * @description Determine if vendor status should be validated
     * @param context Validation context
     * @param quoteLine Quote line being validated
     * @return True if should validate
     */
    private Boolean shouldValidateVendorStatus(ValidationContext context, SBQQ__QuoteLine__c quoteLine) {
        // Validate for Amendment, Exception, Correction, or Quote (non-STP), or STP quotes
        return (context.getQuoteType() == 'Amendment'
            || context.getQuoteType() == 'Exception'
            || context.getQuoteType() == 'Correction'
            || (context.getQuoteType() == 'Quote' && !context.isSTP())
            || (context.getQuoteType() == 'Quote' && context.isSTP()));
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'VendorActiveStatusRule';
    }

    /**
     * @description Check if rule applies to context
     * @param context Validation context
     * @return True (applies to all stages)
     */
    public Boolean appliesTo(ValidationContext context) {
        return true; // Applies to all stages
    }
}
