public without sharing class GoogleLoginController {

    @AuraEnabled
    public static String createAuthURL() {
        // Fetch values from Custom Metadata via helper class
        String clientId    = GoogleOAuthConfig.getClientId();
        String redirectUri = GoogleOAuthConfig.getRedirectUri();
        String authUrl     = GoogleOAuthConfig.getAuthUrl();
        String scope       = GoogleOAuthConfig.getScope();

        // URL-encode the parameters
        String encodedClientId    = EncodingUtil.urlEncode(clientId, 'UTF-8');
        String encodedRedirectUri = EncodingUtil.urlEncode(redirectUri, 'UTF-8');
        String encodedScope       = EncodingUtil.urlEncode(scope, 'UTF-8');

        // Construct the OAuth authorization URI
        String authUri = authUrl
            + '?client_id='    + encodedClientId
            + '&response_type=code'
            + '&scope='         + encodedScope
            + '&redirect_uri='  + encodedRedirectUri
            + '&access_type=offline'
            + '&prompt=consent';

        return authUri;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccessToken(String code) {
        // Fetch values from Custom Metadata via helper class
        String tokenUrl    = GoogleOAuthConfig.getTokenUrl();
        String clientId    = GoogleOAuthConfig.getClientId();
        String clientSecret= GoogleOAuthConfig.getClientSecret();
        String redirectUri = GoogleOAuthConfig.getRedirectUri();

        // Prepare HTTP request to exchange authorization code for access token
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenUrl);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        // Build and URL-encode the request body
        String body = ''
            + 'code='           + EncodingUtil.urlEncode(code, 'UTF-8')
            + '&client_id='     + EncodingUtil.urlEncode(clientId, 'UTF-8')
            + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8')
            + '&redirect_uri='  + EncodingUtil.urlEncode(redirectUri, 'UTF-8')
            + '&grant_type=authorization_code';

        req.setHeader('Content-Length', String.valueOf(body.length()));
        req.setBody(body);
        req.setTimeout(60 * 1000);

        // Send callout
        Http http = new Http();
        HttpResponse response = http.send(req);

        if (response.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to retrieve access token from Google. Status: ' 
                + response.getStatusCode()
                + ', Body: ' + response.getBody());
        }

        // Parse JSON response to extract the access token
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String accessToken = (String) responseMap.get('access_token');
        return accessToken;
    }

    @AuraEnabled
    public static String getUserInfo(String accessToken) {
        // Prepare HTTP request to fetch user info
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/oauth2/v1/userinfo');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Error getting user info from Google. Status: '
                + res.getStatusCode()
                + ', Body: ' + res.getBody());
        }

        // Deserialize the returned JSON payload
        Map<String, Object> userInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String email = (String) userInfo.get('email');

        // Extract domain from the email address
        String emailDomain = null;
        if (String.isNotBlank(email) && email.contains('@')) {
            emailDomain = email.split('@')[1].toLowerCase();
        }

        // Fetch allowed domains from a custom setting
        String allowedDomainsStr = MyTime_Settings__c.getOrgDefaults()?.Allowed_Domains__c;
        if (String.isBlank(allowedDomainsStr)) {
            throw new AuraHandledException('No allowed domains configured.');
        }

        // Normalize and split allowed domains into a list
        List<String> allowedDomains = new List<String>();
        for (String domain : allowedDomainsStr.split(';')) {
            allowedDomains.add(domain.trim().toLowerCase());
        }

        // Verify that the email's domain is permitted
        if (String.isBlank(emailDomain) || !allowedDomains.contains(emailDomain)) {
            throw new AuraHandledException('Email domain "' + emailDomain + '" is not allowed.');
        }

        // Check if an External_User__c already exists for this email
        List<External_User__c> existingUsers = [
            SELECT Id, Name, Email__c
            FROM External_User__c
            WHERE Email__c = :email
            LIMIT 1
        ];

        if (!existingUsers.isEmpty()) {
            // Generate a session token for the existing user
            return LoginController.generateSessionToken(existingUsers[0]);
        } else {
            // Create a new External_User__c record
            External_User__c newUser = new External_User__c();
            newUser.Name      = (String) userInfo.get('name');
            newUser.Email__c  = email;
            newUser.Password__c = null;
            insert newUser;

            return LoginController.generateSessionToken(newUser);
        }
    }
}
