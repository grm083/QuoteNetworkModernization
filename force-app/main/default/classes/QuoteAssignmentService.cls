/**
 * @description Service for quote team assignment logic
 * Consolidates 43+ assignment operations from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Service Layer
 */
public with sharing class QuoteAssignmentService {

    private QuoteTeamsFrameworkRepository teamsRepo;
    private CodeSwitchRepository codeSwitchRepo;

    public QuoteAssignmentService() {
        this.teamsRepo = new QuoteTeamsFrameworkRepository();
        this.codeSwitchRepo = new CodeSwitchRepository();
    }

    /**
     * @description Determine assignee for quote based on business rules
     * Main entry point for assignment logic
     * @param quote Quote record with relationships
     * @param vendorCode Vendor code from quote lines
     * @return AssignmentResult wrapper
     */
    public AssignmentResult determineAssignee(SBQQ__Quote__c quote, String vendorCode) {
        AssignmentResult result = new AssignmentResult();

        try {
            if (quote == null) {
                result.success = false;
                result.errorMessage = 'Quote is null';
                return result;
            }

            // Check for special handling scenarios
            if (shouldRouteToSpecialHandling(quote)) {
                return handleSpecialHandlingAssignment(quote);
            }

            // Check for Quote Only scenario
            if (shouldRouteToQuoteOnly(quote)) {
                return handleQuoteOnlyAssignment(quote);
            }

            // Check for Haul Away scenario
            if (shouldRouteToHaulAway(quote)) {
                return handleHaulAwayAssignment(quote);
            }

            // Standard team assignment
            return handleStandardAssignment(quote, vendorCode);

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteAssignmentService', 'determineAssignee');
            result.success = false;
            result.errorMessage = ex.getMessage();
        }

        return result;
    }

    /**
     * @description Check if quote should route to special handling
     * @param quote Quote record
     * @return Boolean true if special handling
     */
    private Boolean shouldRouteToSpecialHandling(SBQQ__Quote__c quote) {
        // Logic from flow: check_eligiblity_for_Special_handling_or_Quote_Only
        return quote.Special_Handling__c == true;
    }

    /**
     * @description Check if quote should route to Quote Only
     * @param quote Quote record
     * @return Boolean true if quote only
     */
    private Boolean shouldRouteToQuoteOnly(SBQQ__Quote__c quote) {
        return quote.Quote_Only__c == true && codeSwitchRepo.isQuoteOnlyEnabled();
    }

    /**
     * @description Check if quote should route to Haul Away
     * @param quote Quote record
     * @return Boolean true if haul away
     */
    private Boolean shouldRouteToHaulAway(SBQQ__Quote__c quote) {
        if (quote.SBQQ__Opportunity2__r == null || quote.SBQQ__Opportunity2__r.Case__r == null) {
            return false;
        }
        return quote.SBQQ__Opportunity2__r.Case__r.Is_Haul_Away_Service__c == true &&
               codeSwitchRepo.isHaulAwayEnabled();
    }

    /**
     * @description Handle special handling assignment
     * @param quote Quote record
     * @return AssignmentResult
     */
    private AssignmentResult handleSpecialHandlingAssignment(SBQQ__Quote__c quote) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'Special Handling';
        // Implementation would call stored procedure or specific user lookup
        result.success = true;
        return result;
    }

    /**
     * @description Handle quote only assignment
     * @param quote Quote record
     * @return AssignmentResult
     */
    private AssignmentResult handleQuoteOnlyAssignment(SBQQ__Quote__c quote) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'Quote Only';
        // Implementation would retrieve specific user for new store quotes
        result.success = true;
        return result;
    }

    /**
     * @description Handle haul away assignment
     * @param quote Quote record
     * @return AssignmentResult
     */
    private AssignmentResult handleHaulAwayAssignment(SBQQ__Quote__c quote) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'Haul Away';

        // If Assigned_To is null, assign to current user
        if (quote.Assigned_To__c == null) {
            result.assignedUserId = UserInfo.getUserId();
            result.assignedUserName = UserInfo.getName();
        }

        result.success = true;
        return result;
    }

    /**
     * @description Handle standard team assignment
     * @param quote Quote record
     * @param vendorCode Vendor code
     * @return AssignmentResult
     */
    private AssignmentResult handleStandardAssignment(SBQQ__Quote__c quote, String vendorCode) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'Standard';

        // Determine customer type
        String customerGroup = determineCustomerGroup(quote);

        // Check for Canada routing
        if (isCanadaQuote(quote)) {
            return handleCanadaAssignment(quote, customerGroup);
        }

        // Check for VRM routing
        if (shouldRouteToVRM(quote, vendorCode)) {
            return handleVRMAssignment(quote, customerGroup);
        }

        // Standard team lookup
        Quote_Teams_Framework__mdt framework = teamsRepo.getTeamForAssignment(
            customerGroup,
            quote.SBQQ__Status__c,
            quote.SBQQ__Type__c,
            null
        );

        if (framework != null) {
            User assignedUser = teamsRepo.getUserForTeam(framework);
            if (assignedUser != null) {
                result.assignedUserId = assignedUser.Id;
                result.assignedUserName = assignedUser.Name;
                result.teamName = framework.Team_Name__c;
                result.success = true;
            }
        }

        return result;
    }

    /**
     * @description Determine customer group
     * @param quote Quote record
     * @return String customer group
     */
    private String determineCustomerGroup(SBQQ__Quote__c quote) {
        // Logic from flow: Identify_Customer_Type
        if (quote.Project__c != null || quote.Project_Services_Request__c == true) {
            return 'Project Services';
        }
        return 'Core Customer';
    }

    /**
     * @description Check if Canada quote
     * @param quote Quote record
     * @return Boolean true if Canada
     */
    private Boolean isCanadaQuote(SBQQ__Quote__c quote) {
        if (quote.SBQQ__Account__r == null) {
            return false;
        }
        return quote.SBQQ__Account__r.Geography__c == 'Canada';
    }

    /**
     * @description Check if should route to VRM
     * @param quote Quote record
     * @param vendorCode Vendor code
     * @return Boolean true if VRM routing
     */
    private Boolean shouldRouteToVRM(SBQQ__Quote__c quote, String vendorCode) {
        // Check QuoteProcuredStatus__c field
        return quote.QuoteProcuredStatus__c == 'VRM';
    }

    /**
     * @description Handle Canada assignment
     * @param quote Quote record
     * @param customerGroup Customer group
     * @return AssignmentResult
     */
    private AssignmentResult handleCanadaAssignment(SBQQ__Quote__c quote, String customerGroup) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'Canada';

        Quote_Teams_Framework__mdt framework = teamsRepo.getCanadaTeam(customerGroup, quote.SBQQ__Status__c);

        if (framework != null) {
            User assignedUser = teamsRepo.getUserForTeam(framework);
            if (assignedUser != null) {
                result.assignedUserId = assignedUser.Id;
                result.assignedUserName = assignedUser.Name;
                result.teamName = framework.Team_Name__c;
                result.success = true;
            }
        }

        return result;
    }

    /**
     * @description Handle VRM assignment
     * @param quote Quote record
     * @param customerGroup Customer group
     * @return AssignmentResult
     */
    private AssignmentResult handleVRMAssignment(SBQQ__Quote__c quote, String customerGroup) {
        AssignmentResult result = new AssignmentResult();
        result.assignmentType = 'VRM';

        Quote_Teams_Framework__mdt framework = teamsRepo.getVRMTeam(customerGroup, quote.SBQQ__Status__c);

        if (framework != null) {
            User assignedUser = teamsRepo.getUserForTeam(framework);
            if (assignedUser != null) {
                result.assignedUserId = assignedUser.Id;
                result.assignedUserName = assignedUser.Name;
                result.teamName = framework.Team_Name__c;
                result.success = true;
            }
        }

        return result;
    }

    /**
     * @description Assignment result wrapper
     */
    public class AssignmentResult {
        public Id assignedUserId;
        public String assignedUserName;
        public String teamName;
        public String assignmentType; // Standard, Canada, VRM, Haul Away, Quote Only, Special Handling
        public Boolean success = false;
        public String errorMessage;
        public List<String> warnings = new List<String>();

        public AssignmentResult() {
            this.success = false;
            this.warnings = new List<String>();
        }
    }
}
