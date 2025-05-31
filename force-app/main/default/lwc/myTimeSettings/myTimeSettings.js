import getSettings from '@salesforce/apex/MyTimeSettingsController.getSettings';
import saveSettings from '@salesforce/apex/MyTimeSettingsController.saveSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, track } from 'lwc';

export default class MyTimeSettings extends LightningElement {
    @track settings = {};
    @track domains = [];
    newDomain = '';

    connectedCallback() {
        this.loadSettings();
    }

    loadSettings() {
        getSettings()
            .then(result => {
                this.settings = { ...result };
                this.domains = (result.mtime__Allowed_Domains__c || '').split(';').filter(Boolean);
            })
            .catch(error => {
                console.error('Error loading settings:', error);
            });
    }

    handleChange(event) {
        const field = event.target.name;
        this.settings[field] = event.target.value;
    }

    handleNewDomainChange(event) {
        this.newDomain = event.target.value.trim();
    }

    addDomain() {
        if (this.newDomain && !this.domains.includes(this.newDomain)) {
            this.domains = [...this.domains, this.newDomain];
            this.newDomain = '';
        }
    }

    removeDomain(event) {
        const index = event.target.dataset.index;
        this.domains.splice(index, 1);
        this.domains = [...this.domains]; // trigger reactivity
    }

    handleSave() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .every(input => input.reportValidity());

        if (!allValid) return;

        this.settings.mtime__Allowed_Domains__c = this.domains.join(';');

        saveSettings({ settings: this.settings })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Settings updated successfully',
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error('Error saving settings:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to save settings',
                    variant: 'error'
                }));
            });
    }
}