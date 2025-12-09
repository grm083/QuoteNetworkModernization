/**
 * @description Request DTO for Work Order operations
 * Encapsulates delivery, removal, and haul order creation requests
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class WorkOrderRequest {

    /**
     * @description Order type enum
     */
    public enum OrderType {
        DELIVERY,
        REMOVAL,
        HAUL_AWAY,
        EXTRA_PICKUP
    }

    /**
     * @description Parent quote line ID
     */
    public Id parentQuoteLineId { get; set; }

    /**
     * @description Quote ID
     */
    public Id quoteId { get; set; }

    /**
     * @description Service date
     */
    public Date serviceDate { get; set; }

    /**
     * @description Service end date (optional)
     */
    public Date serviceEndDate { get; set; }

    /**
     * @description Vendor service ID
     */
    public String vendorServiceId { get; set; }

    /**
     * @description Order type
     */
    public String orderType { get; set; }

    /**
     * @description Placement instructions
     */
    public String placementInstructions { get; set; }

    /**
     * @description Account ID
     */
    public Id accountId { get; set; }

    /**
     * @description Location ID
     */
    public Id locationId { get; set; }

    /**
     * @description Default constructor
     */
    public WorkOrderRequest() {
    }

    /**
     * @description Constructor with essential fields
     * @param quoteId Quote ID
     * @param parentQuoteLineId Parent quote line ID
     * @param serviceDate Service date
     * @param orderType Order type
     */
    public WorkOrderRequest(Id quoteId, Id parentQuoteLineId, Date serviceDate, String orderType) {
        this.quoteId = quoteId;
        this.parentQuoteLineId = parentQuoteLineId;
        this.serviceDate = serviceDate;
        this.orderType = orderType;
    }

    /**
     * @description Create from OrderWrapper
     * @param ow OrderWrapper
     * @param orderType Order type
     * @param placementInstructions Placement instructions
     * @return WorkOrderRequest
     */
    public static WorkOrderRequest fromOrderWrapper(
        QuoteProcurementController.OrderWrapper ow,
        String orderType,
        String placementInstructions
    ) {
        WorkOrderRequest request = new WorkOrderRequest();
        request.parentQuoteLineId = ow.parentQuoteLine;
        request.quoteId = ow.quoteId;
        request.serviceDate = ow.serviceDate;
        request.serviceEndDate = ow.serviceEndDate;
        request.vendorServiceId = ow.vendorServiceId;
        request.orderType = orderType;
        request.placementInstructions = placementInstructions;
        return request;
    }

    /**
     * @description Validate request
     * @return True if valid
     */
    public Boolean isValid() {
        return parentQuoteLineId != null
            && quoteId != null
            && serviceDate != null
            && !String.isBlank(orderType);
    }

    /**
     * @description Check if this is a delivery order
     * @return True if delivery
     */
    public Boolean isDeliveryOrder() {
        return orderType == Constant_Util.ServiceType_Delivery;
    }

    /**
     * @description Check if this is a removal order
     * @return True if removal
     */
    public Boolean isRemovalOrder() {
        return orderType == Constant_Util.ServiceType_Removal;
    }

    /**
     * @description Check if this is a haul away order
     * @return True if haul away
     */
    public Boolean isHaulAwayOrder() {
        return orderType == Constant_Util.Haul_Away_Service;
    }
}
