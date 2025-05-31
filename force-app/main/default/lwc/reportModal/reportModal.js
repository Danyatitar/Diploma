import getProjectsByUserId from '@salesforce/apex/ProjectController.getProjectsByUserId';
import getProjectsTasksById from '@salesforce/apex/ProjectController.getProjectsTasksById';
import { LightningElement, api, track, wire } from 'lwc';


export default class ReportModal extends LightningElement {
    @api isOpen = false;
    @api date;
    @api currentUserId

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

    // Wire current user's projects
    @wire(getProjectsByUserId, { userId: this.currentUserId })
    wiredProjects({ error, data }) {
        if (data) {
            this.projectOptions = data.map(item => ({
                label: item.mtime__Project__r.Name,
                value: item.mtime__Project__c
            }));
        } else if (error) {
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

        // Fetch task types for selected project
        getProjectsTasksById({ projectId: this.project })
            .then(result => {
                if (result.length > 0 && result[0].mtime__taskTypes__c) {
                    this.taskOptions = result[0].mtime__taskTypes__c.split(';').map(task => ({
                        label: task.trim(),
                        value: task.trim()
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching task types:', error);
            });
    }

    handleTaskChange(e) {
        this.task = e.detail.value;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleProjectChange(e) {
        this.project = e.target.value;
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

    handleSave() {
        const detail = {
            date: this.date,
            project: this.project,
            task: this.task,
            description: this.description,
            minutesSpent: this.minutesSpent
        };
        this.dispatchEvent(new CustomEvent('save', { detail }));
    }
}