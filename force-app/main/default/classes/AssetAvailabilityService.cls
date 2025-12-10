/**
 * @description Service for Asset Availability (AAV) integration and validation
 * Extracts AAV-related logic from QuoteProcurementController and AAV_AvailabilityUtility
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 4
 */
public class AssetAvailabilityService {

    /**
     * @description Get availability bell icon message for quote line
     * Delegates to AAV_AvailabilityUtility.getAvailabilityBellIconMessage()
     * @param quoteLine Quote line with availability data
     * @param procurementErrorMessage Existing error message
     * @return Updated procurement error message with availability info
     * @story SDT-31246, SDT-31583
     */
    public String getAvailabilityBellIconMessage(
        SBQQ__QuoteLine__c quoteLine,
        String procurementErrorMessage
    ) {
        if (quoteLine == null) {
            return procurementErrorMessage;
        }

        try {
            // Delegate to existing utility class
            return AAV_AvailabilityUtility.getAvailabilityBellIconMessage(
                quoteLine,
                procurementErrorMessage
            );

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting availability message: ' + ex.getMessage());
            return procurementErrorMessage;
        }
    }

    /**
     * @description Update AAV override fields on quote line
     * @param quoteLineId Quote line ID
     * @param deliveryOverrideReason Delivery override reason
     * @param deliveryOverrideComment Delivery override comment
     * @param serviceOverrideReason Service override reason
     * @param serviceOverrideComment Service override comment
     * @return Success status
     * @story SDT-29100, SDT-30864
     */
    public Boolean updateAAVOverrideFields(
        Id quoteLineId,
        String deliveryOverrideReason,
        String deliveryOverrideComment,
        String serviceOverrideReason,
        String serviceOverrideComment
    ) {
        if (quoteLineId == null) {
            return false;
        }

        try {
            SBQQ__QuoteLine__c quoteLine = [SELECT Id,
                                                  AAV_Delivery_Override_Reason__c,
                                                  AAV_Delivery_Override_Comment__c,
                                                  AAV_Service_Override_Reason__c,
                                                  AAV_Service_Day_Override_Comment__c
                                            FROM SBQQ__QuoteLine__c
                                            WHERE Id = :quoteLineId
                                            LIMIT 1];

            quoteLine.AAV_Delivery_Override_Reason__c = deliveryOverrideReason;
            quoteLine.AAV_Delivery_Override_Comment__c = deliveryOverrideComment;
            quoteLine.AAV_Service_Override_Reason__c = serviceOverrideReason;
            quoteLine.AAV_Service_Day_Override_Comment__c = serviceOverrideComment;

            update quoteLine;
            return true;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating AAV override fields: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Get availability flag for quote line
     * @param quoteLineId Quote line ID
     * @return Availability flag value
     */
    public String getAvailabilityFlag(Id quoteLineId) {
        if (quoteLineId == null) {
            return null;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Availability_Flag__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :quoteLineId
                                                   LIMIT 1];

            return !quoteLines.isEmpty() ? quoteLines[0].Availability_Flag__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting availability flag: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Check if availability is WM confirmed
     * @param availabilityFlag Availability flag value
     * @return True if WM availability confirmed
     */
    public Boolean isWMAvailabilityConfirmed(String availabilityFlag) {
        return availabilityFlag != null
            && availabilityFlag.containsIgnoreCase('WM Availability Confirmed');
    }

    /**
     * @description Check if availability is non-WM
     * @param availabilityFlag Availability flag value
     * @return True if non-WM availability
     */
    public Boolean isNonWMAvailability(String availabilityFlag) {
        return availabilityFlag != null
            && availabilityFlag.containsIgnoreCase('NON WM Availability');
    }

    /**
     * @description Check if availability API errored out
     * @param availabilityFlag Availability flag value
     * @return True if API error occurred
     */
    public Boolean isAvailabilityAPIError(String availabilityFlag) {
        return availabilityFlag != null
            && availabilityFlag.containsIgnoreCase('Availability could not be confirmed as there is no response from the API');
    }

    /**
     * @description Get AAV API errors from quote line
     * @param quoteLineId Quote line ID
     * @return AAV API errors JSON or null
     */
    public String getAAVAPIErrors(Id quoteLineId) {
        if (quoteLineId == null) {
            return null;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, AAV_Asset_Availability_API_Errors__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :quoteLineId
                                                   LIMIT 1];

            return !quoteLines.isEmpty() ? quoteLines[0].AAV_Asset_Availability_API_Errors__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting AAV API errors: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Parse AAV API errors into structured map
     * @param errorJson AAV API errors JSON
     * @return Map of error categories to error messages
     */
    public Map<String, List<String>> parseAAVAPIErrors(String errorJson) {
        if (String.isBlank(errorJson)) {
            return new Map<String, List<String>>();
        }

        try {
            // Delegate to existing utility method
            return AAV_AvailabilityUtility.deserializeErrorString(errorJson);

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error parsing AAV API errors: ' + ex.getMessage());
            return new Map<String, List<String>>();
        }
    }

    /**
     * @description Get availability records for quote line
     * @param quoteLineId Quote line ID
     * @return List of availability records
     */
    public List<AAV_Asset_Availability__c> getAvailabilityRecords(Id quoteLineId) {
        if (quoteLineId == null) {
            return new List<AAV_Asset_Availability__c>();
        }

        try {
            return [SELECT Id, AAV_APIRequestOutput__c, AAV_Priority__c,
                          CreatedDate, LastModifiedDate
                    FROM AAV_Asset_Availability__c
                    WHERE SBQQ_QuoteLine__c = :quoteLineId
                    ORDER BY CreatedDate DESC];

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting availability records: ' + ex.getMessage());
            return new List<AAV_Asset_Availability__c>();
        }
    }

    /**
     * @description Check if user has permission to override availability
     * @return True if user has override permission
     */
    public Boolean hasAvailabilityOverridePermission() {
        // Check for custom permission or profile-based permission
        try {
            // This is a placeholder - implement actual permission check based on requirements
            return FeatureManagement.checkPermission('AAV_Override_Permission')
                || isUserInOverrideProfiles();

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error checking override permission: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Check if current user is in profiles allowed to override availability
     * @return True if user profile allows override
     */
    private Boolean isUserInOverrideProfiles() {
        // Get current user profile
        try {
            List<User> users = [SELECT Id, Profile.Name
                               FROM User
                               WHERE Id = :UserInfo.getUserId()
                               LIMIT 1];

            if (users.isEmpty()) {
                return false;
            }

            String profileName = users[0].Profile.Name;

            // Check against allowed profiles (customize as needed)
            Set<String> allowedProfiles = new Set<String>{
                'System Administrator',
                'Pricing Manager',
                'Procurement Manager'
            };

            return allowedProfiles.contains(profileName);

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error checking user profile: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Get AAV priority for quote line
     * @param quoteLineId Quote line ID
     * @return AAV priority value
     */
    public String getAAVPriority(Id quoteLineId) {
        if (quoteLineId == null) {
            return null;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, AAV_Priority__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :quoteLineId
                                                   LIMIT 1];

            return !quoteLines.isEmpty() ? quoteLines[0].AAV_Priority__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting AAV priority: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Update AAV priority on quote line
     * Delegates to AAV_AvailabilityUtility if needed
     * @param quoteLine Quote line to update
     * @param startDate Service start date
     * @return Updated quote line
     */
    public SBQQ__QuoteLine__c updateAAVPriority(SBQQ__QuoteLine__c quoteLine, Date startDate) {
        if (quoteLine == null || startDate == null) {
            return quoteLine;
        }

        try {
            // Calculate priority based on start date
            Integer daysUntilStart = Date.today().daysBetween(startDate);

            if (daysUntilStart < 0) {
                quoteLine.AAV_Priority__c = 'P1'; // Past due
            } else if (daysUntilStart <= 2) {
                quoteLine.AAV_Priority__c = 'P1'; // 0-2 days
            } else if (daysUntilStart <= 5) {
                quoteLine.AAV_Priority__c = 'P2'; // 3-5 days
            } else if (daysUntilStart <= 10) {
                quoteLine.AAV_Priority__c = 'P3'; // 6-10 days
            } else {
                quoteLine.AAV_Priority__c = 'P4'; // 11+ days
            }

            return quoteLine;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating AAV priority: ' + ex.getMessage());
            return quoteLine;
        }
    }

    /**
     * @description Validate AAV override reasons are provided when required
     * @param deliveryOverrideReason Delivery override reason
     * @param serviceOverrideReason Service override reason
     * @param availabilityFlag Availability flag
     * @return List of validation errors
     */
    public List<String> validateAAVOverrides(
        String deliveryOverrideReason,
        String serviceOverrideReason,
        String availabilityFlag
    ) {
        List<String> errors = new List<String>();

        // If availability is not WM confirmed, override reasons may be required
        if (!isWMAvailabilityConfirmed(availabilityFlag)) {
            if (String.isBlank(deliveryOverrideReason)) {
                errors.add('Delivery override reason is required when availability is not confirmed');
            }

            if (String.isBlank(serviceOverrideReason)) {
                errors.add('Service override reason is required when availability is not confirmed');
            }
        }

        return errors;
    }
}
