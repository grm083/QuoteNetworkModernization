/**
 * @description Validates MAS Unique ID is provided for WM vendors on Amendment
 * Replaces logic from QuoteProcurementController.vTStage() lines 1147-1151
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class MASUniqueIdRequiredRule implements IValidationRule {

    private static final String ERROR_MAS_UNIQUE_ID_MISSING = 'MAS Unique ID is Missing';

    /**
     * @description Validate MAS Unique ID is provided
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for non-Quote types (Amendment, etc.) and WM vendors
        if (context.getQuoteType() == 'Quote') {
            return result;
        }

        if (!isWMVendor(quoteLine)) {
            return result;
        }

        // MAS Unique ID is required
        if (quoteLine.MASCustomerUniqueId__c == null) {
            result.addError(ERROR_MAS_UNIQUE_ID_MISSING);
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
        return 'MASUniqueIdRequiredRule';
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
