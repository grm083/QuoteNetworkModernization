import { LightningElement, api, track } from 'lwc';

// Frequency constants
const FREQUENCY_WEEKLY = 'weekly';
const FREQUENCY_BIWEEKLY = 'biweekly';
const FREQUENCY_MONTHLY = 'monthly';
const FREQUENCY_QUARTERLY = 'quarterly';

// Duration constants
const DURATION_ONGOING = 'ongoing';
const DURATION_END_DATE = 'endDate';
const DURATION_OCCURRENCES = 'occurrences';

// Days of week
const DAYS_OF_WEEK = [
    { label: 'Mon', value: '1', fullName: 'Monday' },
    { label: 'Tue', value: '2', fullName: 'Tuesday' },
    { label: 'Wed', value: '3', fullName: 'Wednesday' },
    { label: 'Thu', value: '4', fullName: 'Thursday' },
    { label: 'Fri', value: '5', fullName: 'Friday' },
    { label: 'Sat', value: '6', fullName: 'Saturday' },
    { label: 'Sun', value: '0', fullName: 'Sunday' }
];

/**
 * @description Schedule Selector for Quick Quote Wizard Step 2
 * Handles one-time and recurring service scheduling with visual preview
 * @author Quote Network Modernization Team
 * @date 2025-12-18
 */
export default class ScheduleSelector extends LightningElement {

    // ========== Public API Properties ==========

    @api slaDate; // From slaCalculatorDisplay
    @api preSelectedSchedule; // For editing existing quotes

    // ========== Tracked Properties ==========

    // Service type
    @track serviceType = 'one-time'; // 'one-time' or 'recurring'

    // One-time properties
    @track serviceDate = '';
    @track serviceTime = '';

    // Recurring properties
    @track selectedFrequency = FREQUENCY_WEEKLY;
    @track selectedDayOfWeek = '';
    @track selectedDayOfMonth = '';
    @track recurringStartDate = '';
    @track selectedDuration = DURATION_ONGOING;
    @track recurringEndDate = '';
    @track occurrenceCount = 12;

    // Preview data
    @track upcomingDates = [];

    // State
    @track hasError = false;
    @track errorMessage = '';

    // ========== Computed Properties - Service Type ==========

    get isOneTime() {
        return this.serviceType === 'one-time';
    }

    get isRecurring() {
        return this.serviceType === 'recurring';
    }

    get oneTimeCardClass() {
        return this.isOneTime ? 'wm-type-card wm-type-card-selected' : 'wm-type-card';
    }

    get recurringCardClass() {
        return this.isRecurring ? 'wm-type-card wm-type-card-selected' : 'wm-type-card';
    }

    get serviceTypeLabel() {
        return this.isOneTime ? 'One-Time Service' : 'Recurring Service';
    }

    // ========== Computed Properties - Frequency Options ==========

    get frequencyOptions() {
        return [
            { label: 'Weekly', value: FREQUENCY_WEEKLY },
            { label: 'Bi-Weekly (Every 2 Weeks)', value: FREQUENCY_BIWEEKLY },
            { label: 'Monthly', value: FREQUENCY_MONTHLY },
            { label: 'Quarterly (Every 3 Months)', value: FREQUENCY_QUARTERLY }
        ];
    }

    get frequencyLabel() {
        const option = this.frequencyOptions.find(opt => opt.value === this.selectedFrequency);
        return option ? option.label : '';
    }

    // ========== Computed Properties - Day Selection ==========

    get showDayOfWeekSelector() {
        return this.isRecurring && (
            this.selectedFrequency === FREQUENCY_WEEKLY ||
            this.selectedFrequency === FREQUENCY_BIWEEKLY
        );
    }

    get showDayOfMonthSelector() {
        return this.isRecurring && (
            this.selectedFrequency === FREQUENCY_MONTHLY ||
            this.selectedFrequency === FREQUENCY_QUARTERLY
        );
    }

    get daysOfWeek() {
        return DAYS_OF_WEEK.map(day => ({
            ...day,
            buttonClass: this.selectedDayOfWeek === day.value
                ? 'wm-day-button wm-day-button-selected'
                : 'wm-day-button'
        }));
    }

    get dayOfWeekLabel() {
        const day = DAYS_OF_WEEK.find(d => d.value === this.selectedDayOfWeek);
        return day ? day.fullName : '';
    }

    get dayOfMonthOptions() {
        const options = [];
        for (let i = 1; i <= 28; i++) {
            options.push({ label: `${i}${this.getOrdinalSuffix(i)}`, value: String(i) });
        }
        options.push({ label: 'Last Day of Month', value: 'last' });
        return options;
    }

    get dayOfMonthLabel() {
        if (this.selectedDayOfMonth === 'last') {
            return 'Last Day of Month';
        }
        return this.selectedDayOfMonth ? `${this.selectedDayOfMonth}${this.getOrdinalSuffix(parseInt(this.selectedDayOfMonth, 10))}` : '';
    }

    // ========== Computed Properties - Duration ==========

    get durationOptions() {
        return [
            { label: 'Ongoing (No End Date)', value: DURATION_ONGOING },
            { label: 'Until Specific Date', value: DURATION_END_DATE },
            { label: 'Specific Number of Services', value: DURATION_OCCURRENCES }
        ];
    }

    get durationLabel() {
        if (this.selectedDuration === DURATION_ONGOING) {
            return 'Ongoing';
        } else if (this.selectedDuration === DURATION_END_DATE) {
            return `Until ${this.formattedEndDate}`;
        } else if (this.selectedDuration === DURATION_OCCURRENCES) {
            return `${this.occurrenceCount} services`;
        }
        return '';
    }

    get showEndDate() {
        return this.selectedDuration === DURATION_END_DATE;
    }

    get showOccurrenceCount() {
        return this.selectedDuration === DURATION_OCCURRENCES;
    }

    // ========== Computed Properties - Dates ==========

    get formattedServiceDate() {
        if (!this.serviceDate) return '';

        const date = new Date(this.serviceDate);
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get formattedServiceTime() {
        if (!this.serviceTime) return '8:00 AM';

        const [hours, minutes] = this.serviceTime.split(':');
        const hour = parseInt(hours, 10);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour === 0 ? 12 : (hour > 12 ? hour - 12 : hour);

        return `${displayHour}:${minutes} ${ampm}`;
    }

    get formattedStartDate() {
        if (!this.recurringStartDate) return '';

        const date = new Date(this.recurringStartDate);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get formattedEndDate() {
        if (!this.recurringEndDate) return '';

        const date = new Date(this.recurringEndDate);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get minimumStartDate() {
        if (this.slaDate) {
            const date = new Date(this.slaDate);
            return date.toISOString().split('T')[0];
        }

        const today = new Date();
        return today.toISOString().split('T')[0];
    }

    get minimumEndDate() {
        if (this.recurringStartDate) {
            const date = new Date(this.recurringStartDate);
            date.setDate(date.getDate() + 7); // At least 1 week after start
            return date.toISOString().split('T')[0];
        }

        return this.minimumStartDate;
    }

    // ========== Computed Properties - Schedule Preview ==========

    get hasRecurringSchedule() {
        return this.isRecurring && this.recurringStartDate &&
            (this.selectedDayOfWeek || this.selectedDayOfMonth);
    }

    get scheduleDescription() {
        if (!this.hasRecurringSchedule) return '';

        let description = `Service will occur ${this.frequencyLabel.toLowerCase()}`;

        if (this.selectedDayOfWeek) {
            description += ` on ${this.dayOfWeekLabel}s`;
        } else if (this.selectedDayOfMonth) {
            description += ` on the ${this.dayOfMonthLabel}`;
        }

        description += `, starting ${this.formattedStartDate}`;

        if (this.selectedDuration === DURATION_END_DATE && this.recurringEndDate) {
            description += ` and ending ${this.formattedEndDate}`;
        } else if (this.selectedDuration === DURATION_OCCURRENCES) {
            description += ` for ${this.occurrenceCount} occurrences`;
        } else {
            description += ' with no end date';
        }

        return description + '.';
    }

    get showUpcomingDates() {
        return this.upcomingDates && this.upcomingDates.length > 0;
    }

    get hasMoreDates() {
        return this.remainingDatesCount > 0;
    }

    get remainingDatesCount() {
        if (this.selectedDuration === DURATION_OCCURRENCES) {
            return Math.max(0, this.occurrenceCount - this.upcomingDates.length);
        } else if (this.selectedDuration === DURATION_END_DATE) {
            // Estimate based on frequency
            const totalEstimate = this.calculateTotalOccurrences();
            return Math.max(0, totalEstimate - this.upcomingDates.length);
        }
        return 0;
    }

    get totalServicesText() {
        if (this.selectedDuration === DURATION_ONGOING) {
            return 'Ongoing';
        } else if (this.selectedDuration === DURATION_OCCURRENCES) {
            return this.occurrenceCount;
        } else if (this.selectedDuration === DURATION_END_DATE) {
            return this.calculateTotalOccurrences();
        }
        return '0';
    }

    // ========== Computed Properties - Validation ==========

    get hasValidSchedule() {
        if (this.isOneTime) {
            return this.serviceDate !== '';
        } else if (this.isRecurring) {
            return this.recurringStartDate !== '' &&
                   (this.selectedDayOfWeek !== '' || this.selectedDayOfMonth !== '');
        }
        return false;
    }

    // ========== Lifecycle Hooks ==========

    connectedCallback() {
        // Set service date from SLA calculator
        if (this.slaDate) {
            const date = new Date(this.slaDate);
            this.serviceDate = date.toISOString().split('T')[0];
            this.serviceTime = date.toTimeString().split(' ')[0].substring(0, 5);
            this.recurringStartDate = this.serviceDate;
        }

        // Load pre-selected schedule if editing
        if (this.preSelectedSchedule) {
            this.loadPreSelectedSchedule();
        }

        // Auto-select Monday for weekly services by default
        if (this.isRecurring && !this.selectedDayOfWeek) {
            this.selectedDayOfWeek = '1'; // Monday
            this.calculateUpcomingDates();
        }
    }

    // ========== Event Handlers - Service Type ==========

    handleSelectOneTime() {
        this.serviceType = 'one-time';
        this.dispatchScheduleChange();
    }

    handleSelectRecurring() {
        this.serviceType = 'recurring';

        // Auto-select Monday if no day selected
        if (!this.selectedDayOfWeek && this.showDayOfWeekSelector) {
            this.selectedDayOfWeek = '1';
        }

        // Auto-select 1st if no day of month selected
        if (!this.selectedDayOfMonth && this.showDayOfMonthSelector) {
            this.selectedDayOfMonth = '1';
        }

        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    // ========== Event Handlers - Frequency ==========

    handleFrequencyChange(event) {
        this.selectedFrequency = event.detail.value;

        // Reset day selections
        this.selectedDayOfWeek = '';
        this.selectedDayOfMonth = '';

        // Auto-select appropriate day
        if (this.showDayOfWeekSelector) {
            this.selectedDayOfWeek = '1'; // Monday
        } else if (this.showDayOfMonthSelector) {
            this.selectedDayOfMonth = '1'; // 1st of month
        }

        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    handleDayOfWeekClick(event) {
        this.selectedDayOfWeek = event.target.dataset.day;
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    handleDayOfMonthChange(event) {
        this.selectedDayOfMonth = event.detail.value;
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    // ========== Event Handlers - Dates ==========

    handleStartDateChange(event) {
        this.recurringStartDate = event.target.value;
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    handleDurationChange(event) {
        this.selectedDuration = event.detail.value;
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    handleEndDateChange(event) {
        this.recurringEndDate = event.target.value;
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    handleOccurrenceCountChange(event) {
        this.occurrenceCount = parseInt(event.target.value, 10);
        this.calculateUpcomingDates();
        this.dispatchScheduleChange();
    }

    // ========== Schedule Calculation ==========

    calculateUpcomingDates() {
        if (!this.hasRecurringSchedule) {
            this.upcomingDates = [];
            return;
        }

        const dates = [];
        const startDate = new Date(this.recurringStartDate);
        const maxPreview = 5; // Show first 5 dates

        let currentDate = new Date(startDate);
        let count = 0;
        const maxIterations = this.selectedDuration === DURATION_OCCURRENCES
            ? Math.min(this.occurrenceCount, maxPreview)
            : maxPreview;

        while (count < maxIterations) {
            // Adjust to correct day
            if (this.selectedDayOfWeek) {
                currentDate = this.getNextDayOfWeek(currentDate, parseInt(this.selectedDayOfWeek, 10));
            } else if (this.selectedDayOfMonth) {
                currentDate = this.getNextDayOfMonth(currentDate, this.selectedDayOfMonth);
            }

            // Check if within end date constraint
            if (this.selectedDuration === DURATION_END_DATE && this.recurringEndDate) {
                const endDate = new Date(this.recurringEndDate);
                if (currentDate > endDate) break;
            }

            dates.push({
                key: `date-${count}`,
                formatted: currentDate.toLocaleDateString('en-US', {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                }),
                value: new Date(currentDate)
            });

            count++;

            // Move to next occurrence
            currentDate = this.getNextOccurrence(currentDate);
        }

        this.upcomingDates = dates;
    }

    getNextDayOfWeek(date, targetDay) {
        const current = new Date(date);
        const currentDay = current.getDay();

        if (currentDay === targetDay) {
            return current;
        }

        const daysUntilTarget = (targetDay - currentDay + 7) % 7;
        current.setDate(current.getDate() + (daysUntilTarget || 7));

        return current;
    }

    getNextDayOfMonth(date, targetDay) {
        const current = new Date(date);

        if (targetDay === 'last') {
            // Last day of month
            current.setMonth(current.getMonth() + 1, 0);
        } else {
            current.setDate(parseInt(targetDay, 10));
        }

        return current;
    }

    getNextOccurrence(date) {
        const next = new Date(date);

        switch (this.selectedFrequency) {
            case FREQUENCY_WEEKLY:
                next.setDate(next.getDate() + 7);
                break;
            case FREQUENCY_BIWEEKLY:
                next.setDate(next.getDate() + 14);
                break;
            case FREQUENCY_MONTHLY:
                next.setMonth(next.getMonth() + 1);
                break;
            case FREQUENCY_QUARTERLY:
                next.setMonth(next.getMonth() + 3);
                break;
        }

        return next;
    }

    calculateTotalOccurrences() {
        if (!this.recurringStartDate || !this.recurringEndDate) return 0;

        const start = new Date(this.recurringStartDate);
        const end = new Date(this.recurringEndDate);
        const diffTime = Math.abs(end - start);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        switch (this.selectedFrequency) {
            case FREQUENCY_WEEKLY:
                return Math.floor(diffDays / 7) + 1;
            case FREQUENCY_BIWEEKLY:
                return Math.floor(diffDays / 14) + 1;
            case FREQUENCY_MONTHLY:
                return Math.floor(diffDays / 30) + 1;
            case FREQUENCY_QUARTERLY:
                return Math.floor(diffDays / 90) + 1;
            default:
                return 0;
        }
    }

    // ========== Helper Methods ==========

    loadPreSelectedSchedule() {
        // Load existing schedule configuration
        const schedule = this.preSelectedSchedule;

        this.serviceType = schedule.type;

        if (schedule.type === 'one-time') {
            this.serviceDate = schedule.date;
            this.serviceTime = schedule.time;
        } else if (schedule.type === 'recurring') {
            this.selectedFrequency = schedule.frequency;
            this.selectedDayOfWeek = schedule.dayOfWeek;
            this.selectedDayOfMonth = schedule.dayOfMonth;
            this.recurringStartDate = schedule.startDate;
            this.selectedDuration = schedule.duration;
            this.recurringEndDate = schedule.endDate;
            this.occurrenceCount = schedule.occurrenceCount;

            this.calculateUpcomingDates();
        }
    }

    getOrdinalSuffix(num) {
        const j = num % 10;
        const k = num % 100;

        if (j === 1 && k !== 11) return 'st';
        if (j === 2 && k !== 12) return 'nd';
        if (j === 3 && k !== 13) return 'rd';

        return 'th';
    }

    dispatchScheduleChange() {
        const scheduleData = {
            type: this.serviceType,
            isValid: this.hasValidSchedule
        };

        if (this.isOneTime) {
            scheduleData.date = this.serviceDate;
            scheduleData.time = this.serviceTime;
            scheduleData.formattedDate = this.formattedServiceDate;
        } else if (this.isRecurring) {
            scheduleData.frequency = this.selectedFrequency;
            scheduleData.dayOfWeek = this.selectedDayOfWeek;
            scheduleData.dayOfMonth = this.selectedDayOfMonth;
            scheduleData.startDate = this.recurringStartDate;
            scheduleData.duration = this.selectedDuration;
            scheduleData.endDate = this.recurringEndDate;
            scheduleData.occurrenceCount = this.occurrenceCount;
            scheduleData.upcomingDates = this.upcomingDates;
            scheduleData.description = this.scheduleDescription;
        }

        this.dispatchEvent(new CustomEvent('schedulechange', {
            detail: scheduleData
        }));
    }
}
