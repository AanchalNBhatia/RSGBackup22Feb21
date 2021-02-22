@RestResource(urlMapping='/ContentVersionManager/*')
global with sharing class ContentVersionManager {
    /* @HttpPost
    global static String doPost() 
    {
        
        RestRequest     request    = RestContext.request;
        RestResponse    response   = RestContext.response;    
        response.addHeader('Content-Type','applicatin/json');

        fromJSON jsonBody ;
        try
        {
            jsonBody  = (fromJSON) JSON.deserialize(request.requestBody.toString(),fromJSON.class);
        }
        Catch(Exception ee)
        {
            System.debug('Error Occured '+ee.getMessage());
        }
        
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        conVer.PathOnClient = jsonBody.title + '.' + jsonBody.ext  ; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = jsonBody.title; // Display name of the files
        conVer.VersionData = EncodingUtil.base64Decode(jsonBody.image); // converting your binary string to Blob
        conver.mobileUpload__c = true;
        insert conVer;

        // First get the content document Id from ContentVersion
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink cDe = new ContentDocumentLink();
        cDe.ContentDocumentId = conDoc;
        cDe.LinkedEntityId = jsonBody.record; // you can use objectId,GroupId etc
        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDe.Visibility = 'AllUsers';
        insert cDe;

        return 'done';
    } */

    @HttpGet
    global static List<ResponseJSON> doGet() {
        List<ResponseJSON> resp = new List<ResponseJSON>();
        List<String> cdList = new List<String>();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String recordId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        //String recordId = '02i6g0000001rjeAAA';
        List<ContentDocumentLink> CDLList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:recordId];

        for(ContentDocumentLink cdl:CDLList)
        {
            cdList.add(cdl.ContentDocumentId);
        }

        System.debug('CDLMap #### '+cdList);
        List<ContentVersion> Docs = [SELECT Id,ContentDocumentId,VersionData,Title,PathOnClient,FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId IN : cdList];

        for(ContentVersion doc: Docs)
        {
            resp.add(new ResponseJSON(doc, EncodingUtil.base64Encode(doc.VersionData)));
        }
        System.debug('resp #### '+resp);
        return resp;
    }

    @HttpDelete
    global static String doDelete(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String recordId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        String resp='';

        ContentVersion cvRec = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE id =: recordId];

        if(cvRec!=null)
        {
            ContentDocument cd = [select id from ContentDocument where id =: cvRec.ContentDocumentId];
            delete cd;
            resp = 'done';
        }
        else 
        {
            resp = 'Not Found';
        }

        return resp;
    }

    /* global class fromJSON
    {
        global String image;    //Value1
        global String record;    //Value2
        global String title;
        global String ext;   //Value3
    } */

    global class ResponseJSON
    {
        global ContentVersion cvRec;
        global String image;
        
        global ResponseJSON(ContentVersion cvRec, String image)
        {
            this.cvRec = cvRec;
            this.image = image;
        }
    }
}