import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import getMASSetupDetails from '@salesforce/apex/MASConfigurationController.getMASSetupDetails';
import validateMASFields from '@salesforce/apex/MASConfigurationController.validateMASFields';

// Quote Line Fields
import QUOTE_LINE_ID from '@salesforce/schema/SBQQ__QuoteLine__c.Id';
import MAS_LIBRARY from '@salesforce/schema/SBQQ__QuoteLine__c.MASLibrary__c';
import MAS_COMPANY from '@salesforce/schema/SBQQ__QuoteLine__c.MASCompany__c';
import MAS_ACCOUNT from '@salesforce/schema/SBQQ__QuoteLine__c.MASAccount__c';
import MAS_CUSTOMER_ID from '@salesforce/schema/SBQQ__QuoteLine__c.MASCustomerID__c';
import MAS_SERVICE_LINE from '@salesforce/schema/SBQQ__QuoteLine__c.MASServiceLine__c';
import VCR_CODE from '@salesforce/schema/SBQQ__QuoteLine__c.VCRCode__c';

/**
 * WM MAS Configuration Component
 * Manages the 22 MAS fields with auto-population and validation
 */
export default class MasConfiguration extends LightningElement {
    // Public Properties
    @api quoteLineId;
    @api vendorId;
    @api locationId;

    // Tracked Properties
    @track masFields = {};
    @track fieldErrors = {};
    @track validationErrors = [];
    @track showAdditionalFields = false;
    @track isLoading = false;
    @track errorMessage = '';
    @track hasChanges = false;

    // Private Properties
    originalMASFields = {};
    isWMVendor = false;
    canAutoPopulate = false;

    // Critical MAS fields (always visible)
    criticalFields = [
        'MASLibrary__c',
        'MASCompany__c',
        'MASAccount__c',
        'MASCustomerID__c',
        'MASServiceLine__c',
        'VCRCode__c'
    ];

    // All 22 MAS fields with metadata
    allMASFields = [
        { name: 'MASLibrary__c', label: 'MAS Library', type: 'text', required: true },
        { name: 'MASCompany__c', label: 'MAS Company', type: 'text', required: true },
        { name: 'MASAccount__c', label: 'MAS Account', type: 'number', required: true },
        { name: 'MASCustomerID__c', label: 'MAS Customer ID', type: 'text', required: true },
        { name: 'MASServiceLine__c', label: 'MAS Service Line', type: 'text', required: true },
        { name: 'VCRCode__c', label: 'VCR Code', type: 'text', required: true },
        { name: 'MASBillingCode__c', label: 'MAS Billing Code', type: 'text', required: false },
        { name: 'MASContractNumber__c', label: 'MAS Contract Number', type: 'text', required: false },
        { name: 'MASCostCenter__c', label: 'MAS Cost Center', type: 'text', required: false },
        { name: 'MASDivision__c', label: 'MAS Division', type: 'text', required: false },
        { name: 'MASEquipmentCode__c', label: 'MAS Equipment Code', type: 'text', required: false },
        { name: 'MASFrequencyCode__c', label: 'MAS Frequency Code', type: 'text', required: false },
        { name: 'MASHaulerCode__c', label: 'MAS Hauler Code', type: 'text', required: false },
        { name: 'MASItemNumber__c', label: 'MAS Item Number', type: 'text', required: false },
        { name: 'MASLocationCode__c', label: 'MAS Location Code', type: 'text', required: false },
        { name: 'MASPriceCode__c', label: 'MAS Price Code', type: 'text', required: false },
        { name: 'MASProductCode__c', label: 'MAS Product Code', type: 'text', required: false },
        { name: 'MASRegion__c', label: 'MAS Region', type: 'text', required: false },
        { name: 'MASRouteCode__c', label: 'MAS Route Code', type: 'text', required: false },
        { name: 'MASSalesRep__c', label: 'MAS Sales Rep', type: 'text', required: false },
        { name: 'MASServiceType__c', label: 'MAS Service Type', type: 'text', required: false },
        { name: 'MASTaxCode__c', label: 'MAS Tax Code', type: 'text', required: false }
    ];

    // Wire to Quote Line record
    @wire(getRecord, {
        recordId: '$quoteLineId',
        fields: [
            MAS_LIBRARY,
            MAS_COMPANY,
            MAS_ACCOUNT,
            MAS_CUSTOMER_ID,
            MAS_SERVICE_LINE,
            VCR_CODE
        ]
    })
    wiredQuoteLine({ data, error }) {
        if (data) {
            this.loadMASFieldsFromRecord(data);
        } else if (error) {
            this.errorMessage = 'Error loading MAS fields: ' + this.getErrorMessage(error);
        }
    }

    // Lifecycle Hooks
    connectedCallback() {
        this.checkAutoPopulateAvailability();
    }

    // Computed Properties
    get additionalMASFields() {
        return this.allMASFields
            .filter(field => !this.criticalFields.includes(field.name))
            .map(field => ({
                ...field,
                value: this.masFields[field.name] || '',
                error: this.fieldErrors[field.name] || null
            }));
    }

    get additionalFieldCount() {
        return this.additionalMASFields.length;
    }

    get expandIconName() {
        return this.showAdditionalFields ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hasValidationErrors() {
        return this.validationErrors.length > 0;
    }

    get getCriticalFieldClass() {
        return 'wm-critical-field';
    }

    // Event Handlers
    handleFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        this.masFields = {
            ...this.masFields,
            [fieldName]: value
        };

        // Clear field error on change
        if (this.fieldErrors[fieldName]) {
            this.fieldErrors = {
                ...this.fieldErrors,
                [fieldName]: null
            };
        }

        // Track changes
        this.hasChanges = this.detectChanges();

        // Fire change event
        this.dispatchChangeEvent();
    }

    toggleExpandedFields() {
        this.showAdditionalFields = !this.showAdditionalFields;
    }

    async handleAutoPopulate() {
        if (!this.vendorId || !this.locationId) {
            this.showToast('Warning', 'Vendor and location required for auto-populate', 'warning');
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        try {
            const setupDetails = await getMASSetupDetails({
                vendorId: this.vendorId,
                locationId: this.locationId
            });

            if (setupDetails) {
                this.populateMASFieldsFromSetup(setupDetails);
                this.showToast('Success', 'MAS fields auto-populated successfully', 'success');
            } else {
                this.showToast('Warning', 'No MAS setup found for this vendor/location combination', 'warning');
            }
        } catch (error) {
            this.errorMessage = 'Error auto-populating MAS fields: ' + this.getErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleValidateMAS() {
        this.isLoading = true;
        this.errorMessage = '';
        this.validationErrors = [];

        try {
            const result = await validateMASFields({
                quoteLineId: this.quoteLineId,
                masFields: this.masFields
            });

            if (result.isValid) {
                this.showToast('Success', 'MAS configuration is valid', 'success');
            } else {
                this.validationErrors = result.errors.map(err => ({
                    field: err.fieldName,
                    fieldLabel: this.getFieldLabel(err.fieldName),
                    message: err.message
                }));
                this.showToast('Warning', 'MAS validation found issues', 'warning');
            }
        } catch (error) {
            this.errorMessage = 'Error validating MAS fields: ' + this.getErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleSaveMAS() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            // Build fields object for update
            const fields = { Id: this.quoteLineId };
            Object.keys(this.masFields).forEach(fieldName => {
                fields[fieldName] = this.masFields[fieldName];
            });

            const recordInput = { fields };
            await updateRecord(recordInput);

            // Update original fields
            this.originalMASFields = { ...this.masFields };
            this.hasChanges = false;

            this.showToast('Success', 'MAS configuration saved successfully', 'success');

            // Fire update event
            this.dispatchUpdateEvent();
        } catch (error) {
            this.errorMessage = 'Error saving MAS fields: ' + this.getErrorMessage(error);
            this.showToast('Error', 'Failed to save MAS configuration', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleResetChanges() {
        this.masFields = { ...this.originalMASFields };
        this.fieldErrors = {};
        this.validationErrors = [];
        this.hasChanges = false;
        this.showToast('Info', 'Changes reset', 'info');
    }

    // Data Processing Methods
    loadMASFieldsFromRecord(record) {
        const fields = {};
        this.allMASFields.forEach(fieldDef => {
            const fieldValue = getFieldValue(record, fieldDef.name);
            if (fieldValue !== null && fieldValue !== undefined) {
                fields[fieldDef.name] = fieldValue;
            }
        });

        this.masFields = fields;
        this.originalMASFields = { ...fields };
        this.hasChanges = false;
    }

    populateMASFieldsFromSetup(setupDetails) {
        const updatedFields = { ...this.masFields };

        // Map setup detail fields to MAS fields
        if (setupDetails.MASLibrary__c) updatedFields.MASLibrary__c = setupDetails.MASLibrary__c;
        if (setupDetails.MASCompany__c) updatedFields.MASCompany__c = setupDetails.MASCompany__c;
        if (setupDetails.MASAccount__c) updatedFields.MASAccount__c = setupDetails.MASAccount__c;
        if (setupDetails.MASCustomerID__c) updatedFields.MASCustomerID__c = setupDetails.MASCustomerID__c;
        if (setupDetails.MASServiceLine__c) updatedFields.MASServiceLine__c = setupDetails.MASServiceLine__c;
        if (setupDetails.VCRCode__c) updatedFields.VCRCode__c = setupDetails.VCRCode__c;
        if (setupDetails.MASBillingCode__c) updatedFields.MASBillingCode__c = setupDetails.MASBillingCode__c;
        if (setupDetails.MASContractNumber__c) updatedFields.MASContractNumber__c = setupDetails.MASContractNumber__c;
        if (setupDetails.MASCostCenter__c) updatedFields.MASCostCenter__c = setupDetails.MASCostCenter__c;
        if (setupDetails.MASDivision__c) updatedFields.MASDivision__c = setupDetails.MASDivision__c;

        this.masFields = updatedFields;
        this.hasChanges = this.detectChanges();
        this.dispatchChangeEvent();
    }

    async checkAutoPopulateAvailability() {
        this.canAutoPopulate = !!(this.vendorId && this.locationId);

        // Check if vendor is WM vendor
        if (this.vendorId) {
            // This would typically check vendor record type or a field
            // For now, we'll assume WM vendors have specific naming or a field
            this.isWMVendor = true; // TODO: Implement actual check
        }
    }

    detectChanges() {
        return Object.keys(this.masFields).some(
            key => this.masFields[key] !== this.originalMASFields[key]
        );
    }

    getFieldLabel(fieldName) {
        const field = this.allMASFields.find(f => f.name === fieldName);
        return field ? field.label : fieldName;
    }

    // Event Dispatchers
    dispatchChangeEvent() {
        const changeEvent = new CustomEvent('maschange', {
            detail: {
                masFields: this.masFields,
                hasChanges: this.hasChanges
            }
        });
        this.dispatchEvent(changeEvent);
    }

    dispatchUpdateEvent() {
        const updateEvent = new CustomEvent('masupdate', {
            detail: {
                quoteLineId: this.quoteLineId,
                masFields: this.masFields
            }
        });
        this.dispatchEvent(updateEvent);
    }

    // Utility Methods
    getErrorMessage(error) {
        if (error.body) {
            if (error.body.message) {
                return error.body.message;
            }
            if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            }
        }
        return error.message || 'Unknown error';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
