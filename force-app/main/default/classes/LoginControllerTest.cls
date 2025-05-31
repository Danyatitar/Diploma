@isTest
private class LoginControllerTest {

    private static External_User__c createTestUser() {
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
        // Create External_User__c records
        External_User__c user1 = new External_User__c(
            Name = 'Test User 1',
            Email__c = 'testuser1@example.com',
            IsManager__c = false,
            IsHR__c = false,
            Role__c = 'Developer'
        );
        insert user1;
        return user1;
    }
    
     private static External_User__c createTestUserHR() {
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
        // Create External_User__c records
        External_User__c user1 = new External_User__c(
            Name = 'Test User 1',
            Email__c = 'testuser1@example.com',
            IsManager__c = false,
            IsHR__c = true,
            Role__c = 'Developer'
        );
        insert user1;
        return user1;
    }
    private static External_User__c createTestUserManager() {
      
        // Create External_User__c records
        External_User__c user1 = new External_User__c(
            Name = 'Test User 2',
            Email__c = 'testuser2@example.com',
            IsManager__c = true,
            IsHR__c = false,
            Role__c = 'Developer'
        );
        insert user1;
        return user1;
    }

    @isTest
    static void testLoginUser() {
        // Arrange
        External_User__c user = createTestUser();

        Test.startTest();
        String token = LoginController.loginUser(user.Email__c, 'fakePassword');
        GoogleLoginController.createAuthURL();
        Utils.getNamespacePrefix();
        Test.stopTest();
        
        

        System.assertNotEquals(null, token, 'Token should not be null');
        System.assertEquals(
            EncodingUtil.base64Encode(Blob.valueOf(user.Id)),
            token,
            'Token should match encoded user Id'
        );
    }

    @isTest
    static void testValidateSession_validToken() {
        // Arrange
        External_User__c user = createTestUser();
        String token = LoginController.generateSessionToken(user);

        // Act
        Test.startTest();
        External_User__c validatedUser = LoginController.validateSession(EncodingUtil.urlEncode(token, 'UTF-8'));
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, validatedUser, 'Validated user should not be null');
        System.assertEquals(user.Id, validatedUser.Id, 'Validated user ID should match original');
    }



    @isTest
    static void testGenerateSessionToken() {
        External_User__c user = createTestUser();
        String token = LoginController.generateSessionToken(user);

        System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf(user.Id)), token, 'Token should match expected encoding');
        delete user;
    }
    
    @isTest
    static void testUsers() {
        External_User__c user = createTestUserHR();
        External_User__c user2 = createTestUserManager();

        delete user;
        delete user2;
    }
       @isTest
    static void testUsersUpdate() {
        External_User__c user = createTestUserHR();
        External_User__c user2 = createTestUserManager();
		user.IsHR__c = false;
        user2.IsManager__c = false;
        update user;
        update user2;
    }
}