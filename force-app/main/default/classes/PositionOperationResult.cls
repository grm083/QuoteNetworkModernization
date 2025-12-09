/**
 * @description Result object for Position Management operations
 * Encapsulates the outcome of position operations
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class PositionOperationResult {

    /**
     * @description Operation status
     */
    public enum Status {
        SUCCESS,
        DUPLICATE,
        INVALID_INPUT,
        ERROR
    }

    /**
     * @description Operation status
     */
    public Status status { get; set; }

    /**
     * @description Created or found position
     */
    public Account_Position__c position { get; set; }

    /**
     * @description Error message if applicable
     */
    public String errorMessage { get; set; }

    /**
     * @description Was the operation successful
     */
    public Boolean isSuccess {
        get {
            return status == Status.SUCCESS;
        }
    }

    /**
     * @description Constructor
     */
    public PositionOperationResult() {
        this.status = Status.SUCCESS;
    }

    /**
     * @description Create success result
     * @param position Created position
     * @return PositionOperationResult
     */
    public static PositionOperationResult success(Account_Position__c position) {
        PositionOperationResult result = new PositionOperationResult();
        result.status = Status.SUCCESS;
        result.position = position;
        return result;
    }

    /**
     * @description Create duplicate result
     * @return PositionOperationResult
     */
    public static PositionOperationResult duplicate() {
        PositionOperationResult result = new PositionOperationResult();
        result.status = Status.DUPLICATE;
        result.errorMessage = 'A position with this name already exists for this account';
        return result;
    }

    /**
     * @description Create invalid input result
     * @param message Error message
     * @return PositionOperationResult
     */
    public static PositionOperationResult invalidInput(String message) {
        PositionOperationResult result = new PositionOperationResult();
        result.status = Status.INVALID_INPUT;
        result.errorMessage = message;
        return result;
    }

    /**
     * @description Create error result
     * @param message Error message
     * @return PositionOperationResult
     */
    public static PositionOperationResult error(String message) {
        PositionOperationResult result = new PositionOperationResult();
        result.status = Status.ERROR;
        result.errorMessage = message;
        return result;
    }

    /**
     * @description Get status string for legacy compatibility
     * @return Status string ('Success' or 'Duplicate')
     */
    public String getStatusString() {
        if (status == Status.SUCCESS) {
            return 'Success';
        } else if (status == Status.DUPLICATE) {
            return 'Duplicate';
        } else {
            return 'Error';
        }
    }
}
