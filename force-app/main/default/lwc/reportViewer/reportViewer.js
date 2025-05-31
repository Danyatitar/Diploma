import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsersByManager';
import { LightningElement, track } from 'lwc';

//import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsers';import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import getReportsByDatePeriod from '@salesforce/apex/ReportController.getReportsByDatePeriod';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';

export default class ReportViewer extends LightningElement {

    sessionValid = false;
    userName = '';
    namespace = '';
    @track selectedUserId = '';
    @track fromDate;
    @track toDate;
    @track groupedReports;
    @track totalPeriodHours = 0;

    @track userOptions = [];
    @track allReports = [];

    // allReports = [
    //     {
    //         id: 'r1',
    //         userId: 'u1',
    //         date: '2025-05-01',
    //         projectName: 'Project A',
    //         taskType: 'Development',
    //         hours: 4
    //     },
    //     {
    //         id: 'r2',
    //         userId: 'u1',
    //         date: '2025-05-01',
    //         projectName: 'Project A',
    //         taskType: 'Testing',
    //         hours: 2
    //     },
    //     {
    //         id: 'r3',
    //         userId: 'u1',
    //         date: '2025-05-02',
    //         projectName: 'Project B',
    //         taskType: 'Design',
    //         hours: 3
    //     },
    //     {
    //         id: 'r4',
    //         userId: 'u2',
    //         date: '2025-05-01',
    //         projectName: 'Project C',
    //         taskType: 'Research',
    //         hours: 5
    //     }
    // ];


    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.fetchUsers();
            this.setDefaultDates();
            await this.fetchReports();
            this.loadReports();
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
            this.sessionValid = true;
            this.userName = user.Name;
            this.selectedUserId = user.Id;
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
                value: this.selectedUserId
            })
        } catch (error) {
            console.error('Error fetching users:', error);
        }
    }

    setDefaultDates() {
        const today = new Date();
        const year = today.getFullYear();
        const month = today.getMonth();

        const firstDay = new Date(year, month, 1, 12);
        const lastDay = new Date(year, month+1, 0, 12);


        this.fromDate = this.formatDate(firstDay);
        this.toDate = this.formatDate(lastDay);
    }

    formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    async handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        await this.fetchReports();
        this.loadReports();
    }

    async handleFromDateChange(event) {
        this.fromDate = event.target.value;
        await this.fetchReports();
        this.loadReports();
    }

    async handleToDateChange(event) {
        this.toDate = event.target.value;
        await this.fetchReports();
        this.loadReports();
    }

    async fetchReports(){
        try {
            const reports = await getReportsByDatePeriod({ userId: this.selectedUserId, fromDate: this.fromDate, toDate: this.toDate})
            this.allReports = reports.map(report => ({
                id: report.Id,
                userId: report.mtime__External_User__c,
                date: report.mtime__Date__c,
                projectName: report.mtime__Project__r.Name,
                taskType: report.mtime__TaskType__c,
                hours: report.mtime__Hours__c
            }));
        } catch (error) {
            console.error('Error fetching reports:', error);
        }
    }

    loadReports() {
        if (!this.selectedUserId || !this.fromDate || !this.toDate) return;

        const from = new Date(this.fromDate);
        const to = new Date(this.toDate);

        console.log(JSON.stringify(this.allReports))

        const filtered = this.allReports.filter(r => {
            const date = new Date(r.date);
            return r.userId === this.selectedUserId && date >= from && date <= to;
        });

        this.totalPeriodHours = filtered.reduce((sum, r) => sum + (r.hours || 0), 0);
        this.groupedReports = this.processData(filtered);
    }

    processData(data) {
        const map = new Map();

        data.forEach(record => {
            const projectName = record.projectName;
            if (!map.has(projectName)) {
                map.set(projectName, { taskMap: new Map(), totalHours: 0 });
            }

            const project = map.get(projectName);
            const taskType = record.taskType || 'Unspecified';
            const hours = record.hours || 0;

            project.totalHours += hours;
            project.taskMap.set(taskType, (project.taskMap.get(taskType) || 0) + hours);
        });

        const result = [];
        for (let [projectName, { taskMap, totalHours }] of map.entries()) {
            const taskTypes = [];
            for (let [name, hours] of taskMap.entries()) {
                taskTypes.push({ name, hours });
            }

            result.push({ projectName, taskTypes, totalHours });
        }

        return result;
    }
}