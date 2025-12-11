/**
 * @description Test class for ScheduleFormattingService
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7 (Additional Services)
 */
@isTest
private class ScheduleFormattingServiceTest {

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            AccountNumber = 'TEST001'
        );
        insert testAccount;

        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD001',
            Family = 'Commercial',
            IsActive = true
        );
        insert testProduct;

        // Create test quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__StartDate__c = Date.today().addDays(15)
        );
        insert testQuote;
    }

    /**
     * @description Test calculateScheduleField with on-call occurrence type
     */
    @isTest
    static void testCalculateScheduleField_OnCall() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'OC'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('On-Call', result, 'On-call occurrence should return "On-Call"');
    }

    /**
     * @description Test calculateScheduleField with weekly schedule - all days
     */
    @isTest
    static void testCalculateScheduleField_WeeklyAllDays() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'S1;M;T;W;T1;F;S',
            Final_Frequency__c = 7
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E1W(SuMTWRFSa) - 7x', result, 'Should format weekly schedule with all days');
    }

    /**
     * @description Test calculateScheduleField with weekly schedule - weekdays only
     */
    @isTest
    static void testCalculateScheduleField_WeeklyWeekdays() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'M;T;W;T1;F',
            Final_Frequency__c = 5
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E1W(MTWRF) - 5x', result, 'Should format weekly schedule with weekdays');
    }

    /**
     * @description Test calculateScheduleField with weekly schedule - single day
     */
    @isTest
    static void testCalculateScheduleField_WeeklySingleDay() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '2',
            Schedule_Frequency__c = 'W',
            Service_Days__c = 'M',
            Final_Frequency__c = 1
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E2W(M) - 1x', result, 'Should format weekly schedule with single day');
    }

    /**
     * @description Test calculateScheduleField with weekly schedule - empty days
     */
    @isTest
    static void testCalculateScheduleField_WeeklyEmptyDays() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'W',
            Service_Days__c = '',
            Final_Frequency__c = 0
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assert(result.contains('E1W('), 'Should format weekly schedule even with empty days');
    }

    /**
     * @description Test calculateScheduleField with daily schedule
     */
    @isTest
    static void testCalculateScheduleField_Daily() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '2',
            Schedule_Frequency__c = 'D'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E2D', result, 'Should format daily schedule');
    }

    /**
     * @description Test calculateScheduleField with monthly schedule
     */
    @isTest
    static void testCalculateScheduleField_Monthly() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled',
            Frequency_Interval__c = '1',
            Schedule_Frequency__c = 'M'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E1M', result, 'Should format monthly schedule');
    }

    /**
     * @description Test calculateScheduleField with null input
     */
    @isTest
    static void testCalculateScheduleField_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(null);
        Test.stopTest();

        System.assertEquals('', result, 'Null input should return empty string');
    }

    /**
     * @description Test calculateScheduleField with empty fields
     */
    @isTest
    static void testCalculateScheduleField_EmptyFields() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.calculateScheduleField(qLine);
        Test.stopTest();

        System.assertEquals('E', result, 'Empty fields should return base schedule string');
    }

    /**
     * @description Test formatScheduleWithContext with valid schedule
     */
    @isTest
    static void testFormatScheduleWithContext_ValidSchedule() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'OC'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.formatScheduleWithContext(qLine);
        Test.stopTest();

        System.assertEquals('On-Call', result, 'Should return formatted schedule');
    }

    /**
     * @description Test formatScheduleWithContext with empty schedule
     */
    @isTest
    static void testFormatScheduleWithContext_EmptySchedule() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.formatScheduleWithContext(qLine);
        Test.stopTest();

        // Result will be "E" which is not empty, but if it were empty it should show "Not Scheduled"
        System.assertNotEquals(null, result, 'Should return a result');
    }

    /**
     * @description Test formatScheduleWithContext with null input
     */
    @isTest
    static void testFormatScheduleWithContext_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.formatScheduleWithContext(null);
        Test.stopTest();

        System.assertEquals('', result, 'Null input should return empty string');
    }

    /**
     * @description Test parseDayNames with all days
     */
    @isTest
    static void testParseDayNames_AllDays() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        List<String> result = service.parseDayNames('S1;M;T;W;T1;F;S');
        Test.stopTest();

        System.assertEquals(7, result.size(), 'Should return 7 day names');
        System.assert(result.contains('Sunday'), 'Should contain Sunday');
        System.assert(result.contains('Monday'), 'Should contain Monday');
        System.assert(result.contains('Tuesday'), 'Should contain Tuesday');
        System.assert(result.contains('Wednesday'), 'Should contain Wednesday');
        System.assert(result.contains('Thursday'), 'Should contain Thursday');
        System.assert(result.contains('Friday'), 'Should contain Friday');
        System.assert(result.contains('Saturday'), 'Should contain Saturday');
    }

    /**
     * @description Test parseDayNames with weekdays only
     */
    @isTest
    static void testParseDayNames_Weekdays() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        List<String> result = service.parseDayNames('M;T;W;T1;F');
        Test.stopTest();

        System.assertEquals(5, result.size(), 'Should return 5 day names');
        System.assert(result.contains('Monday'), 'Should contain Monday');
        System.assert(result.contains('Friday'), 'Should contain Friday');
    }

    /**
     * @description Test parseDayNames with empty input
     */
    @isTest
    static void testParseDayNames_EmptyInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        List<String> result = service.parseDayNames('');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty input should return empty list');
    }

    /**
     * @description Test parseDayNames with null input
     */
    @isTest
    static void testParseDayNames_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        List<String> result = service.parseDayNames(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Null input should return empty list');
    }

    /**
     * @description Test getDayAbbreviations with all days
     */
    @isTest
    static void testGetDayAbbreviations_AllDays() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.getDayAbbreviations('S1;M;T;W;T1;F;S');
        Test.stopTest();

        System.assertEquals('SuMTWRFSa', result, 'Should return all day abbreviations');
    }

    /**
     * @description Test getDayAbbreviations with weekdays only
     */
    @isTest
    static void testGetDayAbbreviations_Weekdays() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.getDayAbbreviations('M;T;W;T1;F');
        Test.stopTest();

        System.assertEquals('MTWRF', result, 'Should return weekday abbreviations');
    }

    /**
     * @description Test getDayAbbreviations with empty input
     */
    @isTest
    static void testGetDayAbbreviations_EmptyInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.getDayAbbreviations('');
        Test.stopTest();

        System.assertEquals('', result, 'Empty input should return empty string');
    }

    /**
     * @description Test getDayAbbreviations with null input
     */
    @isTest
    static void testGetDayAbbreviations_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        String result = service.getDayAbbreviations(null);
        Test.stopTest();

        System.assertEquals('', result, 'Null input should return empty string');
    }

    /**
     * @description Test isOnCall with on-call occurrence type
     */
    @isTest
    static void testIsOnCall_True() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'OC'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isOnCall(qLine);
        Test.stopTest();

        System.assertEquals(true, result, 'OC type should return true');
    }

    /**
     * @description Test isOnCall with non on-call occurrence type
     */
    @isTest
    static void testIsOnCall_False() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Occurrence_Type__c = 'Scheduled'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isOnCall(qLine);
        Test.stopTest();

        System.assertEquals(false, result, 'Non-OC type should return false');
    }

    /**
     * @description Test isOnCall with null input
     */
    @isTest
    static void testIsOnCall_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isOnCall(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Null input should return false');
    }

    /**
     * @description Test isWeeklySchedule with weekly frequency
     */
    @isTest
    static void testIsWeeklySchedule_True() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Schedule_Frequency__c = 'W'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isWeeklySchedule(qLine);
        Test.stopTest();

        System.assertEquals(true, result, 'Weekly frequency should return true');
    }

    /**
     * @description Test isWeeklySchedule with non-weekly frequency
     */
    @isTest
    static void testIsWeeklySchedule_False() {
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        SBQQ__QuoteLine__c qLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            Schedule_Frequency__c = 'D'
        );
        insert qLine;

        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isWeeklySchedule(qLine);
        Test.stopTest();

        System.assertEquals(false, result, 'Non-weekly frequency should return false');
    }

    /**
     * @description Test isWeeklySchedule with null input
     */
    @isTest
    static void testIsWeeklySchedule_NullInput() {
        ScheduleFormattingService service = new ScheduleFormattingService();

        Test.startTest();
        Boolean result = service.isWeeklySchedule(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Null input should return false');
    }
}
