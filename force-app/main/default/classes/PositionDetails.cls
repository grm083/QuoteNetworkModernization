/**
 * @description DTO for Position Management operations
 * Encapsulates position creation and management details
 * @author Quote Network Modernization Team
 * @date 2025-12-09
 * @story Quote Network Modernization - Phase 3
 */
public class PositionDetails {

    /**
     * @description Account ID for the position
     */
    public Id accountId { get; set; }

    /**
     * @description Container position name
     */
    public String containerPosition { get; set; }

    /**
     * @description Is this an offsite position
     */
    public Boolean isOffsite { get; set; }

    /**
     * @description Alternate street address for offsite
     */
    public String alternateStreet { get; set; }

    /**
     * @description Alternate city for offsite
     */
    public String alternateCity { get; set; }

    /**
     * @description Alternate state for offsite
     */
    public String alternateState { get; set; }

    /**
     * @description Alternate postal code for offsite
     */
    public String alternatePostalCode { get; set; }

    /**
     * @description Quote line ID to update with position
     */
    public Id quoteLineId { get; set; }

    /**
     * @description Setup comments for the position
     */
    public String setupComments { get; set; }

    /**
     * @description Default constructor
     */
    public PositionDetails() {
        this.isOffsite = false;
    }

    /**
     * @description Constructor with account and position
     * @param accountId Account ID
     * @param containerPosition Container position name
     */
    public PositionDetails(Id accountId, String containerPosition) {
        this.accountId = accountId;
        this.containerPosition = containerPosition;
        this.isOffsite = false;
    }

    /**
     * @description Validate position details
     * @return True if valid
     */
    public Boolean isValid() {
        if (accountId == null || String.isBlank(containerPosition)) {
            return false;
        }

        // If offsite, at least one address field should be populated
        if (isOffsite) {
            return !String.isBlank(alternateStreet)
                || !String.isBlank(alternateCity)
                || !String.isBlank(alternateState)
                || !String.isBlank(alternatePostalCode);
        }

        return true;
    }

    /**
     * @description Build offsite position display name
     * @return Formatted offsite position name
     */
    public String buildOffsiteDisplayName() {
        String displayName = Constant_Util.OFFSITE + Constant_Util.COLON + Constant_Util.BLANKSPACE + containerPosition;

        if (!String.isBlank(alternateStreet) || !String.isBlank(alternateCity)
            || !String.isBlank(alternateState) || !String.isBlank(alternatePostalCode)) {
            displayName += ' at ' +
                (String.isBlank(alternateStreet) ? '' : alternateStreet + Constant_Util.BLANKSPACE) +
                (String.isBlank(alternateCity) ? '' : alternateCity + Constant_Util.BLANKSPACE) +
                (String.isBlank(alternateState) ? '' : alternateState + Constant_Util.BLANKSPACE) +
                (String.isBlank(alternatePostalCode) ? '' : alternatePostalCode);
        }

        return displayName.trim();
    }
}
