@isTest
private class ProjectControllerTest {
    
    @testSetup
    static void setupTestData() {
        
       MyTime_Settings__c settings = new MyTime_Settings__c(
            Days_Off__c = 10,
            Hours_per_week__c = 40,
            Illnesses__c = 5,
            Salary_Day_number_of_day__c = 15,
            Taxes__c = 20,
            Vacancies__c = 3,
            Budget__c = 90,
            Allowed_Domains__c = 'example.com'
        );
        insert settings;
        // Create test External Users
        List<External_User__c> users = new List<External_User__c>();
        for (Integer i = 1; i <= 3; i++) {
            users.add(new External_User__c(
                Name = 'Test User ' + i,
                Email__c = 'user' + i + '@example.com'
            ));
        }
        insert users;

        // Create Project
        Project__c proj = new Project__c(Name = 'Test Project', TaskTypes__c = 'Vacation;Illness', Rate__c = 100);
        insert proj;

        // Assign first two users to the project
        List<Project_Member__c> members = new List<Project_Member__c>{
            new Project_Member__c(Project__c = proj.Id, Member__c = users[0].Id),
            new Project_Member__c(Project__c = proj.Id, Member__c = users[1].Id)
        };
        insert members;

        // Optional: Insert MyTime_Settings__c if needed
   
    }

    @isTest
    static void testGetProjectsTasksById() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<Project__c> result = ProjectController.getProjectsTasksById(proj.Id);
        Test.stopTest();
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testGetProjectsByUserId() {
        External_User__c user = [SELECT Id FROM External_User__c LIMIT 1];
        Test.startTest();
        List<Project_Member__c> result = ProjectController.getProjectsByUserId(user.Id);
        Test.stopTest();
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetProjectByName() {
        Test.startTest();
        List<Project__c> projects = ProjectController.getProjectByName('Test Project');
        Test.stopTest();
        System.assertEquals(1, projects.size());
    }

    @isTest
    static void testCreateSocialPackageProject() {
        Test.startTest();
        Project__c p = ProjectController.createSocialPackageProject();
        Test.stopTest();
        System.assertEquals('Social Package', p.Name);
        System.assert(p.Id != null);
    }

    @isTest
    static void testSaveTaskTypes() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        ProjectController.saveTaskTypes(proj.Id, 'Vacation;Sick Leave');
        Test.stopTest();

        Project__c updated = [SELECT TaskTypes__c FROM Project__c WHERE Id = :proj.Id];
        System.assertEquals('Vacation;Sick Leave', updated.TaskTypes__c);
    }

    @isTest
    static void testSaveProjectMembers() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        List<External_User__c> users = [SELECT Id FROM External_User__c ORDER BY CreatedDate ASC LIMIT 3];
        List<Id> newMemberIds = new List<Id>{ users[2].Id }; // replace previous members

        Test.startTest();
        ProjectController.saveProjectMembers(proj.Id, newMemberIds);
        Test.stopTest();

        List<Project_Member__c> updatedMembers = [SELECT Member__c FROM Project_Member__c WHERE Project__c = :proj.Id];
        System.assertEquals(1, updatedMembers.size());
        System.assertEquals(users[2].Id, updatedMembers[0].Member__c);
    }

    @isTest
    static void testGetProjectData() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ProjectController.getProjectData(proj.Id);
        Test.stopTest();

        System.assert(result.containsKey('assignedUserIds'));
        System.assert(result.containsKey('taskTypesString'));
    }
}