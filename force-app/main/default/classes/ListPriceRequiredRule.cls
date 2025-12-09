/**
 * @description Validates List Price is provided for non-STP quotes
 * Replaces logic from QuoteProcurementController.vTStage() lines 1167-1175
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class ListPriceRequiredRule implements IValidationRule {

    private static final String ERROR_PRICE_MISSING = 'Price cannot be blank';
    private static final String ERROR_WM_FEE_PRICE = 'WM Fee charges requires a price greater than 0';

    /**
     * @description Validate list price is provided
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Check if WM Fee vendor
        if (isWMFeeVendor(quoteLine)) {
            if (quoteLine.SBQQ__ListPrice__c == null || quoteLine.SBQQ__ListPrice__c == 0) {
                result.addError(ERROR_WM_FEE_PRICE);
            }
            return result;
        }

        // Only validate for non-STP Amendment or Quote types
        if (!shouldValidatePrice(context, quoteLine)) {
            return result;
        }

        // List price is required
        if (quoteLine.SBQQ__ListPrice__c == null) {
            result.addError(ERROR_PRICE_MISSING);
        }

        return result;
    }

    /**
     * @description Determine if price should be validated
     * @param context Validation context
     * @param quoteLine Quote line being validated
     * @return True if should validate
     */
    private Boolean shouldValidatePrice(ValidationContext context, SBQQ__QuoteLine__c quoteLine) {
        return (context.getQuoteType() == 'Amendment' || context.getQuoteType() == 'Quote')
            && !context.isSTP()
            && quoteLine.PricingUnitMethod__c != 'STP';
    }

    /**
     * @description Check if this is a WM Fee vendor
     * @param quoteLine Quote line to check
     * @return True if WM Fee vendor
     */
    private Boolean isWMFeeVendor(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.Vendor__r == null) {
            return false;
        }

        String vendorName = quoteLine.Vendor__r.Name;
        return vendorName != null && vendorName.startsWithIgnoreCase('WM Fee');
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'ListPriceRequiredRule';
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
