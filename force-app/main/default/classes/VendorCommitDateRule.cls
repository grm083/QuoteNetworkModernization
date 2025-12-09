/**
 * @description Validates vendor commit date against end date
 * Replaces logic from QuoteProcurementController.vSStage() lines 998-1005 and vTStage() lines 1139-1146
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class VendorCommitDateRule implements IValidationRule {

    private static final String ERROR_VENDOR_COMMIT_DATE = 'End Dates must be greater than the vendor commit date';

    /**
     * @description Validate vendor commit date is not after end date
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for Amendment or Quote types
        if (!shouldValidateCommitDate(context)) {
            return result;
        }

        Date vendorCommitDate = quoteLine.Vendor_Commit_Date__c;
        Date endDate = quoteLine.SBQQ__EndDate__c;

        // Validate vendor commit date is not after end date
        if (vendorCommitDate != null && endDate != null && vendorCommitDate > endDate) {
            result.addError(ERROR_VENDOR_COMMIT_DATE);
        }

        return result;
    }

    /**
     * @description Determine if commit date should be validated
     * @param context Validation context
     * @return True if should validate
     */
    private Boolean shouldValidateCommitDate(ValidationContext context) {
        return (context.getQuoteType() == 'Amendment' || context.getQuoteType() == 'Quote');
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'VendorCommitDateRule';
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
