import { LightningElement, api } from 'lwc';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import { NavigationMixin } from 'lightning/navigation';



export default class Header extends NavigationMixin(LightningElement) {
    sessionValid = false;
    userName = '';
    namespace = '';

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
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


    handleLogout() {
        const res = '';
        document.cookie=`sessionToken=${res}`;

        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "Login"
            }
        });

        
    }
}