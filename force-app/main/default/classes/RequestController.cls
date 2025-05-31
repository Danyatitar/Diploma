public without sharing class RequestController {
    
    @AuraEnabled
    public static List<Request__c> getRequestsByDate(Date startDate, Date endDate, Id userId) {

        List<Request__c> requests = new  List<Request__c>();
        List<Request__c> timeOffRequests = [Select Id, StartDate__c, EndDate__c, Status__c, Type__c, Duration__c from Request__c where (Type__c !='Compensation' AND StartDate__c>=:startDate AND StartDate__c<=:endDate AND External_User__c=:userId )];

        for(Request__c request:timeOffRequests){
            requests.add(request);
        }
        List<Request__c> compensationRequests = [Select Id, Date__c, Status__c, Type__c, Budget__c, DocumentLink__c, Subject__c from Request__c where (Type__c ='Compensation' AND Date__c>=:startDate AND Date__c<=:endDate AND External_User__c=:userId )];

        for(Request__c request:compensationRequests){
            requests.add(request);
        }

        return requests;
    }

    @AuraEnabled(cacheable=true)
    public static List<Request__c> getAllRequests() {

        List<Request__c> requests = [Select StartDate__c, EndDate__c, Type__c, Id, External_User__c from Request__c where Type__c != 'Compensation' and Status__c = 'Approved'];
        return requests;
    }

    @AuraEnabled
    public static void createTimeOffRequest(Date startDate, Date endDate, Id userId, String type) {

        // Integer duration = 0;
    
        // for (Date currentDate = startDate; currentDate <= endDate; currentDate = currentDate.addDays(1)) {
        //     Integer dayOfWeek = currentDate.toStartOfWeek().daysBetween(currentDate);
        //     if (dayOfWeek != 0 && dayOfWeek != 6) {
        //         duration++;
        //     }
        // }
        Request__c request = new Request__c(
            StartDate__c = startDate,
            EndDate__c = endDate,
            Status__c = 'Pending',
            Type__c = type,
            External_User__c = userId
        );

        //     External_User__c user = ExternalUsersController.getExternalUserById(request.External_User__c);
        //     switch on request.Type__c {
        //         when 'Vacation' {
        //             user.Used_Vacations__c += request.Duration__c;
        //         } 
        //         when  'Illness'{
        //             user.Used_Illnesses__c += request.Duration__c;

        //         }
        //         when 'Day Off'{
        //             user.Used_Days_Off__c += request.Duration__c;
        //         }
        //     }
        // update user;
        insert request;
    }


    @AuraEnabled
    public static void createCompensationRequest(Date dateOfPaying, Id userId, Integer budget, String link, String subject) {

        Decimal formattedCurrency = Decimal.valueOf(budget);
        Request__c request = new Request__c(
            Date__c = dateOfPaying,
            DocumentLink__c = link,
            Status__c = 'Pending',
            Type__c = 'Compensation',
            External_User__c = userId,
            Budget__c = formattedCurrency,
            Subject__c = subject
        );
           
        
        // External_User__c user = ExternalUsersController.getExternalUserById(request.External_User__c);
        // user.Used_Budget__c += request.Budget__c;


        insert request;
    }

    @AuraEnabled
    public static void updateRequestStatus(Id requestId, String status) {

        Request__c request = [Select Id, Status__c, External_User__c, Type__c, Duration__c, Budget__c, StartDate__c, EndDate__c from Request__c where Id=:requestId limit 1];

        request.Status__c = status;
        // External_User__c user = ExternalUsersController.getExternalUserById(request.External_User__c);


        // if(status=='Declined'){
        //     switch on request.Type__c {
        //         when 'Vacation' {
        //             user.Used_Vacations__c -= request.Duration__c;
        //         } 
        //         when  'Illness'{
        //             user.Used_Illnesses__c -= request.Duration__c;

        //         }
        //         when 'Day Off'{
        //             user.Used_Days_Off__c -= request.Duration__c;
        //         }
        //         when 'Compensation' {
        //             user.Used_Budget__c -= request.Budget__c;
        //         }
        //     }
        // }

       

        // if(status == 'Approved'){
            

        //     if(request.Type__c != 'Compensation'){
        //         List<Project__c> project = ProjectController.getProjectByName('Social Package');
        //         List<Report__c> reportsToInsert = new List<Report__c>();
                
        //         if(project.isEmpty()){
        //             Project__c newProject = ProjectController.createSocialPackageProject();
        //             project.add(newProject);
        //         }
            
        //         Date currentDate = request.StartDate__c;
        //         Integer createdReports = 0;
            
        //         while (createdReports < request.Duration__c) {
        //             Integer dayOfWeek = currentDate.toStartOfWeek().daysBetween(currentDate); // 0 = Sunday, 6 = Saturday
        //             if (dayOfWeek != 0 && dayOfWeek != 6) {
        //                 Report__c newReport = ReportController.createReportWithoutInsert(
        //                     currentDate,
        //                     project[0].Id,
        //                     request.Type__c,
        //                     request.Status__c,
        //                     0,
        //                     8,
        //                     request.External_User__c
        //                 );
        //                 reportsToInsert.add(newReport);
        //                 createdReports++;
        //             }
        //             currentDate = currentDate.addDays(1);
        //         }
            
        //         insert reportsToInsert;
        //     }
            

        // }


        // update user;

        update request;


    }
}