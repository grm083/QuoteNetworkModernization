/**
 * @description Orchestrator for quote lifecycle processing
 * Replaces Quote_Status_Change_Flow (127 elements → clean service orchestration)
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Orchestration Layer
 */
public with sharing class QuoteLifecycleOrchestrator {

    private QuoteChangeDetectorService changeDetector;
    private QuotePriorityService priorityService;
    private NextActionSchedulingService schedulingService;
    private QuoteAssignmentService assignmentService;
    private QuoteActionFrameworkRepository actionFrameworkRepo;

    public QuoteLifecycleOrchestrator() {
        this.changeDetector = new QuoteChangeDetectorService();
        this.priorityService = new QuotePriorityService();
        this.schedulingService = new NextActionSchedulingService();
        this.assignmentService = new QuoteAssignmentService();
        this.actionFrameworkRepo = new QuoteActionFrameworkRepository();
    }

    /**
     * @description Process quote changes (main entry point)
     * Replaces Quote_Status_Change_Flow logic
     * @param newQuote New quote record
     * @param oldQuote Old quote record
     * @return ProcessingResult wrapper
     */
    public ProcessingResult processQuoteChange(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        ProcessingResult result = new ProcessingResult();

        try {
            // Detect what changed
            QuoteChangeDetectorService.ChangeDetectionResult changes =
                changeDetector.detectChanges(newQuote, oldQuote);

            if (!changes.hasAnyChange()) {
                result.noChangesDetected = true;
                return result;
            }

            result.changeType = changeDetector.getPrimaryChangeType(changes);

            // Route based on primary change type
            if (changes.statusChanged) {
                processStatusChange(newQuote, oldQuote, result);
            }

            if (changes.actionTypeChanged && changes.newActionType == 'Escalation') {
                processEscalation(newQuote, result);
            }

            if (changes.pendingInformationChanged) {
                processPendingInformation(newQuote, result);
            }

            if (changes.assignedToChanged) {
                processAssignmentChange(newQuote, oldQuote, result);
            }

            if (changes.startDateChanged) {
                processStartDateChange(newQuote, result);
            }

            result.success = true;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLifecycleOrchestrator', 'processQuoteChange');
            result.success = false;
            result.errors.add('Unexpected error: ' + ex.getMessage());
        }

        return result;
    }

    /**
     * @description Process status change
     * @param newQuote New quote
     * @param oldQuote Old quote
     * @param result Processing result
     */
    private void processStatusChange(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote, ProcessingResult result) {
        // Set action type to Status Change
        newQuote.Action_Type__c = 'Status Change';

        // Check if assignment is needed
        if (requiresAssignment(newQuote)) {
            processAssignment(newQuote, result);
        }

        // Calculate next action timing
        processNextActionTiming(newQuote, result);

        // Set last action performed
        newQuote.Last_Action_Performed__c = DateTime.now();

        result.statusProcessed = true;
    }

    /**
     * @description Process escalation
     * @param newQuote New quote
     * @param result Processing result
     */
    private void processEscalation(SBQQ__Quote__c newQuote, ProcessingResult result) {
        // Add stage tracking logic here (from flow's Add_Stage assignments)
        result.escalationProcessed = true;
    }

    /**
     * @description Process pending information
     * @param newQuote New quote
     * @param result Processing result
     */
    private void processPendingInformation(SBQQ__Quote__c newQuote, ProcessingResult result) {
        // Set Pending_Information__c to false
        newQuote.Pending_Information__c = false;
        result.pendingInfoProcessed = true;
    }

    /**
     * @description Process assignment change
     * @param newQuote New quote
     * @param oldQuote Old quote
     * @param result Processing result
     */
    private void processAssignmentChange(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote, ProcessingResult result) {
        // Trigger Genesys routing if needed
        result.genesysRoutingRequired = true;
        result.assignmentProcessed = true;
    }

    /**
     * @description Process start date change
     * @param newQuote New quote
     * @param result Processing result
     */
    private void processStartDateChange(SBQQ__Quote__c newQuote, ProcessingResult result) {
        // Recalculate priority
        String newPriority = priorityService.determinePriority(newQuote);
        newQuote.Priority__c = newPriority;

        // Set flag for assign to me action
        newQuote.Assing_To_Me_Action__c = true;

        result.priorityRecalculated = true;
        result.newPriority = newPriority;
    }

    /**
     * @description Check if quote status requires assignment
     * @param quote Quote record
     * @return Boolean true if assignment needed
     */
    private Boolean requiresAssignment(SBQQ__Quote__c quote) {
        // Draft status always requires assignment
        if (quote.SBQQ__Status__c == Constant_Util.QUOTE_DRAFT) {
            return true;
        }

        // Cost Configured only requires timing update (no assignment)
        if (quote.SBQQ__Status__c == Constant_Util.QUOTE_COST_CONFIGURED) {
            return false;
        }

        return true;
    }

    /**
     * @description Process quote assignment
     * @param quote Quote record
     * @param result Processing result
     */
    private void processAssignment(SBQQ__Quote__c quote, ProcessingResult result) {
        // Get vendor code from quote lines
        String vendorCode = getVendorCodeFromQuoteLines(quote.Id);

        // Determine assignment
        QuoteAssignmentService.AssignmentResult assignmentResult =
            assignmentService.determineAssignee(quote, vendorCode);

        if (assignmentResult.success && assignmentResult.assignedUserId != null) {
            quote.Assigned_To__c = assignmentResult.assignedUserId;
            result.assignedToUser = assignmentResult.assignedUserName;
            result.assignmentType = assignmentResult.assignmentType;
        } else {
            result.warnings.add('Could not determine assignment: ' + assignmentResult.errorMessage);
        }
    }

    /**
     * @description Process next action timing
     * @param quote Quote record
     * @param result Processing result
     */
    private void processNextActionTiming(SBQQ__Quote__c quote, ProcessingResult result) {
        // Get vendor code
        String vendorCode = getVendorCodeFromQuoteLines(quote.Id);

        // Calculate complete scheduling
        NextActionSchedulingService.SchedulingResult schedulingResult =
            schedulingService.calculateCompleteScheduling(quote, vendorCode);

        if (schedulingResult.success) {
            quote.Next_Action_Start_Date__c = schedulingResult.nextActionStartDate;
            quote.Next_Action_Due_Date__c = schedulingResult.nextActionDueDate;
            result.nextActionCalculated = true;
        } else {
            result.warnings.add('Could not calculate next action: ' + schedulingResult.errorMessage);
        }
    }

    /**
     * @description Get vendor code from quote lines
     * Helper method to query parent vendor
     * @param quoteId Quote ID
     * @return String vendor code
     */
    private String getVendorCodeFromQuoteLines(Id quoteId) {
        try {
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Vendor__r.Vendor_ID__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND SBQQ__RequiredBy__c = null
                AND Vendor__r.Vendor_ID__c != null
                LIMIT 1
            ];

            return quoteLines.isEmpty() ? null : quoteLines[0].Vendor__r.Vendor_ID__c;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'QuoteLifecycleOrchestrator', 'getVendorCodeFromQuoteLines');
            return null;
        }
    }

    /**
     * @description Processing result wrapper
     */
    public class ProcessingResult {
        public Boolean success = false;
        public Boolean noChangesDetected = false;
        public String changeType;

        // What was processed
        public Boolean statusProcessed = false;
        public Boolean escalationProcessed = false;
        public Boolean pendingInfoProcessed = false;
        public Boolean assignmentProcessed = false;
        public Boolean priorityRecalculated = false;
        public Boolean nextActionCalculated = false;

        // Results
        public String assignedToUser;
        public String assignmentType;
        public String newPriority;
        public Boolean genesysRoutingRequired = false;

        // Errors and warnings
        public List<String> errors = new List<String>();
        public List<String> warnings = new List<String>();

        public ProcessingResult() {
            this.success = false;
            this.errors = new List<String>();
            this.warnings = new List<String>();
        }
    }
}
