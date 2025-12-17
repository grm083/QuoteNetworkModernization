/**
 * @description Validates Cost UOM and Cost Model Type requirements
 * Replaces logic from QuoteProcurementController.vSStage() lines 1020-1064
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class CostUOMRequiredRule implements IValidationRule {

    private static final String ERROR_COST_UOM_TYPE = 'Missing Cost Unit of Measure or Model Type';
    private static final String ERROR_COST_MODEL_STP = 'You must enter 2 stepped cost if Cost model type is Stepped.';
    private static final String ERROR_COST_MODEL_REBATE = 'Cost Model Type of Rebate must have a Cost of $0.00';
    private static final String ERROR_COST_MISSING = 'Cost Missing';
    private static final String ERROR_MANAGEMENT_FEE = 'Unit cost should be $0.00 and vendor name should start with WM Fee if product name is Management Fee';
    private static final String ERROR_WM_FEE_COST = 'WM Fee charges should have a cost of 0$';

    /**
     * @description Validate cost UOM and model type
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Cost UOM and Model Type are required
        if (String.isBlank(quoteLine.Cost_Unit_of_Measure__c) || String.isBlank(quoteLine.CostModelType__c)) {
            result.addError(ERROR_COST_UOM_TYPE);
            return result;
        }

        // Validate based on Cost Model Type
        if (quoteLine.CostModelType__c == 'STP') {
            return validateSteppedCost(quoteLine);
        } else if (quoteLine.CostModelType__c == 'REB') {
            return validateRebateCost(quoteLine);
        } else {
            return validateStandardCost(quoteLine, context);
        }
    }

    /**
     * @description Validate stepped cost model
     * @param quoteLine Quote line to validate
     * @return ValidationResult
     */
    private ValidationResult validateSteppedCost(SBQQ__QuoteLine__c quoteLine) {
        ValidationResult result = new ValidationResult();

        // Stepped pricing requires 2 cost prices
        if (quoteLine.CostPrice1__c == null || quoteLine.CostPrice2__c == null) {
            result.addError(ERROR_COST_MODEL_STP);
        }

        return result;
    }

    /**
     * @description Validate rebate cost model
     * @param quoteLine Quote line to validate
     * @return ValidationResult
     */
    private ValidationResult validateRebateCost(SBQQ__QuoteLine__c quoteLine) {
        ValidationResult result = new ValidationResult();

        // Rebate must have $0 cost
        if (quoteLine.SBQQ__UnitCost__c != 0) {
            result.addError(ERROR_COST_MODEL_REBATE);
        }

        return result;
    }

    /**
     * @description Validate standard cost model
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    private ValidationResult validateStandardCost(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Cost is required for standard model
        if (quoteLine.SBQQ__UnitCost__c == null) {
            result.addError(ERROR_COST_MISSING);
            return result;
        }

        // Special validation for Management Fee
        if (quoteLine.SBQQ__ProductName__c == 'Management Fee') {
            String vendorName = quoteLine.Vendor__r != null ? quoteLine.Vendor__r.Name : '';
            if (quoteLine.SBQQ__UnitCost__c != 0 || !vendorName.startsWithIgnoreCase('WM Fee')) {
                result.addError(ERROR_MANAGEMENT_FEE);
            }
        }
        // Validate WM Fee vendors
        else if (isWMFeeVendor(quoteLine, context)) {
            if (quoteLine.SBQQ__UnitCost__c != 0) {
                result.addError(ERROR_WM_FEE_COST);
            }
        }

        return result;
    }

    /**
     * @description Check if this is a WM Fee vendor
     * @param quoteLine Quote line to check
     * @param context Validation context
     * @return True if WM Fee vendor
     */
    private Boolean isWMFeeVendor(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        if (quoteLine.Vendor__r == null) {
            return false;
        }

        String vendorName = quoteLine.Vendor__r.Name;
        return (context.getQuoteType() == 'Amendment' || context.getQuoteType() == 'Quote')
            && !context.isSTP()
            && vendorName != null
            && vendorName.startsWithIgnoreCase('WM Fee');
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'CostUOMRequiredRule';
    }

    /**
     * @description Check if rule applies to context
     * Applies from Cost Configured stage onwards
     * @param context Validation context
     * @return True if applies
     */
    public Boolean appliesTo(ValidationContext context) {
        return context.getCurrentStage() == ValidationContext.Stage.COST_CONFIGURED
            || context.getCurrentStage() == ValidationContext.Stage.PRICE_CONFIGURED;
    }
}
