import getAllHRs from '@salesforce/apex/ExternalUsersController.getAllHRs';
import getExternalUserById from '@salesforce/apex/ExternalUsersController.getExternalUserById';
import getAllManagers from '@salesforce/apex/ExternalUsersController.getManagers';
import saveUser from '@salesforce/apex/ExternalUsersController.saveUser'; // You need to create this
import { LightningElement, api, track } from 'lwc';


export default class UserFormModal extends LightningElement {
    @api recordId; // null for create
    @api currentUserId;
    @api isHR;
    selectedHR;
    canModify = false;
    @track user = {
        Name: '',
        mtime__Email__c: '',
        mtime__Phone__c: '',
        mtime__Role__c: '',
        mtime__HR__c: '',
        mtime__Manager__c: '',
        mtime__FirstWorkingDate__c:'',
        mtime__Level__c: '',
        mtime__EnglishLevel__c: '',
        mtime__IsHR__c: false,
        mtime__IsManager__c: false
    };


    hrOptions = [];
    managerOptions = [];
    levelOptions = [
        {label: 'Trainee', value: 'Trainee'},
        {label: 'Junior', value: 'Junior'},
        {label: 'Middle', value: 'Middle'},
        {label: 'Senior', value: 'Senior'}, 
    ]

    englishOptions = [
        {label: 'Beginner', value: 'Beginner'},
        {label: 'Pre-Intermediate', value: 'Pre-Intermediate'},
        {label: 'Intermediate', value: 'Intermediate'},
        {label: 'Upper-Intermediate', value: 'Upper-Intermediate'}, 
        {label: 'Advanced', value: 'Advanced'},
    ]

    // @wire(getAllHRs)
    // wiredHRs({ error, data }) {
    //     if (data) {
    //         this.hrOptions = data.map(hr => ({ label: hr.Name, value: hr.Id }));
    //     }
    // }

    // @wire(getAllManagers)
    // wiredManagers({ error, data }) {
    //     if (data) {
    //         this.managerOptions = data.map(manager => ({ label: manager.Name, value: manager.Id }));
    //     }
    // }

    get modalTitle() {
        return this.recordId ? 'Edit User' : 'New User';
    }



    async connectedCallback(){
        if(this.recordId){
            await this.fetchUser();
        }
        await this.fetchHRs();
        await this.fetchManagers();

        this.canModify = (this.isHR &&  this.currentUserId === this.selectedHR) || (!this.recordId)
    }


    async fetchUser(){
        this.user = await getExternalUserById({userId: this.recordId});
        this.selectedHR = this.user.mtime__HR__c;
    }

    async fetchHRs(){
        const data = await getAllHRs();
        this.hrOptions = data.map(hr => ({ label: hr.Name, value: hr.Id }));

    }

    async fetchManagers(){
        const data = await getAllManagers();
        this.managerOptions = data.map(manager => ({ label: manager.Name, value: manager.Id }));
    }

    handleChange(event) {
        const { name, value } = event.target;
        this.user[name] = value;
    }

    async handleSave() {


        const isValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
        .filter(input => input.type !== 'checkbox')
        .every(input => input.reportValidity());

        if (!isValid) {
            return;
        }
        try {
            await saveUser({ userRecord: this.user });
            this.dispatchEvent(new CustomEvent('confirm'));
        } catch (error) {
            console.error('Save error:', error);
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}