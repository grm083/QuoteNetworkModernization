/**
 * @description Request DTO for Product Configuration operations
 * Encapsulates product option and configuration attribute requests
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class ProductConfigRequest {

    /**
     * @description Quote line ID
     */
    public Id quoteLineId { get; set; }

    /**
     * @description Product ID
     */
    public Id productId { get; set; }

    /**
     * @description Product option ID (for add/remove operations)
     */
    public Id productOptionId { get; set; }

    /**
     * @description Configuration attribute field name
     */
    public String fieldName { get; set; }

    /**
     * @description Configuration attribute field value
     */
    public String fieldValue { get; set; }

    /**
     * @description Quote ID (for configuration updates)
     */
    public Id quoteId { get; set; }

    /**
     * @description Key option ID (for padlock key operations)
     */
    public Id keyOptionId { get; set; }

    /**
     * @description Quantity for keys
     */
    public Decimal keyQuantity { get; set; }

    /**
     * @description Default constructor
     */
    public ProductConfigRequest() {
    }

    /**
     * @description Constructor for product option operations
     * @param quoteLineId Quote line ID
     * @param productOptionId Product option ID
     */
    public ProductConfigRequest(Id quoteLineId, Id productOptionId) {
        this.quoteLineId = quoteLineId;
        this.productOptionId = productOptionId;
    }

    /**
     * @description Constructor for configuration attribute operations
     * @param quoteLineId Quote line ID
     * @param fieldName Field name
     * @param fieldValue Field value
     * @param quoteId Quote ID
     */
    public ProductConfigRequest(Id quoteLineId, String fieldName, String fieldValue, Id quoteId) {
        this.quoteLineId = quoteLineId;
        this.fieldName = fieldName;
        this.fieldValue = fieldValue;
        this.quoteId = quoteId;
    }

    /**
     * @description Validate request for adding product option
     * @return True if valid
     */
    public Boolean isValidForAddOption() {
        return quoteLineId != null && productOptionId != null;
    }

    /**
     * @description Validate request for removing product option
     * @return True if valid
     */
    public Boolean isValidForRemoveOption() {
        return quoteLineId != null && productOptionId != null;
    }

    /**
     * @description Validate request for updating configuration attribute
     * @return True if valid
     */
    public Boolean isValidForConfigUpdate() {
        return quoteLineId != null
            && !String.isBlank(fieldName)
            && quoteId != null;
    }
}
