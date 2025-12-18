import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * WM Cost Bulk Upload Component
 * CSV-based bulk cost entry with validation and preview
 */
export default class CostBulkUpload extends LightningElement {
    // Public Properties
    @api quoteId;
    @api quoteLines = [];

    // Tracked Properties
    @track previewData = [];
    @track validationErrors = [];
    @track isProcessing = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showSuccessMessage = false;
    @track uploadedFileName = '';
    @track uploadedFileSize = '';
    @track processingMessage = 'Processing CSV...';

    // Private Properties
    csvData = null;
    validRowCount = 0;
    errorRowCount = 0;
    warningRowCount = 0;

    // Cost Model Options
    costModelOptions = ['STD', 'STP', 'REB'];

    // CSV Template Headers
    csvHeaders = [
        'Line Number',
        'Service Name',
        'Frequency',
        'Unit Cost',
        'Cost Model',
        'Unit of Measure'
    ];

    // Computed Properties
    get hasPreviewData() {
        return this.previewData.length > 0 && !this.isProcessing;
    }

    get hasValidationErrors() {
        return this.validationErrors.length > 0;
    }

    get previewRowCount() {
        return this.previewData.length;
    }

    get cannotApply() {
        return this.isProcessing || this.errorRowCount > 0 || this.previewData.length === 0;
    }

    get applyButtonLabel() {
        if (this.errorRowCount > 0) {
            return 'Fix Errors to Apply';
        }
        return `Apply Costs to ${this.validRowCount} Lines`;
    }

    // Event Handlers
    handleDownloadTemplate() {
        try {
            const csvContent = this.generateCSVTemplate();
            this.downloadCSV(csvContent, `Quote_${this.quoteId}_Cost_Template.csv`);
            this.showToast('Success', 'Template downloaded successfully', 'success');
        } catch (error) {
            this.errorMessage = 'Error generating template: ' + error.message;
        }
    }

    async handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length === 0) return;

        const file = uploadedFiles[0];
        this.uploadedFileName = file.name;
        this.uploadedFileSize = this.formatFileSize(file.size);

        this.isProcessing = true;
        this.processingMessage = 'Reading CSV file...';
        this.errorMessage = '';
        this.showSuccessMessage = false;

        try {
            // Read file content
            const fileContent = await this.readFileContent(file);

            this.processingMessage = 'Parsing CSV data...';
            const parsedData = this.parseCSV(fileContent);

            this.processingMessage = 'Validating data...';
            const validatedData = this.validateCSVData(parsedData);

            this.previewData = validatedData;
            this.calculateStats();

            this.showToast('Success', 'CSV file processed successfully', 'success');
        } catch (error) {
            this.errorMessage = 'Error processing CSV: ' + error.message;
            this.clearPreview();
        } finally {
            this.isProcessing = false;
        }
    }

    handleClearFile() {
        this.uploadedFileName = '';
        this.uploadedFileSize = '';
        this.clearPreview();
    }

    handleCancelUpload() {
        this.clearPreview();
        this.uploadedFileName = '';
        this.uploadedFileSize = '';
        this.showSuccessMessage = false;
    }

    async handleApplyCosts() {
        if (this.errorRowCount > 0) {
            this.showToast('Error', 'Please fix all errors before applying costs', 'error');
            return;
        }

        this.isProcessing = true;
        this.processingMessage = 'Applying costs to quote lines...';
        this.errorMessage = '';

        try {
            // Fire custom event with cost data
            const costData = this.previewData
                .filter(row => row.isValid)
                .map(row => ({
                    lineNumber: row.lineNumber,
                    lineId: row.lineId,
                    unitCost: row.unitCost,
                    costModel: row.costModel,
                    unitOfMeasure: row.unitOfMeasure
                }));

            const applyEvent = new CustomEvent('costsapply', {
                detail: { costs: costData }
            });
            this.dispatchEvent(applyEvent);

            this.successMessage = `Successfully applied costs to ${costData.length} quote lines`;
            this.showSuccessMessage = true;

            // Clear preview after short delay
            setTimeout(() => {
                this.handleCancelUpload();
            }, 3000);

        } catch (error) {
            this.errorMessage = 'Error applying costs: ' + error.message;
        } finally {
            this.isProcessing = false;
        }
    }

    // CSV Generation
    generateCSVTemplate() {
        const rows = [this.csvHeaders.join(',')];

        this.quoteLines.forEach((line, index) => {
            const row = [
                index + 1, // Line Number
                `"${line.serviceName || ''}"`, // Service Name
                `"${line.frequency || ''}"`, // Frequency
                line.unitCost || '', // Unit Cost
                line.costModel || 'STD', // Cost Model
                `"${line.unitOfMeasure || 'Per Month'}"` // Unit of Measure
            ];
            rows.push(row.join(','));
        });

        return rows.join('\n');
    }

    downloadCSV(content, filename) {
        const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);

        link.setAttribute('href', url);
        link.setAttribute('download', filename);
        link.style.visibility = 'hidden';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        URL.revokeObjectURL(url);
    }

    // CSV Parsing
    async readFileContent(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsText(file);
        });
    }

    parseCSV(csvContent) {
        const lines = csvContent.split('\n').filter(line => line.trim());

        if (lines.length < 2) {
            throw new Error('CSV file is empty or invalid');
        }

        // Parse header
        const headers = this.parseCSVLine(lines[0]);

        // Validate headers
        this.validateHeaders(headers);

        // Parse data rows
        const data = [];
        for (let i = 1; i < lines.length; i++) {
            const values = this.parseCSVLine(lines[i]);
            if (values.length > 0) {
                const row = {};
                headers.forEach((header, index) => {
                    row[header] = values[index] || '';
                });
                data.push(row);
            }
        }

        return data;
    }

    parseCSVLine(line) {
        const result = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {
            const char = line[i];

            if (char === '"') {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                result.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }

        result.push(current.trim());
        return result;
    }

    validateHeaders(headers) {
        const requiredHeaders = ['Line Number', 'Unit Cost', 'Cost Model', 'Unit of Measure'];
        const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));

        if (missingHeaders.length > 0) {
            throw new Error(`Missing required columns: ${missingHeaders.join(', ')}`);
        }
    }

    // Data Validation
    validateCSVData(csvData) {
        this.validationErrors = [];
        const validatedData = [];

        csvData.forEach((row, index) => {
            const validatedRow = this.validateRow(row, index);
            validatedData.push(validatedRow);

            if (validatedRow.hasError) {
                this.validationErrors.push({
                    key: `error-${index}`,
                    lineNumber: validatedRow.lineNumber,
                    message: validatedRow.validationMessage
                });
            }
        });

        return validatedData;
    }

    validateRow(row, index) {
        const lineNumber = parseInt(row['Line Number'], 10);
        const unitCostStr = row['Unit Cost'];
        const costModel = row['Cost Model']?.toUpperCase();
        const unitOfMeasure = row['Unit of Measure'];

        const errors = [];
        const warnings = [];

        // Validate line number
        if (!lineNumber || lineNumber < 1 || lineNumber > this.quoteLines.length) {
            errors.push('Invalid line number');
        }

        // Get matching quote line
        const quoteLine = this.quoteLines[lineNumber - 1];
        const lineId = quoteLine?.id;

        // Validate unit cost
        const unitCost = parseFloat(unitCostStr);
        if (!unitCostStr || isNaN(unitCost)) {
            errors.push('Unit cost is required and must be a valid number');
        } else if (unitCost <= 0) {
            errors.push('Unit cost must be greater than 0');
        }

        // Validate cost model
        if (!costModel) {
            errors.push('Cost model is required');
        } else if (!this.costModelOptions.includes(costModel)) {
            errors.push(`Cost model must be one of: ${this.costModelOptions.join(', ')}`);
        }

        // Validate unit of measure
        if (!unitOfMeasure) {
            errors.push('Unit of Measure is required');
        }

        // Check for warnings
        if (quoteLine && quoteLine.unitCost && Math.abs(unitCost - quoteLine.unitCost) > unitCost * 0.5) {
            warnings.push('Cost differs significantly from current value');
        }

        const hasError = errors.length > 0;
        const hasWarning = warnings.length > 0 && !hasError;
        const isValid = !hasError && !hasWarning;

        return {
            lineNumber,
            lineId,
            serviceName: quoteLine?.serviceName || 'Unknown Service',
            unitCost,
            unitCostFormatted: this.formatCurrency(unitCost),
            costModel: costModel || '',
            unitOfMeasure: unitOfMeasure || '',
            isValid,
            hasError,
            hasWarning,
            validationMessage: errors.length > 0 ? errors[0] : (warnings.length > 0 ? warnings[0] : ''),
            rowClass: hasError ? 'wm-row-error' : (hasWarning ? 'wm-row-warning' : 'wm-row-valid'),
            messageClass: hasError ? 'wm-message-error' : (hasWarning ? 'wm-message-warning' : '')
        };
    }

    // Utility Methods
    calculateStats() {
        this.validRowCount = this.previewData.filter(row => row.isValid).length;
        this.errorRowCount = this.previewData.filter(row => row.hasError).length;
        this.warningRowCount = this.previewData.filter(row => row.hasWarning).length;
    }

    clearPreview() {
        this.previewData = [];
        this.validationErrors = [];
        this.validRowCount = 0;
        this.errorRowCount = 0;
        this.warningRowCount = 0;
    }

    formatCurrency(value) {
        if (!value && value !== 0) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
