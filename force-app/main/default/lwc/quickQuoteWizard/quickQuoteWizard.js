import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import QUOTE_STATE_CHANNEL from '@salesforce/messageChannel/quoteStateChannel__c';

// Apex imports
import createQuoteLine from '@salesforce/apex/QuoteFavoritesController.addQuoteFavorite';
import getPricing from '@salesforce/apex/QuoteProcurementController.requestPricing';

/**
 * @description Quick Quote Wizard - 4-step guided quote creation for CSRs
 * Target: Complete quotes in under 5 minutes
 * @author Quote Network Modernization Team
 * @date 2025-12-17
 */
export default class QuickQuoteWizard extends LightningElement {

    // ========== Public API Properties ==========

    @api recordId; // Case/Opportunity/Quote ID
    @api quoteId;
    @api accountId;
    @api flowMode = 'new';

    // ========== Tracked Properties ==========

    @track currentStep = 1;
    @track caseDescription = '';

    // Step 1: Product Selection
    @track selectedProduct = null;
    @track selectedFavoriteId = null;

    // Step 2: Service Details
    @track selectedAddress = '';
    @track customAddress = '';
    @track showCustomAddress = false;
    @track addressOptions = [];

    @track calculatedSlaDate = null;
    @track serviceDuration = 7; // Default 7 days
    @track selectedScheduleType = 'one-time';
    @track selectedFrequency = '';
    @track showRecurringOptions = false;

    @track accessInstructions = '';
    @track specialRequirements = '';
    @track showOptionalSection = false;

    // Step 3: Pricing
    @track pricingRequested = false;
    @track isLoadingPricing = false;
    @track pricingReceived = false;
    @track totalPrice = 0;
    @track pricingNote = '';
    @track vendorCount = 1;

    // Validation
    @track validationIssues = [];

    // State
    @track isSubmitting = false;
    @track quoteLineId = null;

    // ========== Wire Services ==========

    @wire(MessageContext)
    messageContext;

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.initializeAddressOptions();
        this.publishStepChange();
    }

    // ========== Computed Properties ==========

    // Step status
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }

    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { return this.currentStep === 4; }

    // Step completion
    get step1Complete() { return this.selectedProduct !== null; }
    get step2Complete() {
        return this.selectedAddress &&
               this.calculatedSlaDate &&
               this.selectedScheduleType;
    }
    get step3Complete() { return this.pricingReceived; }
    get step4Complete() { return false; }

    // Step classes
    get step1Class() {
        return this.getStepClass(1);
    }
    get step2Class() {
        return this.getStepClass(2);
    }
    get step3Class() {
        return this.getStepClass(3);
    }
    get step4Class() {
        return this.getStepClass(4);
    }

    // Progress
    get progressPercentage() {
        return (this.currentStep - 1) * 25 + (this.getStepProgress() * 25);
    }

    get progressBarStyle() {
        return `width: ${this.progressPercentage}%`;
    }

    get progressText() {
        const steps = ['Product Selection', 'Service Details', 'Preview & Pricing', 'Submit Quote'];
        return `Step ${this.currentStep} of 4: ${steps[this.currentStep - 1]}`;
    }

    // Navigation
    get canProceed() {
        switch (this.currentStep) {
            case 1: return this.step1Complete;
            case 2: return this.step2Complete && !this.hasValidationIssues;
            case 3: return this.step3Complete;
            case 4: return true;
            default: return false;
        }
    }

    get nextButtonLabel() {
        const labels = ['Next: Service Details', 'Next: Review & Price', 'Review Quote', 'Submit'];
        return labels[this.currentStep - 1] || 'Next';
    }

    // Validation
    get hasValidationIssues() {
        return this.validationIssues.length > 0;
    }

    // Section status
    get locationStatus() {
        return this.selectedAddress ? 'Complete' : 'Required';
    }
    get locationStatusVariant() {
        return this.selectedAddress ? 'success' : 'warning';
    }

    get dateStatus() {
        return this.calculatedSlaDate ? 'Complete' : 'In Progress';
    }
    get dateStatusVariant() {
        return this.calculatedSlaDate ? 'success' : 'warning';
    }

    get scheduleStatus() {
        return this.selectedScheduleType ? 'Complete' : 'Required';
    }
    get scheduleStatusVariant() {
        return this.selectedScheduleType ? 'success' : 'warning';
    }

    // Optional section
    get optionalSectionLabel() {
        return this.showOptionalSection ? 'Hide Optional Configuration' : 'Show Optional Configuration';
    }

    get optionalSectionIcon() {
        return this.showOptionalSection ? 'utility:chevronup' : 'utility:chevrondown';
    }

    // Schedule options
    get scheduleTypeOptions() {
        return [
            { label: 'One-Time Pickup', value: 'one-time' },
            { label: 'Recurring Service', value: 'recurring' },
            { label: 'On-Call', value: 'on-call' }
        ];
    }

    get frequencyOptions() {
        return [
            { label: 'Daily', value: 'daily' },
            { label: 'Weekly', value: 'weekly' },
            { label: 'Bi-Weekly', value: 'bi-weekly' },
            { label: 'Monthly', value: 'monthly' }
        ];
    }

    // Display values
    get displayAddress() {
        return this.showCustomAddress ? this.customAddress : this.selectedAddress;
    }

    get formattedStartDate() {
        if (!this.calculatedSlaDate) return '';
        const date = new Date(this.calculatedSlaDate);
        return date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
    }

    get scheduleDescription() {
        if (this.selectedScheduleType === 'one-time') {
            return 'One-time pickup';
        }
        if (this.selectedScheduleType === 'recurring' && this.selectedFrequency) {
            return `${this.capitalizeFirst(this.selectedFrequency)} service`;
        }
        if (this.selectedScheduleType === 'on-call') {
            return 'On-call service';
        }
        return this.selectedScheduleType;
    }

    get vendorPlural() {
        return this.vendorCount > 1 ? 's' : '';
    }

    // ========== Step Navigation ==========

    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.publishStepChange();
            this.scrollToTop();
        }
    }

    handleNext() {
        if (this.canProceed) {
            this.validateCurrentStep();

            if (!this.hasValidationIssues) {
                this.currentStep++;
                this.publishStepChange();
                this.scrollToTop();
            }
        }
    }

    handleGoToStep1() {
        if (this.currentStep > 1) {
            this.currentStep = 1;
            this.publishStepChange();
            this.scrollToTop();
        }
    }

    handleGoToStep2() {
        if (this.step1Complete && this.currentStep > 2) {
            this.currentStep = 2;
            this.publishStepChange();
            this.scrollToTop();
        }
    }

    handleGoToStep3() {
        if (this.step1Complete && this.step2Complete && this.currentStep > 3) {
            this.currentStep = 3;
            this.publishStepChange();
            this.scrollToTop();
        }
    }

    async handleSubmit() {
        this.isSubmitting = true;

        try {
            // Final submission logic
            const quoteData = this.collectQuoteData();

            // Publish completion event to parent
            this.dispatchEvent(new CustomEvent('wizardcomplete', {
                detail: quoteData
            }));

        } catch (error) {
            console.error('Submission error:', error);
            // Handle error
        } finally {
            this.isSubmitting = false;
        }
    }

    // ========== Step 1: Product Selection ==========

    handleProductSelect(event) {
        const { product, favoriteId } = event.detail;

        this.selectedProduct = {
            id: product.id,
            name: product.name,
            size: product.size,
            material: product.material,
            quantity: product.quantity,
            ownership: product.ownership
        };

        this.selectedFavoriteId = favoriteId;

        // Create quote line from favorite
        this.createQuoteLineFromFavorite(favoriteId);

        // Auto-advance to next step
        setTimeout(() => {
            this.handleNext();
        }, 500);
    }

    handleChangeProduct() {
        this.currentStep = 1;
        this.publishStepChange();
        this.scrollToTop();
    }

    async createQuoteLineFromFavorite(favoriteId) {
        try {
            const lineId = await createQuoteLine({
                favoriteId: favoriteId,
                quoteId: this.quoteId
            });

            this.quoteLineId = lineId;

            this.publishStateChange('lineAdded', {
                lineId: lineId,
                product: this.selectedProduct
            });

        } catch (error) {
            console.error('Error creating quote line:', error);
        }
    }

    // ========== Step 2: Service Details ==========

    initializeAddressOptions() {
        // In real implementation, fetch from Account
        this.addressOptions = [
            { label: 'Primary Location - 123 Main Street, Phoenix, AZ 85001', value: 'primary' },
            { label: 'Warehouse - 456 Industrial Blvd, Phoenix, AZ 85003', value: 'warehouse' },
            { label: 'Enter Different Address', value: 'custom' }
        ];
    }

    handleAddressChange(event) {
        this.selectedAddress = event.detail.value;
        this.showCustomAddress = (this.selectedAddress === 'custom');
        this.validateStep2();
    }

    handleCustomAddressChange(event) {
        this.customAddress = event.detail.value;
        this.validateStep2();
    }

    handleSlaCalculated(event) {
        this.calculatedSlaDate = event.detail.slaDate;
        this.validateStep2();
    }

    handleDateSelect(event) {
        this.calculatedSlaDate = event.detail.selectedDate;
        this.validateStep2();
    }

    handleDurationChange(event) {
        this.serviceDuration = event.detail.value;
    }

    handleScheduleTypeChange(event) {
        this.selectedScheduleType = event.detail.value;
        this.showRecurringOptions = (this.selectedScheduleType === 'recurring');
        this.validateStep2();
    }

    handleFrequencyChange(event) {
        this.selectedFrequency = event.detail.value;
    }

    handleAccessInstructionsChange(event) {
        this.accessInstructions = event.detail.value;
    }

    handleSpecialRequirementsChange(event) {
        this.specialRequirements = event.detail.value;
    }

    toggleOptionalSection() {
        this.showOptionalSection = !this.showOptionalSection;
    }

    // ========== Step 3: Pricing ==========

    async handleGetPricing() {
        this.isLoadingPricing = true;
        this.pricingRequested = true;

        try {
            // Simulate pricing request
            await this.simulatePricingRequest();

            // In real implementation:
            // const result = await getPricing({ quoteId: this.quoteId });
            // this.totalPrice = result.totalPrice;
            // this.pricingNote = result.note;

            this.pricingReceived = true;
            this.pricingNote = 'Best value from Vendor A - includes all fees';

            this.publishStateChange('priced', {
                totalPrice: this.totalPrice,
                vendor: 'Vendor A'
            });

        } catch (error) {
            console.error('Pricing error:', error);
        } finally {
            this.isLoadingPricing = false;
        }
    }

    async simulatePricingRequest() {
        // Simulate API call delay
        return new Promise(resolve => {
            setTimeout(() => {
                this.totalPrice = 450 + (this.serviceDuration * 10);
                this.vendorCount = 3;
                resolve();
            }, 2000);
        });
    }

    // ========== Validation ==========

    validateCurrentStep() {
        switch (this.currentStep) {
            case 1:
                this.validateStep1();
                break;
            case 2:
                this.validateStep2();
                break;
            case 3:
                this.validateStep3();
                break;
            default:
                this.validationIssues = [];
        }
    }

    validateStep1() {
        this.validationIssues = [];
        if (!this.selectedProduct) {
            this.validationIssues.push({
                id: 'product',
                message: 'Please select a product or service'
            });
        }
    }

    validateStep2() {
        this.validationIssues = [];

        if (!this.selectedAddress) {
            this.validationIssues.push({
                id: 'address',
                message: 'Service address is required'
            });
        }

        if (this.showCustomAddress && !this.customAddress) {
            this.validationIssues.push({
                id: 'customAddress',
                message: 'Please enter the custom address'
            });
        }

        if (!this.calculatedSlaDate) {
            this.validationIssues.push({
                id: 'startDate',
                message: 'Service start date must be selected'
            });
        }

        if (!this.selectedScheduleType) {
            this.validationIssues.push({
                id: 'schedule',
                message: 'Service schedule type is required'
            });
        }

        if (this.showRecurringOptions && !this.selectedFrequency) {
            this.validationIssues.push({
                id: 'frequency',
                message: 'Frequency is required for recurring service'
            });
        }
    }

    validateStep3() {
        this.validationIssues = [];
        // Step 3 validation minimal - just check pricing received
    }

    // ========== Helper Methods ==========

    getStepClass(stepNumber) {
        const baseClass = 'wm-step';
        const classes = [baseClass];

        if (stepNumber === this.currentStep) {
            classes.push('wm-step-active');
        }

        if (stepNumber < this.currentStep) {
            classes.push('wm-step-complete');
        }

        if (stepNumber > this.currentStep) {
            classes.push('wm-step-incomplete');
        }

        return classes.join(' ');
    }

    getStepProgress() {
        switch (this.currentStep) {
            case 1:
                return this.selectedProduct ? 1 : 0;
            case 2:
                let progress = 0;
                if (this.selectedAddress) progress += 0.33;
                if (this.calculatedSlaDate) progress += 0.33;
                if (this.selectedScheduleType) progress += 0.34;
                return progress;
            case 3:
                return this.pricingReceived ? 1 : (this.pricingRequested ? 0.5 : 0);
            case 4:
                return 1;
            default:
                return 0;
        }
    }

    collectQuoteData() {
        return {
            quoteId: this.quoteId,
            quoteLineId: this.quoteLineId,
            quoteNumber: 'QUO-' + Date.now(),
            product: this.selectedProduct,
            address: this.displayAddress,
            startDate: this.calculatedSlaDate,
            duration: this.serviceDuration,
            scheduleType: this.selectedScheduleType,
            frequency: this.selectedFrequency,
            totalPrice: this.totalPrice,
            accessInstructions: this.accessInstructions,
            specialRequirements: this.specialRequirements
        };
    }

    capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    scrollToTop() {
        const container = this.template.querySelector('.wm-wizard-content');
        if (container) {
            container.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    // ========== Message Service ==========

    publishStepChange() {
        this.dispatchEvent(new CustomEvent('wizardstep', {
            detail: {
                step: this.currentStep,
                data: { autoSave: true }
            }
        }));

        this.publishStateChange('stepChanged', {
            step: this.currentStep
        });
    }

    publishStateChange(action, payload) {
        const message = {
            quoteId: this.quoteId,
            action: action,
            payload: payload,
            source: 'quickQuoteWizard'
        };

        publish(this.messageContext, QUOTE_STATE_CHANNEL, message);
    }
}
