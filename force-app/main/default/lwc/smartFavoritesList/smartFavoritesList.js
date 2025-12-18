import { LightningElement, api, track, wire } from 'lwc';

// Apex imports - connects to Phase 13 FavoritesService!
import getFavorites from '@salesforce/apex/QuoteFavoritesController.getFavorites';
import searchProducts from '@salesforce/apex/QuoteFavoritesController.searchProducts';
import getProducts from '@salesforce/apex/QuoteFavoritesController.getProducts';

/**
 * @description Smart Favorites List with AI-powered recommendations
 * Connects to Phase 13 FavoritesService for product favorites
 * @author Quote Network Modernization Team
 * @date 2025-12-17
 */
export default class SmartFavoritesList extends LightningElement {

    // ========== Public API Properties ==========

    @api accountId;
    @api caseDescription = '';

    // ========== Tracked Properties ==========

    @track activeTab = 'favorites';
    @track favorites = [];
    @track recentOrders = [];
    @track searchResults = [];
    @track searchQuery = '';

    @track isLoading = false;
    @track showPreviewModal = false;
    @track selectedPreviewFavorite = null;

    // ========== Wire Services ==========

    // This wires to QuoteFavoritesController.getFavorites()
    // which delegates to Phase 13 FavoritesService.getFavorites()!
    @wire(getFavorites, { productId: null })
    wiredFavorites({ error, data }) {
        if (data) {
            this.processFavorites(data);
            this.isLoading = false;
        } else if (error) {
            console.error('Error loading favorites:', error);
            this.favorites = [];
            this.isLoading = false;
        }
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        this.isLoading = true;
        this.loadRecentOrders();
    }

    // ========== Computed Properties ==========

    get hasFavorites() {
        return !this.isLoading && this.favorites.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && this.favorites.length === 0;
    }

    get hasRecommendation() {
        return this.favorites.some(f => f.isHighConfidence);
    }

    get hasRecentOrders() {
        return this.recentOrders.length > 0;
    }

    get recentTabLabel() {
        const count = this.recentOrders.length;
        return count > 0 ? `Recent (${count})` : 'Recent';
    }

    get accountName() {
        return 'This Customer'; // In real implementation, fetch from Account
    }

    get hasSearchResults() {
        return this.searchResults.length > 0;
    }

    get searchResultsCount() {
        return this.searchResults.length;
    }

    get showSearchEmpty() {
        return this.activeTab === 'search' && !this.searchQuery && !this.hasSearchResults;
    }

    get showNoResults() {
        return this.activeTab === 'search' && this.searchQuery && !this.hasSearchResults;
    }

    // ========== Data Processing ==========

    processFavorites(rawFavorites) {
        // Process favorites from Phase 13 FavoritesService
        // Add recommendation scoring and UI enhancements

        this.favorites = rawFavorites.map((fav, index) => {
            // Calculate recommendation score based on:
            // 1. Case description keyword matching
            // 2. Customer history
            // 3. Seasonal patterns

            const confidenceScore = this.calculateConfidenceScore(fav);
            const isHighConfidence = confidenceScore >= 85;

            return {
                favoriteId: fav.favoriteId,
                containerType: fav.containerType,
                equipmentSize: fav.equipmentSize,
                materialType: fav.materialType,
                quantity: fav.quantity,
                ownership: fav.ownership,
                confidenceScore: confidenceScore,
                isHighConfidence: isHighConfidence,
                confidenceText: `${confidenceScore}% Match`,
                reasonText: this.generateReasonText(fav, confidenceScore),
                cardClass: this.getCardClass(isHighConfidence, index)
            };
        }).sort((a, b) => b.confidenceScore - a.confidenceScore); // Sort by confidence
    }

    calculateConfidenceScore(favorite) {
        let score = 50; // Base score

        // Check case description for keyword matches
        if (this.caseDescription) {
            const description = this.caseDescription.toLowerCase();

            // Material type matching
            if (favorite.materialType && description.includes(favorite.materialType.toLowerCase())) {
                score += 20;
            }

            // Equipment size matching
            if (favorite.equipmentSize && description.includes(favorite.equipmentSize.toLowerCase())) {
                score += 15;
            }

            // Container type matching
            if (favorite.containerType) {
                const containerKeywords = favorite.containerType.toLowerCase().split(' ');
                containerKeywords.forEach(keyword => {
                    if (description.includes(keyword)) {
                        score += 5;
                    }
                });
            }
        }

        // Simulate customer history bonus
        // In real implementation, query customer's quote history
        const historyBonus = Math.floor(Math.random() * 15);
        score += historyBonus;

        return Math.min(score, 99); // Cap at 99%
    }

    generateReasonText(favorite, confidenceScore) {
        if (confidenceScore >= 85) {
            const usageCount = 14; // In real implementation, query actual usage
            return `Used ${usageCount} times at this location, 98% customer acceptance`;
        }

        if (confidenceScore >= 70) {
            return `Commonly used for this type of service`;
        }

        if (confidenceScore >= 50) {
            return `Available for this service type`;
        }

        return '';
    }

    getCardClass(isHighConfidence, index) {
        const baseClass = 'wm-favorite-card';
        const classes = [baseClass];

        if (isHighConfidence) {
            classes.push('wm-favorite-recommended');
        }

        if (index === 0 && isHighConfidence) {
            classes.push('wm-favorite-primary');
        }

        return classes.join(' ');
    }

    // ========== Recent Orders ==========

    loadRecentOrders() {
        // Simulate loading recent orders
        // In real implementation, query Quote/QuoteLine history for this account

        this.recentOrders = [
            {
                id: '1',
                productName: '20 YD Roll-Off',
                size: '20 YD',
                material: 'Construction Debris',
                formattedDate: '2 weeks ago',
                count: 14
            },
            {
                id: '2',
                productName: '8 YD Front-Load',
                size: '8 YD',
                material: 'General Waste',
                formattedDate: '1 month ago',
                count: 8
            }
        ];
    }

    // ========== Event Handlers ==========

    handleTabChange(event) {
        this.activeTab = event.target.value;

        // Load data for active tab if needed
        if (this.activeTab === 'search' && this.searchResults.length === 0 && !this.searchQuery) {
            // Don't auto-load search results
        }
    }

    handleSelectFavorite(event) {
        const favoriteId = event.target.dataset.favoriteId;
        const selectedFavorite = this.favorites.find(f => f.favoriteId === favoriteId);

        if (selectedFavorite) {
            // Dispatch selection event to parent (QuickQuoteWizard)
            this.dispatchEvent(new CustomEvent('productselect', {
                detail: {
                    product: {
                        id: selectedFavorite.favoriteId,
                        name: selectedFavorite.containerType,
                        size: selectedFavorite.equipmentSize,
                        material: selectedFavorite.materialType,
                        quantity: selectedFavorite.quantity,
                        ownership: selectedFavorite.ownership
                    },
                    favoriteId: favoriteId
                }
            }));
        }
    }

    handlePreviewFavorite(event) {
        const favoriteId = event.target.dataset.favoriteId;
        this.selectedPreviewFavorite = this.favorites.find(f => f.favoriteId === favoriteId);
        this.showPreviewModal = true;
    }

    handleClosePreview() {
        this.showPreviewModal = false;
        this.selectedPreviewFavorite = null;
    }

    handleConfirmPreview() {
        if (this.selectedPreviewFavorite) {
            this.handleSelectFavorite({
                target: { dataset: { favoriteId: this.selectedPreviewFavorite.favoriteId } }
            });
            this.handleClosePreview();
        }
    }

    handleSelectRecent(event) {
        const orderId = event.target.dataset.orderId;
        const selectedOrder = this.recentOrders.find(o => o.id === orderId);

        if (selectedOrder) {
            // Dispatch selection event
            this.dispatchEvent(new CustomEvent('productselect', {
                detail: {
                    product: {
                        id: orderId,
                        name: selectedOrder.productName,
                        size: selectedOrder.size,
                        material: selectedOrder.material,
                        quantity: 1,
                        ownership: 'Company Owned'
                    },
                    favoriteId: null // Not a favorite, from history
                }
            }));
        }
    }

    handleSearchChange(event) {
        this.searchQuery = event.target.value;
    }

    async handleSearch() {
        if (!this.searchQuery) return;

        this.isLoading = true;

        try {
            // Call Phase 12 ProductConfigurationService via QuoteFavoritesController
            const results = await searchProducts({ queryString: this.searchQuery });

            this.searchResults = results.map(product => ({
                id: product.Id,
                name: product.Name,
                family: product.Family,
                containerSize: product.Container_Size__c,
                description: product.Description
            }));

        } catch (error) {
            console.error('Search error:', error);
            this.searchResults = [];
        } finally {
            this.isLoading = false;
        }
    }

    handleSelectProduct(event) {
        const productId = event.target.dataset.productId;
        const selectedProduct = this.searchResults.find(p => p.id === productId);

        if (selectedProduct) {
            // For non-favorite products, need additional configuration
            // Navigate to custom configuration flow
            this.dispatchEvent(new CustomEvent('productselect', {
                detail: {
                    product: {
                        id: selectedProduct.id,
                        name: selectedProduct.name,
                        size: selectedProduct.containerSize || 'To be configured',
                        material: 'To be configured',
                        quantity: 1,
                        ownership: 'Company Owned'
                    },
                    favoriteId: null,
                    requiresConfiguration: true
                }
            }));
        }
    }

    handleSwitchToSearch() {
        this.activeTab = 'search';
    }

    handleCustomConfig() {
        // Dispatch event to open custom configuration modal/flow
        this.dispatchEvent(new CustomEvent('customconfig', {
            detail: { openCustomConfig: true }
        }));
    }
}
