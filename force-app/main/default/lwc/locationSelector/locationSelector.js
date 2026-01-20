import { LightningElement, api, track, wire } from 'lwc';

// Apex imports - Location services
import searchLocations from '@salesforce/apex/LocationController.searchLocations';
import getRecentLocations from '@salesforce/apex/LocationController.getRecentLocations';
import validateServiceArea from '@salesforce/apex/LocationController.validateServiceArea';
import createLocation from '@salesforce/apex/LocationController.createLocation';

// US States for dropdown
const US_STATES = [
    { label: 'Alabama', value: 'AL' },
    { label: 'Alaska', value: 'AK' },
    { label: 'Arizona', value: 'AZ' },
    { label: 'Arkansas', value: 'AR' },
    { label: 'California', value: 'CA' },
    { label: 'Colorado', value: 'CO' },
    { label: 'Connecticut', value: 'CT' },
    { label: 'Delaware', value: 'DE' },
    { label: 'Florida', value: 'FL' },
    { label: 'Georgia', value: 'GA' },
    { label: 'Hawaii', value: 'HI' },
    { label: 'Idaho', value: 'ID' },
    { label: 'Illinois', value: 'IL' },
    { label: 'Indiana', value: 'IN' },
    { label: 'Iowa', value: 'IA' },
    { label: 'Kansas', value: 'KS' },
    { label: 'Kentucky', value: 'KY' },
    { label: 'Louisiana', value: 'LA' },
    { label: 'Maine', value: 'ME' },
    { label: 'Maryland', value: 'MD' },
    { label: 'Massachusetts', value: 'MA' },
    { label: 'Michigan', value: 'MI' },
    { label: 'Minnesota', value: 'MN' },
    { label: 'Mississippi', value: 'MS' },
    { label: 'Missouri', value: 'MO' },
    { label: 'Montana', value: 'MT' },
    { label: 'Nebraska', value: 'NE' },
    { label: 'Nevada', value: 'NV' },
    { label: 'New Hampshire', value: 'NH' },
    { label: 'New Jersey', value: 'NJ' },
    { label: 'New Mexico', value: 'NM' },
    { label: 'New York', value: 'NY' },
    { label: 'North Carolina', value: 'NC' },
    { label: 'North Dakota', value: 'ND' },
    { label: 'Ohio', value: 'OH' },
    { label: 'Oklahoma', value: 'OK' },
    { label: 'Oregon', value: 'OR' },
    { label: 'Pennsylvania', value: 'PA' },
    { label: 'Rhode Island', value: 'RI' },
    { label: 'South Carolina', value: 'SC' },
    { label: 'South Dakota', value: 'SD' },
    { label: 'Tennessee', value: 'TN' },
    { label: 'Texas', value: 'TX' },
    { label: 'Utah', value: 'UT' },
    { label: 'Vermont', value: 'VT' },
    { label: 'Virginia', value: 'VA' },
    { label: 'Washington', value: 'WA' },
    { label: 'West Virginia', value: 'WV' },
    { label: 'Wisconsin', value: 'WI' },
    { label: 'Wyoming', value: 'WY' }
];

/**
 * @description Location Selector for Quick Quote Wizard Step 2
 * Provides search, recent locations, and manual entry options
 * Validates service area coverage
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class LocationSelector extends LightningElement {

    // ========== Public API Properties ==========

    @api accountId;
    @api preSelectedLocationId;

    // ========== Tracked Properties ==========

    @track activeTab = 'search';

    // Search tab
    @track searchQuery = '';
    @track searchResults = [];
    @track showNoResults = false;

    // Recent tab
    @track recentLocations = [];

    // Manual entry tab
    @track manualLocationName = '';
    @track manualStreet = '';
    @track manualStreet2 = '';
    @track manualCity = '';
    @track manualState = '';
    @track manualZipCode = '';
    @track showManualValidation = false;
    @track isValidatingManual = false;
    @track manualAddressValid = false;

    // Selected location
    @track selectedLocation = null;
    @track accessInstructions = '';
    @track showAccessInstructions = false;

    // State management
    @track hasError = false;
    @track errorMessage = '';

    // ========== Computed Properties ==========

    get stateOptions() {
        return US_STATES;
    }

    get hasSearchResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get isSearchDisabled() {
        return !this.searchQuery || this.searchQuery.trim().length < 3;
    }

    get hasRecentLocations() {
        return this.recentLocations && this.recentLocations.length > 0;
    }

    get hasSelectedLocation() {
        return this.selectedLocation !== null;
    }

    get isManualValidateDisabled() {
        return !this.manualStreet || !this.manualCity || !this.manualState || !this.manualZipCode;
    }

    get isManualUseDisabled() {
        return this.isManualValidateDisabled || !this.showManualValidation;
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.loadRecentLocations();

        // If pre-selected location ID provided, load it
        if (this.preSelectedLocationId) {
            this.loadPreSelectedLocation();
        }
    }

    // ========== Data Loading ==========

    async loadRecentLocations() {
        try {
            const locations = await getRecentLocations({
                accountId: this.accountId,
                limitCount: 5
            });

            this.recentLocations = locations.map(loc => ({
                id: loc.Id,
                name: loc.Name,
                formattedAddress: this.formatAddress(loc),
                lastUsedDate: this.formatDate(loc.Last_Used__c),
                accountName: loc.Account__r ? loc.Account__r.Name : null,
                street: loc.Street__c,
                city: loc.City__c,
                state: loc.State__c,
                zipCode: loc.Postal_Code__c,
                timezone: loc.Timezone__c,
                isServiceable: loc.Is_Serviceable__c
            }));

        } catch (error) {
            console.warn('Could not load recent locations:', error);
            // Not a fatal error - user can still search or enter manually
        }
    }

    async loadPreSelectedLocation() {
        // In real implementation, fetch location by ID
        // For now, check if it's in recent locations
        const location = this.recentLocations.find(loc => loc.id === this.preSelectedLocationId);
        if (location) {
            this.selectLocation(location);
        }
    }

    // ========== Search Tab Handlers ==========

    handleSearchQueryChange(event) {
        this.searchQuery = event.target.value;
        this.showNoResults = false;
    }

    async handleSearch() {
        if (this.isSearchDisabled) return;

        try {
            const results = await searchLocations({
                searchTerm: this.searchQuery,
                accountId: this.accountId
            });

            if (results && results.length > 0) {
                this.searchResults = results.map(loc => ({
                    id: loc.Id || this.generateTempId(),
                    formattedAddress: this.formatAddress(loc),
                    street: loc.Street__c,
                    city: loc.City__c,
                    state: loc.State__c,
                    zipCode: loc.Postal_Code__c,
                    timezone: loc.Timezone__c,
                    isServiceable: loc.Is_Serviceable__c,
                    distance: loc.Distance__c ? `${loc.Distance__c} mi` : ''
                }));

                this.showNoResults = false;
            } else {
                this.searchResults = [];
                this.showNoResults = true;
            }

        } catch (error) {
            console.error('Search error:', error);
            this.hasError = true;
            this.errorMessage = this.parseErrorMessage(error);
        }
    }

    handleSelectSearchResult(event) {
        const locationId = event.currentTarget.dataset.locationId;
        const location = this.searchResults.find(loc => loc.id === locationId);

        if (location) {
            this.selectLocation(location);
        }
    }

    handleSwitchToManual() {
        this.activeTab = 'manual';
    }

    // ========== Recent Tab Handlers ==========

    handleSelectRecent(event) {
        const locationId = event.currentTarget.dataset.locationId;
        const location = this.recentLocations.find(loc => loc.id === locationId);

        if (location) {
            this.selectLocation(location);
        }
    }

    // ========== Manual Entry Tab Handlers ==========

    handleManualLocationNameChange(event) {
        this.manualLocationName = event.target.value;
    }

    handleManualStreetChange(event) {
        this.manualStreet = event.target.value;
        this.showManualValidation = false;
    }

    handleManualStreet2Change(event) {
        this.manualStreet2 = event.target.value;
    }

    handleManualCityChange(event) {
        this.manualCity = event.target.value;
        this.showManualValidation = false;
    }

    handleManualStateChange(event) {
        this.manualState = event.detail.value;
        this.showManualValidation = false;
    }

    handleManualZipCodeChange(event) {
        this.manualZipCode = event.target.value;
        this.showManualValidation = false;
    }

    async handleValidateManual() {
        if (this.isManualValidateDisabled) return;

        this.isValidatingManual = true;
        this.showManualValidation = true;

        try {
            const address = {
                street: this.manualStreet,
                city: this.manualCity,
                state: this.manualState,
                zipCode: this.manualZipCode
            };

            const validationResult = await validateServiceArea({ address });

            this.manualAddressValid = validationResult.isServiceable;

        } catch (error) {
            console.error('Validation error:', error);
            this.manualAddressValid = false;
        } finally {
            this.isValidatingManual = false;
        }
    }

    async handleUseManualAddress() {
        if (this.isManualUseDisabled) return;

        try {
            // Create location record
            const newLocation = await createLocation({
                accountId: this.accountId,
                locationName: this.manualLocationName || `${this.manualStreet}, ${this.manualCity}`,
                street: this.manualStreet,
                street2: this.manualStreet2,
                city: this.manualCity,
                state: this.manualState,
                zipCode: this.manualZipCode,
                isServiceable: this.manualAddressValid
            });

            // Select the newly created location
            const location = {
                id: newLocation.Id,
                name: this.manualLocationName,
                formattedAddress: this.formatManualAddress(),
                street: this.manualStreet,
                city: this.manualCity,
                state: this.manualState,
                zipCode: this.manualZipCode,
                timezone: newLocation.Timezone__c,
                isServiceable: this.manualAddressValid
            };

            this.selectLocation(location);

            // Clear manual form
            this.clearManualForm();

        } catch (error) {
            console.error('Error creating location:', error);
            this.hasError = true;
            this.errorMessage = 'Unable to save location. Please try again.';
        }
    }

    // ========== Selected Location Handlers ==========

    handleChangeLocation() {
        this.selectedLocation = null;
        this.accessInstructions = '';
        this.showAccessInstructions = false;

        // Dispatch event to parent
        this.dispatchLocationChange(null);
    }

    handleToggleAccessInstructions() {
        this.showAccessInstructions = !this.showAccessInstructions;
    }

    handleAccessInstructionsChange(event) {
        this.accessInstructions = event.target.value;

        // Update location with access instructions
        if (this.selectedLocation) {
            this.selectedLocation.accessInstructions = this.accessInstructions;
            this.dispatchLocationChange(this.selectedLocation);
        }
    }

    // ========== Helper Methods ==========

    selectLocation(location) {
        this.selectedLocation = {
            ...location,
            accessInstructions: this.accessInstructions
        };

        // Dispatch event to parent wizard
        this.dispatchLocationChange(this.selectedLocation);
    }

    dispatchLocationChange(location) {
        this.dispatchEvent(new CustomEvent('locationselect', {
            detail: {
                location: location,
                locationId: location ? location.id : null,
                formattedAddress: location ? location.formattedAddress : null,
                isServiceable: location ? location.isServiceable : null,
                timezone: location ? location.timezone : null,
                accessInstructions: location ? location.accessInstructions : null
            }
        }));
    }

    formatAddress(location) {
        const parts = [];

        if (location.Street__c) parts.push(location.Street__c);
        if (location.City__c) parts.push(location.City__c);
        if (location.State__c) parts.push(location.State__c);
        if (location.Postal_Code__c) parts.push(location.Postal_Code__c);

        return parts.join(', ');
    }

    formatManualAddress() {
        const parts = [];

        if (this.manualStreet) parts.push(this.manualStreet);
        if (this.manualCity) parts.push(this.manualCity);
        if (this.manualState) parts.push(this.manualState);
        if (this.manualZipCode) parts.push(this.manualZipCode);

        return parts.join(', ');
    }

    formatDate(dateValue) {
        if (!dateValue) return '';

        const date = new Date(dateValue);
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    clearManualForm() {
        this.manualLocationName = '';
        this.manualStreet = '';
        this.manualStreet2 = '';
        this.manualCity = '';
        this.manualState = '';
        this.manualZipCode = '';
        this.showManualValidation = false;
        this.manualAddressValid = false;
    }

    generateTempId() {
        return 'temp-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }

    parseErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }

        if (error.message) {
            return error.message;
        }

        return 'An unexpected error occurred. Please try again.';
    }

    handleRetry() {
        this.hasError = false;
        this.errorMessage = '';
        this.loadRecentLocations();
    }
}
