import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchVendors from '@salesforce/apex/VendorSearchController.searchVendors';
import getLocationDetails from '@salesforce/apex/VendorSearchController.getLocationDetails';
import getHistoricalCosts from '@salesforce/apex/VendorSearchController.getHistoricalCosts';

/**
 * WM Vendor Search Component
 * Search and select vendors with scoring, proximity, and historical cost data
 */
export default class VendorSearch extends LightningElement {
    // Public Properties
    @api quoteId;
    @api lineId;
    @api locationId;

    // Tracked Properties
    @track searchTerm = '';
    @track vendors = [];
    @track selectedFilters = [];
    @track sortBy = 'score';
    @track isSearching = false;
    @track errorMessage = '';
    @track locationName = '';

    // Filter Options
    filterOptions = [
        { label: 'WM Vendors Only', value: 'wm_only' },
        { label: 'Show Nearby (50 miles)', value: 'nearby' },
        { label: 'Has Historical Data', value: 'has_history' },
        { label: 'High Score (≥85)', value: 'high_score' }
    ];

    // Sort Options
    sortOptions = [
        { label: 'Score (High to Low)', value: 'score' },
        { label: 'Distance (Near to Far)', value: 'distance' },
        { label: 'Name (A-Z)', value: 'name' },
        { label: 'Recent Activity', value: 'recent' }
    ];

    // Lifecycle Hooks
    connectedCallback() {
        this.loadLocationDetails();
        this.performInitialSearch();
    }

    // Computed Properties
    get hasResults() {
        return !this.isSearching && this.vendors.length > 0;
    }

    get showNoResults() {
        return !this.isSearching && this.vendors.length === 0 && this.searchTerm.length > 0;
    }

    get resultsCountLabel() {
        const count = this.vendors.length;
        return `${count} vendor${count !== 1 ? 's' : ''} found`;
    }

    get showQuickActions() {
        return !this.isSearching && this.vendors.length === 0;
    }

    // Event Handlers
    handleSearchChange(event) {
        this.searchTerm = event.target.value;

        // Debounce search
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }

        this.searchTimeout = setTimeout(() => {
            this.handleSearch();
        }, 500);
    }

    handleFilterChange(event) {
        this.selectedFilters = event.detail.value;
        this.handleSearch();
    }

    handleSortChange(event) {
        this.sortBy = event.detail.value;
        this.sortVendors();
    }

    handleVendorClick(event) {
        const vendorId = event.currentTarget.dataset.vendorId;
        const vendor = this.vendors.find(v => v.id === vendorId);

        if (vendor) {
            // Highlight selected vendor
            this.vendors = this.vendors.map(v => ({
                ...v,
                isSelected: v.id === vendorId
            }));
        }
    }

    handleSelectVendor(event) {
        event.stopPropagation();
        const vendorId = event.target.dataset.vendorId;
        const vendor = this.vendors.find(v => v.id === vendorId);

        if (vendor) {
            // Fire custom event with vendor details
            const selectEvent = new CustomEvent('vendorselect', {
                detail: {
                    vendorId: vendor.id,
                    vendorName: vendor.name,
                    vendorScore: vendor.score,
                    historicalCost: vendor.historicalCostRaw,
                    distance: vendor.distanceRaw
                }
            });
            this.dispatchEvent(selectEvent);

            this.showToast('Success', `${vendor.name} selected`, 'success');
        }
    }

    handleViewAllVendors() {
        this.searchTerm = '';
        this.selectedFilters = [];
        this.performInitialSearch();
    }

    handleRequestNewVendor() {
        // Fire event to parent to open vendor request form
        const requestEvent = new CustomEvent('vendorrequest');
        this.dispatchEvent(requestEvent);
    }

    // Search Methods
    async handleSearch() {
        if (this.searchTerm.length === 0) {
            this.performInitialSearch();
            return;
        }

        this.isSearching = true;
        this.errorMessage = '';

        try {
            const result = await searchVendors({
                searchTerm: this.searchTerm,
                locationId: this.locationId,
                quoteId: this.quoteId,
                filters: this.selectedFilters
            });

            await this.processVendorData(result);
            this.sortVendors();
        } catch (error) {
            this.errorMessage = 'Error searching vendors: ' + this.getErrorMessage(error);
        } finally {
            this.isSearching = false;
        }
    }

    async performInitialSearch() {
        this.isSearching = true;
        this.errorMessage = '';

        try {
            const result = await searchVendors({
                searchTerm: '',
                locationId: this.locationId,
                quoteId: this.quoteId,
                filters: this.selectedFilters
            });

            await this.processVendorData(result);
            this.sortVendors();
        } catch (error) {
            this.errorMessage = 'Error loading vendors: ' + this.getErrorMessage(error);
        } finally {
            this.isSearching = false;
        }
    }

    async loadLocationDetails() {
        if (!this.locationId) return;

        try {
            const location = await getLocationDetails({ locationId: this.locationId });
            this.locationName = location.Name || location.City__c || '';
        } catch (error) {
            console.error('Error loading location details:', error);
        }
    }

    // Data Processing
    async processVendorData(vendors) {
        // Fetch historical costs for all vendors
        let historicalCosts = {};
        if (this.quoteId) {
            try {
                const costs = await getHistoricalCosts({
                    vendorIds: vendors.map(v => v.Id),
                    quoteId: this.quoteId
                });
                historicalCosts = costs || {};
            } catch (error) {
                console.error('Error loading historical costs:', error);
            }
        }

        this.vendors = vendors.map(vendor => this.processVendor(vendor, historicalCosts));
    }

    processVendor(vendor, historicalCosts) {
        const score = vendor.VendorScore__c || 0;
        const distance = vendor.Distance__c || null;
        const historical = historicalCosts[vendor.Id];

        return {
            id: vendor.Id,
            name: vendor.Name,
            score: score,
            hasScore: score > 0,
            scoreClass: this.getScoreClass(score),
            distance: distance ? distance.toFixed(1) : null,
            distanceRaw: distance,
            address: this.formatAddress(vendor),
            phone: vendor.Phone,
            email: vendor.Email__c,
            hasHistoricalCost: !!historical,
            historicalCost: historical ? this.formatCurrency(historical.cost) : null,
            historicalCostRaw: historical?.cost,
            costDate: historical ? this.formatDate(historical.date) : null,
            hasCapabilities: vendor.Capabilities__c && vendor.Capabilities__c.length > 0,
            capabilities: vendor.Capabilities__c ? vendor.Capabilities__c.split(';') : [],
            isSelected: false,
            _original: vendor
        };
    }

    // Utility Methods
    getScoreClass(score) {
        let baseClass = 'wm-vendor-score';
        if (score >= 85) {
            return `${baseClass} wm-score-high`;
        } else if (score >= 70) {
            return `${baseClass} wm-score-medium`;
        } else if (score > 0) {
            return `${baseClass} wm-score-low`;
        }
        return baseClass;
    }

    formatAddress(vendor) {
        const parts = [];
        if (vendor.BillingStreet) parts.push(vendor.BillingStreet);
        if (vendor.BillingCity) parts.push(vendor.BillingCity);
        if (vendor.BillingState) parts.push(vendor.BillingState);
        if (vendor.BillingPostalCode) parts.push(vendor.BillingPostalCode);
        return parts.join(', ');
    }

    formatCurrency(value) {
        if (!value) return '';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return new Intl.DateFormat('en-US', {
            month: 'short',
            year: 'numeric'
        }).format(date);
    }

    sortVendors() {
        const sortedVendors = [...this.vendors];

        switch (this.sortBy) {
            case 'score':
                sortedVendors.sort((a, b) => (b.score || 0) - (a.score || 0));
                break;
            case 'distance':
                sortedVendors.sort((a, b) => {
                    if (!a.distanceRaw) return 1;
                    if (!b.distanceRaw) return -1;
                    return a.distanceRaw - b.distanceRaw;
                });
                break;
            case 'name':
                sortedVendors.sort((a, b) => a.name.localeCompare(b.name));
                break;
            case 'recent':
                sortedVendors.sort((a, b) => {
                    if (!a.costDate && !b.costDate) return 0;
                    if (!a.costDate) return 1;
                    if (!b.costDate) return -1;
                    return new Date(b.costDate) - new Date(a.costDate);
                });
                break;
            default:
                break;
        }

        this.vendors = sortedVendors;
    }

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
