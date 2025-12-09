/**
 * @description Validates MAS Library and Company Code for WM vendors
 * Replaces logic from QuoteProcurementController.vSStage() lines 973-995
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class MASLibraryRequiredRule implements IValidationRule {

    private static final String ERROR_MAS_LIBRARY_CODE = 'Missing MAS Library, Company Code';
    private static final String ERROR_SETUP_COMMENT = 'Missing Setup Comment';
    private static final String ERROR_SETUP_COMMENT_OR = ' or Setup Comment';

    /**
     * @description Validate MAS requirements for WM vendors
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate for WM vendors
        if (!isWMVendor(quoteLine)) {
            return result;
        }

        Boolean hasErrors = false;

        // Validate MAS Library and Company Code
        if (String.isBlank(quoteLine.MASLibrary__c) || String.isBlank(quoteLine.MASCompany__c)) {
            result.addError(ERROR_MAS_LIBRARY_CODE);
            hasErrors = true;
        }

        // Validate Setup Comment (unless TaskGrid tickets are bypassed)
        if (String.isBlank(quoteLine.SetupComment__c) && quoteLine.DoNotCreateTaskGridTickets__c == false) {
            String errorMsg = hasErrors ? ERROR_SETUP_COMMENT_OR : ERROR_SETUP_COMMENT;
            result.addError(errorMsg);
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
        return 'MASLibraryRequiredRule';
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
