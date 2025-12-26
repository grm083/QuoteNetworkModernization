import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import QUOTE_STATE_CHANNEL from '@salesforce/messageChannel/quoteStateChannel__c';

// Apex imports
import getQuoteData from '@salesforce/apex/QuoteProcurementController.getQuoteById';
import saveQuoteDraft from '@salesforce/apex/QuoteProcurementController.saveQuote';

/**
 * @description Root container component for Quote Flow
 * Manages overall state and routing between Quick Quote Wizard and Advanced Builder
 * @author Quote Network Modernization Team
 * @date 2025-12-17
 */
export default class QuoteFlowContainer extends NavigationMixin(LightningElement) {

    // ========== Public Properties ==========

    @api recordId; // Case, Opportunity, or Quote ID
    @api flowMode = 'new'; // 'new' | 'edit' | 'amend' | 'correct'

    // ========== Tracked Properties ==========

    @track quoteId;
    @track accountId;
    @track accountName;
    @track quoteNumber = 'NEW';
    @track quoteStatus = 'Draft';
    @track quoteValue;
    @track lastSaved;

    @track mode = 'quick'; // 'quick' | 'advanced'
    @track currentStep = 1;

    @track isLoading = false;
    @track isSaving = false;

    // Toast state
    @track showToast = false;
    @track toastTitle = '';
    @track toastMessage = '';
    @track toastVariant = 'info'; // 'success' | 'error' | 'warning' | 'info'

    // Help content (changes based on current step)
    @track helpContent = '';
    @track helpLink = '';

    // ========== Wire Services ==========

    @wire(MessageContext)
    messageContext;

    subscription = null;

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.subscribeToQuoteStateChanges();
        this.initializeQuote();
        this.updateHelpContent();
    }

    disconnectedCallback() {
        this.unsubscribeFromQuoteStateChanges();
    }

    // ========== Computed Properties ==========

    get isQuickMode() {
        return this.mode === 'quick';
    }

    get isAdvancedMode() {
        return this.mode === 'advanced';
    }

    get quickModeVariant() {
        return this.isQuickMode ? 'brand' : 'neutral';
    }

    get advancedModeVariant() {
        return this.isAdvancedMode ? 'brand' : 'neutral';
    }

    get showModeToggle() {
        // Only show toggle for new quotes, not amendments/corrections
        return this.flowMode === 'new' || this.flowMode === 'edit';
    }

    get showSidebar() {
        // Hide sidebar on mobile, show on desktop
        // This would be enhanced with actual viewport detection
        return true;
    }

    get lastSavedFormatted() {
        if (!this.lastSaved) return '';

        const now = new Date();
        const saved = new Date(this.lastSaved);
        const diffMs = now - saved;
        const diffMins = Math.floor(diffMs / 60000);

        if (diffMins < 1) return 'just now';
        if (diffMins === 1) return '1 minute ago';
        if (diffMins < 60) return `${diffMins} minutes ago`;

        return saved.toLocaleTimeString();
    }

    get toastClass() {
        const baseClass = 'wm-toast';
        return `${baseClass} wm-toast-${this.toastVariant}`;
    }

    get toastIcon() {
        const iconMap = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };
        return iconMap[this.toastVariant] || 'utility:info';
    }

    // ========== Initialize Data ==========

    async initializeQuote() {
        this.isLoading = true;

        try {
            // Determine if recordId is Case, Opportunity, or Quote
            // For now, assume it's a Quote ID if flowMode is 'edit'/'amend'/'correct'
            if (this.flowMode !== 'new' && this.recordId) {
                await this.loadExistingQuote(this.recordId);
            } else {
                // New quote - create placeholder data
                this.quoteNumber = 'NEW-' + Date.now().toString().slice(-6);
                this.quoteStatus = 'Draft';

                // In real implementation, would fetch Account from Case/Opportunity
                this.accountName = 'Loading...';
            }

        } catch (error) {
            this.showErrorToast('Error Loading Quote', error.body?.message || error.message);
        } finally {
            this.isLoading = false;
        }
    }

    async loadExistingQuote(quoteId) {
        try {
            const quoteData = await getQuoteData({ quoteId });

            this.quoteId = quoteData.Id;
            this.quoteNumber = quoteData.Name || quoteData.QuoteNumber;
            this.accountId = quoteData.SBQQ__Account__c;
            this.accountName = quoteData.SBQQ__Account__r?.Name;
            this.quoteStatus = quoteData.SBQQ__Status__c || 'Draft';
            this.quoteValue = quoteData.SBQQ__NetAmount__c;

        } catch (error) {
            throw new Error('Failed to load quote: ' + error.message);
        }
    }

    // ========== Message Service ==========

    subscribeToQuoteStateChanges() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                QUOTE_STATE_CHANNEL,
                (message) => this.handleQuoteStateChange(message)
            );
        }
    }

    unsubscribeFromQuoteStateChanges() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleQuoteStateChange(message) {
        console.log('Quote state changed:', message);

        // Update local state based on message
        if (message.action === 'lineAdded' || message.action === 'lineUpdated') {
            // Refresh quote value
            this.refreshQuoteValue(message.payload);
        }

        if (message.action === 'stepChanged') {
            this.currentStep = message.payload.step;
            this.updateHelpContent();
        }

        if (message.action === 'validated' && message.payload.success) {
            this.showSuccessToast('Validation Passed', 'Quote is ready for pricing');
        }
    }

    publishStateChange(action, payload) {
        const message = {
            quoteId: this.quoteId,
            action: action,
            payload: payload,
            source: 'quoteFlowContainer'
        };

        publish(this.messageContext, QUOTE_STATE_CHANNEL, message);
    }

    // ========== Mode Switching ==========

    handleQuickMode() {
        if (this.mode !== 'quick') {
            this.mode = 'quick';
            this.publishStateChange('modeChanged', { mode: 'quick' });
        }
    }

    handleAdvancedMode() {
        if (this.mode !== 'advanced') {
            this.mode = 'advanced';
            this.publishStateChange('modeChanged', { mode: 'advanced' });

            // Show info toast about advanced mode
            this.showInfoToast(
                'Advanced Mode',
                'Advanced Builder is coming soon. Returning to Quick Quote.'
            );

            // For now, switch back to quick mode
            setTimeout(() => {
                this.mode = 'quick';
            }, 2000);
        }
    }

    // ========== Wizard Event Handlers ==========

    handleWizardComplete(event) {
        const quoteData = event.detail;

        this.showSuccessToast(
            'Quote Created',
            'Quote ' + (quoteData.quoteNumber || 'created') + ' successfully'
        );

        // Navigate to quote record
        if (quoteData.quoteId) {
            this.navigateToQuote(quoteData.quoteId);
        }
    }

    handleWizardStep(event) {
        const { step, data } = event.detail;
        this.currentStep = step;
        this.updateHelpContent();

        // Auto-save on step change
        if (data && data.autoSave) {
            this.handleSaveDraft();
        }
    }

    // ========== Action Handlers ==========

    handleCancel() {
        // Confirm if there are unsaved changes
        const hasUnsavedChanges = true; // In real implementation, check dirty state

        if (hasUnsavedChanges) {
            if (confirm('You have unsaved changes. Are you sure you want to cancel?')) {
                this.navigateBack();
            }
        } else {
            this.navigateBack();
        }
    }

    async handleSaveDraft() {
        this.isSaving = true;

        try {
            // In real implementation, collect data from child components
            const quoteData = {
                Id: this.quoteId,
                // ... other fields
            };

            await saveQuoteDraft({ quoteData: JSON.stringify(quoteData) });

            this.lastSaved = new Date().toISOString();
            this.publishStateChange('saved', { timestamp: this.lastSaved });

            this.showSuccessToast('Draft Saved', 'Your quote has been saved');

        } catch (error) {
            this.showErrorToast('Save Failed', error.body?.message || error.message);
        } finally {
            this.isSaving = false;
        }
    }

    // ========== Helper Methods ==========

    updateHelpContent() {
        // Update contextual help based on current step
        const helpMap = {
            1: {
                content: 'Select a service from your favorites, recent orders, or search the full catalog. Recommendations are based on customer history.',
                link: '/help/product-selection'
            },
            2: {
                content: 'Enter the service location, start date, and schedule. The system will calculate the earliest available service date based on your SLA.',
                link: '/help/service-details'
            },
            3: {
                content: 'Review your configuration and request pricing. The system will compare multiple vendors if available.',
                link: '/help/pricing'
            },
            4: {
                content: 'Review the final quote details and submit for approval or send to customer.',
                link: '/help/quote-submission'
            }
        };

        const help = helpMap[this.currentStep] || { content: '', link: '' };
        this.helpContent = help.content;
        this.helpLink = help.link;
    }

    refreshQuoteValue(payload) {
        // In real implementation, recalculate total from all lines
        if (payload && payload.lineValue) {
            this.quoteValue = (this.quoteValue || 0) + payload.lineValue;
        }
    }

    // ========== Toast Methods ==========

    showSuccessToast(title, message) {
        this.displayToast(title, message, 'success');
    }

    showErrorToast(title, message) {
        this.displayToast(title, message, 'error');
    }

    showWarningToast(title, message) {
        this.displayToast(title, message, 'warning');
    }

    showInfoToast(title, message) {
        this.displayToast(title, message, 'info');
    }

    displayToast(title, message, variant) {
        this.toastTitle = title;
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;

        // Auto-hide after 5 seconds
        setTimeout(() => {
            this.showToast = false;
        }, 5000);

        // Also dispatch standard Salesforce toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    handleCloseToast() {
        this.showToast = false;
    }

    // ========== Navigation ==========

    navigateToQuote(quoteId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: quoteId,
                objectApiName: 'SBQQ__Quote__c',
                actionName: 'view'
            }
        });
    }

    navigateBack() {
        // Navigate back to originating record (Case/Opportunity)
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } else {
            // Navigate to home
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                }
            });
        }
    }
}
