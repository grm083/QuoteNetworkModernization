import { LightningElement, api, track, wire } from 'lwc';

// Apex imports - connects to Phase 11 SLA and Entitlement Services!
import determineSLA from '@salesforce/apex/QuoteFavoritesController.determineSLA';
import getRelatedEntitlement from '@salesforce/apex/QuoteFavoritesController.getRelatedEntitlement';

/**
 * @description Transparent SLA Calculator Display with Phase 11 Integration
 * Shows step-by-step SLA calculation breakdown for complete transparency
 * Connects to:
 *   - Phase 11a: SLAManagementService.determineSLA()
 *   - Phase 11b: EntitlementMatchingService.getRelatedEntitlement()
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class SlaCalculatorDisplay extends LightningElement {

    // ========== Public API Properties ==========

    @api accountId;
    @api locationId;
    @api projectId;
    @api productFamily;
    @api equipmentSize;
    @api materialType;

    // ========== Tracked Properties ==========

    @track isCalculating = false;
    @track calculatedSlaDate = null;
    @track entitlement = null;
    @track selectedDate = '';
    @track selectedTime = '';
    @track showCalculationDetails = false;
    @track showEntitlementDetails = false;
    @track hasError = false;
    @track errorMessage = '';

    // Override properties (for authorized users)
    @track isOverridden = false;
    @track overrideDate = '';
    @track overrideReason = '';

    // ========== Computed Properties ==========

    get hasCalculatedSla() {
        return this.calculatedSlaDate !== null && !this.hasError;
    }

    get formattedSlaDate() {
        if (!this.calculatedSlaDate) return '';

        const date = new Date(this.calculatedSlaDate);
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get formattedSlaTime() {
        if (!this.calculatedSlaDate) return '';

        const date = new Date(this.calculatedSlaDate);
        return date.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    }

    get currentDateTime() {
        const now = new Date();
        return now.toLocaleString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    }

    get hasEntitlement() {
        return this.entitlement !== null;
    }

    get entitlementGuarantee() {
        if (!this.entitlement) return '';

        const category = this.entitlement.Service_Guarantee_Category__c;
        const value = this.entitlement.Service_Guarantee_Category_Value__c;
        const unit = this.getEntitlementUnit(category);

        return `${value} ${unit}`;
    }

    get entitlementUnit() {
        if (!this.entitlement) return '';
        return this.getEntitlementUnit(this.entitlement.Service_Guarantee_Category__c);
    }

    get entitlementPriority() {
        if (!this.entitlement) return '';

        const priority = this.entitlement.Entitlement_Priority__c;
        const priorityLabels = {
            1: 'Highest - Contract Specific',
            2: 'High - Project Specific',
            3: 'Medium-High - Size & Material',
            4: 'Medium - Product Family',
            5: 'Medium-Low - Location',
            6: 'Standard - Account Level'
        };

        return priorityLabels[priority] || `Priority ${priority}`;
    }

    get industryStandardSla() {
        // Default industry standard when no entitlement exists
        return '3 Business Days';
    }

    get locationTimezone() {
        // In real implementation, fetch from Location__c.Timezone__c
        return 'America/New_York (EST)';
    }

    get businessHoursRange() {
        // In real implementation, fetch from BusinessHours
        return 'Monday - Friday, 8:00 AM - 5:00 PM';
    }

    get slaAdditionText() {
        if (this.hasEntitlement) {
            return this.entitlementGuarantee;
        }
        return this.industryStandardSla;
    }

    get minimumDate() {
        if (!this.calculatedSlaDate) {
            const today = new Date();
            return today.toISOString().split('T')[0];
        }

        const slaDate = new Date(this.calculatedSlaDate);
        return slaDate.toISOString().split('T')[0];
    }

    get dateFieldHelp() {
        return `Service cannot begin before ${this.formattedSlaDate} due to service level agreements`;
    }

    get showEarlyDateWarning() {
        if (!this.selectedDate || !this.calculatedSlaDate) return false;

        const selected = new Date(this.selectedDate);
        const sla = new Date(this.calculatedSlaDate);

        return selected < sla;
    }

    get canOverrideSla() {
        // In real implementation, check user permissions
        // return this.userHasPermission('Override_SLA');
        return false; // Default to false for safety
    }

    get detailsIcon() {
        return this.showCalculationDetails ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get entitlementDetailsLabel() {
        return this.showEntitlementDetails ? 'Hide Details' : 'Show Details';
    }

    get entitlementDetailsIcon() {
        return this.showEntitlementDetails ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get hasAlternatives() {
        // In real implementation, check for alternative service options
        return false;
    }

    get alternatives() {
        return [];
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.calculateSLA();
    }

    // ========== SLA Calculation (Phase 11 Integration) ==========

    async calculateSLA() {
        this.isCalculating = true;
        this.hasError = false;

        try {
            // Step 1: Get entitlement (Phase 11b EntitlementMatchingService)
            await this.fetchEntitlement();

            // Step 2: Calculate SLA date (Phase 11a SLAManagementService)
            await this.fetchSLADate();

            // Step 3: Set selected date to calculated SLA
            if (this.calculatedSlaDate) {
                const slaDate = new Date(this.calculatedSlaDate);
                this.selectedDate = slaDate.toISOString().split('T')[0];
                this.selectedTime = slaDate.toTimeString().split(' ')[0].substring(0, 5);
            }

        } catch (error) {
            console.error('SLA Calculation Error:', error);
            this.hasError = true;
            this.errorMessage = this.parseErrorMessage(error);
        } finally {
            this.isCalculating = false;
        }
    }

    async fetchEntitlement() {
        try {
            // Call Phase 11b EntitlementMatchingService via QuoteFavoritesController
            const result = await getRelatedEntitlement({
                accountId: this.accountId,
                locationId: this.locationId,
                projectId: this.projectId,
                productFamily: this.productFamily,
                equipmentSize: this.equipmentSize,
                materialType: this.materialType
            });

            this.entitlement = result;

        } catch (error) {
            console.warn('No entitlement found, will use industry standard:', error);
            this.entitlement = null;
            // This is not a fatal error - we can proceed with industry standard
        }
    }

    async fetchSLADate() {
        try {
            // Call Phase 11a SLAManagementService via QuoteFavoritesController
            const result = await determineSLA({
                accountId: this.accountId,
                locationId: this.locationId,
                projectId: this.projectId,
                productFamily: this.productFamily,
                equipmentSize: this.equipmentSize,
                materialType: this.materialType,
                entitlement: this.entitlement
            });

            this.calculatedSlaDate = result.slaDate;

            // Dispatch event to parent with calculated SLA
            this.dispatchSLACalculated();

        } catch (error) {
            throw new Error('Failed to calculate SLA date: ' + error.message);
        }
    }

    // ========== Event Handlers ==========

    toggleCalculationDetails() {
        this.showCalculationDetails = !this.showCalculationDetails;
    }

    toggleEntitlementDetails() {
        this.showEntitlementDetails = !this.showEntitlementDetails;
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.dispatchDateSelection();
    }

    handleTimeChange(event) {
        this.selectedTime = event.target.value;
        this.dispatchDateSelection();
    }

    handleSelectAlternative(event) {
        const altDate = event.target.dataset.altDate;
        const selected = new Date(altDate);

        this.selectedDate = selected.toISOString().split('T')[0];
        this.selectedTime = selected.toTimeString().split(' ')[0].substring(0, 5);

        this.dispatchDateSelection();
    }

    handleOverrideToggle(event) {
        this.isOverridden = event.target.checked;

        if (!this.isOverridden) {
            // Reset override fields
            this.overrideDate = '';
            this.overrideReason = '';
        }
    }

    handleOverrideDateChange(event) {
        this.overrideDate = event.target.value;
    }

    handleOverrideReasonChange(event) {
        this.overrideReason = event.target.value;
    }

    async retryCalculation() {
        await this.calculateSLA();
    }

    // ========== Event Dispatching ==========

    dispatchSLACalculated() {
        this.dispatchEvent(new CustomEvent('slacalculated', {
            detail: {
                slaDate: this.calculatedSlaDate,
                formattedDate: this.formattedSlaDate,
                formattedTime: this.formattedSlaTime,
                hasEntitlement: this.hasEntitlement,
                entitlement: this.entitlement
            }
        }));
    }

    dispatchDateSelection() {
        const selectedDateTime = this.combineDateTime(this.selectedDate, this.selectedTime);

        this.dispatchEvent(new CustomEvent('dateselect', {
            detail: {
                selectedDate: selectedDateTime,
                isBeforeSLA: this.showEarlyDateWarning,
                slaDate: this.calculatedSlaDate,
                isOverridden: this.isOverridden,
                overrideReason: this.overrideReason
            }
        }));
    }

    // ========== Helper Methods ==========

    getEntitlementUnit(category) {
        const unitMap = {
            'Business Days': 'business days',
            'Calendar Days': 'calendar days',
            'Business Hours': 'business hours',
            'Same Day': 'same day service',
            'Next Day': 'next day service'
        };

        return unitMap[category] || 'days';
    }

    combineDateTime(dateStr, timeStr) {
        if (!dateStr) return null;

        if (timeStr) {
            return new Date(`${dateStr}T${timeStr}:00`);
        }

        return new Date(`${dateStr}T08:00:00`); // Default to 8 AM
    }

    parseErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }

        if (error.message) {
            return error.message;
        }

        return 'An unexpected error occurred while calculating the service date. Please try again or contact support.';
    }
}
