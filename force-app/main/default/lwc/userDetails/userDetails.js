import { LightningElement,api,wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import getExternalUserById from '@salesforce/apex/ExternalUsersController.getExternalUserById';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import validateSession from '@salesforce/apex/LoginController.validateSession';

export default class UserDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    currentUserId;
    _hasInitialized = false;
    isModalOpen = false;
    userImage = '';
    fullName;
    role;
    phone;
    email;
    selectedHR;
    isHR = false;

    careerDetails = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (!currentPageReference || this._hasInitialized) return;

        const recordIdFromUrl = currentPageReference.state?.c__recordId || currentPageReference.state?.recordId;
        if (!this.recordId && recordIdFromUrl) {
            this.recordId = recordIdFromUrl;
        }

        this._hasInitialized = true;

    }

    get canModify(){
        return (this.isHR &&  this.currentUserId === this.selectedHR) ||(this.currentUserId === this.recordId);
    }

    // async connectedCallback() {
    //     await this.fetchUser();
    // }

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.fetchUser();
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
            this.currentUserId = user.Id;
            this.isHR = user.mtime__IsHR__c;
        } catch (error) {
            console.error('Session validation error:', error);
        }
    }


    async fetchUser(){
        const user = await getExternalUserById({userId: this.recordId});
        this.email = user.mtime__Email__c;
        this.phone = user.mtime__Phone__c;
        this.fullName = user.mtime__Name;
        this.role = user.mtime__Role__c;
        this.selectedHR = user.mtime__HR__c;
        this.careerDetails = [
            { label: 'Role', value: user.mtime__Role__c, icon: 'standard:user' },
            { label: 'Level', value: user.mtime__Level__c, icon: 'standard:news' },
            { label: 'English Level', value: user.mtime__EnglishLevel__c, icon: 'standard:quip' },
            { label: 'Lead', value: user.mtime__Manager__r.Name, icon: 'standard:groups' },
            { label: 'First working day', value: user.mtime__FirstWorkingDate__c, icon: 'standard:event' },
            { label: 'HR', value: user.mtime__HR__r.Name, icon: 'standard:people' },
        ];
    }

    openModal() {
        this.isModalOpen = true;
    }

    handleModalClose() {
        this.isModalOpen = false;
    }

    async handleModalConfirm(event) {
        await this.fetchUser();
        this.isModalOpen = false;
    }

    

    // navigateToLinkedIn() {
    //     window.open('', '_blank');
    // }

    // navigateToInstagram() {
    //     window.open('', '_blank');
    // }
}