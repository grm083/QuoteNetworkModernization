/**
 * @description Handler for commercial product-specific logic
 * Extracts commercial product handling from createDelivery() lines 3326-3332
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3C
 */
public class CommercialProductHandler {

    /**
     * @description Check if quote line is commercial product
     * @param quoteLine Quote line to check
     * @return True if commercial
     */
    public Boolean isCommercialProduct(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null) {
            return false;
        }

        // Check product family
        if (quoteLine.SBQQ__ProductFamily__c == Constant_Util.COMMERCIAL) {
            return true;
        }

        // Special check for compactor products (CMP) with equipment size < 10
        if (quoteLine.SBQQ__ProductCode__c == 'CMP'
            && quoteLine.Equipment_Size__c != null
            && quoteLine.Equipment_Size__c.contains('-')) {

            Double eqSize = Double.valueOf(quoteLine.Equipment_Size__c.substringAfter('-'));
            return (eqSize < 10);
        }

        return false;
    }

    /**
     * @description Handle commercial product delivery/removal creation
     * Replaces logic from createDelivery() lines 3323-3333 (SDT-30092)
     * @param parentQLId Parent quote line ID
     * @param ow Order wrapper
     * @param caseRecordType Case record type
     * @return Result message
     */
    public String handleCommercialProductDelivery(
        Id parentQLId,
        QuoteProcurementController.OrderWrapper ow,
        String caseRecordType
    ) {
        if (parentQLId == null || ow == null) {
            return 'Invalid input';
        }

        // Only process for non-new service cases
        if (caseRecordType == Constant_Util.New_Service_Case) {
            return 'N/A';
        }

        try {
            // Call existing method for commercial product handling
            QuoteProcurementController.CreateDeliveryRemovalForCommercialProducts(
                parentQLId,
                ow
            );
            return 'SUCCESS';
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error handling commercial product delivery: ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    /**
     * @description Validate commercial product for delivery/removal
     * @param parentQL Parent quote line
     * @param caseRecordType Case record type
     * @return True if should process commercial product logic
     */
    public Boolean shouldProcessCommercialProduct(
        SBQQ__QuoteLine__c parentQL,
        String caseRecordType
    ) {
        if (parentQL == null) {
            return false;
        }

        return isCommercialProduct(parentQL)
            && caseRecordType != Constant_Util.New_Service_Case;
    }

    /**
     * @description Determine product family from quote line
     * Replaces logic from createDelivery() lines 3216-3227
     * @param quoteLine Quote line
     * @return Product family string
     */
    public String determineProductFamily(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null || String.isBlank(quoteLine.SBQQ__ProductCode__c)) {
            return '';
        }

        String productFamily = quoteLine.SBQQ__ProductFamily__c;

        // Check compactor logic
        if (quoteLine.SBQQ__ProductCode__c == 'CMP'
            && quoteLine.Equipment_Size__c != null
            && quoteLine.Equipment_Size__c.contains('-')) {

            Double eqSize = Double.valueOf(quoteLine.Equipment_Size__c.substringAfter('-'));
            if (eqSize < 10) {
                return Constant_Util.COMMERCIAL;
            }
        }

        return productFamily != null ? productFamily : '';
    }
}
