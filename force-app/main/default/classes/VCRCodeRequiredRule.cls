/**
 * @description Validates VCR Code is provided for WM vendors on Quote type
 * Replaces logic from QuoteProcurementController.vSStage() lines 1008-1013 and vTStage() lines 1152-1157
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class VCRCodeRequiredRule implements IValidationRule {

    private static final String ERROR_VCR_CODE_MISSING = 'Vendor requires VCR Code field';

    /**
     * @description Validate VCR Code is provided
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for Quote type and WM vendors
        if (context.getQuoteType() != 'Quote') {
            return result;
        }

        if (!isWMVendor(quoteLine)) {
            return result;
        }

        // VCR Code is required
        if (String.isBlank(quoteLine.VCRCode__c)) {
            result.addError(ERROR_VCR_CODE_MISSING);
        }

        return result;
    }

    /**
     * @description Check if vendor is WM vendor
     * @param quoteLine Quote line to check
     * @return True if WM vendor
     */
    private Boolean isWMVendor(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.Vendor__r == null) {
            return false;
        }

        String vendorId = quoteLine.Vendor__r.Parent_Vendor_ID__c;
        return (vendorId == Constant_Util.WM_US_VENDOR || vendorId == Constant_Util.WM_CANADA_VENDOR);
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'VCRCodeRequiredRule';
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
