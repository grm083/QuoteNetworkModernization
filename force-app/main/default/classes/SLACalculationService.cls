/**
 * @description Service for calculating SLA dates for quotes and quote lines
 * Extracts SLA calculation logic from QuoteFavoritesController
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7A
 */
public class SLACalculationService {

    private HaulAwayService haulAwayService = new HaulAwayService();

    /**
     * @description Calculate SLA date for a quote line
     * Replaces QuoteFavoritesController.determineSLA() lines 318-459
     * @param parentQuoteLineId Parent quote line ID
     * @return Calculated SLA DateTime
     */
    public DateTime determineSLA(Id parentQuoteLineId) {
        DateTime slaDate = System.now();

        if (parentQuoteLineId == null) {
            return slaDate;
        }

        try {
            // Get quote line with all required fields
            List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c,
                      SBQQ__Quote__r.SBQQ__Account__c, SBQQ__ProductFamily__c, Duration__c,
                      SBQQ__Quote__r.SBQQ__Account__r.ParentId, SBQQ__Quote__r.Project__c,
                      SBQQ__ProductName__c, Equipment_Size__c,
                      SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c,
                      SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.SLA_Service_DateTime__c,
                      SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c,
                      SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Is_Haul_Away_Service__c,
                      SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :parentQuoteLineId
                LIMIT 1
            ];

            if (quoteLines.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'Could not determine parent quote line for SLA calculation');
                return slaDate;
            }

            SBQQ__QuoteLine__c parentLine = quoteLines[0];

            // Check for haul away service - returns current time
            if (haulAwayService.getIsHaulAwayService(parentLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__c)) {
                return System.now();
            }

            // Get timezone and business hours
            String locTimeZone = parentLine.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c;
            BusinessHours businessHourId = getBusinessHoursForLocation(locTimeZone);

            // Convert duration code to label
            String duration = convertDurationCode(parentLine.Duration__c);
            if (duration == null) {
                return System.now();
            }

            // Get entitlement for the quote line
            Entitlement relEntitlement = getRelatedEntitlement(parentLine.SBQQ__Quote__c, parentLine.Id);

            if (relEntitlement == null || relEntitlement.Id == null) {
                // Use industry standard SLA
                slaDate = calculateIndustryStandardSLA(
                    parentLine,
                    duration,
                    businessHourId,
                    locTimeZone
                );
            } else {
                // Use entitlement-based SLA
                slaDate = calculateEntitlementBasedSLA(
                    relEntitlement,
                    businessHourId,
                    locTimeZone
                );
            }

            // Override for amendment/correction/exception quotes with service date
            if (parentLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c != null
                && isAmendmentQuoteType(parentLine.SBQQ__Quote__r.SBQQ__Type__c)) {

                Date serviceDate = parentLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Case__r.Service_Date__c;
                slaDate = DateTime.newInstance(serviceDate.year(), serviceDate.month(), serviceDate.day());
            }

            return slaDate;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error calculating SLA: ' + ex.getMessage());
            UTIL_LoggingService.logHandledException(
                ex,
                UserInfo.getOrganizationId(),
                UTIL_ErrorConstants.ERROR_APPLICATION,
                LoggingLevel.ERROR
            );
            return slaDate;
        }
    }

    /**
     * @description Calculate SLA using industry standards
     * @param parentLine Quote line
     * @param duration Duration label
     * @param businessHourId Business hours
     * @param locTimeZone Location timezone
     * @return Calculated SLA DateTime
     */
    private DateTime calculateIndustryStandardSLA(
        SBQQ__QuoteLine__c parentLine,
        String duration,
        BusinessHours businessHourId,
        String locTimeZone
    ) {
        // Query industry standards
        List<Industry_Standard_SLA__mdt> industryStandards = [
            SELECT Id, Service__c, After__c, Before__c
            FROM Industry_Standard_SLA__mdt
            WHERE Service__c LIKE 'New Service%'
        ];

        Industry_Standard_SLA__mdt matchedStandard = findMatchingIndustryStandard(
            industryStandards,
            parentLine,
            duration
        );

        if (matchedStandard == null) {
            return System.now();
        }

        // Calculate based on SLA switch setting
        if (useLegacySLALogic()) {
            return calculateISSLA(matchedStandard, businessHourId);
        } else {
            return calculateISSLA_LocTimezone(matchedStandard, businessHourId, parentLine, locTimeZone);
        }
    }

    /**
     * @description Calculate SLA using entitlement
     * @param entitlement Entitlement record
     * @param businessHourId Business hours
     * @param locTimeZone Location timezone
     * @return Calculated SLA DateTime
     */
    private DateTime calculateEntitlementBasedSLA(
        Entitlement entitlement,
        BusinessHours businessHourId,
        String locTimeZone
    ) {
        if (useLegacySLALogic()) {
            return calculateEntitlementSLA(entitlement, businessHourId);
        } else {
            return calculateEntitlementSLA_LocTimezone(entitlement, businessHourId, locTimeZone);
        }
    }

    /**
     * @description Find matching industry standard for quote line
     * @param industryStandards List of industry standards
     * @param parentLine Quote line
     * @param duration Duration label
     * @return Matched industry standard or null
     */
    private Industry_Standard_SLA__mdt findMatchingIndustryStandard(
        List<Industry_Standard_SLA__mdt> industryStandards,
        SBQQ__QuoteLine__c parentLine,
        String duration
    ) {
        Industry_Standard_SLA__mdt matchedStandard = null;

        for (Industry_Standard_SLA__mdt ind : industryStandards) {
            // Compactor logic for SDT-24088
            if (parentLine.SBQQ__ProductName__c != null
                && parentLine.SBQQ__ProductName__c.contains('Compactor')
                && String.isNotBlank(parentLine.Equipment_Size__c)) {

                Decimal equipmentSize = parseEquipmentSize(parentLine.Equipment_Size__c);

                if (equipmentSize != null) {
                    // Compactor <= 10 yards = Commercial
                    if (equipmentSize <= 10
                        && ind.Service__c.contains(Constant_Util.COMMERCIAL)
                        && ind.Service__c.contains(duration)) {
                        matchedStandard = ind;
                        break;
                    }
                    // Compactor > 10 yards = Roll Off
                    else if (equipmentSize > 10
                        && ind.Service__c.contains(Constant_Util.ROLLOFF)
                        && ind.Service__c.contains(duration)) {
                        matchedStandard = ind;
                        break;
                    }
                }
            }
            // Product family match
            else if (ind.Service__c.contains(parentLine.SBQQ__ProductFamily__c)
                && ind.Service__c.contains(duration)) {
                matchedStandard = ind;
            }
            // Generic service match (fallback)
            else if (ind.Service__c.contains('Service')
                && ind.Service__c.contains(duration)
                && matchedStandard == null) {
                matchedStandard = ind;
            }
            // None product family
            else if (ind.Service__c.contains('Service')
                && ind.Service__c.contains(duration)
                && parentLine.SBQQ__ProductFamily__c == 'None') {
                matchedStandard = ind;
            }
        }

        return matchedStandard;
    }

    /**
     * @description Calculate entitlement SLA (legacy logic)
     * Replaces QuoteFavoritesController.calculateEntitlementSLA() lines 566-614
     * @param entitlement Entitlement record
     * @param businessHours Business hours
     * @return Calculated SLA DateTime
     */
    public DateTime calculateEntitlementSLA(Entitlement entitlement, BusinessHours businessHours) {
        currentDateTime currDateTime = new currentDateTime();
        Integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        Long milliseconds = 0;

        switch on entitlement.Service_Guarantee_Category__c {
            when 'Hours' {
                milliseconds = Integer.valueOf(entitlement.Service_Guarantee_Category_Value__c) * 3600000;
            }
            when 'Days' {
                Integer serviceGuaranteeValue = calculateServiceGuaranteeValue(
                    entitlement,
                    currentHour,
                    false
                );
                milliseconds = serviceGuaranteeValue * 16 * 3600000;
            }
        }

        return addBusinessHours(businessHours.Id, currDateTime.local, milliseconds);
    }

    /**
     * @description Calculate entitlement SLA with timezone support
     * Replaces QuoteFavoritesController.calculateEntitlementSLA_LocTimezone() lines 617-724
     * @param entitlement Entitlement record
     * @param businessHours Business hours
     * @param locTimeZone Location timezone
     * @return Calculated SLA DateTime
     */
    public DateTime calculateEntitlementSLA_LocTimezone(
        Entitlement entitlement,
        BusinessHours businessHours,
        String locTimeZone
    ) {
        currentDateTime currDateTime;
        Integer offset = 0;

        if (String.isNotEmpty(locTimeZone)) {
            currDateTime = new currentDateTime(locTimeZone);
            Timezone tz = Timezone.getTimeZone(locTimeZone);
            offset = tz.getOffset(System.now());
        } else {
            currDateTime = new currentDateTime();
        }

        Integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        Long milliseconds = 0;

        switch on entitlement.Service_Guarantee_Category__c {
            when 'Hours' {
                milliseconds = Integer.valueOf(entitlement.Service_Guarantee_Category_Value__c) * 3600000;
            }
            when 'Days' {
                Integer serviceGuaranteeValue = calculateServiceGuaranteeValue(
                    entitlement,
                    currentHour,
                    true
                );
                milliseconds = serviceGuaranteeValue * 16 * 3600000;
            }
        }

        if (locTimeZone != null) {
            return getBusinessHoursInAccountTimeZone(
                businessHours.Id,
                System.now(),
                milliseconds,
                locTimeZone
            );
        } else {
            return addBusinessHours(businessHours.Id, currDateTime.local, milliseconds);
        }
    }

    /**
     * @description Calculate industry standard SLA (legacy logic)
     * Replaces QuoteFavoritesController.calculateISSLA() lines 727-758
     * @param indStandard Industry standard metadata
     * @param businessHours Business hours
     * @return Calculated SLA DateTime
     */
    public DateTime calculateISSLA(Industry_Standard_SLA__mdt indStandard, BusinessHours businessHours) {
        currentDateTime currDateTime = new currentDateTime();
        Integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        Long milliseconds = 0;

        if (currentHour >= 14) {
            milliseconds = indStandard.After__c != null
                ? (indStandard.After__c.intValue() * 16 * 3600000)
                : 0;
        } else if (currentHour >= 10 && currentHour < 14) {
            milliseconds = indStandard.Before__c != null
                ? (indStandard.Before__c.intValue() * 16 * 3600000) - 57600000
                : 0;
        } else {
            milliseconds = indStandard.Before__c != null
                ? (indStandard.Before__c.intValue() * 16 * 3600000)
                : 0;
        }

        return addBusinessHours(businessHours.Id, currDateTime.local, milliseconds);
    }

    /**
     * @description Calculate industry standard SLA with timezone support
     * Replaces QuoteFavoritesController.calculateISSLA_LocTimezone() lines 761-874
     * @param indStandard Industry standard metadata
     * @param businessHours Business hours
     * @param parentQL Parent quote line
     * @param locTimeZone Location timezone
     * @return Calculated SLA DateTime
     */
    public DateTime calculateISSLA_LocTimezone(
        Industry_Standard_SLA__mdt indStandard,
        BusinessHours businessHours,
        SBQQ__QuoteLine__c parentQL,
        String locTimeZone
    ) {
        currentDateTime currDateTime;

        if (locTimeZone != null) {
            currDateTime = new currentDateTime(locTimeZone);
        } else {
            currDateTime = new currentDateTime();
        }

        Integer currentHour = Integer.valueOf(currDateTime.hours.split(':')[0]);
        Long milliseconds = 0;

        if (currentHour >= 12) {
            milliseconds = indStandard.After__c != null
                ? (indStandard.After__c.intValue() * 16 * 60 * 60 * 1000)
                : 0;
        } else if (currentHour >= 0 && currentHour < 5) {
            milliseconds = indStandard.Before__c != null
                ? (indStandard.Before__c.intValue() * 16 * 60 * 60 * 1000)
                : 0;
        } else if (currentHour < 12) {
            milliseconds = indStandard.Before__c != null
                ? (indStandard.Before__c.intValue() * 16 * 60 * 60 * 1000) - 57600000
                : 0;
        }

        return getBusinessHoursInAccountTimeZone(
            businessHours.Id,
            System.now(),
            milliseconds,
            locTimeZone
        );
    }

    /**
     * @description Calculate service guarantee value adjustments
     * @param entitlement Entitlement record
     * @param currentHour Current hour of day
     * @param useNewLogic Use new timezone logic
     * @return Adjusted service guarantee value
     */
    private Integer calculateServiceGuaranteeValue(
        Entitlement entitlement,
        Integer currentHour,
        Boolean useNewLogic
    ) {
        Integer value = Integer.valueOf(entitlement.Service_Guarantee_Category_Value__c);

        if (useNewLogic) {
            // New logic for timezone support (SDT-39637)
            if (value == 0 || value == 1) {
                // Same day and next day - no adjustment
                return value;
            } else if (String.isNotBlank(entitlement.Before_After__c)
                && Constant_Util.BEFORE.equalsIgnoreCase(entitlement.Before_After__c)) {
                value = value - 1;
            }

            // Morning adjustment (00:00-05:00)
            if (currentHour >= 0 && currentHour < 5) {
                value = value + 1;
            }
        } else {
            // Legacy logic
            if (String.isNotBlank(entitlement.Before_After__c)
                && Constant_Util.BEFORE.equalsIgnoreCase(entitlement.Before_After__c)) {

                if (currentHour < 9 && value != 0 && value == 1) {
                    value = value + 1;
                } else if (currentHour >= 10 && value != 0 && value != 1) {
                    value = value - 1;
                }
            } else if (String.isNotBlank(entitlement.Before_After__c)
                && Constant_Util.AFTER.equalsIgnoreCase(entitlement.Before_After__c)) {

                if (entitlement.Call_Time__c == '14:00'
                    || entitlement.Call_Time__c == '15:00'
                    || entitlement.Call_Time__c == '23:59') {
                    // No adjustment
                } else if (entitlement.Call_Time__c == '13:00'
                    || entitlement.Call_Time__c == '12:00'
                    || entitlement.Call_Time__c == '10:00') {
                    if (value != 0 && value != 1) {
                        value = value - 1;
                    }
                }
            }
        }

        return value;
    }

    /**
     * @description Get related entitlement for quote
     * Replaces QuoteFavoritesController.getRelatedEntitleMent() lines 933-1075
     * @param quoteId Quote ID
     * @param parentQuoteLineId Parent quote line ID
     * @return Entitlement record or null
     */
    public Entitlement getRelatedEntitlement(String quoteId, String parentQuoteLineId) {
        try {
            SBQQ__Quote__c quote = [
                SELECT Id, Project__c, SBQQ__Opportunity2__r.Case__c,
                      SBQQ__Account__c, SBQQ__Account__r.ParentId
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
                LIMIT 1
            ];

            SBQQ__QuoteLine__c quoteLine = [
                SELECT Id, Name, SBQQ__Quote__c, Duration__c, SBQQ__ProductName__c,
                      SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :parentQuoteLineId
                AND SBQQ__RequiredBy__c = null
                LIMIT 1
            ];

            // Query entitlements with priority logic (SDT-24925, SDT-25065)
            List<Entitlement> entitlements = [
                SELECT Id, Request_Type__c, Service__c, AccountId, Project_Code__c,
                      Container__c, Service_Guarantee_Category__c,
                      Service_Guarantee_Category_Value__c, Call_On__c, Project__c,
                      Location__c, Schedule_Type__c, Before_After__c, Call_Time__c
                FROM Entitlement
                WHERE Request_Type__c = :Constant_Util.NEW_SERVICE
                AND Status__c = :Constant_Util.APPROVED
                AND (Container__c = :quoteLine.SBQQ__ProductName__c OR Container__c = '' OR Container__c = null)
                AND ((AccountId = :quote.SBQQ__Account__r.ParentId AND Location__c = :quote.SBQQ__Account__c)
                    OR (AccountId = :quote.SBQQ__Account__r.ParentId AND Location__c = null))
                AND StartDate <= TODAY
                AND (EndDate = null OR EndDate >= TODAY)
                ORDER BY Container__c DESC
            ];

            if (entitlements.isEmpty()) {
                return null;
            }

            // Filter entitlements based on duration and service
            return filterEntitlementByDuration(entitlements, quoteLine);

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error getting related entitlement: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description Filter entitlements by duration and service
     * @param entitlements List of entitlements
     * @param quoteLine Quote line
     * @return Filtered entitlement or null
     */
    private Entitlement filterEntitlementByDuration(
        List<Entitlement> entitlements,
        SBQQ__QuoteLine__c quoteLine
    ) {
        String durationLabel = convertDurationCode(quoteLine.Duration__c);

        if (useLegacySLALogic()) {
            // Legacy filtering logic
            for (Entitlement ent : entitlements) {
                if (ent.Service__c != null && ent.Service__c.contains(durationLabel)) {
                    return ent;
                }
            }
        } else {
            // New timezone-aware filtering
            currentDateTime currDateTime = new currentDateTime(
                quoteLine.SBQQ__Quote__r.SBQQ__Account__r.tz__Timezone_SFDC__c
            );

            for (Entitlement ent : entitlements) {
                if (ent.Service__c != null && ent.Service__c.contains(durationLabel)) {
                    return ent;
                }
            }
        }

        return entitlements.isEmpty() ? null : entitlements[0];
    }

    /**
     * @description Get business hours for location timezone
     * @param locTimeZone Location timezone
     * @return BusinessHours record
     */
    private BusinessHours getBusinessHoursForLocation(String locTimeZone) {
        BusinessHours defaultHours = [
            SELECT Id FROM BusinessHours WHERE isDefault = true LIMIT 1
        ];

        if (useLegacySLALogic()) {
            return defaultHours;
        }

        List<BusinessHours> locationHours = getBusinessHoursByTimeZone(locTimeZone);
        return (locationHours != null && !locationHours.isEmpty())
            ? locationHours[0]
            : defaultHours;
    }

    /**
     * @description Get business hours by timezone
     * Replaces QuoteFavoritesController.getBusinessIdByTimeZone() lines 923-930
     * @param timeZone Timezone string
     * @return List of BusinessHours
     */
    public List<BusinessHours> getBusinessHoursByTimeZone(String timeZone) {
        if (String.isBlank(timeZone)) {
            return new List<BusinessHours>();
        }

        String businessHoursName = 'WM SBS - ' + timeZone;

        return [
            SELECT Id, Name, TimeZoneSidKey, isActive
            FROM BusinessHours
            WHERE isActive = true
            AND Name = :businessHoursName
            LIMIT 1
        ];
    }

    /**
     * @description Add business hours in account timezone
     * Replaces QuoteFavoritesController.getBusinessHoursInAccountTimeZone() lines 896-914
     * @param businessHoursId Business hours ID
     * @param utcStartDateTime Start datetime in UTC
     * @param intervalMilliseconds Interval in milliseconds
     * @param accTimeZone Account timezone
     * @return Converted DateTime
     */
    public DateTime getBusinessHoursInAccountTimeZone(
        Id businessHoursId,
        DateTime utcStartDateTime,
        Long intervalMilliseconds,
        String accTimeZone
    ) {
        Timezone tz = Timezone.getTimeZone(accTimeZone);
        Integer offsetMillis = tz.getOffset(utcStartDateTime);

        DateTime utcEndDateTime = BusinessHours.add(
            businessHoursId,
            utcStartDateTime,
            intervalMilliseconds
        );

        return utcEndDateTime.addSeconds(offsetMillis / 1000);
    }

    /**
     * @description Add business hours (utility method)
     * @param businessHoursId Business hours ID
     * @param startDate Start datetime
     * @param intervalMilliseconds Interval in milliseconds
     * @return Calculated DateTime
     */
    private DateTime addBusinessHours(
        Id businessHoursId,
        DateTime startDate,
        Long intervalMilliseconds
    ) {
        return BusinessHours.addGmt(businessHoursId, startDate, intervalMilliseconds);
    }

    /**
     * @description Check if using legacy SLA logic
     * Replaces QuoteFavoritesController.getSLASwitch() lines 878-881
     * @return True if using legacy logic
     */
    public Boolean useLegacySLALogic() {
        Code_Switch__c codeSwitchSetting = Code_Switch__c.getValues('SLA Logic Switch');
        return codeSwitchSetting != null && codeSwitchSetting.Switch_Off__c;
    }

    /**
     * @description Convert duration code to label
     * @param durationCode Duration code (TEMP, PERM, SEAS)
     * @return Duration label or null
     */
    private String convertDurationCode(String durationCode) {
        switch on durationCode {
            when 'TEMP' {
                return 'Temporary';
            }
            when 'PERM' {
                return 'Permanent';
            }
            when 'SEAS' {
                return 'Seasonal';
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description Parse equipment size to decimal
     * @param equipmentSize Equipment size string
     * @return Parsed size or null
     */
    private Decimal parseEquipmentSize(String equipmentSize) {
        try {
            return Decimal.valueOf(
                equipmentSize.replace('YRDS', '').replace('-', '')
            );
        } catch (Exception ex) {
            return null;
        }
    }

    /**
     * @description Check if quote type is amendment/correction/exception
     * @param quoteType Quote type
     * @return True if amendment type
     */
    private Boolean isAmendmentQuoteType(String quoteType) {
        return quoteType == 'Amendment'
            || quoteType == 'Correction'
            || quoteType == 'Exception';
    }
}
