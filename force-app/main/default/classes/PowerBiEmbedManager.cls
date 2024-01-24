public with sharing class PowerBiEmbedManager {
    
    public PowerBiEmbedManager() {}
    
    public class ClientCredentialPostData {
        public String client_id;
        public String client_info;
        public string client_secret;
        public String scope;
        public string grant_type;
        public String getPostData(){
          return 'client_id=' + this.client_id + 
                '&client_info=' + this.client_info +
                '&client_secret=' + this.client_secret +
                '&scope=' + this.scope +
                '&grant_type=' + grant_type;
        }
    }

    public class ClientCredentialResponse {
    	public String access_token;
        public String expires_in;
        public String ext_expires_in;
        public String token_type;
    }
    
    public class PowerBiReport    {
        public String id { get; set; } 
        public String reportType { get; set; } 
        public String name { get; set; } 
        public String webUrl { get; set; } 
        public String embedUrl { get; set; } 
        public boolean isFromPbix { get; set; } 
        public boolean isOwnedByMe { get; set; } 
        public String datasetId { get; set; } 
   }
    
    public class PowerBiEmbedToken    {
        public string token { get; set; } 
        public string tokenId { get; set; } 
        public DateTime expiration { get; set; } 
    }
 
    public class PowerBiReportData    {
    	@AuraEnabled
        public String workspaceId { get; set; } 
    	@AuraEnabled
        public String reportId { get; set; } 
    	@AuraEnabled
        public String name { get; set; } 
    	@AuraEnabled
        public String embedUrl { get; set; } 
    	@AuraEnabled
        public String embedToken { get; set; } 
        @AuraEnabled
        public String visualName { get; set; }
        @AuraEnabled
        public String type { get; set; }
    	@AuraEnabled
        public String pageName { get; set; }
    	@AuraEnabled
        public DateTime embedTokenExpires { get; set; } 
        @AuraEnabled
        public String error { get; set; } 
     }
    
    public static String getPowerBiAccessToken() {

        // get auth settings from Custom Metadata Type reconrd
        Power_BI_Auth_Setting__mdt authSetting = Power_BI_Auth_Setting__mdt.getInstance('PowerBiApp');
        string TenantId = authSetting.TenantId__c;    
        string ClientId = authSetting.ClientId__c;    
        string ClientSecret = authSetting.ClientSecret__c;        

        // construct URL for client credentials flow
        String aadTokenEndpoint = 'https://login.microsoftonline.com/' + TenantId + '/oauth2/v2.0/token';

        // prepare HTTP request 
        HttpRequest reqClientCredentialsFlow = new HttpRequest();
        reqClientCredentialsFlow.setMethod('POST');
        reqClientCredentialsFlow.setEndpoint(aadTokenEndpoint);        
        reqClientCredentialsFlow.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        // compose data for POST body
        ClientCredentialPostData postData = new ClientCredentialPostData();
		postData.client_id = ClientId;
		postData.client_info = '1';
		postData.client_secret = ClientSecret;
		postData.scope = 'https://analysis.windows.net/powerbi/api/.default';
		postData.grant_type = 'client_credentials';        
        String postBody = postData.getPostData();
        reqClientCredentialsFlow.setBody(postBody);
        system.debug(postBody);

        // send HTTP POST to execute client credentials flow
        Http http = new Http();        
        HttpResponse response = http.send(reqClientCredentialsFlow);
 
        // extract and return app-only access token for service principal
        String responseJson = response.getBody();
        ClientCredentialResponse responseData = (ClientCredentialResponse)JSON.deserialize(responseJson, ClientCredentialResponse.class);
        String access_token = responseData.access_token;         
        return access_token;
    }
   
    @AuraEnabled(cacheable=true)
    public static PowerBiReportData getEmbeddingDataForReport(String WorkspaceId, String ReportId, String Username, String Datasets, String PageName, String Visual) {

        // get access token for Authorization header
        String access_token = getPowerBiAccessToken();        

        // Call to Power BI Service API to get report data for embedding        
        HttpRequest reqGetReport = new HttpRequest();
        reqGetReport.setMethod('GET');
        // String urlGetReport = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + 'd8fdc4db-070c-4a70-af25-b62ac6bd739e';
        String urlGetReport = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + ReportId;
        // reqGetReport.setEndpoint('https://app.powerbi.com/reportEmbed?reportId=d8fdc4db-070c-4a70-af25-b62ac6bd739e&groupId=cb51c114-6678-4c97-90d4-55baa6704ecb&w=2&config=eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly9XQUJJLUlORElBLVdFU1QtcmVkaXJlY3QuYW5hbHlzaXMud2luZG93cy5uZXQiLCJlbWJlZEZlYXR1cmVzIjp7InVzYWdlTWV0cmljc1ZOZXh0Ijp0cnVlfX0=');
        reqGetReport.setEndpoint(urlGetReport);
        reqGetReport.setHeader('Authorization', 'Bearer ' + access_token);

        
        Http http = new Http();        
        HttpResponse response = http.send(reqGetReport);
        
        // check response for success
        if(response.getStatusCode()!=200){
            System.debug('ERROR --- Getting Report Data --- ERROR');
            System.debug('Status Code: ' + response.getStatusCode());
            PowerBiReportData getReportError = new PowerBiReportData();
            getReportError.error = 'Get Report Error: ' + response.getStatus();
            return getReportError;            
        }            
    
        // extract Power BI report data from JSON response
        String responseJson = response.getBody();
        PowerBiReport powerBiReport = (PowerBiReport)JSON.deserialize(responseJson, PowerBiReport.class);
        
        // send report info to debug window
        System.debug('id: ' + powerBiReport.id);        
        System.debug('reportType: ' + powerBiReport.reportType);        
        System.debug('name: ' + powerBiReport.name);  
        System.debug('webUrl: ' + powerBiReport.webUrl);      
        System.debug('embedUrl: ' + powerBiReport.embedUrl);        
        System.debug('isFromPbix: ' + powerBiReport.isFromPbix);        
        System.debug('isOwnedByMe: ' + powerBiReport.isOwnedByMe);        
        System.debug('datasetId: ' + powerBiReport.datasetId);        

	    // Call to Power BI Service API to get embed token for report        
        HttpRequest reqGetEmbedToken = new HttpRequest();
        reqGetEmbedToken.setMethod('POST');
        reqGetEmbedToken.setHeader('Content-Type', 'application/json');
        String urlGetEmbedToken = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + ReportId + '/GenerateToken';
        // String urlGetEmbedToken = 'https://api.powerbi.com/v1.0/myorg/groups/' + WorkspaceId + '/reports/' + 'd8fdc4db-070c-4a70-af25-b62ac6bd739e' + '/GenerateToken';
        reqGetEmbedToken.setEndpoint(urlGetEmbedToken);
        reqGetEmbedToken.setHeader('Authorization', 'Bearer ' + access_token);    
        // reqGetEmbedToken.setBody('{"accessLevel": "View", "datasetId": "' + powerBiReport.datasetId + '"}');
        reqGetEmbedToken.setBody('{"accessLevel": "View","identities":[{"username": "'+Username+'", "roles":["'+PageName+'"],"datasets":["'+Datasets+'"]}]}');
        system.debug(reqGetEmbedToken.getBody());
        HttpResponse responseEmbedToken = http.send(reqGetEmbedToken);

        // check response for success
        if(responseEmbedToken.getStatusCode()!=200){
            System.debug('ERROR --- Getting Embed Token --- ERROR');
            System.debug('Status Code: ' + responseEmbedToken.getStatusCode());            
            PowerBiReportData getEmbedTokenError = new PowerBiReportData();
            getEmbedTokenError.error = 'Get Embed Token Error: ' + response.getStatus();
            return getEmbedTokenError;            
        }            

        // extract Power BI embed token and expiration
        PowerBiEmbedToken embedToken = (PowerBiEmbedToken)JSON.deserialize(responseEmbedToken.getBody(), PowerBiEmbedToken.class);
        
        // send report info to debug window
        System.debug('EmbedToken: ' + embedToken.token);        
        System.debug('EmbedToken ID: ' + embedToken.tokenId);        
        System.debug('expiration: ' + embedToken.expiration);
        
        // create custom remote-able object to return to caller in browser 
        PowerBiReportData powerBiReportData = new PowerBiReportData();        
        powerBiReportData.workspaceId = WorkspaceId;
        powerBiReportData.reportId = ReportId;
        powerBiReportData.name = powerBiReport.name;
        powerBiReportData.embedUrl = powerBiReport.embedUrl;
        powerBiReportData.embedToken = embedToken.token;
        powerBiReportData.type = (String.isBlank(Visual) || String.isBlank(PageName)) ?'report':'visual';
        powerBiReportData.visualName = String.isBlank(Visual)? '':Visual;
        powerBiReportData.pageName = String.isBlank(PageName)? '':PageName;
        powerBiReportData.embedTokenExpires = embedToken.expiration;
        //  powerBiReportData.embedToken = 'H4sIAAAAAAAEACWUxw6r2BZE_-VOaYmcWuoBOWdswox8wESbA4bW-_dnqedbVVLVqv3vH7-4xqWo__z95yZl_Xkrj34FIJCYGJYxNerktumdHu4FyVeEVFnsjPKK6DzglT2ycBk26jSS_ipOuf7Ur7YO7EBKt0VrGZ0eHQNIUTt9Pkc1Je7naTbfWbOBossexhhDtUQLHscnrxH02tST-gYg_sogYXS-M5tyvLQhRirvCQXJLnaTM1j8WRS2kGcvMRwC-7vz4Ounp6CPnXnQIXy_ynbxasmWmIZmG6mFmTOQnXAMmAqdou58JUbMnKZ6C-s3_sPvkDz7BbG5yXWblwJfO_DtcapwZYUH5riT9DwUrtUU0qUrSjU8IYAbk-BiISnmy9I3YSXpxMk14tEclKUFiWI135FZPz9jn71ksi_e0sA0NRVmlB6GKK3vubPbUu5X2sSTvHxNKyFsZ3D_XHmqvY2cP7hJtbGiVMokgSf9SY2PBqXBs0wXtCPLHKPLYZ2sjvdjx-36SVzma_HC854orCLp4JLu4ZGwXTDtkKZA19IE9Le0rJDcN66y8C3f9Id97yZ2He1UduG-Cf61e10tYVRHMKaNynU5L00IrdGv2INpEwfxx6-aMNOqeTPbzQWb_SAhCRgxzQdXcbG0m68AxQ9x0aTWc1KsBPhWPk_U7BTX4_tWa44DW9daqK2j3_dnkI8JIYKjSR5Ifj-geA_T_PE3LyJ8MVSEaOMtBrMbKD3MM8Cy51BVeeWUoRysB2aaluPXmtBq7qGyQLdVxsMPacKwSLtyENMYMeho1pVmxtXTlKsDEbKxPMNe7vsI72x4Cyz3QkQWBbAyypA7SSUpulXHd7YrAtwlZxJ54W5q3bOkrAwlmRFTiw58RvEd1VKFvlNAAsWHmWEgNcqnvyLH_YokFIlKy-9o0gj--efPX3-k97Xui9Vcv5nFeTk0iShg184ZZdEj7ctLcUUsZz2LyS2NlNF0DamMcT0avlESgK5Qy-PUtYNndldCkmhoBBYxD8TyEpZgN50AN5VSmQKu7RsAd39tAmrl9RzRRTQfweh56VW_aj0qmUP26Mh47-fFsCMbXM5ts7uLpEz-6L24eRJd7FIT-6h5tPJv5qhVO73TaOQykhDN4c2NgCAcI3NaLc1N-E12wB3vi_7Q2imOX1tYtKWb50Qq1TQEnTkJu_AY2CXW6KXrkdVmN1ygr0zzWsJ5HaQic2i72TWSdKEZEni5RjZgLUNSWL5wICjHPWeUr5irSrHBLQI_Ed2U9PU9JisdjA_XIcUvK_wX87WC5m08fynPTc8ob9_PEYncqAYNJqfo_isj6n_s7vDd_M5SQ1-jk0hZsFq08PY5kObOVaeY52cLdAv2ci_wG2e9kHcLKtcGp-3gNI3Ws9f4BqrtmKni9T5H5ysbsE_DgcawTXpi4F2hJtbuCxxlnafHintAkz9N3dOX0iB_Yt_eTB0GbdZAfTLWJIqzbfLeJLG-_JofgjHyiayuxNXqNF1ksuywCvnV8gibF72dXZ9sGNnRi60kX4S5xzV5FsN-LKA5v-acI_M7iDuG4ET5cYz1WEqVIasbXp1lA7dPEnbXI11g4-obVbDeTZB6sHyUE3HfT3S2Gv77yUsDJeXRaM1KoVLcHeZYa6sfCJcmyyF2CSYLDvf3hmwmsOtMAm2pv7I9P38x_-__mR--51oGAAA=.eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly9XQUJJLUlORElBLVdFU1QtcmVkaXJlY3QuYW5hbHlzaXMud2luZG93cy5uZXQiLCJleHAiOjE2OTc3MjAyMDQsImFsbG93QWNjZXNzT3ZlclB1YmxpY0ludGVybmV0Ijp0cnVlfQ==';
        //       powerBiReportData.embedTokenExpires = Date.valueOf('2023-10-19T10:18:46Z');
        
        return powerBiReportData;            
 
    }

}