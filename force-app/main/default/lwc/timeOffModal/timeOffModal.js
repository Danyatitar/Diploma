import { LightningElement, api, track } from 'lwc';
import createTimeOffRequest from '@salesforce/apex/RequestController.createTimeOffRequest';


export default class TimeOffModal extends LightningElement {

    @api vacationDays = 0;
    @api illnesses = 0;
    @api daysOff = 0;
    @api userId;
    @track selectedType = 'Vacation';
    @track startDate;
    @track endDate;
    @track days = 0;
    @track unusedDays = 0;
    @track errorMessage = '';

    get today() {
        return new Date().toISOString().split('T')[0];
    }

    get minEndDate() {
        return this.startDate || this.today;
    }

    get typeOptions() {
        return [
            { label: 'Vacation', value: 'Vacation' },
            { label: 'Illness', value: 'Illness' },
            { label: 'Day Off', value: 'Day Off' }
        ];
    }

    get isInvalid() {
        return (
            !this.startDate ||
            !this.endDate ||
            this.startDate < this.today ||
            this.endDate < this.startDate ||
            this.days > this.unusedDays
        );
    }

    connectedCallback(){
        this.unusedDays = this.vacationDays;
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        if(this.selectedType === 'Illness') {
            this.unusedDays = this.illnesses;
        } else if (this.selectedType === 'Vacation'){
            this.unusedDays = this.vacationDays;
        }else  if (this.selectedType === 'Day Off'){
            this.unusedDays = this.daysOff;
        }

        this.validateDates();

    }

    handleFromDateChange(event) {
        this.startDate = event.detail.value;
        if (this.endDate && this.endDate < this.startDate) {
            this.endDate = null;
        }
        this.validateDates();
        this.calculateDays();
    }

    handleToDateChange(event) {
        this.endDate = event.detail.value;
        this.validateDates();
        this.calculateDays();
    }

    validateDates() {
        this.errorMessage = '';

        if (this.startDate && this.startDate < this.today) {
            this.errorMessage = 'Start Date cannot be in the past.';
        } else if (this.endDate && this.endDate < this.startDate) {
            this.errorMessage = 'End Date cannot be before Start Date.';
        } else if (this.days > this.unusedDays) {
            this.errorMessage = 'Requested days exceed unused days.';
        }else{
            this.errorMessage = '';
        }
    }

    calculateDays() {
        if (this.startDate && this.endDate) {
            const start = new Date(this.startDate);
            const end = new Date(this.endDate);
            let count = 0;
    
            // Iterate from start to end date
            for (
                let d = new Date(start);
                d <= end;
                d.setDate(d.getDate() + 1)
            ) {
                const day = d.getDay(); // 0 = Sunday, 6 = Saturday
                if (day !== 0 && day !== 6) {
                    count++;
                }
            }
    
            this.days = count;
        } else {
            this.days = 0;
        }
    }
    

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async confirmRequest() {
        if (this.isInvalid) {
            this.validateDates();
            return;
        }

        try {


            await createTimeOffRequest({
                type: this.selectedType,
                startDate: new Date(this.startDate),
                endDate: new Date(this.endDate),
                userId: this.userId
            })


            this.dispatchEvent(new CustomEvent('confirm', {
                detail: {
                    type: this.selectedType,
                    from: this.startDate,
                    to: this.endDate,
                    days: this.days
                }
            }));
            
        } catch (error) {
            console.log(error);
            
        }


        this.closeModal();
    }
}