/**
 * @description Service for Favorites operations
 * Handles favorite product to quote line conversion
 * @author Quote Network Modernization Team
 * @date 2025-12-16
 * @story Phase 13: Favorites Service Extraction
 */
public class FavoritesService {

    /**
     * @description Get favorites for a product with configuration
     * Replaces: QuoteFavoritesController.getFavorites()
     * @param productId Product ID
     * @return List of FavoriteWrapper
     * Phase 13: Extracted from QuoteFavoritesController
     */
    public List<FavoriteWrapper> getFavorites(Id productId) {
        List<FavoriteWrapper> productFavorites = new List<FavoriteWrapper>();

        List<SBQQ__FavoriteProduct__c> productFavoriteDetails = [SELECT Id, SBQQ__Favorite__r.Name, SBQQ__Favorite__c, SBQQ__ConfigurationAttributes__c,
                                                                SBQQ__Product__r.Family, SBQQ__Product__r.Name, SBQQ__Quantity__c
                                                                FROM SBQQ__FavoriteProduct__c
                                                                WHERE SBQQ__Product__c =: productId OR
                                                                SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c =: productId
                                                                ORDER BY SBQQ__Favorite__c ASC];

        if(productFavoriteDetails.size() == 0) {
            return productFavorites;
        }
        /*
         String favoriteIndex = '';
        FavoriteWrapper favoriteConfig = new FavoriteWrapper();
        for (SBQQ__FavoriteProduct__c fp : productFavoriteDetails) {
            favoriteIndex = (favoriteIndex == '') ? fp.SBQQ__Favorite__c : favoriteIndex;
         */

        Id favoriteIndex;
        FavoriteWrapper favoriteConfig = new FavoriteWrapper();
        system.debug('productFavoriteDetails--->'+ productFavoriteDetails);
        for (SBQQ__FavoriteProduct__c fp : productFavoriteDetails) {
            system.debug('favoriteIndex--->'+ favoriteIndex);
            system.debug('favoriteIndex2--->'+ favoriteIndex);
            if (favoriteIndex != fp.SBQQ__Favorite__c){
                productFavorites.add(favoriteConfig);
                favoriteConfig = new FavoriteWrapper();
                favoriteIndex = fp.SBQQ__Favorite__c;
                favoriteConfig.favoriteId = fp.SBQQ__Favorite__c;
            }
            if (fp.SBQQ__Product__r.Family == 'Waste Stream') {
                favoriteConfig.materialType = fp.SBQQ__Product__r.Name;
            }
            if (fp.SBQQ__Product__c == productId) {
                favoriteConfig.containerType = fp.SBQQ__Product__r.Name;
                favoriteConfig.quantity = fp.SBQQ__Quantity__c;
                String confAttributes = fp.SBQQ__ConfigurationAttributes__c;
                Map<String, Object> attributes = (Map<String, Object>) JSON.deserializeUntyped(confAttributes);
                favoriteConfig.equipmentSize = (String)attributes.get('Equipment_Size__c');
                favoriteConfig.ownership = (String)attributes.get('Ownership__c');
            }
        }
        productFavorites.add(favoriteConfig);

        return productFavorites;
    }

    /**
     * @description Add quote favorite to quote
     * Replaces: QuoteFavoritesController.addQuoteFavorite()
     * @param favoriteId Favorite ID
     * @param quoteId Quote ID
     * @return Quote line ID
     * Phase 13: Extracted from QuoteFavoritesController
     */
    public String addQuoteFavorite(Id favoriteId, Id quoteId) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = [SELECT Id, SBQQ__Opportunity2__r.Case__c
                FROM SBQQ__Quote__c
                WHERE Id =: quoteId];

        //Ref: QuoteProcurementController for documentation
        String returnedId = QuoteProcurementController.addQuoteandQuoteine(favoriteId, quote.SBQQ__Opportunity2__r.Case__c, quoteId, true);

        SBQQ__QuoteLine__c newQL = [SELECT Id, SBQQ__StartDate__c
                                    FROM SBQQ__QuoteLine__c
                                    WHERE SBQQ__ProductOption__c = null
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];

        //Date SLADateTime = NULL;//determineSLA(newQL.Id);
        //sdt-27107
        //newQL.SBQQ__StartDate__c = SLADateTime;
        //newQL.SBQQ__EndDate__c = SLADateTime;//added by seema
        //sdt-27107 end
        try {
            //update newQL;
            return newQL.Id;
        } catch (exception e) {
            system.debug(e.getMessage());
            return newQL.Id;
        }

    }

    /**
     * @description Create non-favorite line
     * Replaces: QuoteFavoritesController.createNonFavoriteLine()
     * @param quoteId Quote ID
     * @param productId Product ID
     * @param wasteStream Waste stream ID
     * @param equipmentSize Equipment size
     * @return Success message
     * Phase 13: Extracted from QuoteFavoritesController
     */
    public String createNonFavoriteLine(Id quoteId, Id productId, Id wasteStream, String equipmentSize) {

        String successMessage;

        successMessage = QuoteProcurementController.createQuoteLines(quoteId, productId, wasteStream, equipmentSize);

        return successMessage;

    }

    /**
     * @description Wrapper class for favorite product data
     * Phase 13: Extracted from QuoteFavoritesController
     */
    public class FavoriteWrapper {
        public String favoriteId {get; set;}
        public String containerType {get; set;}
        public String equipmentSize {get; set;}
        public String materialType {get; set;}
        public Decimal quantity {get; set;}
        public String ownership {get; set;}
        public Boolean quantityEditable {get; set;}
    }
}
