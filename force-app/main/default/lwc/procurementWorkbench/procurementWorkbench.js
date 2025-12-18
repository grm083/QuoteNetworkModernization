import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Apex imports
import getQuoteWithLines from '@salesforce/apex/QuoteProcurementController.getQuoteWithLines';
import saveQuoteLines from '@salesforce/apex/QuoteProcurementController.saveQuoteLines';
import validateQuoteLines from '@salesforce/apex/QuoteProcurementController.validateQuoteLines';
import transitionToPricing from '@salesforce/apex/QuoteProcurementController.transitionToPricing';

/**
 * @description Procurement Workbench - Main interface for Procure Service phase
 * Allows bulk editing of vendor assignments, costs, and MAS fields
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class ProcurementWorkbench extends LightningElement {

    // ========== Public API Properties ==========

    @api quoteId;

    // ========== Tracked Properties ==========

    // Quote data
    @track quoteNumber = '';
    @track quoteStatus = 'Procure Service';
    @track customerName = '';
    @track serviceLocation = '';
    @track primaryComponent = '';
    @track wasteStream = '';
    @track serviceDate = null;
    @track dueTime = null;
    @track locationId = '';

    // Quote lines
    @track quoteLines = [];
    @track selectedLine = null;
    @track allLinesSelected = false;
    @track filterOption = 'all';

    // UI state
    @track showBulkVendorModal = false;
    @track showUploadModal = false;
    @track isSaving = false;
    @track lastSavedTime = '';

    // Validation
    @track validationErrors = [];

    // Wire result for refresh
    wiredQuoteResult;

    // ========== Cost/UOM Options ==========

    get costModelOptions() {
        return [
            { label: 'Standard', value: 'STD' },
            { label: 'Stepped', value: 'STP' },
            { label: 'Rebate', value: 'REB' }
        ];
    }

    get costUOMOptions() {
        return [
            { label: 'Per Service', value: 'Per Service' },
            { label: 'Per Ton', value: 'Per Ton' },
            { label: 'Per Haul', value: 'Per Haul' },
            { label: 'Per Month', value: 'Per Month' },
            { label: 'One Time', value: 'One Time' }
        ];
    }

    get filterOptions() {
        return [
            { label: 'All Lines', value: 'all' },
            { label: 'Incomplete Only', value: 'incomplete' },
            { label: 'Complete Only', value: 'complete' },
            { label: 'With Errors', value: 'errors' }
        ];
    }

    // ========== Computed Properties - Quote Overview ==========

    get serviceDateFormatted() {
        if (!this.serviceDate) return '';
        const date = new Date(this.serviceDate);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get dueTimeFormatted() {
        if (!this.dueTime) return '';
        const now = new Date();
        const due = new Date(this.dueTime);
        const diffMs = due - now;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));

        if (diffHours < 0) return 'Overdue';
        if (diffHours === 0) return '<1 hour';
        return `${diffHours} hours`;
    }

    get totalLines() {
        return this.quoteLines.length;
    }

    get completeLines() {
        return this.quoteLines.filter(line => line.isValid).length;
    }

    get incompleteLines() {
        return this.totalLines - this.completeLines;
    }

    get completionPercentage() {
        if (this.totalLines === 0) return 0;
        return Math.round((this.completeLines / this.totalLines) * 100);
    }

    // ========== Computed Properties - Grid ==========

    get hasSelectedLine() {
        return this.selectedLine !== null;
    }

    get selectedLineCount() {
        return this.quoteLines.filter(line => line.selected).length;
    }

    get noBulkSelection() {
        return this.selectedLineCount === 0;
    }

    get selectedLineRequiresMAS() {
        if (!this.selectedLine) return false;
        return this.isWMVendor(this.selectedLine.vendorId);
    }

    // ========== Computed Properties - Validation ==========

    get hasValidationErrors() {
        return this.validationErrors && this.validationErrors.length > 0;
    }

    get validationErrorCount() {
        return this.validationErrors.length;
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.loadQuoteData();
    }

    // ========== Wire - Get Quote Data ==========

    @wire(getQuoteWithLines, { quoteId: '$quoteId' })
    wiredQuote(result) {
        this.wiredQuoteResult = result;

        if (result.data) {
            this.processQuoteData(result.data);
        } else if (result.error) {
            console.error('Error loading quote:', result.error);
            this.showToast('Error', 'Unable to load quote data', 'error');
        }
    }

    // ========== Data Loading ==========

    loadQuoteData() {
        // Wire adapter will handle loading
        this.lastSavedTime = 'Loading...';
    }

    processQuoteData(quoteData) {
        // Quote header
        this.quoteNumber = quoteData.Name || '';
        this.quoteStatus = quoteData.SBQQ__Status__c || 'Procure Service';
        this.customerName = quoteData.SBQQ__Account__r?.Name || '';
        this.serviceLocation = this.formatLocation(quoteData);
        this.primaryComponent = quoteData.Primary_Component__c || '';
        this.wasteStream = quoteData.Waste_Stream__c || '';
        this.serviceDate = quoteData.SBQQ__StartDate__c;
        this.dueTime = quoteData.Due_Date_Time__c;
        this.locationId = quoteData.Location__c;

        // Quote lines
        this.quoteLines = (quoteData.SBQQ__LineItems__r || []).map((line, index) => this.processQuoteLine(line, index));

        // Update last saved time
        this.lastSavedTime = this.formatLastSaved(quoteData.LastModifiedDate);

        // Run initial validation
        this.validateAllLines();
    }

    processQuoteLine(line, index) {
        const hasVendor = line.Vendor__c !== null;
        const hasCost = line.SBQQ__UnitCost__c !== null && line.SBQQ__UnitCost__c !== undefined;
        const masComplete = this.checkMASComplete(line);
        const vendorScore = line.Vendor__r?.VendorScore__c;

        return {
            id: line.Id,
            lineNumber: index + 1,
            serviceName: line.SBQQ__ProductName__c || '',
            serviceDetail: line.SBQQ__Description__c || '',
            frequency: this.formatFrequency(line),

            // Vendor
            vendorId: line.Vendor__c,
            vendorName: line.Vendor__r?.Name || '',
            hasVendor: hasVendor,
            vendorScore: vendorScore,
            hasScore: vendorScore !== null && vendorScore !== undefined,
            scoreClass: this.getScoreClass(vendorScore),

            // Cost
            unitCost: line.SBQQ__UnitCost__c,
            hasCost: hasCost,
            formattedCost: hasCost ? this.formatCurrency(line.SBQQ__UnitCost__c) : '',
            costModel: line.CostModelType__c || 'STD',
            costUOM: line.Cost_Unit_of_Measure__c || '',
            commitDate: line.Vendor_Commit_Date__c,

            // MAS
            masComplete: masComplete,
            masLibrary: line.MASLibrary__c,
            masCompany: line.MASCompany__c,

            // UI state
            selected: false,
            isValid: false,
            validationMessage: '',
            rowClass: 'wm-grid-row',

            // Original line data
            _original: { ...line }
        };
    }

    // ========== Grid Event Handlers ==========

    handleSelectAll(event) {
        this.allLinesSelected = event.target.checked;
        this.quoteLines = this.quoteLines.map(line => ({
            ...line,
            selected: this.allLinesSelected
        }));
    }

    handleLineSelect(event) {
        const lineId = event.target.dataset.lineId;
        const checked = event.target.checked;

        this.quoteLines = this.quoteLines.map(line => {
            if (line.id === lineId) {
                return { ...line, selected: checked };
            }
            return line;
        });

        // Update select all checkbox
        this.allLinesSelected = this.quoteLines.every(line => line.selected);
    }

    handleLineClick(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const clickedLine = this.quoteLines.find(line => line.id === lineId);

        if (clickedLine) {
            this.selectedLine = { ...clickedLine };
        }
    }

    handleCloseDetails() {
        this.selectedLine = null;
    }

    handleFilterChange(event) {
        this.filterOption = event.detail.value;
        this.applyFilter();
    }

    applyFilter() {
        // Filter logic would be implemented here
        // For now, showing all lines
    }

    // ========== Cost Input Handlers ==========

    handleCostChange(event) {
        const lineId = event.target.dataset.lineId;
        const newCost = parseFloat(event.target.value);

        this.updateQuoteLine(lineId, { unitCost: newCost });
    }

    handleCostModelChange(event) {
        this.selectedLine.costModel = event.detail.value;
    }

    handleCostUOMChange(event) {
        this.selectedLine.costUOM = event.detail.value;
    }

    handleUnitCostChange(event) {
        this.selectedLine.unitCost = parseFloat(event.target.value);
    }

    handleCommitDateChange(event) {
        this.selectedLine.commitDate = event.target.value;
    }

    // ========== Vendor Selection Handlers ==========

    handleSelectVendor(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const clickedLine = this.quoteLines.find(line => line.id === lineId);

        if (clickedLine) {
            this.selectedLine = { ...clickedLine };
        }
    }

    handleVendorSelected(event) {
        const vendorData = event.detail;

        if (this.selectedLine) {
            this.selectedLine.vendorId = vendorData.vendorId;
            this.selectedLine.vendorName = vendorData.vendorName;
            this.selectedLine.vendorScore = vendorData.vendorScore;
            this.selectedLine.hasVendor = true;
            this.selectedLine.hasScore = true;
            this.selectedLine.scoreClass = this.getScoreClass(vendorData.vendorScore);

            // Auto-populate MAS if WM vendor
            if (this.isWMVendor(vendorData.vendorId)) {
                this.autoPopulateMAS(this.selectedLine.id, vendorData.vendorId);
            }
        }
    }

    // ========== MAS Configuration Handlers ==========

    handleConfigureMAS(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const clickedLine = this.quoteLines.find(line => line.id === lineId);

        if (clickedLine) {
            this.selectedLine = { ...clickedLine };
        }
    }

    handleMASUpdated(event) {
        const masData = event.detail;

        if (this.selectedLine) {
            this.selectedLine.masLibrary = masData.masLibrary;
            this.selectedLine.masCompany = masData.masCompany;
            this.selectedLine.masComplete = this.checkMASComplete(this.selectedLine);
        }
    }

    // ========== Line Save Handlers ==========

    handleCancelLineChanges() {
        this.selectedLine = null;
    }

    async handleSaveLine() {
        if (!this.selectedLine) return;

        await this.saveLineData(this.selectedLine);
        this.selectedLine = null;
    }

    async handleSaveAndNext() {
        if (!this.selectedLine) return;

        await this.saveLineData(this.selectedLine);

        // Find next incomplete line
        const nextLine = this.quoteLines.find(line => !line.isValid && line.lineNumber > this.selectedLine.lineNumber);

        if (nextLine) {
            this.selectedLine = { ...nextLine };
        } else {
            this.selectedLine = null;
            this.showToast('Success', 'All lines processed!', 'success');
        }
    }

    async saveLineData(lineData) {
        this.isSaving = true;

        try {
            // Build quote line record
            const quoteLine = {
                Id: lineData.id,
                Vendor__c: lineData.vendorId,
                SBQQ__UnitCost__c: lineData.unitCost,
                CostModelType__c: lineData.costModel,
                Cost_Unit_of_Measure__c: lineData.costUOM,
                Vendor_Commit_Date__c: lineData.commitDate,
                MASLibrary__c: lineData.masLibrary,
                MASCompany__c: lineData.masCompany
            };

            await saveQuoteLines({
                quoteLines: [quoteLine]
            });

            // Update local data
            this.updateQuoteLine(lineData.id, lineData);

            // Refresh from server
            await refreshApex(this.wiredQuoteResult);

            this.showToast('Success', 'Line saved successfully', 'success');

        } catch (error) {
            console.error('Error saving line:', error);
            this.showToast('Error', 'Failed to save line: ' + this.parseErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // ========== Bulk Action Handlers ==========

    handleBulkVendor() {
        this.showBulkVendorModal = true;
    }

    handleCloseBulkVendorModal() {
        this.showBulkVendorModal = false;
    }

    handleBulkVendorSelected(event) {
        const vendorData = event.detail;
        const selectedLines = this.quoteLines.filter(line => line.selected);

        selectedLines.forEach(line => {
            line.vendorId = vendorData.vendorId;
            line.vendorName = vendorData.vendorName;
            line.vendorScore = vendorData.vendorScore;
            line.hasVendor = true;
        });

        this.showBulkVendorModal = false;
        this.showToast('Success', `Vendor applied to ${selectedLines.length} lines`, 'success');
    }

    handleBulkUpload() {
        this.showUploadModal = true;
    }

    handleCloseUploadModal() {
        this.showUploadModal = false;
    }

    handleUploadComplete(event) {
        const uploadResults = event.detail;

        this.showUploadModal = false;
        this.showToast('Success', `Uploaded costs for ${uploadResults.successCount} lines`, 'success');

        // Refresh data
        refreshApex(this.wiredQuoteResult);
    }

    handleBulkMAS() {
        const selectedLines = this.quoteLines.filter(line => line.selected);

        selectedLines.forEach(line => {
            if (this.isWMVendor(line.vendorId)) {
                this.autoPopulateMAS(line.id, line.vendorId);
            }
        });

        this.showToast('Success', `MAS configuration applied to ${selectedLines.length} lines`, 'success');
    }

    async handleValidateAll() {
        try {
            const lineIds = this.quoteLines.map(line => line.id);

            const results = await validateQuoteLines({
                quoteLineIds: lineIds
            });

            this.processValidationResults(results);

        } catch (error) {
            console.error('Validation error:', error);
            this.showToast('Error', 'Validation failed: ' + this.parseErrorMessage(error), 'error');
        }
    }

    async validateAllLines() {
        await this.handleValidateAll();
    }

    processValidationResults(results) {
        this.validationErrors = [];

        results.forEach(result => {
            const line = this.quoteLines.find(l => l.id === result.lineId);

            if (line) {
                line.isValid = result.isValid;
                line.validationMessage = result.errorMessage || '';
                line.rowClass = result.isValid ? 'wm-grid-row' : 'wm-grid-row wm-row-error';

                if (!result.isValid) {
                    this.validationErrors.push({
                        lineId: result.lineId,
                        lineNumber: line.lineNumber,
                        message: result.errorMessage
                    });
                }
            }
        });
    }

    handleFixValidation(event) {
        const lineId = event.currentTarget.dataset.lineId;
        const line = this.quoteLines.find(l => l.id === lineId);

        if (line) {
            this.selectedLine = { ...line };
        }
    }

    // ========== Save & Complete Handlers ==========

    async handleSaveProgress() {
        await this.saveAllLines();
    }

    async saveAllLines() {
        this.isSaving = true;

        try {
            const linesToSave = this.quoteLines.map(line => ({
                Id: line.id,
                Vendor__c: line.vendorId,
                SBQQ__UnitCost__c: line.unitCost,
                CostModelType__c: line.costModel,
                Cost_Unit_of_Measure__c: line.costUOM,
                Vendor_Commit_Date__c: line.commitDate
            }));

            await saveQuoteLines({ quoteLines: linesToSave });

            this.lastSavedTime = this.formatLastSaved(new Date());
            this.showToast('Success', 'Progress saved', 'success');

        } catch (error) {
            console.error('Error saving:', error);
            this.showToast('Error', 'Failed to save: ' + this.parseErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async handleCompleteProcurement() {
        if (this.hasValidationErrors) {
            this.showToast('Error', 'Please fix all validation errors before completing', 'error');
            return;
        }

        this.isSaving = true;

        try {
            await saveAllLines();

            await transitionToPricing({ quoteId: this.quoteId });

            this.showToast('Success', 'Procurement complete! Moving to pricing phase', 'success');

            // Dispatch event to parent
            this.dispatchEvent(new CustomEvent('procurementcomplete', {
                detail: { quoteId: this.quoteId }
            }));

        } catch (error) {
            console.error('Error completing procurement:', error);
            this.showToast('Error', 'Failed to complete: ' + this.parseErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    // ========== Add Line Handler ==========

    handleAddChargeLine() {
        // Dispatch event to open add line modal
        this.dispatchEvent(new CustomEvent('addchargeline', {
            detail: { quoteId: this.quoteId }
        }));
    }

    // ========== Navigation Handlers ==========

    handleBackToDraft() {
        this.dispatchEvent(new CustomEvent('backtodraft', {
            detail: { quoteId: this.quoteId }
        }));
    }

    // ========== Helper Methods ==========

    updateQuoteLine(lineId, updates) {
        this.quoteLines = this.quoteLines.map(line => {
            if (line.id === lineId) {
                return { ...line, ...updates };
            }
            return line;
        });
    }

    isWMVendor(vendorId) {
        // Check if vendor is WM US or WM Canada
        // In real implementation, check Vendor__r.Parent_Vendor_ID__c
        return false; // Placeholder
    }

    async autoPopulateMAS(lineId, vendorId) {
        // Auto-populate MAS fields from MAS_Setup_Detail__c
        // Implementation would query setup and update line
    }

    checkMASComplete(line) {
        if (!this.isWMVendor(line.Vendor__c)) {
            return true; // N/A for non-WM vendors
        }

        return line.MASLibrary__c && line.MASCompany__c;
    }

    formatLocation(quote) {
        if (!quote.Location__r) return '';

        const parts = [];
        if (quote.Location__r.Street__c) parts.push(quote.Location__r.Street__c);
        if (quote.Location__r.City__c) parts.push(quote.Location__r.City__c);
        if (quote.Location__r.State__c) parts.push(quote.Location__r.State__c);
        if (quote.Location__r.Postal_Code__c) parts.push(quote.Location__r.Postal_Code__c);

        return parts.join(', ');
    }

    formatFrequency(line) {
        const occType = line.Occurrence_Type__c;
        const freq = line.Schedule_Frequency__c;

        if (occType === 'OC') return 'On Call';
        if (freq === 'W') return 'Weekly';
        if (freq === 'M') return 'Monthly';
        if (freq === 'D') return 'Daily';

        return 'One Time';
    }

    getScoreClass(score) {
        if (!score) return 'wm-score';
        if (score >= 85) return 'wm-score wm-score-high';
        if (score >= 70) return 'wm-score wm-score-medium';
        return 'wm-score wm-score-low';
    }

    formatCurrency(amount) {
        if (amount === null || amount === undefined) return '$0.00';

        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(amount);
    }

    formatLastSaved(date) {
        if (!date) return 'Never';

        const now = new Date();
        const saved = new Date(date);
        const diffMs = now - saved;
        const diffMins = Math.floor(diffMs / (1000 * 60));

        if (diffMins < 1) return 'Just now';
        if (diffMins === 1) return '1 minute ago';
        if (diffMins < 60) return `${diffMins} minutes ago`;

        return saved.toLocaleTimeString('en-US', {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    }

    parseErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unexpected error occurred';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}
