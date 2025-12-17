/**
 * @description DTO for Asset Comparison operations
 * Encapsulates the result of comparing an asset with a quote line
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 3B
 */
public class AssetComparisonResult {

    /**
     * @description Does the quote line match the asset
     */
    public Boolean isMatched { get; set; }

    /**
     * @description Is this an End and Extend Baseline case
     */
    public Boolean isEndAndExtendBaseline { get; set; }

    /**
     * @description Is this an Update Baseline case
     */
    public Boolean isUpdateBaseline { get; set; }

    /**
     * @description List of fields that changed
     */
    public List<String> changedFields { get; set; }

    /**
     * @description Asset being compared
     */
    public Asset asset { get; set; }

    /**
     * @description Quote line being compared
     */
    public SBQQ__QuoteLine__c quoteLine { get; set; }

    /**
     * @description Default constructor
     */
    public AssetComparisonResult() {
        this.isMatched = true;
        this.isEndAndExtendBaseline = false;
        this.isUpdateBaseline = false;
        this.changedFields = new List<String>();
    }

    /**
     * @description Create matched result
     * @return AssetComparisonResult
     */
    public static AssetComparisonResult createMatched() {
        AssetComparisonResult result = new AssetComparisonResult();
        result.isMatched = true;
        return result;
    }

    /**
     * @description Create mismatched result for End and Extend
     * @param changedFields List of changed fields
     * @return AssetComparisonResult
     */
    public static AssetComparisonResult createEndAndExtend(List<String> changedFields) {
        AssetComparisonResult result = new AssetComparisonResult();
        result.isMatched = false;
        result.isEndAndExtendBaseline = true;
        result.isUpdateBaseline = false;
        result.changedFields = changedFields != null ? changedFields : new List<String>();
        return result;
    }

    /**
     * @description Create mismatched result for Update Baseline
     * @param changedFields List of changed fields
     * @return AssetComparisonResult
     */
    public static AssetComparisonResult createUpdateBaseline(List<String> changedFields) {
        AssetComparisonResult result = new AssetComparisonResult();
        result.isMatched = false;
        result.isEndAndExtendBaseline = false;
        result.isUpdateBaseline = true;
        result.changedFields = changedFields != null ? changedFields : new List<String>();
        return result;
    }

    /**
     * @description Check if asset/quoteline comparison requires updates
     * @return True if updates needed
     */
    public Boolean requiresUpdate() {
        return !isMatched;
    }

    /**
     * @description Get comparison type description
     * @return Description string
     */
    public String getComparisonType() {
        if (isMatched) {
            return 'Matched';
        } else if (isEndAndExtendBaseline) {
            return 'End and Extend Baseline';
        } else if (isUpdateBaseline) {
            return 'Update Baseline';
        }
        return 'Unknown';
    }
}
