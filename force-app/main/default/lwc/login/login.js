import { LightningElement, track, wire } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import createAuthURL from '@salesforce/apex/GoogleLoginController.createAuthURL';
import loginUser from '@salesforce/apex/LoginController.loginUser';
import getAccessToken from '@salesforce/apex/GoogleLoginController.getAccessToken';
import getUserInfo from '@salesforce/apex/GoogleLoginController.getUserInfo';


export default class Login extends NavigationMixin(LightningElement){

    showPassword = false;
    codeParam = '';
    email = '';
    password = '';
    namespace = '';

    @wire(getAccessToken, { code: '$codeParam' })
    accessTokenHandler({ error, data }) {

        if (data) {
            console.log(data)
            getUserInfo({accessToken: data}).then(res=>{
   
                document.cookie=`sessionToken=${res}`;
                this[NavigationMixin.Navigate]({        
                    type: "comm__namedPage",
                    attributes: {
                        name: "Home"
                    }      
              });
            })
        } else if (error) {
            console.log('Get token error', error);
        }
    }

    async connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.codeParam = urlParams.get('code') || '';
        this.namespace = await getNamespacePrefix();
    }



    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    async handleLogin() {
        try {

            const sessionToken = await loginUser({ email: this.email, passwordInput: this.password });
            document.cookie = `sessionToken=${sessionToken}; SameSite=Strict; Path=/; Max-Age=3600`;
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Home'
                }
            })

        } catch (error) {
            console.error('Login error:', error.body.message);
            alert('Login failed: ' + error.body.message);
        }
    }

    togglePasswordVisibility() {
        const passwordInput = this.template.querySelector('.password');
        this.showPassword = !this.showPassword;
        passwordInput.type = this.showPassword ? 'text' : 'password';

    }

    async handleLoginGoogle(){
        const result = await createAuthURL();
        window.location.replace(result);
        
    }
}