/**
 * @description Validates removal and swapout sizes match asset size when parent size changed
 * Replaces logic from QuoteProcurementController.validateRemovalAndSwapoutSize() lines 1097-1123
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - SDT-32753
 */
public class RemovalSwapoutSizeRule implements IValidationRule {

    private static final String ERROR_REMOVAL_SWAPOUT_SIZE = 'Please ensure your Swapout and Removal have the correct sizes';

    /**
     * @description Validate removal/swapout sizes
     * @param quoteLine Quote line to validate
     * @param context Validation context
     * @return ValidationResult
     */
    public ValidationResult validate(SBQQ__QuoteLine__c quoteLine, ValidationContext context) {
        ValidationResult result = new ValidationResult();

        // Only validate in Product Configured stage for Commercial products
        if (context.getCurrentStage() != ValidationContext.Stage.PRODUCT_CONFIGURED) {
            return result;
        }

        // Only validate for non-new service cases
        if (context.isNewService()) {
            return result;
        }

        // Check if this is a Removal or Swapout product with Commercial parent
        if (!isRemovalOrSwapout(quoteLine)) {
            return result;
        }

        if (!hasCommercialParent(quoteLine)) {
            return result;
        }

        // Get equipment size values
        List<Schema.PicklistEntry> equipmentSizeEntries =
            Schema.SObjectType.SBQQ__QuoteLine__c.fields.Equipment_Size__c.getPicklistValues();

        // Convert asset size label to API value
        String assetSize = quoteLine.SBQQ__RequiredBy__r.AssetId__r.Equipment_Size__c;
        String convertedAssetSize = AssetQuoteProcurementController.getPicklistEntryByLabel(
            equipmentSizeEntries,
            assetSize
        );

        // Check if parent size has changed from asset
        String parentSize = quoteLine.SBQQ__RequiredBy__r.Equipment_Size__c;
        if (parentSize != convertedAssetSize) {
            // Removal/Swapout should have the asset size, not the new parent size
            if (quoteLine.Equipment_Size__c != convertedAssetSize) {
                result.addError(ERROR_REMOVAL_SWAPOUT_SIZE);
            }
        }

        return result;
    }

    /**
     * @description Check if this is a Removal or Swapout product
     * @param quoteLine Quote line to check
     * @return True if Removal or Swapout
     */
    private Boolean isRemovalOrSwapout(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.SBQQ__Product__r == null) {
            return false;
        }

        String productName = quoteLine.SBQQ__Product__r.Name;
        return (productName == Constant_Util.REMOVAL || productName == Constant_Util.SWAPOUT_PRODUCT);
    }

    /**
     * @description Check if parent is Commercial family
     * @param quoteLine Quote line to check
     * @return True if parent is Commercial
     */
    private Boolean hasCommercialParent(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__RequiredBy__c != null
            && quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductFamily__c == Constant_Util.COMMERCIAL;
    }

    /**
     * @description Get rule name for logging
     * @return Rule name
     */
    public String getRuleName() {
        return 'RemovalSwapoutSizeRule';
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
