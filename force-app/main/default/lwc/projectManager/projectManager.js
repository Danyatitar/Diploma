import { LightningElement, api, wire, track } from 'lwc';
import getUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsers';
import getProjectData from '@salesforce/apex/ProjectController.getProjectData';
import saveMembers from '@salesforce/apex/ProjectController.saveProjectMembers';
import saveTaskTypes from '@salesforce/apex/ProjectController.saveTaskTypes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProjectManager extends LightningElement {
    @api recordId;
    @track userOptions = [];
    @track selectedUserIds = [];
    @track taskTypes = [];
    newTaskType = '';

    async connectedCallback() {
        await this.loadData();
    }

    async loadData() {
        try {
            const users = await getUsers();
            this.userOptions = users.map(user => ({
                label: user.Name,
                value: user.Id
            }));

            const projectData = await getProjectData({ projectId: this.recordId });
            this.selectedUserIds = projectData.assignedUserIds || [];

            if (projectData.taskTypesString) {
                this.taskTypes = projectData.taskTypesString.split(';').filter(t => t.trim());
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error loading data', 'error');
        }
    }

    handleUserChange(event) {
        this.selectedUserIds = event.detail.value;

    }

    handleNewTypeChange(event) {
        this.newTaskType = event.target.value;
    }

    addTaskType() {
        const trimmed = this.newTaskType.trim();
        if (trimmed && !this.taskTypes.includes(trimmed)) {
            this.taskTypes = [...this.taskTypes, trimmed];
            this.newTaskType = '';
        }
    }

    removeType(event) {
        const typeToRemove = event.currentTarget.dataset.type;
        this.taskTypes = this.taskTypes.filter(t => t !== typeToRemove);
    }

    async saveAssignments() {
        try {
            await saveMembers({ projectId: this.recordId, userIds: this.selectedUserIds });
            await this.loadData();
            this.showToast('Success', 'Users assigned successfully', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error saving assignments', 'error');
        }
    }

    async saveTaskTypes() {
        try {
            const taskTypeString = this.taskTypes.join(';');
            await saveTaskTypes({ projectId: this.recordId, taskTypes: taskTypeString });
            await this.loadData();
            this.showToast('Success', 'Task types updated', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error saving task types', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}