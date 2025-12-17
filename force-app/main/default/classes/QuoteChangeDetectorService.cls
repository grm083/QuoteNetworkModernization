/**
 * @description Service to detect what changed on a quote record
 * Replaces complex 28-decision flow logic from Quote_Status_Change_Flow
 * Part of Phase 9 Phase 1 - Quote Lifecycle Refactoring
 * @author Quote Network Modernization Team
 * @date 2025-12-12
 * @story Phase 9 Phase 1 - Service Layer
 */
public with sharing class QuoteChangeDetectorService {

    /**
     * @description Detect all changes on quote record
     * Returns structured result with all detected changes
     * @param newQuote New quote record
     * @param oldQuote Old quote record
     * @return ChangeDetectionResult wrapper
     */
    public ChangeDetectionResult detectChanges(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        ChangeDetectionResult result = new ChangeDetectionResult();

        if (newQuote == null) {
            return result;
        }

        // Status changed
        if (oldQuote != null && newQuote.SBQQ__Status__c != oldQuote.SBQQ__Status__c) {
            result.statusChanged = true;
            result.oldStatus = oldQuote.SBQQ__Status__c;
            result.newStatus = newQuote.SBQQ__Status__c;
        }

        // Assigned To changed
        if (oldQuote != null && newQuote.Assigned_To__c != oldQuote.Assigned_To__c) {
            result.assignedToChanged = true;
            result.oldAssignedTo = oldQuote.Assigned_To__c;
            result.newAssignedTo = newQuote.Assigned_To__c;
        }

        // Start Date changed
        if (oldQuote != null && newQuote.SBQQ__StartDate__c != oldQuote.SBQQ__StartDate__c) {
            result.startDateChanged = true;
            result.oldStartDate = oldQuote.SBQQ__StartDate__c;
            result.newStartDate = newQuote.SBQQ__StartDate__c;
        }

        // Action Type changed
        if (oldQuote != null && newQuote.Action_Type__c != oldQuote.Action_Type__c) {
            result.actionTypeChanged = true;
            result.oldActionType = oldQuote.Action_Type__c;
            result.newActionType = newQuote.Action_Type__c;
        }

        // Pending Information changed
        if (oldQuote != null && newQuote.Pending_Information__c != oldQuote.Pending_Information__c) {
            result.pendingInformationChanged = true;
            result.pendingInformation = newQuote.Pending_Information__c;
        }

        // Integration Status changed
        if (oldQuote != null && newQuote.Integration_Status__c != oldQuote.Integration_Status__c) {
            result.integrationStatusChanged = true;
        }

        // STP changed
        if (oldQuote != null && newQuote.STP__c != oldQuote.STP__c) {
            result.stpChanged = true;
            result.stpValue = newQuote.STP__c;
        }

        return result;
    }

    /**
     * @description Determine primary change type
     * Returns single highest-priority change
     * @param result ChangeDetectionResult
     * @return String change type
     */
    public String getPrimaryChangeType(ChangeDetectionResult result) {
        if (result.statusChanged) return 'STATUS_CHANGE';
        if (result.actionTypeChanged && result.newActionType == 'Escalation') return 'ESCALATION';
        if (result.pendingInformationChanged) return 'PENDING_INFORMATION';
        if (result.assignedToChanged) return 'ASSIGNMENT_CHANGE';
        if (result.startDateChanged) return 'START_DATE_CHANGE';
        if (result.stpChanged) return 'STP_CHANGE';
        return 'NO_CHANGE';
    }

    /**
     * @description Check if requires status transition processing
     * @param result ChangeDetectionResult
     * @return Boolean true if status transition needed
     */
    public Boolean requiresStatusTransition(ChangeDetectionResult result) {
        return result.statusChanged;
    }

    /**
     * @description Check if requires reassignment
     * @param result ChangeDetectionResult
     * @return Boolean true if reassignment needed
     */
    public Boolean requiresReassignment(ChangeDetectionResult result) {
        return result.statusChanged || result.assignedToChanged;
    }

    /**
     * @description Check if requires priority recalculation
     * @param result ChangeDetectionResult
     * @return Boolean true if priority calc needed
     */
    public Boolean requiresPriorityRecalculation(ChangeDetectionResult result) {
        return result.startDateChanged;
    }

    /**
     * @description Check if requires Genesys routing
     * @param result ChangeDetectionResult
     * @return Boolean true if Genesys routing needed
     */
    public Boolean requiresGenesysRouting(ChangeDetectionResult result) {
        return result.statusChanged || result.assignedToChanged;
    }

    /**
     * @description Change detection result wrapper
     */
    public class ChangeDetectionResult {
        // Status change
        public Boolean statusChanged = false;
        public String oldStatus;
        public String newStatus;

        // Assignment change
        public Boolean assignedToChanged = false;
        public Id oldAssignedTo;
        public Id newAssignedTo;

        // Start date change
        public Boolean startDateChanged = false;
        public Date oldStartDate;
        public Date newStartDate;

        // Action type change
        public Boolean actionTypeChanged = false;
        public String oldActionType;
        public String newActionType;

        // Pending information change
        public Boolean pendingInformationChanged = false;
        public Boolean pendingInformation;

        // Integration status change
        public Boolean integrationStatusChanged = false;

        // STP change
        public Boolean stpChanged = false;
        public Boolean stpValue;

        public ChangeDetectionResult() {
            // Initialize all flags to false
        }

        /**
         * @description Check if any change detected
         * @return Boolean true if any change
         */
        public Boolean hasAnyChange() {
            return statusChanged || assignedToChanged || startDateChanged ||
                   actionTypeChanged || pendingInformationChanged ||
                   integrationStatusChanged || stpChanged;
        }

        /**
         * @description Get list of all changes
         * @return List of change descriptions
         */
        public List<String> getChangeDescriptions() {
            List<String> changes = new List<String>();

            if (statusChanged) {
                changes.add('Status: ' + oldStatus + ' → ' + newStatus);
            }
            if (assignedToChanged) {
                changes.add('Assigned To changed');
            }
            if (startDateChanged) {
                changes.add('Start Date changed');
            }
            if (actionTypeChanged) {
                changes.add('Action Type: ' + oldActionType + ' → ' + newActionType);
            }
            if (pendingInformationChanged) {
                changes.add('Pending Information: ' + pendingInformation);
            }
            if (stpChanged) {
                changes.add('STP: ' + stpValue);
            }

            return changes;
        }
    }
}
