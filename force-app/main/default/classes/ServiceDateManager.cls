/**
 * @description Service for managing service date calculations and validations
 * Extracts date management logic from createDelivery()
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3B
 */
public class ServiceDateManager {

    /**
     * @description Calculate end date based on product and service dates
     * Replaces logic from createDelivery() lines 2891-2892, 3037, 3087, 3146
     * @param productName Product name
     * @param serviceDate Service date (for delivery/keys)
     * @param serviceEndDate Service end date (for ongoing services)
     * @param currentEndDate Current end date from asset
     * @return Calculated end date
     */
    public Date calculateEndDate(
        String productName,
        Date serviceDate,
        Date serviceEndDate,
        Date currentEndDate
    ) {
        // Delivery and Keys products use service date as end date
        if (productName == Constant_Util.ServiceType_Delivery || productName == Constant_Util.KEYS) {
            return serviceDate;
        }

        // Use provided service end date if available
        if (serviceEndDate != null) {
            return serviceEndDate;
        }

        // Otherwise keep current end date
        return currentEndDate;
    }

    /**
     * @description Validate start date for quote line
     * Replaces logic from createDelivery() lines 3020-3024
     * @param quoteLine Quote line to validate
     * @return True if valid
     */
    public Boolean validateStartDate(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine == null) {
            return false;
        }

        try {
            StartDateManagement startDateMgr = new StartDateManagement();
            return startDateMgr.validateQuoteLineStartDate(quoteLine);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error validating start date: ' + ex.getMessage());
            throw new AuraHandledException(StartDateManagement.InvalidStartDateErrorMessage);
        }
    }

    /**
     * @description Update quote line dates for End and Extend baseline
     * Replaces logic from createDelivery() lines 3015-3037
     * @param quoteLine Quote line to update
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     */
    public void updateDatesForEndAndExtend(
        SBQQ__QuoteLine__c quoteLine,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLine == null || serviceDate == null) {
            return;
        }

        // Update start date
        quoteLine.SBQQ__StartDate__c = serviceDate;

        // Calculate and set end date
        quoteLine.SBQQ__EndDate__c = calculateEndDate(
            quoteLine.SBQQ__ProductName__c,
            serviceDate,
            serviceEndDate,
            quoteLine.SBQQ__EndDate__c
        );

        // Validate start date (SDT-33378)
        Boolean isValid = validateStartDate(quoteLine);
        if (!isValid) {
            throw new AuraHandledException(StartDateManagement.InvalidStartDateErrorMessage);
        }
    }

    /**
     * @description Update quote line dates for new services (no asset)
     * Replaces logic from createDelivery() lines 3080-3087
     * @param quoteLine Quote line to update
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     */
    public void updateDatesForNewService(
        SBQQ__QuoteLine__c quoteLine,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLine == null || serviceDate == null) {
            return;
        }

        // Skip waste category and waste stream products
        if (quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_CATEGORY
            || quoteLine.SBQQ__ProductFamily__c == Constant_Util.WASTE_STREAM) {
            return;
        }

        // Update start date
        quoteLine.SBQQ__StartDate__c = serviceDate;

        // Calculate and set end date
        quoteLine.SBQQ__EndDate__c = calculateEndDate(
            quoteLine.SBQQ__ProductName__c,
            serviceDate,
            serviceEndDate,
            quoteLine.SBQQ__EndDate__c
        );
    }

    /**
     * @description Update dates for all quote lines (new service case)
     * Replaces logic from createDelivery() lines 3141-3148
     * @param quoteLines List of quote lines
     * @param serviceDate Service date
     * @param serviceEndDate Service end date
     */
    public void updateDatesForAllLines(
        List<SBQQ__QuoteLine__c> quoteLines,
        Date serviceDate,
        Date serviceEndDate
    ) {
        if (quoteLines == null || quoteLines.isEmpty() || serviceDate == null) {
            return;
        }

        for (SBQQ__QuoteLine__c ql : quoteLines) {
            ql.SBQQ__StartDate__c = serviceDate;
            ql.SBQQ__EndDate__c = calculateEndDate(
                ql.SBQQ__ProductName__c,
                serviceDate,
                serviceEndDate,
                ql.SBQQ__EndDate__c
            );
        }
    }

    /**
     * @description Update extra pickup line start dates based on regular pickup changes
     * Replaces logic from createDelivery() lines 3122-3129 (SDT-32782)
     * @param extraPickupLine Extra pickup quote line
     * @param pickupStartDate Regular pickup start date
     */
    public void updateExtraPickupStartDate(
        SBQQ__QuoteLine__c extraPickupLine,
        Date pickupStartDate
    ) {
        if (extraPickupLine == null || pickupStartDate == null) {
            return;
        }

        extraPickupLine.SBQQ__StartDate__c = pickupStartDate;
    }

    /**
     * @description Format date for display/comparison
     * @param serviceDate Date to format
     * @return Formatted date string
     */
    public String formatServiceDate(Date serviceDate) {
        if (serviceDate == null) {
            return Constant_Util.EMPTY_STRING;
        }
        return serviceDate.format();
    }

    /**
     * @description Calculate service date from OrderWrapper
     * @param ow OrderWrapper with service date info
     * @return Service date
     */
    public Date getServiceDate(QuoteProcurementController.OrderWrapper ow) {
        return ow != null ? ow.serviceDate : null;
    }

    /**
     * @description Calculate service end date from OrderWrapper
     * @param ow OrderWrapper with service end date info
     * @return Service end date
     */
    public Date getServiceEndDate(QuoteProcurementController.OrderWrapper ow) {
        return ow != null ? ow.serviceEndDate : null;
    }
}
