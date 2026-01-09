import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex imports - Quote submission
import submitQuote from '@salesforce/apex/QuoteSubmissionController.submitQuote';
import saveDraftQuote from '@salesforce/apex/QuoteSubmissionController.saveDraftQuote';
import sendQuoteEmail from '@salesforce/apex/QuoteSubmissionController.sendQuoteEmail';

/**
 * @description Quote Submit Confirmation for Quick Quote Wizard Step 4
 * Final review, checklist, and submission with success confirmation
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class QuoteSubmitConfirmation extends NavigationMixin(LightningElement) {

    // ========== Public API Properties ==========

    @api quoteData; // Complete quote data from wizard

    // ========== Tracked Properties ==========

    // Product/Service
    @track productName = '';
    @track productDescription = '';
    @track containerSize = '';
    @track materialType = '';

    // Location
    @track locationAddress = '';
    @track accessInstructions = '';
    @track isServiceable = false;

    // Schedule
    @track scheduleType = '';
    @track serviceDate = '';
    @track scheduleDescription = '';
    @track firstServiceDate = '';
    @track totalServices = '';

    // Pricing
    @track subtotal = 0;
    @track discounts = 0;
    @track taxAmount = 0;
    @track taxRate = 0;
    @track total = 0;

    // Checklist
    @track checklist1 = false;
    @track checklist2 = false;
    @track checklist3 = false;
    @track checklist4 = false;

    // Terms & Options
    @track termsAccepted = false;
    @track emailToCustomer = false;
    @track customerEmail = '';
    @track saveAsDraft = false;

    // Submission state
    @track isSubmitting = false;
    @track isSubmitted = false;
    @track submittedQuoteNumber = '';
    @track submittedQuoteId = '';
    @track submittedDateTime = '';
    @track emailSent = false;

    // Error handling
    @track hasError = false;
    @track errorMessage = '';

    // ========== Computed Properties - Schedule Type ==========

    get isOneTimeService() {
        return this.scheduleType === 'One-Time Service';
    }

    get isRecurringService() {
        return this.scheduleType === 'Recurring Service';
    }

    // ========== Computed Properties - Pricing ==========

    get formattedSubtotal() {
        return this.formatCurrency(this.subtotal);
    }

    get formattedDiscounts() {
        return this.formatCurrency(this.discounts);
    }

    get formattedTax() {
        return this.formatCurrency(this.taxAmount);
    }

    get formattedTotal() {
        return this.formatCurrency(this.total);
    }

    get hasDiscounts() {
        return this.discounts > 0;
    }

    get hasTax() {
        return this.taxAmount > 0;
    }

    // ========== Computed Properties - Checklist ==========

    get checklistItem1Class() {
        return this.checklist1 ? 'wm-checklist-item wm-checklist-complete' : 'wm-checklist-item';
    }

    get checklistItem2Class() {
        return this.checklist2 ? 'wm-checklist-item wm-checklist-complete' : 'wm-checklist-item';
    }

    get checklistItem3Class() {
        return this.checklist3 ? 'wm-checklist-item wm-checklist-complete' : 'wm-checklist-item';
    }

    get checklistItem4Class() {
        return this.checklist4 ? 'wm-checklist-item wm-checklist-complete' : 'wm-checklist-item';
    }

    get allChecklistComplete() {
        return this.checklist1 && this.checklist2 && this.checklist3 && this.checklist4;
    }

    // ========== Computed Properties - Submit Button ==========

    get isSubmitDisabled() {
        return !this.allChecklistComplete || !this.termsAccepted || this.isSubmitting;
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.loadQuoteData();
    }

    // ========== Data Loading ==========

    loadQuoteData() {
        if (!this.quoteData) return;

        // Product/Service
        this.productName = this.quoteData.productName || '';
        this.productDescription = this.quoteData.productDescription || '';
        this.containerSize = this.quoteData.containerSize || '';
        this.materialType = this.quoteData.materialType || '';

        // Location
        this.locationAddress = this.quoteData.locationAddress || '';
        this.accessInstructions = this.quoteData.accessInstructions || '';
        this.isServiceable = this.quoteData.isServiceable || false;

        // Schedule
        this.scheduleType = this.quoteData.scheduleType || '';
        this.serviceDate = this.quoteData.serviceDate || '';
        this.scheduleDescription = this.quoteData.scheduleDescription || '';
        this.firstServiceDate = this.quoteData.firstServiceDate || '';
        this.totalServices = this.quoteData.totalServices || '';

        // Pricing
        this.subtotal = this.quoteData.subtotal || 0;
        this.discounts = this.quoteData.discounts || 0;
        this.taxAmount = this.quoteData.taxAmount || 0;
        this.taxRate = this.quoteData.taxRate || 0;
        this.total = this.quoteData.total || 0;

        // Customer email (if available from account)
        this.customerEmail = this.quoteData.customerEmail || '';
    }

    // ========== Event Handlers - Edit Actions ==========

    handleEditProduct() {
        this.dispatchNavigationEvent('product', 1);
    }

    handleEditLocation() {
        this.dispatchNavigationEvent('location', 2);
    }

    handleEditSchedule() {
        this.dispatchNavigationEvent('schedule', 2);
    }

    handleEditPricing() {
        this.dispatchNavigationEvent('pricing', 3);
    }

    dispatchNavigationEvent(section, step) {
        this.dispatchEvent(new CustomEvent('editstep', {
            detail: {
                section: section,
                step: step
            }
        }));
    }

    // ========== Event Handlers - Checklist ==========

    handleChecklistChange(event) {
        const checklistNumber = event.currentTarget.dataset.checklist;
        const isChecked = event.target.checked;

        switch (checklistNumber) {
            case '1':
                this.checklist1 = isChecked;
                break;
            case '2':
                this.checklist2 = isChecked;
                break;
            case '3':
                this.checklist3 = isChecked;
                break;
            case '4':
                this.checklist4 = isChecked;
                break;
        }
    }

    // ========== Event Handlers - Terms & Options ==========

    handleTermsChange(event) {
        this.termsAccepted = event.target.checked;
    }

    handleViewTerms() {
        // Open terms modal or navigate to terms page
        // For now, dispatch event to parent
        this.dispatchEvent(new CustomEvent('viewterms'));
    }

    handleEmailOptionChange(event) {
        this.emailToCustomer = event.target.checked;
    }

    handleCustomerEmailChange(event) {
        this.customerEmail = event.target.value;
    }

    handleDraftOptionChange(event) {
        this.saveAsDraft = event.target.checked;
    }

    // ========== Event Handlers - Navigation ==========

    handleGoBack() {
        this.dispatchEvent(new CustomEvent('goback', {
            detail: {
                step: 3
            }
        }));
    }

    // ========== Quote Submission ==========

    async handleSaveDraft() {
        this.isSubmitting = true;
        this.hasError = false;

        try {
            const result = await saveDraftQuote({
                quoteData: JSON.stringify(this.quoteData)
            });

            this.submittedQuoteId = result.quoteId;
            this.submittedQuoteNumber = result.quoteNumber;
            this.submittedDateTime = new Date().toLocaleString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });

            this.isSubmitted = true;

            // Dispatch success event
            this.dispatchEvent(new CustomEvent('quotesaved', {
                detail: {
                    quoteId: this.submittedQuoteId,
                    quoteNumber: this.submittedQuoteNumber
                }
            }));

        } catch (error) {
            console.error('Save draft error:', error);
            this.hasError = true;
            this.errorMessage = this.parseErrorMessage(error);
        } finally {
            this.isSubmitting = false;
        }
    }

    async handleSubmitQuote() {
        if (this.isSubmitDisabled) return;

        this.isSubmitting = true;
        this.hasError = false;

        try {
            // Submit quote
            const result = await submitQuote({
                quoteData: JSON.stringify(this.quoteData)
            });

            this.submittedQuoteId = result.quoteId;
            this.submittedQuoteNumber = result.quoteNumber;
            this.submittedDateTime = new Date().toLocaleString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });

            // Send email if requested
            if (this.emailToCustomer && this.customerEmail) {
                await this.sendConfirmationEmail();
            }

            this.isSubmitted = true;

            // Dispatch success event
            this.dispatchEvent(new CustomEvent('quotesubmitted', {
                detail: {
                    quoteId: this.submittedQuoteId,
                    quoteNumber: this.submittedQuoteNumber,
                    total: this.total
                }
            }));

        } catch (error) {
            console.error('Submit quote error:', error);
            this.hasError = true;
            this.errorMessage = this.parseErrorMessage(error);
        } finally {
            this.isSubmitting = false;
        }
    }

    async sendConfirmationEmail() {
        try {
            await sendQuoteEmail({
                quoteId: this.submittedQuoteId,
                emailAddress: this.customerEmail
            });

            this.emailSent = true;

        } catch (error) {
            console.warn('Email send error:', error);
            // Not a fatal error - quote was still submitted
            this.emailSent = false;
        }
    }

    // ========== Success Actions ==========

    handleViewQuote() {
        // Navigate to quote record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.submittedQuoteId,
                objectApiName: 'SBQQ__Quote__c',
                actionName: 'view'
            }
        });
    }

    handleCreateAnother() {
        // Dispatch event to reset wizard and start over
        this.dispatchEvent(new CustomEvent('createnew'));
    }

    // ========== Error Handling ==========

    handleRetry() {
        this.hasError = false;
        this.errorMessage = '';
        this.isSubmitted = false;
    }

    // ========== Helper Methods ==========

    formatCurrency(amount) {
        if (amount === null || amount === undefined) return '$0.00';

        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(amount);
    }

    parseErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }

        if (error.message) {
            return error.message;
        }

        return 'An unexpected error occurred while submitting your quote. Please try again or contact support.';
    }
}
