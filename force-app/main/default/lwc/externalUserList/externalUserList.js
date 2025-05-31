import getManagers from '@salesforce/apex/ExternalUsersController.getManagers';
import getTotalCount from '@salesforce/apex/ExternalUsersController.getTotalCount';
import getUsers from '@salesforce/apex/ExternalUsersController.getUsersByFilters';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, track } from 'lwc';


export default class ExternalUserList extends NavigationMixin(LightningElement) {
    @track users = [];
    @track pageNumber = 1;
    @track totalCount = 0;
    pageSize = 10;
    isModalOpen = false;
    isHR = false;
    currentUserId = '';

    @track filters = {
        name: '',
        role: '',
        lead: '',
        client: ''
    };

    @track leadOptions = [
        { label: 'All', value: '' }
    ];

    get isPreviousDisabled() {
        return this.pageNumber === 1;
    }



    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.loadData();
            await this.loadManagers();
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


    async loadManagers() {
        const managers = await getManagers();
        this.leadOptions = [
            { label: 'All', value: '' },
            ...managers.map(manager => ({
                label: manager.Name,
                value: manager.Id
            }))
        ]
    }

    async loadData() {
        this.users = await getUsers({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            nameFilter: this.filters.name ?? '',
            roleFilter: this.filters.role ?? '',
            leadFilter:  this.filters.lead ?? '',
            clientFilter: this.filters.client ?? ''
        })






        this.totalCount = await getTotalCount({nameFilter: this.filters.name ?? '',
            roleFilter: this.filters.role ?? '',
            leadFilter:  this.filters.lead ?? '',
            clientFilter: this.filters.client ?? '' })
    }

    get isLastPage() {
        return this.pageNumber >= Math.ceil(this.totalCount / this.pageSize);
    }

   async handleInputChange(event) {
        const field = event.target.dataset.field;
        this.filters[field] = event.target.value;
        this.pageNumber = 1;
        await this.loadData();
    }

    async handleNext() {
        this.pageNumber++;
        await this.loadData();
    }

    async handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            await this.loadData();
        }
    }

    handleUserClick(event){
        const recordId = event.target.dataset.id;

        //console.log('error')
        console.log('Record ID from record page:', recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'mtime__External_User__c',
                actionName: 'view'
            },
            state: {
                c__recordId: recordId
            }
        });
        
    }

    openModal() {
        this.isModalOpen = true;
    }

    handleModalClose() {
        this.isModalOpen = false;
    }

    async handleModalConfirm(event) {
        await this.loadData();
        this.isModalOpen = false;
    }
}