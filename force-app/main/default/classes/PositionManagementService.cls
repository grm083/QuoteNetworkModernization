/**
 * @description Service for managing Account Position CRUD operations
 * Replaces position management logic from QuoteProcurementController
 * Handles onsite/offsite position creation, validation, and quote line assignment
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class PositionManagementService {

    /**
     * @description Get all positions for an account, ordered with Default first
     * Replaces: QuoteProcurementController.allPositions()
     * @param accountId Account ID
     * @return List of positions
     */
    public List<Account_Position__c> getAllPositions(Id accountId) {
        if (accountId == null) {
            return new List<Account_Position__c>();
        }

        List<Account_Position__c> positions = new List<Account_Position__c>();

        // Get default positions first
        List<Account_Position__c> defaultPositions = [
            SELECT Id, Name, Container_Position__c, AlternateStreet__c,
                   AlternateCity__c, AlternateState__c, AlternatePostalCode__c
            FROM Account_Position__c
            WHERE AccountId__c = :accountId
            AND Container_Position__c = 'Default'
        ];

        // Get other positions
        List<Account_Position__c> otherPositions = [
            SELECT Id, Name, Container_Position__c, AlternateStreet__c,
                   AlternateCity__c, AlternateState__c, AlternatePostalCode__c
            FROM Account_Position__c
            WHERE AccountId__c = :accountId
            AND Container_Position__c != 'Default'
            ORDER BY Container_Position__c ASC
        ];

        positions.addAll(defaultPositions);
        positions.addAll(otherPositions);

        return positions;
    }

    /**
     * @description Search positions by search string
     * Replaces: QuoteProcurementController.searchPositions()
     * @param accountId Account ID
     * @param searchString Search term
     * @return List of matching positions
     */
    public List<Account_Position__c> searchPositions(Id accountId, String searchString) {
        if (accountId == null) {
            return new List<Account_Position__c>();
        }

        List<Account_Position__c> positions = new List<Account_Position__c>();

        if (String.isBlank(searchString)) {
            return getAllPositions(accountId);
        }

        List<List<SObject>> searchList = [
            FIND :searchString
            IN ALL FIELDS
            RETURNING Account_Position__c(
                Id, Name, Container_Position__c, AlternateStreet__c,
                AlternateCity__c, AlternateState__c, AlternatePostalCode__c
                WHERE AccountId__c = :accountId
                ORDER BY Container_Position__c ASC
            )
        ];

        if (!searchList.isEmpty()) {
            positions = (List<Account_Position__c>)searchList[0];
        }

        return positions;
    }

    /**
     * @description Create onsite position
     * Replaces: QuoteProcurementController.storeOnsite()
     * @param details Position details
     * @return PositionOperationResult
     */
    public PositionOperationResult createOnsitePosition(PositionDetails details) {
        // Validate input
        if (details == null || !details.isValid()) {
            return PositionOperationResult.invalidInput('Position details are invalid');
        }

        // Validate position doesn't already exist
        if (!validatePositionUnique(details.accountId, details.containerPosition)) {
            return PositionOperationResult.duplicate();
        }

        try {
            Account_Position__c position = new Account_Position__c();
            position.AccountId__c = details.accountId;
            position.Container_Position__c = details.containerPosition;

            insert position;

            // Update quote line if specified
            if (details.quoteLineId != null) {
                updateQuoteLineWithPosition(details.quoteLineId, position.Id, details.containerPosition, false);
            }

            return PositionOperationResult.success(position);
        } catch (Exception ex) {
            return PositionOperationResult.error(ex.getMessage());
        }
    }

    /**
     * @description Create offsite position
     * Replaces: QuoteProcurementController.storeOffsite()
     * @param details Position details
     * @return PositionOperationResult
     */
    public PositionOperationResult createOffsitePosition(PositionDetails details) {
        // Validate input
        if (details == null || !details.isValid()) {
            return PositionOperationResult.invalidInput('Position details are invalid');
        }

        try {
            Account_Position__c position = new Account_Position__c();
            position.AccountId__c = details.accountId;
            position.AlternateStreet__c = !String.isBlank(details.alternateStreet)
                ? details.alternateStreet
                : Constant_Util.EMPTY_STRING;
            position.AlternateCity__c = !String.isBlank(details.alternateCity)
                ? details.alternateCity
                : Constant_Util.EMPTY_STRING;
            position.AlternateState__c = !String.isBlank(details.alternateState)
                ? details.alternateState
                : Constant_Util.EMPTY_STRING;
            position.AlternatePostalCode__c = !String.isBlank(details.alternatePostalCode)
                ? details.alternatePostalCode
                : Constant_Util.EMPTY_STRING;

            // Build offsite display name
            position.Container_Position__c = details.buildOffsiteDisplayName();

            // Validate position doesn't already exist
            if (!validatePositionUnique(details.accountId, position.Container_Position__c)) {
                return PositionOperationResult.duplicate();
            }

            insert position;

            // Update quote line if specified
            if (details.quoteLineId != null) {
                updateQuoteLineWithPosition(details.quoteLineId, position.Id, position.Container_Position__c, true);
            }

            return PositionOperationResult.success(position);
        } catch (Exception ex) {
            return PositionOperationResult.error(ex.getMessage());
        }
    }

    /**
     * @description Assign position to quote line
     * @param quoteLineId Quote line ID
     * @param positionId Position ID
     * @return True if successful
     */
    public Boolean assignPositionToQuoteLine(Id quoteLineId, Id positionId) {
        if (quoteLineId == null || positionId == null) {
            return false;
        }

        try {
            // Get position details
            Account_Position__c position = [
                SELECT Id, Container_Position__c
                FROM Account_Position__c
                WHERE Id = :positionId
                LIMIT 1
            ];

            Boolean isOffsite = position.Container_Position__c.startsWith('Offsite:');
            updateQuoteLineWithPosition(quoteLineId, positionId, position.Container_Position__c, isOffsite);

            return true;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error assigning position to quote line: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Validate position is unique for account
     * Replaces: QuoteProcurementController.validatePosition()
     * @param accountId Account ID
     * @param containerPosition Container position name
     * @return True if unique (valid)
     */
    public Boolean validatePositionUnique(Id accountId, String containerPosition) {
        if (accountId == null || String.isBlank(containerPosition)) {
            return false;
        }

        // Query all positions for account
        // Note: Cannot use Container_Position__c directly in WHERE clause if it's a TextArea
        List<Account_Position__c> positions = [
            SELECT Id, Container_Position__c
            FROM Account_Position__c
            WHERE AccountId__c = :accountId
        ];

        // Check for duplicates
        for (Account_Position__c position : positions) {
            if (position.Container_Position__c == containerPosition) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description Update quote line with position details
     * Replaces: QuoteProcurementController.updateALPOnQuoteLine()
     * @param parentQuoteLineId Parent quote line ID
     * @param positionId Position ID
     * @param setupComments Setup comments
     * @param isOffsite Is offsite position
     */
    public void updateQuoteLineWithPosition(Id parentQuoteLineId, Id positionId, String setupComments, Boolean isOffsite) {
        if (parentQuoteLineId == null) {
            return;
        }

        try {
            // Get all quote lines for this parent (includes children)
            List<SBQQ__QuoteLine__c> quoteLines = QuoteLineServices.getQuoteLinesForPosition(parentQuoteLineId);

            List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();

            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
                ql.Id = quoteLine.Id;
                ql.Location_Position_Name__c = positionId;
                ql.LocationPositionName__c = setupComments;

                // Set setup comments for offsite positions
                if (isOffsite) {
                    ql.SetupComment__c = setupComments;
                }

                quoteLinesToUpdate.add(ql);
            }

            if (!quoteLinesToUpdate.isEmpty()) {
                update quoteLinesToUpdate;
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating quote line with position: ' + ex.getMessage());
            throw ex;
        }
    }

    /**
     * @description Get positions for quote line display
     * @param quoteLineId Quote line ID
     * @return List of quote lines with position info
     */
    public List<SBQQ__QuoteLine__c> getPositionsForQuoteLine(Id quoteLineId) {
        if (quoteLineId == null) {
            return new List<SBQQ__QuoteLine__c>();
        }

        return [
            SELECT Id, LocationPositionName__c, Location_Position_Name__c,
                   Location_Position_Name__r.Name,
                   Location_Position_Name__r.Container_Position__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLineId
            ORDER BY CreatedDate DESC
        ];
    }
}
