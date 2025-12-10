/**
 * @description Service for vendor search, assignment, and validation logic
 * Extracts vendor-related logic from QuoteProcurementController
 * @author Quote Network Modernization Team
 * @date 2025-12-10
 * @story Quote Network Modernization - Phase 4
 */
public class VendorManagementService {

    /**
     * @description Search for vendors using SOSL
     * Replaces QuoteProcurementController.searchVendors() lines 1274-1305
     * @param searchString Search term
     * @return List of vendor accounts
     * @story SDT-45005
     */
    public List<Account> searchVendors(String searchString) {
        if (String.isBlank(searchString)) {
            return new List<Account>();
        }

        List<Account> vendorList = new List<Account>();

        try {
            // SOSL search for vendors
            List<List<SObject>> searchList = [FIND :searchString
                                              IN ALL FIELDS
                                              RETURNING Account(Id, Name, AccountNumber, Vendor_Business_Unit__c,
                                                              ShippingState, ShippingCity, FacilityCode__c,
                                                              Parent_Vendor_Id__c, Status__c, Vendor_Id__c
                                                              WHERE RecordType.Name = 'Vendor')];

            vendorList = (Account[])searchList[0];

            // Filter parent vendors that are referenced by child vendors (SDT-45005)
            return filterParentVendors(vendorList);

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error searching vendors: ' + ex.getMessage());
            return new List<Account>();
        }
    }

    /**
     * @description Filter out parent vendors that are referenced by child vendors
     * @param vendorList List of vendors from search
     * @return Filtered vendor list
     * @story SDT-45005
     */
    private List<Account> filterParentVendors(List<Account> vendorList) {
        // Get all parent vendor IDs that are referenced by children
        Set<String> parentVendorIds = new Set<String>();
        List<Account> childVendors = [SELECT Parent_Vendor_Id__c
                                      FROM Account
                                      WHERE Parent_Vendor_Id__c != null
                                      AND RecordType.Name = 'Vendor'
                                      LIMIT 49999];

        for (Account child : childVendors) {
            parentVendorIds.add(child.Parent_Vendor_Id__c);
        }

        // Filter vendors: exclude parents referenced by children, include all children
        List<Account> filteredVendors = new List<Account>();
        for (Account vendor : vendorList) {
            if (vendor.Parent_Vendor_Id__c == null) {
                // This is a parent vendor
                if (!parentVendorIds.contains(vendor.Vendor_Id__c)) {
                    filteredVendors.add(vendor);
                } else {
                    System.debug('Skipping parent vendor (referenced by other vendors): ' +
                               vendor.Name + ' (Vendor Id: ' + vendor.Vendor_Id__c + ')');
                }
            } else {
                // This is a child vendor - always include
                filteredVendors.add(vendor);
            }
        }

        return filteredVendors;
    }

    /**
     * @description Update vendor and sCode on quote lines
     * Replaces QuoteProcurementController.updateVendorDetails() lines 632-659
     * @param parentId Parent quote line ID
     * @param vendorId Vendor account ID
     * @param sCode Service code
     * @return Success status
     */
    public Boolean updateVendorDetails(Id parentId, Id vendorId, String sCode) {
        if (parentId == null) {
            return false;
        }

        try {
            // Query all related quote lines (parent, children, grandchildren)
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Vendor__c, sCode__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE Id = :parentId
                                                   OR SBQQ__RequiredBy__c = :parentId
                                                   OR SBQQ__RequiredBy__r.SBQQ__RequiredBy__c = :parentId];

            System.debug('Selected s-code is: ' + sCode);
            System.debug('Selected vendor count: ' + quoteLines.size());

            // Update vendor and sCode on all lines
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                quoteLine.Vendor__c = vendorId;
                quoteLine.sCode__c = sCode;
            }

            update quoteLines;
            return true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating vendor details: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Check if vendor is active
     * @param vendorId Vendor account ID
     * @return True if vendor is active
     */
    public Boolean isVendorActive(Id vendorId) {
        if (vendorId == null) {
            return false;
        }

        try {
            List<Account> vendors = [SELECT Id, Status__c
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            return !vendors.isEmpty() && vendors[0].Status__c != 'Inactive';

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error checking vendor status: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Check if vendor is a WM vendor
     * @param vendorId Vendor account ID
     * @return True if WM vendor
     */
    public Boolean isWMVendor(Id vendorId) {
        if (vendorId == null) {
            return false;
        }

        try {
            List<Account> vendors = [SELECT Id, Vendor_Business_Unit__c
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            if (!vendors.isEmpty()) {
                String businessUnit = vendors[0].Vendor_Business_Unit__c;
                return businessUnit != null && businessUnit.startsWithIgnoreCase('WM');
            }

            return false;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error checking WM vendor: ' + ex.getMessage());
            return false;
        }
    }

    /**
     * @description Get vendor business unit
     * @param vendorId Vendor account ID
     * @return Business unit or null
     */
    public String getVendorBusinessUnit(Id vendorId) {
        if (vendorId == null) {
            return null;
        }

        try {
            List<Account> vendors = [SELECT Id, Vendor_Business_Unit__c
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            return !vendors.isEmpty() ? vendors[0].Vendor_Business_Unit__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting vendor business unit: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Get vendor facility code
     * @param vendorId Vendor account ID
     * @return Facility code or null
     * @story SDT-29645
     */
    public String getVendorFacilityCode(Id vendorId) {
        if (vendorId == null) {
            return null;
        }

        try {
            List<Account> vendors = [SELECT Id, FacilityCode__c
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            return !vendors.isEmpty() ? vendors[0].FacilityCode__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting vendor facility code: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Get vendor parent vendor ID
     * @param vendorId Vendor account ID
     * @return Parent vendor ID or null
     */
    public String getVendorParentVendorId(Id vendorId) {
        if (vendorId == null) {
            return null;
        }

        try {
            List<Account> vendors = [SELECT Id, Parent_Vendor_Id__c
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            return !vendors.isEmpty() ? vendors[0].Parent_Vendor_Id__c : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting parent vendor ID: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Get full vendor details for display
     * @param vendorId Vendor account ID
     * @return Vendor account or null
     */
    public Account getVendorDetails(Id vendorId) {
        if (vendorId == null) {
            return null;
        }

        try {
            List<Account> vendors = [SELECT Id, Name, AccountNumber, Vendor_Business_Unit__c,
                                           ShippingState, ShippingCity, FacilityCode__c,
                                           Parent_Vendor_Id__c, Status__c, Vendor_Id__c,
                                           RecordType.Name
                                    FROM Account
                                    WHERE Id = :vendorId
                                    LIMIT 1];

            return !vendors.isEmpty() ? vendors[0] : null;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting vendor details: ' + ex.getMessage());
            return null;
        }
    }
}
