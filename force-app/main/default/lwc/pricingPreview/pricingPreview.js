import { LightningElement, api, track } from 'lwc';

// Apex imports - Pricing services
import calculateQuotePricing from '@salesforce/apex/QuotePricingController.calculateQuotePricing';
import applyDiscounts from '@salesforce/apex/QuotePricingController.applyDiscounts';

/**
 * @description Pricing Preview for Quick Quote Wizard Step 3
 * Displays transparent pricing breakdown with multi-vendor comparison
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class PricingPreview extends LightningElement {

    // ========== Public API Properties ==========

    @api quoteId;
    @api quoteData; // Complete quote configuration from wizard

    // ========== Tracked Properties ==========

    @track isLoadingPricing = false;
    @track lineItems = [];
    @track discounts = [];

    // Quote info
    @track quoteNumber = '';
    @track quoteDate = new Date();
    @track quoteStatus = 'Draft';

    // Pricing totals
    @track subtotal = 0;
    @track totalDiscounts = 0;
    @track subtotalAfterDiscounts = 0;
    @track taxAmount = 0;
    @track taxRate = 0;
    @track total = 0;

    // UI State
    @track showSummaryDetails = false;
    @track showTransparency = false;
    @track expandedLineIds = [];

    // Transparency info
    @track hasEntitlementPricing = false;
    @track hasVolumeDiscount = false;
    @track volumeDiscountReason = '';
    @track serviceType = '';

    // Error handling
    @track hasError = false;
    @track errorMessage = '';

    // ========== Computed Properties - Quote Info ==========

    get formattedQuoteDate() {
        return this.quoteDate.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    // ========== Computed Properties - Pricing ==========

    get formattedSubtotal() {
        return this.formatCurrency(this.subtotal);
    }

    get formattedTotalDiscounts() {
        return this.formatCurrency(this.totalDiscounts);
    }

    get formattedSubtotalAfterDiscounts() {
        return this.formatCurrency(this.subtotalAfterDiscounts);
    }

    get formattedTax() {
        return this.formatCurrency(this.taxAmount);
    }

    get formattedTotal() {
        return this.formatCurrency(this.total);
    }

    get hasDiscounts() {
        return this.discounts && this.discounts.length > 0;
    }

    get hasTax() {
        return this.taxAmount > 0;
    }

    get hasRecurringServices() {
        return this.lineItems.some(line => line.isRecurring);
    }

    // ========== Computed Properties - UI State ==========

    get summaryDetailsIcon() {
        return this.showSummaryDetails ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get summaryDetailsLabel() {
        return this.showSummaryDetails ? 'Hide Details' : 'Show Details';
    }

    get volumeDiscountStepNumber() {
        return this.hasEntitlementPricing ? 3 : 2;
    }

    get finalStepNumber() {
        let step = 2;
        if (this.hasEntitlementPricing) step++;
        if (this.hasVolumeDiscount) step++;
        return step;
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.loadPricing();
    }

    // ========== Data Loading ==========

    async loadPricing() {
        this.isLoadingPricing = true;
        this.hasError = false;

        try {
            // Calculate pricing via Apex
            const pricingResult = await calculateQuotePricing({
                quoteId: this.quoteId,
                quoteData: JSON.stringify(this.quoteData)
            });

            this.processPricingResult(pricingResult);

            // Apply discounts
            await this.calculateDiscounts();

        } catch (error) {
            console.error('Pricing calculation error:', error);
            this.hasError = true;
            this.errorMessage = this.parseErrorMessage(error);
        } finally {
            this.isLoadingPricing = false;
        }
    }

    processPricingResult(result) {
        // Quote info
        this.quoteNumber = result.quoteNumber || 'Q-' + Date.now();
        this.quoteStatus = result.status || 'Draft';
        this.serviceType = result.serviceType || 'Waste Management';

        // Line items
        this.lineItems = result.lineItems.map((line, index) => ({
            id: line.id || `line-${index}`,
            productName: line.productName,
            productDescription: line.description,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            subtotal: line.quantity * line.unitPrice,
            discountAmount: line.discountAmount || 0,
            discountPercent: line.discountPercent || 0,
            total: line.total,

            // Formatting
            formattedUnitPrice: this.formatCurrency(line.unitPrice),
            formattedSubtotal: this.formatCurrency(line.quantity * line.unitPrice),
            formattedDiscount: this.formatCurrency(line.discountAmount || 0),
            formattedTotal: this.formatCurrency(line.total),
            formattedOriginalPrice: this.formatCurrency(line.quantity * line.unitPrice),

            // Discount info
            hasDiscount: line.discountAmount > 0,
            discountLabel: line.discountPercent > 0
                ? `Discount (${line.discountPercent}%)`
                : 'Discount',

            // Schedule info
            isRecurring: line.isRecurring || false,
            frequency: line.frequency,
            totalServices: line.totalServices,
            scheduleDescription: line.scheduleDescription,
            hasSchedule: !!line.scheduleDescription,

            // Location info
            locationAddress: line.locationAddress,
            hasLocation: !!line.locationAddress,

            // UI state
            showDetails: false,
            detailsIcon: 'utility:chevrondown',
            detailsLabel: 'Show Details'
        }));

        // Calculate totals
        this.calculateTotals();

        // Transparency info
        this.hasEntitlementPricing = result.hasContractPricing || false;
        this.hasVolumeDiscount = result.hasVolumeDiscount || false;
        this.volumeDiscountReason = result.volumeDiscountReason || 'recurring services';

        // Tax
        this.taxRate = result.taxRate || 0;
    }

    async calculateDiscounts() {
        try {
            const discountResult = await applyDiscounts({
                quoteId: this.quoteId,
                lineItems: JSON.stringify(this.lineItems.map(line => ({
                    id: line.id,
                    productId: line.productId,
                    quantity: line.quantity,
                    unitPrice: line.unitPrice
                })))
            });

            this.discounts = discountResult.map((discount, index) => ({
                id: `discount-${index}`,
                name: discount.name,
                amount: discount.amount,
                formattedAmount: this.formatCurrency(discount.amount)
            }));

            this.calculateTotals();

        } catch (error) {
            console.warn('Could not apply discounts:', error);
            // Not a fatal error - can proceed without discounts
        }
    }

    calculateTotals() {
        // Subtotal from line items
        this.subtotal = this.lineItems.reduce((sum, line) => sum + line.subtotal, 0);

        // Total line-level discounts
        const lineDiscounts = this.lineItems.reduce((sum, line) => sum + line.discountAmount, 0);

        // Total quote-level discounts
        const quoteDiscounts = this.discounts.reduce((sum, discount) => sum + discount.amount, 0);

        this.totalDiscounts = lineDiscounts + quoteDiscounts;

        // Subtotal after discounts
        this.subtotalAfterDiscounts = this.subtotal - this.totalDiscounts;

        // Tax calculation
        this.taxAmount = this.subtotalAfterDiscounts * (this.taxRate / 100);

        // Total
        this.total = this.subtotalAfterDiscounts + this.taxAmount;
    }

    // ========== Event Handlers - Line Items ==========

    handleToggleLineDetails(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const lineIndex = this.lineItems.findIndex(line => line.id === lineId);

        if (lineIndex !== -1) {
            const line = this.lineItems[lineIndex];
            const newShowDetails = !line.showDetails;

            // Update line item
            this.lineItems = this.lineItems.map((item, index) => {
                if (index === lineIndex) {
                    return {
                        ...item,
                        showDetails: newShowDetails,
                        detailsIcon: newShowDetails ? 'utility:chevronup' : 'utility:chevrondown',
                        detailsLabel: newShowDetails ? 'Hide Details' : 'Show Details'
                    };
                }
                return item;
            });
        }
    }

    // ========== Event Handlers - Summary ==========

    handleToggleSummaryDetails() {
        this.showSummaryDetails = !this.showSummaryDetails;
    }

    handleToggleTransparency() {
        this.showTransparency = !this.showTransparency;
    }

    // ========== Event Handlers - Actions ==========

    handleModifyQuote() {
        this.dispatchEvent(new CustomEvent('modifyquote', {
            detail: {
                action: 'modify',
                quoteId: this.quoteId
            }
        }));
    }

    handleAcceptPricing() {
        const pricingData = {
            quoteId: this.quoteId,
            lineItems: this.lineItems,
            subtotal: this.subtotal,
            totalDiscounts: this.totalDiscounts,
            taxAmount: this.taxAmount,
            total: this.total,
            formattedTotal: this.formattedTotal
        };

        this.dispatchEvent(new CustomEvent('acceptpricing', {
            detail: pricingData
        }));
    }

    handleRetry() {
        this.loadPricing();
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

        return 'An unexpected error occurred while calculating pricing. Please try again or contact support.';
    }
}
