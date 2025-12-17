/**
 * @description Context object for validation operations
 * Provides context about the quote line being validated including stage, quote type, etc.
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization
 */
public class ValidationContext {

    /**
     * @description Validation stages corresponding to quote status
     */
    public enum Stage {
        DRAFT,
        PRODUCT_CONFIGURED,
        COST_CONFIGURED,
        PRICE_CONFIGURED
    }

    @TestVisible
    private Stage currentStage;
    @TestVisible
    private String quoteType;
    @TestVisible
    private Boolean isSTP;
    @TestVisible
    private String caseRecordType;
    @TestVisible
    private Boolean isNewService;
    @TestVisible
    private String quoteStatus;

    /**
     * @description Constructor that builds context from quote line
     * @param quoteLine Quote line to extract context from
     */
    public ValidationContext(SBQQ__QuoteLine__c quoteLine) {
        this.quoteStatus = quoteLine.SBQQ__Quote__r.SBQQ__Status__c;
        this.currentStage = determineStage(this.quoteStatus);
        this.quoteType = quoteLine.SBQQ__Quote__r.SBQQ__Type__c;
        this.isSTP = quoteLine.SBQQ__Quote__r.STP__c != null ? quoteLine.SBQQ__Quote__r.STP__c : false;
        this.caseRecordType = quoteLine.SBQQ__Quote__r.Case_record_Type__c;
        this.isNewService = (this.caseRecordType == Constant_Util.New_Service_Case);
    }

    /**
     * @description Default constructor for test scenarios
     */
    @TestVisible
    private ValidationContext() {
        this.currentStage = Stage.DRAFT;
        this.quoteType = 'Quote';
        this.isSTP = false;
        this.caseRecordType = '';
        this.isNewService = false;
        this.quoteStatus = 'Draft';
    }

    /**
     * @description Determine stage from quote status
     * @param quoteStatus Quote status value
     * @return Validation stage
     */
    private Stage determineStage(String quoteStatus) {
        if (String.isBlank(quoteStatus)) {
            return Stage.DRAFT;
        }

        if (quoteStatus == 'Draft') {
            return Stage.DRAFT;
        } else if (quoteStatus == 'Product Configured') {
            return Stage.PRODUCT_CONFIGURED;
        } else if (quoteStatus == 'Cost Configured') {
            return Stage.COST_CONFIGURED;
        } else if (quoteStatus == 'Price Configured') {
            return Stage.PRICE_CONFIGURED;
        }

        return Stage.DRAFT;
    }

    // Getters

    /**
     * @description Get current validation stage
     * @return Current stage
     */
    public Stage getCurrentStage() {
        return this.currentStage;
    }

    /**
     * @description Get quote type
     * @return Quote type (Quote, Amendment, Exception, etc.)
     */
    public String getQuoteType() {
        return this.quoteType;
    }

    /**
     * @description Check if quote is STP
     * @return True if STP quote
     */
    public Boolean isSTP() {
        return this.isSTP;
    }

    /**
     * @description Get case record type
     * @return Case record type name
     */
    public String getCaseRecordType() {
        return this.caseRecordType;
    }

    /**
     * @description Check if this is a new service case
     * @return True if new service
     */
    public Boolean isNewService() {
        return this.isNewService;
    }

    /**
     * @description Get quote status
     * @return Quote status
     */
    public String getQuoteStatus() {
        return this.quoteStatus;
    }

    // Builder methods for test scenarios

    /**
     * @description Set the stage (for testing)
     * @param stage Stage to set
     * @return This context for chaining
     */
    @TestVisible
    public ValidationContext withStage(Stage stage) {
        this.currentStage = stage;
        return this;
    }

    /**
     * @description Set the quote type (for testing)
     * @param quoteType Quote type to set
     * @return This context for chaining
     */
    @TestVisible
    public ValidationContext withQuoteType(String quoteType) {
        this.quoteType = quoteType;
        return this;
    }

    /**
     * @description Set STP flag (for testing)
     * @param isSTP STP flag
     * @return This context for chaining
     */
    @TestVisible
    public ValidationContext withSTP(Boolean isSTP) {
        this.isSTP = isSTP;
        return this;
    }

    /**
     * @description Set case record type (for testing)
     * @param caseRecordType Case record type
     * @return This context for chaining
     */
    @TestVisible
    public ValidationContext withCaseRecordType(String caseRecordType) {
        this.caseRecordType = caseRecordType;
        this.isNewService = (caseRecordType == Constant_Util.New_Service_Case);
        return this;
    }

    /**
     * @description Set new service flag (for testing)
     * @param isNewService New service flag
     * @return This context for chaining
     */
    @TestVisible
    public ValidationContext withNewService(Boolean isNewService) {
        this.isNewService = isNewService;
        return this;
    }

    /**
     * @description Create a test context with default values
     * @return New ValidationContext for testing
     */
    @TestVisible
    public static ValidationContext createTestContext() {
        return new ValidationContext();
    }
}
