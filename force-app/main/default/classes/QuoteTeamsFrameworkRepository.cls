/**
 * @description Repository for Quote_Teams_Framework__mdt metadata access
 * Consolidates 15+ duplicate lookups from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Repository Layer
 */
public with sharing class QuoteTeamsFrameworkRepository {

    // Cache for frequently accessed frameworks
    private static Map<String, Quote_Teams_Framework__mdt> frameworkCache;

    /**
     * @description Get team framework for quote assignment
     * Consolidates multiple flow lookups with different filter combinations
     * @param customerGroup Customer group (Core Customer, Project Services, etc.)
     * @param status Quote status (Draft, Product Configured, etc.)
     * @param quoteType Quote type (Quote, Amendment, Correction, Exception)
     * @param location Geographic location (Canada, etc.)
     * @return Quote_Teams_Framework__mdt or null if not found
     */
    public Quote_Teams_Framework__mdt getTeamForAssignment(
        String customerGroup,
        String status,
        String quoteType,
        String location
    ) {
        // Build cache key
        String cacheKey = buildCacheKey(customerGroup, status, quoteType, location);

        // Check cache first
        if (frameworkCache == null) {
            frameworkCache = new Map<String, Quote_Teams_Framework__mdt>();
        }

        if (frameworkCache.containsKey(cacheKey)) {
            return frameworkCache.get(cacheKey);
        }

        try {
            // Query with all filters
            List<Quote_Teams_Framework__mdt> results = [
                SELECT Id, MasterLabel, DeveloperName,
                       Customer_Group__c, Quote_Status__c, Quote_Type__c,
                       Location__c, Team_Name__c, Assignment_User__c,
                       Priority__c, Active__c
                FROM Quote_Teams_Framework__mdt
                WHERE Active__c = true
                AND Customer_Group__c = :customerGroup
                AND Quote_Status__c = :status
                AND Quote_Type__c = :quoteType
                AND (Location__c = :location OR Location__c = null)
                LIMIT 1
            ];

            Quote_Teams_Framework__mdt result = results.isEmpty() ? null : results[0];

            // Cache the result
            frameworkCache.put(cacheKey, result);

            return result;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteTeamsFrameworkRepository', 'getTeamForAssignment');
            return null;
        }
    }

    /**
     * @description Get VRM (Vendor Relationship Management) team framework
     * Used for quotes that require VRM team assignment
     * @param customerGroup Customer group
     * @param status Quote status
     * @return Quote_Teams_Framework__mdt or null
     */
    public Quote_Teams_Framework__mdt getVRMTeam(String customerGroup, String status) {
        try {
            List<Quote_Teams_Framework__mdt> results = [
                SELECT Id, MasterLabel, Team_Name__c, Assignment_User__c
                FROM Quote_Teams_Framework__mdt
                WHERE Active__c = true
                AND Customer_Group__c = :customerGroup
                AND Quote_Status__c = :status
                AND Team_Name__c LIKE '%VRM%'
                LIMIT 1
            ];

            return results.isEmpty() ? null : results[0];

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteTeamsFrameworkRepository', 'getVRMTeam');
            return null;
        }
    }

    /**
     * @description Get Canada team framework
     * Special routing for Canadian quotes
     * @param customerGroup Customer group
     * @param status Quote status
     * @return Quote_Teams_Framework__mdt or null
     */
    public Quote_Teams_Framework__mdt getCanadaTeam(String customerGroup, String status) {
        return getTeamForAssignment(customerGroup, status, null, 'Canada');
    }

    /**
     * @description Get team framework by status only
     * Simplified lookup for status-based routing
     * @param status Quote status
     * @return Quote_Teams_Framework__mdt or null
     */
    public Quote_Teams_Framework__mdt getTeamByStatus(String status) {
        try {
            List<Quote_Teams_Framework__mdt> results = [
                SELECT Id, MasterLabel, Team_Name__c, Assignment_User__c
                FROM Quote_Teams_Framework__mdt
                WHERE Active__c = true
                AND Quote_Status__c = :status
                LIMIT 1
            ];

            return results.isEmpty() ? null : results[0];

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteTeamsFrameworkRepository', 'getTeamByStatus');
            return null;
        }
    }

    /**
     * @description Get user for team assignment
     * Queries User based on framework configuration
     * @param framework Quote_Teams_Framework__mdt with Assignment_User__c populated
     * @return User or null if not found
     */
    public User getUserForTeam(Quote_Teams_Framework__mdt framework) {
        if (framework == null || String.isBlank(framework.Assignment_User__c)) {
            return null;
        }

        try {
            List<User> users = [
                SELECT Id, Name, UserName, Email, IsActive
                FROM User
                WHERE UserName = :framework.Assignment_User__c
                AND IsActive = true
                LIMIT 1
            ];

            return users.isEmpty() ? null : users[0];

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteTeamsFrameworkRepository', 'getUserForTeam');
            return null;
        }
    }

    /**
     * @description Get all active frameworks for a customer group
     * Used for complex assignment scenarios
     * @param customerGroup Customer group
     * @return List of Quote_Teams_Framework__mdt
     */
    public List<Quote_Teams_Framework__mdt> getFrameworksByCustomerGroup(String customerGroup) {
        if (String.isBlank(customerGroup)) {
            return new List<Quote_Teams_Framework__mdt>();
        }

        try {
            return [
                SELECT Id, MasterLabel, Customer_Group__c, Quote_Status__c,
                       Quote_Type__c, Location__c, Team_Name__c,
                       Assignment_User__c, Priority__c
                FROM Quote_Teams_Framework__mdt
                WHERE Active__c = true
                AND Customer_Group__c = :customerGroup
                ORDER BY Priority__c ASC
            ];

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteTeamsFrameworkRepository', 'getFrameworksByCustomerGroup');
            return new List<Quote_Teams_Framework__mdt>();
        }
    }

    /**
     * @description Build cache key for framework lookup
     * @param customerGroup Customer group
     * @param status Quote status
     * @param quoteType Quote type
     * @param location Location
     * @return String cache key
     */
    private String buildCacheKey(String customerGroup, String status, String quoteType, String location) {
        List<String> keyParts = new List<String>{
            String.valueOf(customerGroup),
            String.valueOf(status),
            String.valueOf(quoteType),
            String.valueOf(location)
        };
        return String.join(keyParts, '|');
    }

    /**
     * @description Clear framework cache
     * Useful for testing or when metadata changes
     */
    public static void clearCache() {
        if (frameworkCache != null) {
            frameworkCache.clear();
        }
    }
}
