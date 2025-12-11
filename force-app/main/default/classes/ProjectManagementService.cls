/**
 * @description Service for managing project codes and business rules
 * Extracts project management logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
public class ProjectManagementService {

    /**
     * @description Get active projects for quote
     * Replaces QuoteProcurementController.getActiveProjects() lines 2150-2166
     * @param quoteId Quote ID
     * @param searchString Search term
     * @return List of active project codes
     */
    public List<Project_Code__c> getActiveProjects(Id quoteId, String searchString) {
        if (quoteId == null || String.isBlank(searchString)) {
            return new List<Project_Code__c>();
        }

        try {
            // Get quote details
            List<SBQQ__Quote__c> currentQuote = [
                SELECT Id, Project__c, Project__r.Name, SBQQ__Account__c, SBQQ__Account__r.ParentId
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (currentQuote.isEmpty()) {
                return new List<Project_Code__c>();
            }

            // SOSL search for projects
            List<List<SObject>> projectSOSL = [
                FIND :searchString
                IN NAME FIELDS
                RETURNING Project_Code__c(
                    Id, Name, Project_Manager__r.Name, Program_Manager__r.Name,
                    Effective_Date__c, End_Date__c, Duration__c, Company_Category__c
                    WHERE Client_Account__c = :currentQuote[0].SBQQ__Account__r.ParentId
                    ORDER BY Project_Manager__r.Name ASC, Effective_Date__c DESC
                )
            ];

            List<Project_Code__c> activeProjects = (Project_Code__c[])projectSOSL[0];
            return activeProjects;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting active projects: ' + ex.getMessage());
            return new List<Project_Code__c>();
        }
    }

    /**
     * @description Get quote business rules
     * Replaces QuoteProcurementController.quoteBusinessRules() lines 2169+
     * @param quoteId Quote ID
     * @param caseType Case type
     * @param subType Case sub type
     * @return Business rule record
     */
    public Business_Rule__c getQuoteBusinessRules(Id quoteId, String caseType, String subType) {
        if (quoteId == null) {
            return null;
        }

        try {
            // Query business rules
            List<Business_Rule__c> rules = [
                SELECT Id, Name, Case_Type__c, Sub_Type__c, Reason__c,
                      Enable_Special_Handling__c, Enable_Quote_Only__c,
                      Enable_Project_Code__c, Enable_Financial_Details__c
                FROM Business_Rule__c
                WHERE Case_Type__c = :caseType
                AND Sub_Type__c = :subType
                AND Is_Active__c = true
                LIMIT 1
            ];

            return !rules.isEmpty() ? rules[0] : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting business rules: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Validate project code assignment
     * @param quoteLineId Quote line ID
     * @param projectCodeId Project code ID
     * @return Validation result
     */
    public ProjectValidationResult validateProjectCode(Id quoteLineId, Id projectCodeId) {
        ProjectValidationResult result = new ProjectValidationResult();

        if (quoteLineId == null) {
            result.isValid = false;
            result.errorMessage = 'Quote line ID is required';
            return result;
        }

        if (projectCodeId == null) {
            result.isValid = true; // Project code is optional
            return result;
        }

        try {
            // Get quote line and project code
            SBQQ__QuoteLine__c quoteLine = [
                SELECT Id, SBQQ__Quote__r.SBQQ__Account__r.ParentId,
                      SBQQ__StartDate__c, SBQQ__EndDate__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :quoteLineId
                LIMIT 1
            ];

            Project_Code__c projectCode = [
                SELECT Id, Name, Client_Account__c, Effective_Date__c,
                      End_Date__c, Is_Active__c
                FROM Project_Code__c
                WHERE Id = :projectCodeId
                LIMIT 1
            ];

            // Validate project is active
            if (!projectCode.Is_Active__c) {
                result.isValid = false;
                result.errorMessage = 'Project code is not active';
                return result;
            }

            // Validate project belongs to client account
            if (projectCode.Client_Account__c != quoteLine.SBQQ__Quote__r.SBQQ__Account__r.ParentId) {
                result.isValid = false;
                result.errorMessage = 'Project code does not belong to the quote account';
                return result;
            }

            // Validate project dates overlap with service dates
            if (!validateDateOverlap(
                quoteLine.SBQQ__StartDate__c,
                quoteLine.SBQQ__EndDate__c,
                projectCode.Effective_Date__c,
                projectCode.End_Date__c
            )) {
                result.isValid = false;
                result.errorMessage = 'Service dates do not overlap with project dates';
                return result;
            }

            result.isValid = true;
            return result;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error validating project code: ' + ex.getMessage());
            result.isValid = false;
            result.errorMessage = 'Error validating project code: ' + ex.getMessage();
            return result;
        }
    }

    /**
     * @description Validate date overlap between service and project
     * @param serviceStartDate Service start date
     * @param serviceEndDate Service end date
     * @param projectStartDate Project start date
     * @param projectEndDate Project end date
     * @return True if dates overlap
     */
    private Boolean validateDateOverlap(
        Date serviceStartDate,
        Date serviceEndDate,
        Date projectStartDate,
        Date projectEndDate
    ) {
        if (serviceStartDate == null || projectStartDate == null) {
            return true; // Allow if dates not set
        }

        // Service starts before project ends (or project has no end date)
        Boolean startsBeforeProjectEnds = projectEndDate == null
            || serviceStartDate <= projectEndDate;

        // Service ends after project starts (or service has no end date)
        Boolean endsAfterProjectStarts = serviceEndDate == null
            || serviceEndDate >= projectStartDate;

        return startsBeforeProjectEnds && endsAfterProjectStarts;
    }

    /**
     * @description Assign project code to quote lines
     * @param parentQuoteLineId Parent quote line ID
     * @param projectCodeId Project code ID
     * @return Success status
     */
    public Boolean assignProjectCode(Id parentQuoteLineId, Id projectCodeId) {
        if (parentQuoteLineId == null) {
            return false;
        }

        try {
            // Get all quote lines in bundle
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :parentQuoteLineId
                OR SBQQ__RequiredBy__c = :parentQuoteLineId
                OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :parentQuoteLineId
            ];

            if (quoteLines.isEmpty()) {
                return false;
            }

            // Update quote with project code
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Id = quoteLines[0].SBQQ__Quote__c,
                Project__c = projectCodeId
            );

            update quote;
            return true;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error assigning project code: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Get project details
     * @param projectCodeId Project code ID
     * @return Project code record
     */
    public Project_Code__c getProjectDetails(Id projectCodeId) {
        if (projectCodeId == null) {
            return null;
        }

        try {
            List<Project_Code__c> projects = [
                SELECT Id, Name, Project_Manager__c, Project_Manager__r.Name,
                      Program_Manager__c, Program_Manager__r.Name,
                      Client_Account__c, Client_Account__r.Name,
                      Effective_Date__c, End_Date__c, Duration__c,
                      Company_Category__c, Is_Active__c
                FROM Project_Code__c
                WHERE Id = :projectCodeId
                LIMIT 1
            ];

            return !projects.isEmpty() ? projects[0] : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting project details: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Check if project code is required for quote
     * @param quoteId Quote ID
     * @param caseType Case type
     * @param subType Case sub type
     * @return True if project code required
     */
    public Boolean isProjectCodeRequired(Id quoteId, String caseType, String subType) {
        Business_Rule__c rule = getQuoteBusinessRules(quoteId, caseType, subType);
        return rule != null && rule.Enable_Project_Code__c;
    }

    /**
     * @description Project validation result wrapper
     */
    public class ProjectValidationResult {
        public Boolean isValid { get; set; }
        public String errorMessage { get; set; }

        public ProjectValidationResult() {
            this.isValid = true;
            this.errorMessage = '';
        }
    }
}
