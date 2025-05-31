public without sharing class LoginController {

    @AuraEnabled
    public static String loginUser(String email, String passwordInput) {
        External_User__c user = [SELECT Id, Name FROM External_User__c WHERE Email__c = :email LIMIT 1];
        
        String sessionToken = generateSessionToken(user);

        setSessionCookie(sessionToken);

        return sessionToken;
    }

    public static String generateSessionToken(External_User__c user) {
        return EncodingUtil.base64Encode(Blob.valueOf(user.Id));
    }

    private static void setSessionCookie(String sessionToken) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Set-Cookie', 'sessionToken=' + sessionToken + '; SameSite=Strict; Path=/; Max-Age=3600');
        
    }
    @AuraEnabled(cacheable=true)
    public static External_User__c validateSession(String sessionToken) {
        
        try {
            String decoded = EncodingUtil.urlDecode(sessionToken, 'UTF-8');
            String userId = EncodingUtil.base64Decode(decoded).toString();
            External_User__c user = ExternalUsersController.getExternalUserById(userId);
            return user;
            
        } catch (Exception e) {
            throw new AuraHandledException('User not found.');

        }
       
    }
}