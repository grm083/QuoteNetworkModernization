/**
 * @description Service for managing financial details on quote lines
 * Extracts financial management logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 5
 */
public class FinancialManagementService {

    /**
     * @description Update financial details on quote lines
     * Replaces QuoteProcurementController.updateFinancialDetail() lines 2092-2146
     * @param quoteLineId Parent quote line ID
     * @param isQuoteOnly Whether quote is quote only
     * @param companyCategory Company category code
     * @param companyCategoryName Company category name
     * @param generalLedgerNo General ledger account number
     * @param customerCostCenter Customer cost center
     * @return Success or failure message
     */
    public String updateFinancialDetail(
        Id quoteLineId,
        Boolean isQuoteOnly,
        String companyCategory,
        String companyCategoryName,
        String generalLedgerNo,
        String customerCostCenter
    ) {
        if (quoteLineId == null) {
            return 'Failed: Quote Line ID is required';
        }

        try {
            // Query quote lines
            List<SBQQ__QuoteLine__c> qlRecords = [
                SELECT Id, SBQQ__Quote__c, CompanyCategoryCode__c, CompanyCategoryName__c,
                      ClientGLAccount__c, ClientCostCenter__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__RequiredBy__c = :quoteLineId
            ];

            if (qlRecords.isEmpty()) {
                return 'Failed: No quote lines found';
            }

            List<SObject> recordsToUpdate = new List<SObject>();

            // Update child quote lines
            for (SBQQ__QuoteLine__c ql : qlRecords) {
                applyFinancialUpdates(ql, companyCategory, companyCategoryName, generalLedgerNo, customerCostCenter);
                recordsToUpdate.add(ql);
            }

            // Update parent quote line
            SBQQ__QuoteLine__c parentQL = new SBQQ__QuoteLine__c(Id = quoteLineId);
            applyFinancialUpdates(parentQL, companyCategory, companyCategoryName, generalLedgerNo, customerCostCenter);
            recordsToUpdate.add(parentQL);

            // Update quote
            SBQQ__Quote__c quoteRecord = new SBQQ__Quote__c(
                Id = qlRecords[0].SBQQ__Quote__c,
                Quote_Only__c = isQuoteOnly
            );
            recordsToUpdate.add(quoteRecord);

            // Perform update
            update recordsToUpdate;

            return 'Success';

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating financial details: ' + ex.getMessage());
            UTIL_LoggingService.logHandledException(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.ERROR_APPLICATION,
                LoggingLevel.ERROR
            );
            return 'Failed: ' + ex.getMessage();
        }
    }

    /**
     * @description Apply financial updates to a quote line
     * @param quoteLine Quote line to update
     * @param companyCategory Company category code
     * @param companyCategoryName Company category name
     * @param generalLedgerNo General ledger account
     * @param customerCostCenter Customer cost center
     */
    private void applyFinancialUpdates(
        SBQQ__QuoteLine__c quoteLine,
        String companyCategory,
        String companyCategoryName,
        String generalLedgerNo,
        String customerCostCenter
    ) {
        if (String.isNotBlank(companyCategoryName) && String.isNotBlank(companyCategory)) {
            quoteLine.CompanyCategoryCode__c = companyCategory;
            quoteLine.CompanyCategoryName__c = companyCategoryName;
        }

        quoteLine.ClientGLAccount__c = generalLedgerNo;
        quoteLine.ClientCostCenter__c = customerCostCenter;
    }

    /**
     * @description Update company categories on quote lines
     * Replaces QuoteProcurementController.updateCompanyCategories() lines 715-735
     * @param parentId Parent quote line ID
     * @param companyCategory Company category code
     * @return Success status
     */
    public Boolean updateCompanyCategories(Id parentId, String companyCategory) {
        if (parentId == null) {
            return false;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, CompanyCategoryCode__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :parentId
                OR SBQQ__RequiredBy__c = :parentId
                OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :parentId
            ];

            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                quoteLine.CompanyCategoryCode__c = companyCategory;
            }

            update quoteLines;
            return true;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating company categories: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Validate financial details completeness
     * @param quoteLine Quote line to validate
     * @return List of validation errors
     */
    public List<String> validateFinancialDetails(SBQQ__QuoteLine__c quoteLine) {
        List<String> errors = new List<String>();

        if (quoteLine == null) {
            errors.add('Quote line is required');
            return errors;
        }

        // Validate company category
        if (String.isBlank(quoteLine.CompanyCategoryCode__c)) {
            errors.add('Company category is required');
        }

        // Validate GL account for certain scenarios
        if (requiresGLAccount(quoteLine) && String.isBlank(quoteLine.ClientGLAccount__c)) {
            errors.add('General ledger account is required');
        }

        // Validate cost center for certain scenarios
        if (requiresCostCenter(quoteLine) && String.isBlank(quoteLine.ClientCostCenter__c)) {
            errors.add('Cost center is required');
        }

        return errors;
    }

    /**
     * @description Check if quote line requires GL account
     * @param quoteLine Quote line to check
     * @return True if GL account required
     */
    private Boolean requiresGLAccount(SBQQ__QuoteLine__c quoteLine) {
        // Business logic to determine if GL account is required
        // This can be customized based on product family, quote type, etc.
        return quoteLine.SBQQ__ProductFamily__c != null
            && !quoteLine.SBQQ__ProductFamily__c.containsIgnoreCase('Waste');
    }

    /**
     * @description Check if quote line requires cost center
     * @param quoteLine Quote line to check
     * @return True if cost center required
     */
    private Boolean requiresCostCenter(SBQQ__QuoteLine__c quoteLine) {
        // Business logic to determine if cost center is required
        return quoteLine.SBQQ__ProductFamily__c != null
            && !quoteLine.SBQQ__ProductFamily__c.containsIgnoreCase('Waste');
    }

    /**
     * @description Get financial details for quote line
     * @param quoteLineId Quote line ID
     * @return Financial details wrapper
     */
    public FinancialDetails getFinancialDetails(Id quoteLineId) {
        if (quoteLineId == null) {
            return null;
        }

        try {
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, CompanyCategoryCode__c, CompanyCategoryName__c,
                      ClientGLAccount__c, ClientCostCenter__c,
                      SBQQ__Quote__r.Quote_Only__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :quoteLineId
                LIMIT 1
            ];

            if (quoteLines.isEmpty()) {
                return null;
            }

            SBQQ__QuoteLine__c ql = quoteLines[0];
            FinancialDetails details = new FinancialDetails();
            details.companyCategory = ql.CompanyCategoryCode__c;
            details.companyCategoryName = ql.CompanyCategoryName__c;
            details.generalLedgerAccount = ql.ClientGLAccount__c;
            details.costCenter = ql.ClientCostCenter__c;
            details.isQuoteOnly = ql.SBQQ__Quote__r.Quote_Only__c;

            return details;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting financial details: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Financial details wrapper class
     */
    public class FinancialDetails {
        public String companyCategory { get; set; }
        public String companyCategoryName { get; set; }
        public String generalLedgerAccount { get; set; }
        public String costCenter { get; set; }
        public Boolean isQuoteOnly { get; set; }

        public FinancialDetails() {
            this.isQuoteOnly = false;
        }
    }
}
