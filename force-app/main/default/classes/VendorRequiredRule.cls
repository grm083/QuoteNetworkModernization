/**
 * @description Validates vendor is assigned to quote line
 * Replaces logic from QuoteProcurementController.vSStage() lines 954-957
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class VendorRequiredRule implements IValidationRule {

    private static final String ERROR_VENDOR_MISSING = 'Vendor missing';

    /**
     * @description Validate vendor is assigned
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
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

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'VendorRequiredRule';
    }

    /**
     * @description Check if rule applies to context
     * Applies from Product Configured stage onwards
     * @param context Validation context
     * @return True if applies
     */
    public Boolean appliesTo(ValidationContext context) {
        return context.getCurrentStage() != ValidationContext.Stage.DRAFT;
    }
}
