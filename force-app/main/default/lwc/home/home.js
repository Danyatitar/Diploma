import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsersByManager';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import createReport from '@salesforce/apex/ReportController.createReport';
import deleteReport from '@salesforce/apex/ReportController.deleteReport';
import getReportsByDate from '@salesforce/apex/ReportController.getReportsByDate';
import updateReport from '@salesforce/apex/ReportController.updateReport';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, track } from 'lwc';
import { addDays, formatDate, startOfWeek } from './utils';

//import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsers';
import updateReportStatus from '@salesforce/apex/ReportController.updateReportStatus';
import updateReportsStatusesByWeek from '@salesforce/apex/ReportController.updateReportsStatusesByWeek';

export default class Home extends NavigationMixin(LightningElement) {
    sessionValid = false;
    userName = '';
    namespace = '';
    selectedReport = null;
    @track isManager = false;
    @track userOptions = [];
    @track currentUserId = '';
    @track selectedUserId = '';
    @track selectedDate = new Date();
    @track showReportModal = false;
    @track weekDays = [];
    sessionToken = this.getCookie();
    isDatePickerOpen = false;
    currentWeekStart = null;

    get selectedDay() {
        return this.weekDays.find(day => day.isSelected) || {};
    }

    get selectedDateFormatted() {
        return this.selectedDate.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'short' });
    }

    get progressPercent() {
        return Math.floor((this.currentHours / this.totalHours) * 100);
    }

    get totalWeekTimeFormatted() {
        let totalMinutes = 0;
        this.weekDays.forEach(day => {
            const [hours, minutes] = day.hours.split(':').map(Number);
            totalMinutes += hours * 60 + minutes;
        });
        const hrs = Math.floor(totalMinutes / 60);
        const mins = totalMinutes % 60;
        return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
    }

    get isMe(){
        return this.currentUserId === this.selectedUserId;
    }
    get canApprove(){
        return this.isManager && this.currentUserId !== this.selectedUserId;
    }



    getReportClass(report) {
        return report.mtime__IsApproved__c ? 'report-container approved' : 'report-container';
    }
    get areAllReportsApproved() {
        return this.weekDays.every(day => {
            return day.reports.every(report => report.mtime__IsApproved__c === true);
        });
    }

    get areAnyReportsApproved() {
        return this.weekDays.any(day => {
            return day.reports.any(report => report.mtime__IsApproved__c === true);
        });
    }

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            if(this.isManager){
                await this.fetchUsers();

            }
            await this.generateWeek();
        }
    }

    getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
    }

    async validateToken(token) {
        try {
            const user = await validateSession({ sessionToken: token });
            console.log(JSON.stringify(user))
            this.sessionValid = true;
            this.userName = user.Name;
            this.currentUserId = user.Id;
            this.selectedUserId = user.Id;
            this.isManager = user.mtime__IsManager__c;
            console.log(this.isManager)
        } catch (error) {
            console.error('Session validation error:', error);
        }
    }

    async fetchUsers() {
        try {
            const users = await getAllExternalUsers({ managerId: this.selectedUserId }); 

            this.userOptions = users.map(user => ({
                label: user.Name,
                value: user.Id
            }));

            this.userOptions.push({
                label: 'Me',
                value: this.currentUserId
            })
        } catch (error) {
            console.error('Error fetching users:', error);
        }
    }
    
    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        this.generateWeek(); 
    }
    

    async generateWeek() {
        const weekStart = startOfWeek(this.selectedDate);
        this.weekDays = [];

        for (let i = 0; i < 7; i++) {
            const dayDate = addDays(weekStart, i);
            const isSelected = this.isSameDay(dayDate, this.selectedDate);
            const dateISO = dayDate.toISOString().slice(0, 10);

            const day = {
                date: dateISO,
                label: formatDate(dayDate),
                hours: '00:00',
                isSelected,
                reports: [],
                hasReports: false,
                totalTimeText: '',

            };

            if (this.selectedUserId) {
                try {
                    const reports = await getReportsByDate({
                        dateISO: dateISO,
                        userId: this.selectedUserId
                    });
                    day.reports = reports.map(report => ({
                        ...report,
                        cssClass: report.mtime__IsApproved__c ? 'report-container approved' : 'report-container'
                    }));
                    if (reports.length > 0) {
                        day.hasReports = true;

                        let totalMinutes = reports.reduce((sum, r) => {
                            return sum + (r.mtime__Hours__c * 60 + r.mtime__Minutes__c);
                        }, 0);
                        const hours = Math.floor(totalMinutes / 60);
                        const minutes = totalMinutes % 60;
                        day.hours = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
                        day.totalTimeText = `${day.hours}`;
                    }
                } catch (error) {
                    console.error('Error fetching reports for day:', error);
                }
            }

            this.weekDays.push(day);
        }
    }

    async handlePrevious() {
        const newDate = addDays(this.selectedDate, -1);
        await this.handleDateChange(newDate);
    }

    async handleNext() {
        const newDate = addDays(this.selectedDate, 1);
        await this.handleDateChange(newDate);
    }

    async handleDayClick(event) {
        const clickedDate = new Date(event.currentTarget.dataset.date);
        await this.handleDateChange(clickedDate);
    }

    async handleDateSelected(event) {
        const pickedDate = new Date(event.target.value);
        if (!isNaN(pickedDate)) {
            await this.handleDateChange(pickedDate);
        }
    }

    async handleDateChange(newDate) {
        const newWeekStart = startOfWeek(newDate);
        this.selectedDate = newDate;

        if (!this.currentWeekStart || newWeekStart.toDateString() !== this.currentWeekStart.toDateString()) {
            this.currentWeekStart = newWeekStart;
            await this.generateWeek();
        } else {
            this.weekDays = this.weekDays.map(day => ({
                ...day,
                isSelected: day.date === newDate.toISOString().slice(0, 10)
            }));
            await this.fetchReportsForSelectedDate();
        }
    }

    async fetchReportsForSelectedDate() {
        const dateISO = this.selectedDate.toISOString().slice(0, 10);

        try {
            const reports = await getReportsByDate({
                dateISO,
                userId: this.selectedUserId
            });

            this.weekDays = this.weekDays.map(day => {
                if (day.date === dateISO) {
                    let totalMinutes = reports.reduce((sum, r) => sum + (r.mtime__Hours__c * 60 + r.mtime__Minutes__c), 0);
                    const hours = Math.floor(totalMinutes / 60);
                    const minutes = totalMinutes % 60;
                    return {
                        ...day,
                        reports: reports.map(report => ({
                            ...report,
                            cssClass: report.mtime__IsApproved__c ? 'report-container approved' : 'report-container'
                        })),
                        hasReports: reports.length > 0,
                        hours: `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`,
                        totalTimeText: `Total - ${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
                    };
                }
                return day;
            });
        } catch (error) {
            console.error('Error fetching reports:', error);
        }
    }

    isSameDay(date1, date2) {
        return date1.getFullYear() === date2.getFullYear() &&
               date1.getMonth() === date2.getMonth() &&
               date1.getDate() === date2.getDate();
    }

    openCreateReportModal() {
        this.showReportModal = true;

    }
    openEditReportModal(event) {
        this.selectedReport = event.target.dataset.reportId;
        this.showReportModal = true;

    }

    handleReportClose() {
        this.showReportModal = false;
    }

    async handleReportSave(event) {
        this.showReportModal = false;
        const formData = event.detail;
        const { reportId, date, project, task, description, minutesSpent, hoursSpent } = event.detail;


        try {
            if (reportId) {
                // Editing existing report
                await updateReport({ reportId, dateISO: date, projectId: project, task, description, minutesSpent, hoursSpent});
            } else {
                // Creating new report
                await createReport({ dateISO: date, projectId: project, task, description, minutesSpent, hoursSpent, userId: this.selectedUserId });
            }

            await this.fetchReportsForSelectedDate();
        } catch (error) {
            console.error('Error saving report:', error);
        }
    }
    
    async handleDeleteReport(event) {
        const reportId = event.target.dataset.reportId;
        try {
            await deleteReport({ reportId });
            await this.fetchReportsForSelectedDate();
        } catch (error) {
            console.error('Error deleting report:', error);
        }
    }

    async handleApproveReport(event){
        const reportId = event.target.dataset.reportId;
        try {
            await updateReportStatus({ reportId, value: true });
            await this.fetchReportsForSelectedDate();
        } catch (error) {
            console.error('Error deleting report:', error);
        }
    }

    async handleUnblockReport(event){
        const reportId = event.target.dataset.reportId;
        try {
            await updateReportStatus({ reportId: reportId, value: false });
            await this.fetchReportsForSelectedDate();
        } catch (error) {
            console.error('Error deleting report:', error);
        }
    }

    async handleApproveAll(){
        try {
            const start = this.weekDays[0].date;
            const end = this.weekDays[6].date
            await updateReportsStatusesByWeek({startDateISO: start, endDateISO: end, value: true});
            await this.fetchReportsForSelectedDate();

            
        } catch (error) {
            console.error('Error deleting report:', error);
        }
    }

    async handleUnblockAll(){
        try {
            const start = this.weekDays[0].date;
            const end = this.weekDays[6].date
            await updateReportsStatusesByWeek({startDateISO: start, endDateISO: end, value: false});
            await this.fetchReportsForSelectedDate();

            
        } catch (error) {
            console.error('Error deleting report:', error);
        }
    }
}