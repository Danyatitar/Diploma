import { LightningElement, api, track } from 'lwc';
import createCompensationRequest from '@salesforce/apex/RequestController.createCompensationRequest';


export default class CompensationModal extends LightningElement {
    @api unusedBudget;
    @api userId;
    @track subject = '';
    @track date;
    @track link = '';
    @track budget = 0;
    @track errorMessage = '';
    @track budgetErrorMessage = '';

    get today() {
        return new Date().toISOString().split('T')[0];
    }

    get isInvalid() {
        return !this.subject || !this.date || this.date < this.today || !this.isValidUrl(this.link) || this.budget <= 0 || this.budget > this.unusedBudget;
    }

    connectedCallback() {
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
        this.validateInputs();
    }

    handleDateChange(event) {
        this.date = event.target.value;
        this.validateInputs();
    }

    handleLinkChange(event) {
        this.link = event.target.value;
        this.validateInputs();
    }

    handleBudgetChange(event) {
        this.budget = parseFloat(event.target.value);
        this.validateInputs();
    }

    validateInputs() {
        this.errorMessage = '';
        this.budgetErrorMessage = '';

        if (!this.subject) {
            this.errorMessage = 'Subject is required.';
        } else if (!this.date || this.date < this.today) {
            this.errorMessage = 'Date cannot be earlier than today.';
        } else if (!this.isValidUrl(this.link)) {
            this.errorMessage = 'Please enter a valid URL.';
        }

        if (this.budget > this.unusedBudget) {
            this.budgetErrorMessage = `Budget cannot exceed unused budget of $${this.unusedBudget}.`;
        }
    }

    isValidUrl(value) {
        try {
            new URL(value);
            return true;
        } catch (_) {
            return false;
        }
    }

    async handleSubmit() {
        this.validateInputs();
        if (this.isInvalid) return;
            try {
                const details = {
                    subject: this.subject,
                    date: this.date,
                    link: this.link,
                    budget: this.budget
                };

                await createCompensationRequest({ dateOfPaying: this.date, budget: this.budget, subject: this.subject, link: this.link, userId: this.userId })
        
        
                this.dispatchEvent(new CustomEvent('submit', { detail: details }));
                this.closeModal();
                
            } catch (error) {
                console.log(error);
            } 
        
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}