import getProjectsByUserId from '@salesforce/apex/ProjectController.getProjectsByUserId';
import getProjectsTasksById from '@salesforce/apex/ProjectController.getProjectsTasksById';
import getReportById from '@salesforce/apex/ReportController.getReportById';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import { LightningElement, api, track } from 'lwc';
export default class ReportPopUp extends LightningElement {
    @api isOpen = false;
    @api date;
    _userId;
    @api
    set userId(value) {
        this._userId = value;
        if (value) {
            this.initializeComponent();
        }
    }
    get userId() {
        return this._userId;
    }   
     _report;
    @api
    set report(value) {
        this._report = value;
        if (value) {
            this.initializeComponent();
        }
    }
    get report() {
        return this._report;
    }

    namespace;

    @track project = '';
    @track task = '';
    @track description = '';
    @track minutesSpent = 0;
    @track projectOptions = [];
    @track taskOptions = [];

    timeOptions = [
        { label: '+ 15 min', minutes: 15 },
        { label: '+ 30 min', minutes: 30 },
        { label: '+ 1 hour', minutes: 60 },
        { label: '+ 8 hours', minutes: 480 },
    ];

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
       
    }

    renderedCallback(){

    }


    async initializeComponent() {
        if (!this.userId) return;

        await this.fetchProjects();
        await this.initializeFields();
    }


    // async renderedCallback(){
    //     if (this.userId && this.isOpen) {
    //         await this.fetchProjects();
    //         this.initializeFields(); // New: Set initial values if editing
    //     }
    // }

    async initializeFields() {
        if (this.report) {
            const reportData = await getReportById({reportId: this.report});
            console.log(JSON.stringify(reportData))
            this.project = reportData.mtime__Project__c;
            this.description = reportData.mtime__Description__c;
            const totalMinutes = (reportData.mtime__Hours__c || 0) * 60 + (reportData.mtime__Minutes__c || 0);
            this.minutesSpent = totalMinutes;

            getProjectsTasksById({ projectId: this.project })
                .then(result => {
                    if (result.length > 0 && result[0].mtime__TaskTypes__c) {
                        this.taskOptions = result[0].mtime__TaskTypes__c.split(';').map(task => ({
                            label: task.trim(),
                            value: task.trim()
                        }));
                    }
                    this.task = reportData.mtime__TaskType__c;

                })
                .catch(error => console.error('Error fetching task types:', error));
        }
    }


    async fetchProjects() {
        try {
            const result = await getProjectsByUserId({ userId: this.userId });
            this.projectOptions = result.map(item => ({
                label: item.mtime__Project__r.Name,
                value: item.mtime__Project__c
            }));
        } catch (error) {
            console.error('Error fetching projects:', error);
        }
    }

    get formattedDate() {
        return new Date(this.date).toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'short' });
    }

    get formattedTime() {
        const hours = Math.floor(this.minutesSpent / 60);
        const minutes = this.minutesSpent % 60;
        return `${hours}:${minutes.toString().padStart(2, '0')}`;
    }

    handleProjectChange(e) {
        this.project = e.detail.value;
        this.task = '';
        this.taskOptions = [];

        getProjectsTasksById({ projectId: this.project })
            .then(result => {
                if (result.length > 0 && result[0].mtime__TaskTypes__c) {
                    this.taskOptions = result[0].mtime__TaskTypes__c.split(';').map(task => ({
                        label: task.trim(),
                        value: task.trim()
                    }));
                }
            })
            .catch(error => console.error('Error fetching task types:', error));
    }

    handleTaskChange(e) {
        this.task = e.target.value;
    }

    handleDescriptionChange(e) {
        this.description = e.target.value;
    }

    handleTimeClick(e) {
        this.minutesSpent += parseInt(e.currentTarget.dataset.minutes, 10);
    }

    increaseTime() {
        this.minutesSpent += 15;
    }

    decreaseTime() {
        this.minutesSpent = Math.max(this.minutesSpent - 15, 0);
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));

        this._report = null;
        this.project = '';
        this.task='';
        this.description = '';
        this.minutesSpent = 0;
        this.hoursSpent = 0


    }

    handleSave() {
        const hours = Math.floor(this.minutesSpent / 60);
        const minutes = this.minutesSpent % 60;

        const detail = {
            reportId: this.report, 
            date: this.date,
            project: this.project,
            task: this.task,
            description: this.description,
            minutesSpent: minutes,
            hoursSpent: hours
        };

        this.dispatchEvent(new CustomEvent('save', { detail }));

        this._report = null;
        this.project = '';
        this.task='';
        this.description = '';
        this.minutesSpent = 0;
        this.hoursSpent = 0
    }
}