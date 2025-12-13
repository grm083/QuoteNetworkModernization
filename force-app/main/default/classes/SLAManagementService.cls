/**
 * @description Service for SLA (Service Level Agreement) management operations
 * Handles SLA override comments, validation, and date calculations
 * @author Quote Network Modernization Team
 * @date 2025-12-13
 * @story Phase 10.5: SLA & Special Handling
 */
public class SLAManagementService {

    // Constants for special handling reasons
    public static final String SPECIAL_HANDLING_AUTOMATIC_REASON = 'Automatically flagged by system';
    public static final String SPECIAL_HANDLING_BACKDATED_REASON = 'Back-dated service requested';

    /**
     * @description Add SLA override comment to case
     * Wrapper method for intake screen calls
     * @param caseId Case ID
     */
    public void addCommentForSLAOverrideFromIntake(String caseId) {
        addCommentForSLAOverride(caseId, null, null);
    }

    /**
     * @description Add SLA override comment from flow
     * @param caseId Case ID
     * @param slaComment SLA override comment
     * @param slaReason SLA override reason
     */
    public void addCommentForSLAOverrideFromFlow(String caseId, String slaComment, String slaReason) {
        addCommentForSLAOverride(caseId, slaComment, slaReason);
    }

    /**
     * @description Create case comment displaying SLA override reason and comment
     * @param caseId Case ID
     * @param slaComment SLA override comment (optional)
     * @param slaReason SLA override reason (optional)
     * @story SDT-25005
     */
    public void addCommentForSLAOverride(String caseId, String slaComment, String slaReason) {
        try {
            String commentBody;
            String trackingNumber;
            String caseNumber;

            // Get SLA Override comment template from metadata
            Map<String, Comment_Log_Detail__mdt> commentLogTemplateData = new Map<String, Comment_Log_Detail__mdt>();
            for (Comment_Log_Detail__mdt c : Comment_Log_Detail__mdt.getAll().values()) {
                commentLogTemplateData.put(c.DeveloperName, c);
            }
            Comment_Log_Detail__mdt slaOverrideCommentTemplate = commentLogTemplateData.get('SLA_Override');

            Id recordTypeId = Schema.getGlobalDescribe()
                .get('Comment__c')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('Acorn_Ticket_Comment')
                .getRecordTypeId();

            // When called from MIF flow with explicit comment and reason
            if (String.isNotEmpty(slaComment) && String.isNotEmpty(slaReason)) {
                commentBody = slaOverrideCommentTemplate.Comment__c.replaceAll('<Reason__x>', slaReason);
                commentBody = commentBody.replaceAll('<Comment__c>', slaComment);

                List<Case> csList = [
                    SELECT Id, CaseNumber, Tracking_Number__c
                    FROM Case
                    WHERE Id = :caseId
                    LIMIT 1
                ];

                if (csList.size() > 0) {
                    caseNumber = csList[0].CaseNumber;
                    trackingNumber = csList[0].Tracking_Number__c;
                }
            } else {
                // Query quote line for SLA override details
                List<SBQQ__QuoteLine__c> ql = [
                    SELECT Id, SLA_Override_Reason__c, SLA_Override_Comment__c,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.CaseNumber,
                           SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c = :caseId
                    AND SBQQ__Requiredby__c = null
                    AND SLA_Override_Reason__c != null
                    LIMIT 1
                ];

                if (ql.size() > 0) {
                    String overrideReason = ql[0].SLA_Override_Reason__c;
                    String overrideComment = ql[0].SLA_Override_Comment__c;

                    commentBody = slaOverrideCommentTemplate.Comment__c.replaceAll('<Reason__x>', overrideReason);
                    commentBody = commentBody.replaceAll('<Comment__c>', overrideComment);

                    caseNumber = ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.CaseNumber;
                    if (String.isNotEmpty(ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c)) {
                        trackingNumber = ql[0].SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Tracking_Number__c;
                    }
                }
            }

            // Create Comment record (SDT-48501)
            if (String.isNotBlank(commentBody)) {
                Comment__c comment = new Comment__c();
                comment.RecordTypeId = recordTypeId;
                comment.Comment__c = commentBody;
                comment.is_Log__c = true;
                comment.Workflow_TeamUser__c = System.UserInfo.getName();
                comment.Communication_Log_Type_Name__c = 'Internal';
                comment.Case__c = caseId;
                comment.Type__c = Constant_Util.OBJECT_CASE;
                comment.Case_Number__c = caseNumber;
                comment.Acorn_Tracking_Number__c = trackingNumber;

                insert comment;
            }

        } catch (Exception ex) {
            // SDT-48086 - Log handled exception
            UTIL_LoggingService.logHandledExceptionWithClass(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.CONFIRM_CONFIGURATION_ACTION,
                System.LoggingLevel.ERROR,
                'SLAManagementService',
                'addCommentForSLAOverride',
                null
            );
        }
    }

    /**
     * @description Validate SLA override fields
     * @param quoteLine Quote line with SLA override details
     * @return Validation result
     */
    public ValidationResult validateSLAOverride(SBQQ__QuoteLine__c quoteLine) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;

        if (String.isNotEmpty(quoteLine.SLA_Override_Reason__c)) {
            if (String.isEmpty(quoteLine.SLA_Override_Comment__c)) {
                result.isValid = false;
                result.errorMessage = 'SLA Override Comment is required when SLA Override Reason is specified';
            }
        }

        return result;
    }

    /**
     * @description Calculate SLA date for quote line
     * @param quoteLineId Quote line ID
     * @return SLA date
     */
    public Date calculateSLADate(String quoteLineId) {
        DateTime slaDateTime = QuoteFavoritesController.determineSLA(quoteLineId);
        if (slaDateTime != null) {
            return slaDateTime.date();
        }
        return null;
    }

    /**
     * @description Check if service is backdated (SLA date before today)
     * @param quoteLine Quote line with SLA date
     * @return True if backdated, false otherwise
     */
    public Boolean isBackdatedService(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.Quote_SLA_Date__c != null && quoteLine.Quote_SLA_Date__c < System.today()) {
            return true;
        }
        return false;
    }

    /**
     * @description Validation result wrapper class
     */
    public class ValidationResult {
        public Boolean isValid;
        public String errorMessage;
        public List<String> warnings;

        public ValidationResult() {
            this.isValid = false;
            this.warnings = new List<String>();
        }
    }
}
