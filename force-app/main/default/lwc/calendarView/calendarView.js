import getAllExternalUsers from '@salesforce/apex/ExternalUsersController.getAllExternalUsers';
import validateSession from '@salesforce/apex/LoginController.validateSession';
import getAllRequests from '@salesforce/apex/RequestController.getAllRequests';
import getNamespacePrefix from '@salesforce/apex/Utils.getNamespacePrefix';
import { LightningElement, track } from 'lwc';


export default class CalendarView extends LightningElement {

    sessionValid = false;
    userName = '';
    namespace = '';
    @track currentUserId = '';


    @track selectedYear = 2025;
    @track selectedMonth = 1; // February (0-based index)

    daysInMonth = [];

    @track employees = [];

    // staticRequests = [
    //     {
    //         External_User__c: '1',
    //         StartDate__c: '2025-02-10',
    //         EndDate__c: '2025-02-11',
    //         Type__c: 'Vacation'
    //     },
    //     {
    //         External_User__c: '2',
    //         StartDate__c: '2025-02-12',
    //         EndDate__c: '2025-02-12',
    //         Type__c: 'Day Off'
    //     },
    //     {
    //         External_User__c: '3',
    //         StartDate__c: '2025-02-13',
    //         EndDate__c: '2025-02-13',
    //         Type__c: 'Illness'
    //     },
    //     {
    //         External_User__c: '4',
    //         StartDate__c: '2025-02-14',
    //         EndDate__c: '2025-02-14',
    //         Type__c: 'Vacation'
    //     }
    // ];

    @track staticRequests = []

    // @track allEmployees = [
    //     { id: '1', name: 'Anna Dehoda', role: 'Project Manager' },
    //     { id: '2', name: 'Danylo Tytarenko', role: 'Salesforce Developer'},
    //     { id: '3', name: 'Denis Sorokin', role: 'Salesforce Developer' },
    //     { id: '4', name: 'Dmytro Rybalchenko', role: 'QA Automation' }
    // ];

    @track allEmployees = [];

    async connectedCallback() {
        this.namespace = await getNamespacePrefix();
        const sessionToken = this.getCookie('sessionToken');
        if (sessionToken) {
            await this.validateToken(sessionToken);
            await this.fetchUsers();
            await this.fetchRequests();
            this.generateCalendar();

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

    async fetchUsers() {
        try {
            const users = await getAllExternalUsers(); 
            this.allEmployees = users.map(user => ({
                id: user.Id,
                name: user.Name,
                role: user.mtime__Role__c
            }));
        } catch (error) {
            console.error('Error fetching users:', error);
        }
    }

    async fetchRequests() {
        try {
            const requests = await getAllRequests(); 
            this.staticRequests = requests.map(request => ({
                mtime__External_User__c: request.mtime__External_User__c,
                mtime__StartDate__c: request.mtime__StartDate__c,
                mtime__EndDate__c: request.mtime__EndDate__c,
                mtime__Type__c: request.mtime__Type__c
            }));
        } catch (error) {
            console.error('Error fetching requests:', error);
        }
    }


    generateCalendar() {
        // const days = [];
        // const date = new Date(this.selectedYear, this.selectedMonth, 1);
        // while (date.getMonth() === this.selectedMonth) {
        //     const day = date.getDate().toString().padStart(2, '0');
        //     days.push(day);
        //     date.setDate(date.getDate() + 1);
        // }
        const days = [];
        const date = new Date(this.selectedYear, this.selectedMonth, 1);
        while (date.getMonth() === this.selectedMonth) {
            const day = date.getDate().toString().padStart(2, '0');
            const weekdayLetter = date.toLocaleDateString('en-US', { weekday: 'short' }).charAt(0); // e.g. 'M' for Monday
            const isWeekend = date.getDay() === 0 || date.getDay() === 6; // Sunday (0) or Saturday (6)
    
            const className = isWeekend ? 'weekend' : '';
    
            days.push({
                dayNumber: day,
                letter: weekdayLetter,
                className 
            });
    
            date.setDate(date.getDate() + 1);
        }
    
        this.daysInMonth = days;

        this.employees = this.allEmployees.map(emp => {
            const dayStatus = {};
            this.staticRequests.forEach(req => {
                if (req.mtime__External_User__c === emp.id) {
                    const start = new Date(req.mtime__StartDate__c);
                    const end = new Date(req.mtime__EndDate__c);
                    let current = new Date(start);
                    while (current <= end) {
                        if (
                            current.getFullYear() === this.selectedYear &&
                            current.getMonth() === this.selectedMonth
                        ) {
                            const day = current.getDate().toString().padStart(2, '0');
                            dayStatus[day] = req.mtime__Type__c.toLowerCase().replace(' ', '');
                        }
                        current.setDate(current.getDate() + 1);
                    }
                }
            });
            return { ...emp, dayStatus };
        });
    }

    get monthName() {
        return new Date(this.selectedYear, this.selectedMonth).toLocaleString('default', { month: 'long' });
    }

    get years() {
        const current = new Date().getFullYear();
        return [current - 1, current, current + 1];
    }


    get employeeData() {
        return this.employees.map(emp => {
            const dayStatusList = this.daysInMonth.map(day => {
                if(day.className == 'weekend'){
                    return {
                        day: day.dayNumber,
                        className: day.className,
                        status: day.className 
                    };
                }else{
                    return {
                        day: day.dayNumber,
                        className: day.className,
                        status: emp.dayStatus[day.dayNumber] || ''
                    };
                }
                
            });
    
            return {
                id: emp.id,
                name: emp.name,
                role: emp.role,
                dayStatusList
            };
        });
    }
    

    handleYearChange(event) {
        this.selectedYear = parseInt(event.target.value, 10);
        this.generateCalendar();
    }

    goToPreviousMonth() {
        if (this.selectedMonth === 0) {
            this.selectedMonth = 11;
            this.selectedYear--;
        } else {
            this.selectedMonth--;
        }
        this.generateCalendar();
    }

    goToNextMonth() {
        if (this.selectedMonth === 11) {
            this.selectedMonth = 0;
            this.selectedYear++;
        } else {
            this.selectedMonth++;
        }
        this.generateCalendar();
    }
}