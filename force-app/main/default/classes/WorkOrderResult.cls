/**
 * @description Result object for Work Order operations
 * Encapsulates the outcome of work order operations
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class WorkOrderResult {

    /**
     * @description Was the operation successful
     */
    public Boolean success { get; set; }

    /**
     * @description Error message if applicable
     */
    public String errorMessage { get; set; }

    /**
     * @description Created quote orders
     */
    public List<Quote_Order__c> quoteOrders { get; set; }

    /**
     * @description Updated quote lines
     */
    public List<SBQQ__QuoteLine__c> quoteLines { get; set; }

    /**
     * @description Was asset changed
     */
    public Boolean isAssetChanged { get; set; }

    /**
     * @description Warning messages
     */
    public List<String> warnings { get; set; }

    /**
     * @description Default constructor
     */
    public WorkOrderResult() {
        this.success = true;
        this.quoteOrders = new List<Quote_Order__c>();
        this.quoteLines = new List<SBQQ__QuoteLine__c>();
        this.isAssetChanged = false;
        this.warnings = new List<String>();
    }

    /**
     * @description Create success result
     * @return WorkOrderResult
     */
    public static WorkOrderResult createSuccess() {
        WorkOrderResult result = new WorkOrderResult();
        result.success = true;
        return result;
    }

    /**
     * @description Create error result
     * @param errorMessage Error message
     * @return WorkOrderResult
     */
    public static WorkOrderResult createError(String errorMessage) {
        WorkOrderResult result = new WorkOrderResult();
        result.success = false;
        result.errorMessage = errorMessage;
        return result;
    }

    /**
     * @description Add warning message
     * @param warning Warning message
     */
    public void addWarning(String warning) {
        if (!String.isBlank(warning)) {
            this.warnings.add(warning);
        }
    }

    /**
     * @description Check if there are warnings
     * @return True if warnings exist
     */
    public Boolean hasWarnings() {
        return !warnings.isEmpty();
    }

    /**
     * @description Get all warning messages as single string
     * @return Concatenated warnings
     */
    public String getWarningsText() {
        return String.join(warnings, '; ');
    }
}
