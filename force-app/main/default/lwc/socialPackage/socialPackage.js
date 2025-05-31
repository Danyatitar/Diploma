import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsers';
import getExternalUserById from '@salesforce/apex/ExternalUsersController.getExternalUserById';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import getSettings from '@salesforce/apex/MyTimeSettingsController.getSettings';
import getRequestsByDate from '@salesforce/apex/RequestController.getRequestsByDate';
import updateRequestStatus from '@salesforce/apex/RequestController.updateRequestStatus';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import { LightningElement, track } from 'lwc';


export default class socialPackage extends LightningElement {
    @track userOptions = []
    currentUserId = ''
    selectedUserId = ''
    namespace=''
    usedVacations = 0
    usedIllness = 0
    usedDayOff = 0
    usedBudget = 0

    remainingVacations = 0
    remainingIllness = 0
    remainingDayOff = 0
    remainingBudget = 0

    isManager = false;
    isHR = false;
    selectedHR = '';
    selectedManager = ''

    socialPackageDate;
    firstWorkingDate;
    @track currentWorkingYearIndex = 1;
    totalWorkingYears = 1;
    @track isModalOpen = false;
    @track isCompensationModalOpen = false;
    @track timeOffRequests = [];
    @track compensationRequests = [];





    // timeOffRequests = [
    //     {
    //         id: 'r1',
    //         type: 'Vacation',
    //         duration: '13/01/2025 - 17/01/2025',
    //         days: 5,
    //         status: 'Approved'
    //     },
    //     {
    //         id: 'r2',
    //         type: 'Vacation',
    //         duration: '14/11/2024 - 15/11/2024',
    //         days: 2,
    //         status: 'Approved'
    //     },
    //     {
    //         id: 'r3',
    //         type: 'Vacation',
    //         duration: '27/08/2024 - 28/08/2024',
    //         days: 2,
    //         status: 'Approved'
    //     }
    // ];


    // compensationRequests = [
    //     {
    //         id: 'b1',
    //         type: 'Compensation',
    //         date: '13/01/2025',
    //         subject: 'Test',
    //         status: 'Approved',
    //         budget: 100,

    //     },
    //     {
    //         id: 'b2',
    //         type: 'Compensation',
    //         date: '14/11/2024',
    //         subject: 'Test',
    //         status: 'Approved',
    //         budget: 100,

    //     },
    //     {
    //         id: 'b3',
    //         type: 'Compensation',
    //         date: '27/08/2024',
    //         subject: 'Test',
    //         budget: 100,
    //         status: 'Approved'
    //     }
    // ];

    get isFirstYear() {
        return this.currentWorkingYearIndex === 1;
    }
    
    get isLastYear() {
        return this.currentWorkingYearIndex === this.totalWorkingYears;
    }

    get displayedYear() {
        if (!this.firstWorkingDate) return '';
        return this.currentWorkingYearIndex;
    }

    get isMe(){
        return this.currentUserId === this.selectedUserId;
    }
    get canApproveTimeOff(){
        return this.isManager && this.currentUserId === this.selectedManager;
    }

    get canApproveCompensation(){
        return this.isHR && this.currentUserId === this.selectedHR;
    }
    

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.fetchUsers();
            await this.displayRequests();
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
            const settings = await getSettings();
            this.currentUserId = user.Id;
            this.selectedUserId = user.Id;
            this.isHR = user.mtime__IsHR__c;
            this.isManager = user.mtime__IsManager__c;
            this.selectedHR= user.mtime__HR__c;
            this.selectedManager = user.mtime__Manager__c;
            this.usedBudget = user.mtime__Used_Budget__c;
            this.usedVacations = user.mtime__Used_Vacations__c;
            this.usedDayOff = user.mtime__Used_Days_Off__c;
            this.usedIllness = user.mtime__Used_Illnesses__c;
            this.remainingBudget = settings.mtime__Budget__c - user.mtime__Used_Budget__c;
            this.remainingDayOff = settings.mtime__Days_Off__c - user.mtime__Used_Days_Off__c;
            this.remainingIllness = settings.mtime__Illnesses__c - user.mtime__Used_Illnesses__c;
            this.remainingVacations = settings.mtime__Vacancies__c - user.mtime__Used_Vacations__c;
            this.socialPackageDate = new Date();
            this.firstWorkingDate = new Date(user.mtime__FirstWorkingDate__c);

            const socialPackageYear = this.socialPackageDate.getFullYear();
            const firstWorkingYear = this.firstWorkingDate.getFullYear();
            this.totalWorkingYears = socialPackageYear - firstWorkingYear + 1;
            this.currentWorkingYearIndex = this.totalWorkingYears;
        } catch (error) {
            console.error('Session validation error:', error);
        }
    }

    async handlePreviousYear() {
        if (this.currentWorkingYearIndex > 1) {
            this.currentWorkingYearIndex--;
            this.updateSocialPackageDate();
            await this.displayRequests();
        }
    }
    
    async handleNextYear() {
        if (this.currentWorkingYearIndex < this.totalWorkingYears) {
            this.currentWorkingYearIndex++;
            this.updateSocialPackageDate();
            await this.displayRequests();

        } else if (this.currentWorkingYearIndex === this.totalWorkingYears) {
            this.socialPackageDate = new Date();
            await this.displayRequests();

        }
    }

    updateSocialPackageDate() {
        const firstDate = new Date(this.firstWorkingDate);
        const baseYear = firstDate.getFullYear();
        const targetYear = baseYear + this.currentWorkingYearIndex - 1;
    
        if (this.currentWorkingYearIndex === this.totalWorkingYears) {
            this.socialPackageDate = new Date();
        } else {
            const adjustedDate = new Date(firstDate);
            adjustedDate.setFullYear(targetYear);
            adjustedDate.setDate(adjustedDate.getDate() - 1);
        
            this.socialPackageDate = adjustedDate;        
        }
    }
    

    async fetchUsers() {
        try {
            const users = await getAllExternalUsers(); 
            this.userOptions = users.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } catch (error) {
            console.error('Error fetching users:', error);
        }
    }

    async handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        await this.getUserInfo();
        await this.displayRequests();
    }

    async getUserInfo(){
        const user = await getExternalUserById({userId: this.selectedUserId});
        const settings = await getSettings();
        this.usedBudget = user.mtime__Used_Budget__c;
        this.usedVacations = user.mtime__Used_Vacations__c;
        this.usedDayOff = user.mtime__Used_Days_Off__c;
        this.usedIllness = user.mtime__Used_Illnesses__c;
        this.selectedHR= user.mtime__HR__c;
        this.selectedManager = user.mtime__Manager__c;
        this.remainingBudget = settings.mtime__Budget__c - user.mtime__Used_Budget__c;
        this.remainingDayOff = settings.mtime__Days_Off__c - user.mtime__Used_Days_Off__c;
        this.remainingIllness = settings.mtime__Illnesses__c - user.mtime__Used_Illnesses__c;
        this.remainingVacations = settings.mtime__Vacancies__c - user.mtime__Used_Vacations__c;
        this.socialPackageDate = new Date();
        this.firstWorkingDate = new Date(user.mtime__FirstWorkingDate__c);

        const socialPackageYear = this.socialPackageDate.getFullYear();
        const firstWorkingYear = this.firstWorkingDate.getFullYear();
        this.totalWorkingYears = socialPackageYear - firstWorkingYear + 1;
        this.currentWorkingYearIndex = this.totalWorkingYears;
    }



    openModal() {
        this.isModalOpen = true;
    }

    handleModalClose() {
        this.isModalOpen = false;
    }

    async handleModalConfirm(event) {
        const { type, from, to, days } = event.detail;
        await this.displayRequests();
        await this.getUserInfo();
        this.isModalOpen = false;
    }

    openCompensationModal() {
        this.isCompensationModalOpen = true;
    }

    handleCompensationModalClose() {
        this.isCompensationModalOpen = false;
    }

    async handleCompensationModalConfirm(event) {
        await this.displayRequests();
        await this.getUserInfo();
        this.isCompensationModalOpen = false;
    }

    async displayRequests(){

        
        if (!this.firstWorkingDate || !this.selectedUserId) return;

        // Clone the original firstWorkingDate
        const startDate = new Date(this.firstWorkingDate);
        const baseYear = startDate.getFullYear();
    
        // Set startDate to the correct working year
        const targetYear = baseYear + this.currentWorkingYearIndex - 1;
        startDate.setFullYear(targetYear);
    
        // Calculate endDate as one year after startDate minus 1 day
        const endDate = new Date(startDate);
        endDate.setFullYear(endDate.getFullYear() + 1);
        endDate.setDate(endDate.getDate() - 1);
    
        try {
            const requests = await getRequestsByDate({
                startDate,
                endDate,
                userId: this.selectedUserId
            });

            this.compensationRequests = []
            this.timeOffRequests = []
            // Do something with the requests

            if(requests!=null && Array.isArray(requests) && requests.length>0){
                for(let i=0; i<requests.length; i++){
                    const statusClass = this.getStatusClass(requests[i].mtime__Status__c);

                    if(requests[i].mtime__Type__c == 'Compensation'){
                        this.compensationRequests.push({
                            id: requests[i].Id,
                            type: 'Compensation',
                            date: requests[i].mtime__Date__c,
                            subject: requests[i].mtime__Subject__c,
                            status: requests[i].mtime__Status__c,
                            budget: requests[i].mtime__Budget__c,
                            statusClass: statusClass,
                            displayActions: requests[i].mtime__Status__c == 'Pending'
                        })
                    }else{
                        this.timeOffRequests.push({
                            id: requests[i].Id,
                            type: requests[i].mtime__Type__c,
                            duration: `${requests[i].mtime__StartDate__c} - ${requests[i].mtime__EndDate__c}`,
                            days: requests[i].mtime__Duration__c,
                            status: requests[i].mtime__Status__c,
                            statusClass: statusClass,
                            displayActions: requests[i].mtime__Status__c == 'Pending'

                        })
                    }
                }
            }
           
        } catch (error) {
            console.error('Error fetching requests:', error);
        }    
    }


    async handleApprove(event) {
        const requestId = event.currentTarget.dataset.id;
        await updateRequestStatus({ requestId, status: 'Approved' });
        await this.getUserInfo();
        await this.displayRequests();
    }

    async handleDecline(event) {
        const requestId = event.currentTarget.dataset.id;
        await updateRequestStatus({ requestId, status: 'Declined' });
        await this.getUserInfo();
        await this.displayRequests();


    }

    getStatusClass(status) {
        switch (status) {
            case 'Approved':
                return 'badge approved';
            case 'Pending':
                return 'badge pending';
            case 'Declined':
                return 'badge declined';
            default:
                return 'badge pending';
        }
    }
       
}