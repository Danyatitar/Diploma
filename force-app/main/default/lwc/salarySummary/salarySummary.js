import { LightningElement, track } from 'lwc';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import getAllSalaryDetails from '@salesforce/apex/SalaryDetailController.getAllSalaryDetails';

export default class SalarySummary extends LightningElement {

    sessionValid = false;
    userName = '';
    namespace = '';
    @track currentUserId = '';

    @track salaries = [];

    @track selected;

    // connectedCallback() {
    //     const rawSalaries = [
    //         {
    //             Id: '1',
    //             Date__c: '2025-04-01',
    //             Rate__c: 50,
    //             Compensation__c: 200,
    //             Hours__c: 160,
    //             Tax__c: 300,
    //             Final__c: 4700
    //         },
    //         {
    //             Id: '2',
    //             Date__c: '2025-03-01',
    //             Rate__c: 48,
    //             Compensation__c: 180,
    //             Hours__c: 150,
    //             Tax__c: 280,
    //             Final__c: 4520
    //         },
    //         {
    //             Id: '3',
    //             Date__c: '2025-02-01',
    //             Rate__c: 47,
    //             Compensation__c: 150,
    //             Hours__c: 140,
    //             Tax__c: 260,
    //             Final__c: 4300
    //         }
    //     ];

    //     // Format date into month-year
    //     this.salaries = rawSalaries.map(sal => ({
    //         ...sal,
    //         monthYear: new Date(sal.Date__c).toLocaleString('default', { month: 'long', year: 'numeric' })
    //     }));

    //     this.selected = this.salaries[0];
    // }


    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.fetchSalaries();
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
            this.currentUserId = user.Id;
        } catch (error) {
            console.error('Session validation error:', error);
        }
    }

    async fetchSalaries() {
        try {
            const salariesDetails = await getAllSalaryDetails({userId: this.currentUserId}); 
            this.salaries = salariesDetails.map(detail => ({
                Id: detail.Id,
                mtime__Date__c: detail.mtime__Date__c,
                mtime__Rate__c: detail.mtime__Rate__c,
                mtime__Compensation__c: detail.mtime__Compensation__c,
                mtime__Hours__c: detail.mtime__Hours__c,
                mtime__Tax__c: detail.mtime__Tax__c,
                mtime__Final__c: detail.mtime__Final__c,
                monthYear: new Date(detail.mtime__Date__c).toLocaleString('default', { month: 'long', year: 'numeric' })


            }));

            this.selected = this.salaries[0];

        } catch (error) {
            console.error('Error fetching salaries:', error);
        }
    }

    handleClick(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selected = this.salaries.find(rec => rec.Id === selectedId);
    }
}