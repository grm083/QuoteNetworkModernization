/**
 * @description Test class for PricingAPIResponseParser
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Phase 8 Phase 1 - Foundation Layer
 */
@isTest
private class PricingAPIResponseParserTest {

    /**
     * @description Build sample rolloff pricing response JSON
     */
    private static String buildRolloffResponseJson() {
        return '{' +
            '"data": {' +
                '"supplierCode": "WM_US",' +
                '"costSource": "WM",' +
                '"currencyCode": "USD",' +
                '"isCostOnly": false,' +
                '"lineOfBusiness": "Rolloff",' +
                '"rollOff": {' +
                    '"haulCost": 100.00,' +
                    '"haulPrice": 150.00,' +
                    '"disposalCost": 50.00,' +
                    '"disposalPrice": 75.00,' +
                    '"pricingMethodHaulingDescription": "Standard Haul",' +
                    '"pricingMethodDisposalDescription": "Per Ton"' +
                '},' +
                '"serviceCharges": [' +
                    '{' +
                        '"code": "DLV",' +
                        '"name": "Delivery",' +
                        '"actionName": "Allow",' +
                        '"cost": 25.00,' +
                        '"price": 35.00,' +
                        '"costUOM": "EA",' +
                        '"priceUOM": "EA"' +
                    '},' +
                    '{' +
                        '"code": "PIC",' +
                        '"name": "Pickup",' +
                        '"actionName": "Exclude",' +
                        '"cost": 0.00,' +
                        '"price": 0.00' +
                    '}' +
                ']' +
            '}' +
        '}';
    }

    /**
     * @description Build sample commercial pricing response JSON
     */
    private static String buildCommercialResponseJson() {
        return '{' +
            '"data": {' +
                '"supplierCode": "TP001",' +
                '"costSource": "TP",' +
                '"currencyCode": "USD",' +
                '"lineOfBusiness": "Commercial",' +
                '"commercial": {' +
                    '"cost": 200.00,' +
                    '"price": 250.00,' +
                    '"pricingMethodCodeDescription": "Per Service"' +
                '}' +
            '}' +
        '}';
    }

    /**
     * @description Build error response JSON
     */
    private static String buildErrorResponseJson() {
        return '{' +
            '"problem": {' +
                '"title": "Validation Error",' +
                '"status": 400,' +
                '"errors": [' +
                    '{"code": "E001", "message": "Invalid equipment size"},' +
                    '{"code": "E002", "message": "Missing vendor code"}' +
                ']' +
            '}' +
        '}';
    }

    /**
     * @description Build step disposal response JSON
     */
    private static String buildStepDisposalResponseJson() {
        return '{' +
            '"data": {' +
                '"supplierCode": "WM_US",' +
                '"rollOff": {' +
                    '"haulCost": 100.00,' +
                    '"haulPrice": 150.00,' +
                    '"stepDisposals": [' +
                        '{"costUpTo": 1.0, "cost": 50.00, "priceUpTo": 1.0, "price": 75.00},' +
                        '{"costUpTo": 2.0, "cost": 45.00, "priceUpTo": 2.0, "price": 70.00}' +
                    ']' +
                '}' +
            '}' +
        '}';
    }

    /**
     * @description Test parse valid rolloff response
     */
    @isTest
    static void testParsePricingResponse_RolloffSuccess() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();

        Test.startTest();
        PricingAPIResponseParser.ParseResult result = parser.parsePricingResponse(responseJson);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Parse should succeed');
        System.assertEquals(false, result.hasErrors, 'Should not have errors');
        System.assertNotEquals(null, result.response, 'Response should not be null');
        System.assertNotEquals(null, result.response.data, 'Data should not be null');
    }

    /**
     * @description Test parse with blank JSON
     */
    @isTest
    static void testParsePricingResponse_BlankJson() {
        PricingAPIResponseParser parser = new PricingAPIResponseParser();

        Test.startTest();
        PricingAPIResponseParser.ParseResult result = parser.parsePricingResponse('');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Parse should fail for blank JSON');
        System.assertNotEquals(null, result.parseErrorMessage, 'Should have parse error message');
    }

    /**
     * @description Test parse with error response
     */
    @isTest
    static void testParsePricingResponse_WithErrors() {
        String responseJson = buildErrorResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();

        Test.startTest();
        PricingAPIResponseParser.ParseResult result = parser.parsePricingResponse(responseJson);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Parse should succeed');
        System.assertEquals(true, result.hasErrors, 'Should have errors');
        System.assertEquals(2, result.errorMessages.size(), 'Should have 2 error messages');
    }

    /**
     * @description Test extract error messages
     */
    @isTest
    static void testExtractErrorMessages() {
        String responseJson = buildErrorResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        List<String> messages = parser.extractErrorMessages(response);
        Test.stopTest();

        System.assertEquals(2, messages.size(), 'Should extract 2 error messages');
        System.assert(messages[0].contains('Invalid equipment size'), 'Should contain first error');
        System.assert(messages[1].contains('Missing vendor code'), 'Should contain second error');
    }

    /**
     * @description Test has valid data
     */
    @isTest
    static void testHasValidData() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean hasData = parser.hasValidData(response);
        Test.stopTest();

        System.assertEquals(true, hasData, 'Should have valid data');
    }

    /**
     * @description Test has rolloff data
     */
    @isTest
    static void testHasRolloffData() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean hasRolloff = parser.hasRolloffData(response);
        Test.stopTest();

        System.assertEquals(true, hasRolloff, 'Should have rolloff data');
    }

    /**
     * @description Test has commercial data
     */
    @isTest
    static void testHasCommercialData() {
        String commercialJson = buildCommercialResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(commercialJson);

        Test.startTest();
        Boolean hasCommercial = parser.hasCommercialData(response);
        Test.stopTest();

        System.assertEquals(true, hasCommercial, 'Should have commercial data');
    }

    /**
     * @description Test has service charges
     */
    @isTest
    static void testHasServiceCharges() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean hasCharges = parser.hasServiceCharges(response);
        Test.stopTest();

        System.assertEquals(true, hasCharges, 'Should have service charges');
    }

    /**
     * @description Test get vendor code
     */
    @isTest
    static void testGetVendorCode() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        String vendorCode = parser.getVendorCode(response);
        Test.stopTest();

        System.assertEquals('WM_US', vendorCode, 'Should return vendor code');
    }

    /**
     * @description Test get cost source
     */
    @isTest
    static void testGetCostSource() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        String costSource = parser.getCostSource(response);
        Test.stopTest();

        System.assertEquals('WM', costSource, 'Should return cost source');
    }

    /**
     * @description Test get currency code
     */
    @isTest
    static void testGetCurrencyCode() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        String currencyCode = parser.getCurrencyCode(response);
        Test.stopTest();

        System.assertEquals('USD', currencyCode, 'Should return currency code');
    }

    /**
     * @description Test is cost only response
     */
    @isTest
    static void testIsCostOnlyResponse() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean isCostOnly = parser.isCostOnlyResponse(response);
        Test.stopTest();

        System.assertEquals(false, isCostOnly, 'Should not be cost only');
    }

    /**
     * @description Test get haul cost
     */
    @isTest
    static void testGetHaulCost() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Decimal haulCost = parser.getHaulCost(response);
        Test.stopTest();

        System.assertEquals(100.00, haulCost, 'Should return haul cost');
    }

    /**
     * @description Test get haul price
     */
    @isTest
    static void testGetHaulPrice() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Decimal haulPrice = parser.getHaulPrice(response);
        Test.stopTest();

        System.assertEquals(150.00, haulPrice, 'Should return haul price');
    }

    /**
     * @description Test get disposal cost
     */
    @isTest
    static void testGetDisposalCost() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Decimal disposalCost = parser.getDisposalCost(response);
        Test.stopTest();

        System.assertEquals(50.00, disposalCost, 'Should return disposal cost');
    }

    /**
     * @description Test get disposal price
     */
    @isTest
    static void testGetDisposalPrice() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Decimal disposalPrice = parser.getDisposalPrice(response);
        Test.stopTest();

        System.assertEquals(75.00, disposalPrice, 'Should return disposal price');
    }

    /**
     * @description Test get pickup cost
     */
    @isTest
    static void testGetPickupCost() {
        String commercialJson = buildCommercialResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(commercialJson);

        Test.startTest();
        Decimal pickupCost = parser.getPickupCost(response);
        Test.stopTest();

        System.assertEquals(200.00, pickupCost, 'Should return pickup cost');
    }

    /**
     * @description Test get pickup price
     */
    @isTest
    static void testGetPickupPrice() {
        String commercialJson = buildCommercialResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(commercialJson);

        Test.startTest();
        Decimal pickupPrice = parser.getPickupPrice(response);
        Test.stopTest();

        System.assertEquals(250.00, pickupPrice, 'Should return pickup price');
    }

    /**
     * @description Test find service charge by code
     */
    @isTest
    static void testFindServiceChargeByCode() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        PricingReportingFieldsMetadata.ServiceCharges charge = parser.findServiceChargeByCode(response, 'DLV');
        Test.stopTest();

        System.assertNotEquals(null, charge, 'Should find service charge');
        System.assertEquals('DLV', charge.code, 'Should have correct code');
        System.assertEquals('Allow', charge.actionName, 'Should have correct action');
    }

    /**
     * @description Test find service charges by action
     */
    @isTest
    static void testFindServiceChargesByAction() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        List<PricingReportingFieldsMetadata.ServiceCharges> charges = parser.findServiceChargesByAction(response, 'Allow');
        Test.stopTest();

        System.assertEquals(1, charges.size(), 'Should find one Allow service charge');
        System.assertEquals('DLV', charges[0].code, 'Should be delivery charge');
    }

    /**
     * @description Test get service charge codes
     */
    @isTest
    static void testGetServiceChargeCodes() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Set<String> codes = parser.getServiceChargeCodes(response);
        Test.stopTest();

        System.assertEquals(2, codes.size(), 'Should have 2 service charge codes');
        System.assert(codes.contains('DLV'), 'Should contain DLV');
        System.assert(codes.contains('PIC'), 'Should contain PIC');
    }

    /**
     * @description Test has required pricing data for rolloff
     */
    @isTest
    static void testHasRequiredPricingData_Rolloff() {
        String responseJson = buildRolloffResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean hasRequired = parser.hasRequiredPricingData(response, 'Rolloff');
        Test.stopTest();

        System.assertEquals(true, hasRequired, 'Should have required rolloff pricing');
    }

    /**
     * @description Test has required pricing data for commercial
     */
    @isTest
    static void testHasRequiredPricingData_Commercial() {
        String commercialJson = buildCommercialResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(commercialJson);

        Test.startTest();
        Boolean hasRequired = parser.hasRequiredPricingData(response, 'Commercial');
        Test.stopTest();

        System.assertEquals(true, hasRequired, 'Should have required commercial pricing');
    }

    /**
     * @description Test build error summary
     */
    @isTest
    static void testBuildErrorSummary() {
        String responseJson = buildErrorResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        String errorSummary = parser.buildErrorSummary(response);
        Test.stopTest();

        System.assertNotEquals(null, errorSummary, 'Should have error summary');
        System.assert(errorSummary.contains('Invalid equipment size'), 'Should contain error 1');
        System.assert(errorSummary.contains('Missing vendor code'), 'Should contain error 2');
    }

    /**
     * @description Test parse bulk pricing responses
     */
    @isTest
    static void testParseBulkPricingResponses() {
        List<String> responseList = new List<String>{
            buildRolloffResponseJson(),
            buildCommercialResponseJson()
        };

        PricingAPIResponseParser parser = new PricingAPIResponseParser();

        Test.startTest();
        List<PricingAPIResponseParser.ParseResult> results = parser.parseBulkPricingResponses(responseList);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should parse both responses');
        System.assertEquals(true, results[0].success, 'First parse should succeed');
        System.assertEquals(true, results[1].success, 'Second parse should succeed');
    }

    /**
     * @description Test get step disposals
     */
    @isTest
    static void testGetStepDisposals() {
        String responseJson = buildStepDisposalResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        List<PricingReportingFieldsMetadata.StepDisposal> steps = parser.getStepDisposals(response);
        Test.stopTest();

        System.assertEquals(2, steps.size(), 'Should have 2 step disposal tiers');
        System.assertEquals(50.00, steps[0].cost, 'First tier cost should be 50');
        System.assertEquals(45.00, steps[1].cost, 'Second tier cost should be 45');
    }

    /**
     * @description Test has step disposal pricing
     */
    @isTest
    static void testHasStepDisposalPricing() {
        String responseJson = buildStepDisposalResponseJson();
        PricingAPIResponseParser parser = new PricingAPIResponseParser();
        PricingReportingFieldsMetadata response = PricingReportingFieldsMetadata.parse(responseJson);

        Test.startTest();
        Boolean hasSteps = parser.hasStepDisposalPricing(response);
        Test.stopTest();

        System.assertEquals(true, hasSteps, 'Should have step disposal pricing');
    }

    /**
     * @description Test null safety for various methods
     */
    @isTest
    static void testNullSafety() {
        PricingAPIResponseParser parser = new PricingAPIResponseParser();

        Test.startTest();
        Boolean hasData = parser.hasValidData(null);
        String vendorCode = parser.getVendorCode(null);
        Decimal haulCost = parser.getHaulCost(null);
        List<String> messages = parser.extractErrorMessages(null);
        Test.stopTest();

        System.assertEquals(false, hasData, 'Null response should not have valid data');
        System.assertEquals(null, vendorCode, 'Null response should return null vendor code');
        System.assertEquals(null, haulCost, 'Null response should return null haul cost');
        System.assertEquals(0, messages.size(), 'Null response should return empty error list');
    }
}
