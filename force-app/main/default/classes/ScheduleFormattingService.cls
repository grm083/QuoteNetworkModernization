/**
 * @description Service for formatting schedule strings from quote line data
 * Extracts schedule calculation logic from QuoteLineTriggerHelper
 * @author Quote Network Modernization Team
 * @date 2025-12-11
 * @story Quote Network Modernization - Phase 7 (Additional Services)
 */
public class ScheduleFormattingService {

    // Day code constants
    private static final String SUNDAY_CODE = 'S1';
    private static final String MONDAY_CODE = 'M';
    private static final String TUESDAY_CODE = 'T';
    private static final String WEDNESDAY_CODE = 'W';
    private static final String THURSDAY_CODE = 'T1';
    private static final String FRIDAY_CODE = 'F';
    private static final String SATURDAY_CODE = 'S';

    // Occurrence type constants
    private static final String ON_CALL_TYPE = 'OC';
    private static final String WEEKLY_FREQUENCY = 'W';

    /**
     * @description Calculate formatted schedule string from quote line
     * Replaces QuoteLineTriggerHelper.calculateScheduleField() lines 1173-1214
     * @param qLine Quote line with schedule information
     * @return Formatted schedule string (e.g., "E1W(MTWRF) - 5x" or "On-Call")
     */
    public String calculateScheduleField(SBQQ__QuoteLine__c qLine) {
        if (qLine == null) {
            return '';
        }

        try {
            String scheduleStr = '';

            // Handle On-Call occurrence type
            if (qLine.Occurrence_Type__c == ON_CALL_TYPE) {
                scheduleStr = 'On-Call';
            } else {
                // Build scheduled occurrence string
                scheduleStr = 'E';

                // Add frequency interval
                if (!String.isEmpty(qLine.Frequency_Interval__c)) {
                    scheduleStr += qLine.Frequency_Interval__c;
                }

                // Add schedule frequency
                if (!String.isEmpty(qLine.Schedule_Frequency__c)) {
                    scheduleStr += qLine.Schedule_Frequency__c;
                }

                // For weekly schedules, add day breakdown
                if (qLine.Schedule_Frequency__c == WEEKLY_FREQUENCY) {
                    scheduleStr += '(';

                    // Parse service days
                    List<String> daysList = (!String.isEmpty(qLine.Service_Days__c)) ?
                        qLine.Service_Days__c.split(';') : new List<String>();

                    // Build day abbreviations in standard week order
                    if (daysList.contains(SUNDAY_CODE)) {
                        scheduleStr += 'Su';
                    }
                    if (daysList.contains(MONDAY_CODE)) {
                        scheduleStr += 'M';
                    }
                    if (daysList.contains(TUESDAY_CODE)) {
                        scheduleStr += 'T';
                    }
                    if (daysList.contains(WEDNESDAY_CODE)) {
                        scheduleStr += 'W';
                    }
                    if (daysList.contains(THURSDAY_CODE)) {
                        scheduleStr += 'R';
                    }
                    if (daysList.contains(FRIDAY_CODE)) {
                        scheduleStr += 'F';
                    }
                    if (daysList.contains(SATURDAY_CODE)) {
                        scheduleStr += 'Sa';
                    }

                    // Add final frequency count
                    scheduleStr += ') - ' + qLine.Final_Frequency__c + 'x';
                }
            }

            System.debug('Calculated schedule string: ' + scheduleStr);
            return scheduleStr;

        } catch (Exception ex) {
            UTIL_LoggingService.logException(ex, 'ScheduleFormattingService', 'calculateScheduleField');
            return '';
        }
    }

    /**
     * @description Format schedule for display with additional context
     * @param qLine Quote line with schedule information
     * @return Formatted schedule with occurrence type context
     */
    public String formatScheduleWithContext(SBQQ__QuoteLine__c qLine) {
        if (qLine == null) {
            return '';
        }

        String schedule = calculateScheduleField(qLine);

        if (String.isEmpty(schedule)) {
            return 'Not Scheduled';
        }

        return schedule;
    }

    /**
     * @description Get human-readable day names from service days string
     * @param serviceDays Semicolon-separated day codes (e.g., "M;T;W;T1;F")
     * @return List of day names (e.g., ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
     */
    public List<String> parseDayNames(String serviceDays) {
        List<String> dayNames = new List<String>();

        if (String.isEmpty(serviceDays)) {
            return dayNames;
        }

        List<String> daysList = serviceDays.split(';');

        if (daysList.contains(SUNDAY_CODE)) {
            dayNames.add('Sunday');
        }
        if (daysList.contains(MONDAY_CODE)) {
            dayNames.add('Monday');
        }
        if (daysList.contains(TUESDAY_CODE)) {
            dayNames.add('Tuesday');
        }
        if (daysList.contains(WEDNESDAY_CODE)) {
            dayNames.add('Wednesday');
        }
        if (daysList.contains(THURSDAY_CODE)) {
            dayNames.add('Thursday');
        }
        if (daysList.contains(FRIDAY_CODE)) {
            dayNames.add('Friday');
        }
        if (daysList.contains(SATURDAY_CODE)) {
            dayNames.add('Saturday');
        }

        return dayNames;
    }

    /**
     * @description Get day abbreviations from service days string
     * @param serviceDays Semicolon-separated day codes
     * @return Concatenated day abbreviations (e.g., "MTWRF")
     */
    public String getDayAbbreviations(String serviceDays) {
        if (String.isEmpty(serviceDays)) {
            return '';
        }

        String abbrev = '';
        List<String> daysList = serviceDays.split(';');

        if (daysList.contains(SUNDAY_CODE)) {
            abbrev += 'Su';
        }
        if (daysList.contains(MONDAY_CODE)) {
            abbrev += 'M';
        }
        if (daysList.contains(TUESDAY_CODE)) {
            abbrev += 'T';
        }
        if (daysList.contains(WEDNESDAY_CODE)) {
            abbrev += 'W';
        }
        if (daysList.contains(THURSDAY_CODE)) {
            abbrev += 'R';
        }
        if (daysList.contains(FRIDAY_CODE)) {
            abbrev += 'F';
        }
        if (daysList.contains(SATURDAY_CODE)) {
            abbrev += 'Sa';
        }

        return abbrev;
    }

    /**
     * @description Check if quote line is on-call occurrence type
     * @param qLine Quote line to check
     * @return True if on-call, false otherwise
     */
    public Boolean isOnCall(SBQQ__QuoteLine__c qLine) {
        if (qLine == null) {
            return false;
        }
        return qLine.Occurrence_Type__c == ON_CALL_TYPE;
    }

    /**
     * @description Check if quote line has weekly frequency
     * @param qLine Quote line to check
     * @return True if weekly, false otherwise
     */
    public Boolean isWeeklySchedule(SBQQ__QuoteLine__c qLine) {
        if (qLine == null) {
            return false;
        }
        return qLine.Schedule_Frequency__c == WEEKLY_FREQUENCY;
    }
}
