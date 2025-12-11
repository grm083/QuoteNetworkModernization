/**
 * @description Service for aggregating data from various sources
 * Extracts data aggregation logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
public class DataAggregationService {

    /**
     * @description Get unique MAS details for a quote line
     * Replaces QuoteProcurementController.returnUniqueMASDetails() lines 612-667
     * @param quoteLineId Quote line ID
     * @return Aggregated MAS setup details
     * @story SDT-29645, SDT-21065
     */
    public List<AggregateResult> getUniqueMASDetails(Id quoteLineId) {
        if (quoteLineId == null) {
            return new List<AggregateResult>();
        }

        try {
            // Get quote line details
            List<SBQQ__QuoteLine__c> quoteLines = getQuoteLineMASDetails(quoteLineId);

            if (quoteLines.isEmpty()) {
                return new List<AggregateResult>();
            }

            SBQQ__QuoteLine__c parentLine = quoteLines[0];
            Boolean newServiceCase = isNewServiceCase(parentLine);
            String lineOfBusiness = determineLineOfBusiness(parentLine);
            String businessUnit = parentLine.Vendor__r.Vendor_Business_Unit__c;

            List<AggregateResult> masDetails = new List<AggregateResult>();

            // First attempt: Query by facility code if available
            if (parentLine.Vendor__c != null && parentLine.Vendor__r.FacilityCode__c != null) {
                masDetails = queryMASDetailsByFacility(
                    parentLine.Vendor__r.FacilityCode__c,
                    lineOfBusiness,
                    newServiceCase
                );
            }

            // Fallback: Query by business unit
            if (masDetails.isEmpty() && String.isNotBlank(businessUnit)) {
                masDetails = queryMASDetailsByBusinessUnit(businessUnit, lineOfBusiness);
            }

            return masDetails;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting unique MAS details: ' + ex.getMessage());
            UTIL_LoggingService.logHandledException(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.ERROR_APPLICATION,
                LoggingLevel.ERROR
            );
            return new List<AggregateResult>();
        }
    }

    /**
     * @description Query MAS details by facility code
     * @param facilityCode Facility code
     * @param lineOfBusiness Line of business
     * @param newServiceCase New service case indicator
     * @return Aggregated MAS details
     */
    private List<AggregateResult> queryMASDetailsByFacility(
        String facilityCode,
        String lineOfBusiness,
        Boolean newServiceCase
    ) {
        return [SELECT MAS_Library__c, MAS_Company_Code__c, MAS_Line_of_Business__c, Bypass_Price_Review__c
                FROM MAS_Setup_Detail__c
                WHERE Facility_Id__c = :facilityCode
                AND MAS_Line_of_Business__c = :lineOfBusiness
                AND Valid_For_New_Service__c = :newServiceCase
                GROUP BY MAS_Library__c, MAS_Company_Code__c, MAS_Line_of_Business__c, Bypass_Price_Review__c];
    }

    /**
     * @description Query MAS details by business unit
     * @param businessUnit Business unit number
     * @param lineOfBusiness Line of business
     * @return Aggregated MAS details
     */
    private List<AggregateResult> queryMASDetailsByBusinessUnit(
        String businessUnit,
        String lineOfBusiness
    ) {
        return [SELECT MAS_Library__c, MAS_Company_Code__c, MAS_Line_of_Business__c, Bypass_Price_Review__c
                FROM MAS_Setup_Detail__c
                WHERE Business_Unit_Number__c = :businessUnit
                AND MAS_Line_of_Business__c = :lineOfBusiness
                GROUP BY MAS_Library__c, MAS_Company_Code__c, MAS_Line_of_Business__c, Bypass_Price_Review__c];
    }

    /**
     * @description Determine if quote is for new service case
     * @param quoteLine Quote line to evaluate
     * @return True if new service case
     */
    private Boolean isNewServiceCase(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.SBQQ__Quote__r.SBQQ__Type__c == 'Quote'
            && quoteLine.SBQQ__Quote__r.Case_Type__c == 'New Service'
            && quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name == 'New Service') {
            return true;
        }
        return false;
    }

    /**
     * @description Determine line of business for MAS lookup
     * @param quoteLine Quote line to evaluate
     * @return Line of business value
     */
    private String determineLineOfBusiness(SBQQ__QuoteLine__c quoteLine) {
        String productFamily = quoteLine.SBQQ__Product__r.Family;

        if (productFamily == 'Industrial Services') {
            return 'Industrial';
        } else if (productFamily == 'Broker') {
            return 'Broker';
        }

        return 'Commercial';
    }

    /**
     * @description Get quote line MAS details
     * Replaces QuoteProcurementController.getQuoteLineMASDetails() lines 929-941
     * @param quoteLineId Quote line ID
     * @return Quote line with MAS-related fields
     */
    private List<SBQQ__QuoteLine__c> getQuoteLineMASDetails(Id quoteLineId) {
        return [SELECT Id, Vendor__r.Status__c, PricingUnitMethod__c, Vendor_Commit_Date__c,
                      SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.Case_Type__c, SBQQ__Quote__r.STP__c,
                      MASLibrary__c, MASCompany__c, MASAccount__c, MASCustomerUniqueId__c,
                      MASServiceLine__c, MASBox__c, BypassPriceReview__c, BypassMASServiceChange__c,
                      SetupComment__c, DoNotCreateMASTicket__c, DoNotCreateTaskGridTickets__c,
                      SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.RecordType.Name,
                      Vendor__c, Vendor__r.FacilityCode__c, Vendor__r.Vendor_Business_Unit__c,
                      SBQQ__Product__r.Family
                FROM SBQQ__QuoteLine__c
                WHERE Id = :quoteLineId
                LIMIT 1];
    }

    /**
     * @description Aggregate quote line data for reporting
     * @param quoteId Quote ID
     * @return Aggregated quote line data
     */
    public List<AggregateResult> aggregateQuoteLinesByProduct(Id quoteId) {
        if (quoteId == null) {
            return new List<AggregateResult>();
        }

        try {
            return [SELECT SBQQ__Product__r.Name, COUNT(Id) lineCount,
                          SUM(SBQQ__NetTotal__c) totalNet,
                          SUM(SBQQ__ListTotal__c) totalList
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quoteId
                    AND SBQQ__RequiredBy__c = null
                    GROUP BY SBQQ__Product__r.Name
                    ORDER BY SBQQ__Product__r.Name];

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error aggregating quote lines by product: ' + ex.getMessage());
            return new List<AggregateResult>();
        }
    }

    /**
     * @description Aggregate quote line data by vendor
     * @param quoteId Quote ID
     * @return Aggregated vendor data
     */
    public List<AggregateResult> aggregateQuoteLinesByVendor(Id quoteId) {
        if (quoteId == null) {
            return new List<AggregateResult>();
        }

        try {
            return [SELECT Vendor__r.Name, COUNT(Id) lineCount,
                          SUM(SBQQ__CustomerTotal__c) totalCustomer
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quoteId
                    AND SBQQ__RequiredBy__c = null
                    AND Vendor__c != null
                    GROUP BY Vendor__r.Name
                    ORDER BY Vendor__r.Name];

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error aggregating quote lines by vendor: ' + ex.getMessage());
            return new List<AggregateResult>();
        }
    }

    /**
     * @description Get MAS setup summary statistics
     * @return Aggregated MAS setup statistics
     */
    public MASSetupStatistics getMASSetupStatistics() {
        MASSetupStatistics stats = new MASSetupStatistics();

        try {
            // Count active MAS setups by business unit
            List<AggregateResult> businessUnitCounts = [
                SELECT Business_Unit_Number__c, COUNT(Id) setupCount
                FROM MAS_Setup_Detail__c
                WHERE Is_Active__c = true
                GROUP BY Business_Unit_Number__c
            ];

            stats.businessUnitCounts = new Map<String, Integer>();
            for (AggregateResult ar : businessUnitCounts) {
                String bu = (String)ar.get('Business_Unit_Number__c');
                Integer count = (Integer)ar.get('setupCount');
                stats.businessUnitCounts.put(bu, count);
            }

            // Count by line of business
            List<AggregateResult> lobCounts = [
                SELECT MAS_Line_of_Business__c, COUNT(Id) setupCount
                FROM MAS_Setup_Detail__c
                WHERE Is_Active__c = true
                GROUP BY MAS_Line_of_Business__c
            ];

            stats.lineOfBusinessCounts = new Map<String, Integer>();
            for (AggregateResult ar : lobCounts) {
                String lob = (String)ar.get('MAS_Line_of_Business__c');
                Integer count = (Integer)ar.get('setupCount');
                stats.lineOfBusinessCounts.put(lob, count);
            }

            // Total active setups
            AggregateResult totalResult = [
                SELECT COUNT(Id) total
                FROM MAS_Setup_Detail__c
                WHERE Is_Active__c = true
            ];
            stats.totalActiveSetups = (Integer)totalResult.get('total');

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting MAS setup statistics: ' + ex.getMessage());
        }

        return stats;
    }

    /**
     * @description MAS setup statistics wrapper
     */
    public class MASSetupStatistics {
        public Integer totalActiveSetups { get; set; }
        public Map<String, Integer> businessUnitCounts { get; set; }
        public Map<String, Integer> lineOfBusinessCounts { get; set; }

        public MASSetupStatistics() {
            this.totalActiveSetups = 0;
            this.businessUnitCounts = new Map<String, Integer>();
            this.lineOfBusinessCounts = new Map<String, Integer>();
        }
    }
}
