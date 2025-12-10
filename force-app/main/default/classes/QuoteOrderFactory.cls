/**
 * @description Factory service for creating Quote Order records
 * Extracts quote order creation logic from createDelivery()
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3B
 */
public class QuoteOrderFactory {

    /**
     * @description Create delivery quote order
     * Replaces logic from createDelivery() lines 3247-3306
     * @param ow OrderWrapper with order details
     * @param quoteLine Service quote line
     * @param positionName Position name
     * @param placementInstructions Placement instructions
     * @param vendorServiceId Vendor service ID (SDT-41473)
     * @param existingOrderId Existing order ID for updates
     * @return Quote_Order__c
     */
    public Quote_Order__c createDeliveryOrder(
        QuoteProcurementController.OrderWrapper ow,
        SBQQ__QuoteLine__c quoteLine,
        String positionName,
        String placementInstructions,
        String vendorServiceId,
        Id existingOrderId
    ) {
        Quote_Order__c order = new Quote_Order__c();

        // Set instructions with position if available
        if (quoteLine.Location_Position_Name__c != null) {
            String positionText = quoteLine.Location_Position_Name__r.Container_Position__c;
            order.Instructions__c = 'POSITION:' + positionText + '\n' + ow.instructions;
            order.Acorn_Instructions__c = 'POSITION:' + positionText + '\n' + ow.acornInstructions;
        } else {
            order.Instructions__c = ow.instructions;
            order.Acorn_Instructions__c = ow.acornInstructions;
        }

        // Set quote line references
        order.Quote_Line__c = ow.parentQuoteLine;
        order.Service_Quote_Line__c = quoteLine.Id;

        // Set service type (handle surcharges/fees and haul away - SDT-41624)
        if (quoteLine.SBQQ__ProductFamily__c == PricingJSONRequest.SURCHARGES_AND_FEES) {
            // Check if this is haul away service
            Boolean isHaulAway = HaulAwayService.getIsHaulAwayService(
                quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c
            );
            order.Service_Type__c = isHaulAway
                ? Constant_Util.Haul_Away_Service
                : Constant_Util.LOCK_DELIVERY;
        } else {
            order.Service_Type__c = ow.serviceType;
        }

        // Set order details
        order.Quantity__c = ow.quantity;
        order.Onsite_Contact__c = ow.onsiteContact;
        order.Onsite_Contact_Phone__c = ow.onsitePhone;
        order.Product_Type__c = quoteLine.SBQQ__ProductName__c;

        if (String.isNotEmpty(ow.PONumber)) {
            order.Cust_Ref_Number__c = ow.PONumber;
        }

        order.Duration__c = ow.Duration;
        order.Occurrence_Type__c = quoteLine.Occurrence_Type__c;
        order.Service_Time_Span__c = 'ASAP';
        order.Placement_Instructions__c = placementInstructions;
        order.Vendor_Service_Id__c = vendorServiceId; // SDT-41473, 41625, 41966
        order.Service_Date__c = ow.serviceDate;

        // Set ID for update if exists
        if (existingOrderId != null) {
            order.Id = existingOrderId;
        }

        return order;
    }

    /**
     * @description Create removal quote order
     * Replaces logic from createDelivery() lines 3350-3394 (createQuoteOrder method)
     * @param ow OrderWrapper with order details
     * @param quoteLine Quote line for removal
     * @param positionName Position name
     * @param placementInstructions Placement instructions
     * @param existingOrderId Existing order ID for updates
     * @return Quote_Order__c
     */
    public Quote_Order__c createRemovalOrder(
        QuoteProcurementController.OrderWrapper ow,
        SBQQ__QuoteLine__c quoteLine,
        String positionName,
        String placementInstructions,
        Id existingOrderId
    ) {
        Quote_Order__c order = new Quote_Order__c();

        // Set instructions with position if available
        if (positionName != null && positionName != '') {
            order.Instructions__c = 'POSITION:' + positionName + '\n' + ow.instructions;
            order.Acorn_Instructions__c = 'POSITION:' + positionName + '\n' + ow.acornInstructions;
        } else {
            order.Instructions__c = ow.instructions;
            order.Acorn_Instructions__c = ow.acornInstructions;
        }

        // Set quote line references
        order.Quote_Line__c = ow.parentQuoteLine;
        order.Service_Quote_Line__c = quoteLine.Id;

        // Use end date for removal service date
        if (quoteLine.SBQQ__EndDate__c != null) {
            order.Service_Date__c = quoteLine.SBQQ__EndDate__c;
        }

        order.Service_Type__c = 'Removal';
        order.Quantity__c = ow.quantity;
        order.Onsite_Contact__c = ow.onsiteContact;
        order.Onsite_Contact_Phone__c = ow.onsitePhone;
        order.Product_Type__c = quoteLine.SBQQ__ProductName__c;
        order.Cust_Ref_Number__c = ow.PONumber;
        order.Duration__c = ow.Duration;
        order.Occurrence_Type__c = quoteLine.Occurrence_Type__c;
        order.Service_Time_Span__c = 'ASAP';
        order.Placement_Instructions__c = placementInstructions;
        order.Vendor_Service_Id__c = ow.vendorServiceId; // SDT-41473, 41625, 41966

        // Set ID for update if exists
        if (existingOrderId != null) {
            order.Id = existingOrderId;
        }

        return order;
    }

    /**
     * @description Create multiple delivery orders for quote lines
     * @param ow OrderWrapper with order details
     * @param deliveryQuoteLines List of delivery quote lines
     * @param positionName Position name
     * @param placementInstructions Placement instructions
     * @param vendorServiceId Vendor service ID
     * @param serviceTypeOrderIdMap Map of service type to existing order IDs
     * @return List of Quote_Order__c records
     */
    public List<Quote_Order__c> createDeliveryOrders(
        QuoteProcurementController.OrderWrapper ow,
        List<SBQQ__QuoteLine__c> deliveryQuoteLines,
        String positionName,
        String placementInstructions,
        String vendorServiceId,
        Map<String, Id> serviceTypeOrderIdMap
    ) {
        List<Quote_Order__c> orders = new List<Quote_Order__c>();

        if (deliveryQuoteLines == null || deliveryQuoteLines.isEmpty()) {
            return orders;
        }

        // Check if any orders already exist
        Boolean isOrderAvailable = serviceTypeOrderIdMap != null
            && serviceTypeOrderIdMap.containsKey(ow.serviceType);
        Boolean isKeyOrderAvailable = serviceTypeOrderIdMap != null
            && (serviceTypeOrderIdMap.containsKey(Constant_Util.LOCK_DELIVERY)
                || serviceTypeOrderIdMap.containsKey(Constant_Util.Haul_Away_Service));

        for (SBQQ__QuoteLine__c ql : deliveryQuoteLines) {
            // Get existing order ID if available
            Id existingOrderId = null;
            if (isOrderAvailable) {
                existingOrderId = serviceTypeOrderIdMap.get(ow.serviceType);
            }
            if (isKeyOrderAvailable && ql.SBQQ__ProductFamily__c == PricingJSONRequest.SURCHARGES_AND_FEES) {
                Boolean isHaulAway = HaulAwayService.getIsHaulAwayService(
                    ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c
                );
                existingOrderId = isHaulAway
                    ? serviceTypeOrderIdMap.get(Constant_Util.Haul_Away_Service)
                    : serviceTypeOrderIdMap.get(Constant_Util.LOCK_DELIVERY);
            }

            Quote_Order__c order = createDeliveryOrder(
                ow,
                ql,
                positionName,
                placementInstructions,
                vendorServiceId,
                existingOrderId
            );

            orders.add(order);
        }

        return orders;
    }

    /**
     * @description Upsert quote orders
     * @param orders List of orders to upsert
     * @return SUCCESS or error message
     */
    public String upsertOrders(List<Quote_Order__c> orders) {
        if (orders == null || orders.isEmpty()) {
            return 'SUCCESS';
        }

        try {
            upsert orders;
            return 'SUCCESS';
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error upserting quote orders: ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    /**
     * @description Build service type to order ID map from existing orders
     * Replaces logic from createDelivery() lines 3156-3183
     * @param existingOrders List of existing quote orders
     * @return Map of service type to order ID
     */
    public Map<String, Id> buildServiceTypeOrderIdMap(List<Quote_Order__c> existingOrders) {
        Map<String, Id> serviceTypeOrderIdMap = new Map<String, Id>();

        if (existingOrders == null || existingOrders.isEmpty()) {
            return serviceTypeOrderIdMap;
        }

        for (Quote_Order__c order : existingOrders) {
            serviceTypeOrderIdMap.put(order.Service_Type__c, order.Id);
        }

        return serviceTypeOrderIdMap;
    }

    /**
     * @description Check if specific service type order exists
     * @param existingOrders List of existing orders
     * @param serviceType Service type to check
     * @return True if exists
     */
    public Boolean hasServiceTypeOrder(List<Quote_Order__c> existingOrders, String serviceType) {
        if (existingOrders == null || existingOrders.isEmpty() || String.isBlank(serviceType)) {
            return false;
        }

        for (Quote_Order__c order : existingOrders) {
            if (order.Service_Type__c == serviceType
                || order.Service_Type__c.equalsIgnoreCase(Constant_Util.Haul_Away_Service)) {
                return true;
            }
        }

        return false;
    }
}
