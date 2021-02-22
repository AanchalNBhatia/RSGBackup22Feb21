public with sharing class WorkOrder_Handler {
    public static void populateGeoLocationOnWorkOrder(List<WorkOrder> woList) {
        
        Set<Id> woIdSet = new Set<Id>();
        for (WorkOrder wo : woList) {
            if (String.isNotEmpty(wo.Address__c)) {            
                woIdSet.add(wo.Id);    
            }
        }
        if (!Test.isRunningTest() && woIdSet.size() > 0) {
            Database.executeBatch(new Batch_getGeolocation(woIdSet, 'WorkOrder'), 100);                 
        }
    }
    
    /* Added to delete Event record if WorkOrder is Rejected */
    
    public static void deleteEvent(List<WorkOrder> woList, Map<Id, WorkOrder> woOldMap){
        for(WorkOrder wo:woList){
         	if((wo.Status=='Assignment Rejected' || wo.Status=='Submitted') && (wo.Status!=woOldMap.get(wo.Id).Status)){
                delete [select id from Event where whatId =:wo.Id];
            }   
        }
    }
    
    public static void notifyConfiguredUsers(List<WorkOrder> woList, Set<Id> inspectorSet) {
        
        Map<String,DateTime> taskWOMap = new Map<String, DateTime>();
        SFDCAccessController accessCtlr = new SFDCAccessController(); 
        //accessCtlr.assertAuthorizedToView(Inspection_Configuration__c.getSObjectType(), new List<String>{'Notification_on_Inspection_Approve__c', 'Notification_on_Inspection_Reject__c', 'Notification_on_Assign__c', 'Notification_on_Submit__c', 'Notification_on_Assignment_Accept__c', 'Notification_on_Assignment_Reject__c', 'Email_Addresses__c', 'Send_Notification_to__c', 'User_Contact_Id__c', 'User_Contact_Name__c'});
        //Commented on 5/8 because of package fail.
        Inspection_Configuration__c inspectionConfig = Inspection_Configuration__c.getInstance('Inspection_Configuration');
        List<Email_Log__c> emailLogs = new List<Email_Log__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Map<String, String> userIdAndNameMap = new Map<String, String>();
        Map<Id, String> inspectorMap = new Map<Id, String>();
        List<WorkOrder> woListToBeUpdated = new List<WorkOrder>();
        Set<String> emailLogFldSet = new Set<String> { 'Subject__c', 'Email_Body__c' };
        
        if (inspectorSet != NULL && inspectorSet.size() > 0) {
            for (Inspector__c ins : [ SELECT Inspector_Contact__c, Inspector_Contact__r.Email, Inspector_User__c, Inspector_User__r.Email FROM Inspector__c WHERE Id IN :inspectorSet ]) {
                String inspector = (ins.Inspector_Contact__c != NULL) ? ins.Inspector_Contact__c : (ins.Inspector_User__c != NULL) ? ins.Inspector_User__c : NULL;
                inspectorMap.put(ins.Id, inspector);    
            }
        }
        
        List<Event> taskList = [select id,whatId, StartDateTime from Event where whatId in:woList];
        //system.debug('#### taskList: ' + taskList);
        if(taskList!=null && taskList.size() > 0){
            for(Event evt:taskList){
            	if(!taskWOMap.containsKey(evt.whatId)){
                    taskWOMap.put(evt.whatId, evt.StartDateTime);
                }   
            }
        }
        //system.debug('#### taskWOMap: ' + taskWOMap);
        
        if (inspectionConfig != NULL) {
            for (WorkOrder wo : woList) {            
                //system.debug('#### woId: ' + wo.Id);
                String emailBody = '';
                String recLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + wo.Id;
                String stDate = (taskWOMap.get(wo.Id) != NULL) ? taskWOMap.get(wo.Id).format() : '';
                String stDateWO = '';
                //system.debug('#### stDate: ' + stDate);
                if (stDate == null || stDate == '')
                {
                    if (wo.rsg__Event_Start_Date_Time__c != null)
                    {
                        stDateWO = wo.rsg__Event_Start_Date_Time__c.format();
                    }
                }
                else
                {
                    stDateWO = stDate;
                }
                if (inspectionConfig.Notification_on_Assign__c && wo.Status == 'Assigned') {
                    emailBody += 'Hi ' + wo.Inspector_Name__c + ',<br/><br/>'; 
                    emailBody += 'The Inspection ' + wo.Subject + ' is assigned to you.<br/>'; 
                    emailBody += 'Inspection Location: ' + wo.Address__c + '<br/>';
                    emailBody += 'Inspection Date: ' + stDateWO + '<br/><br/>';
                    emailBody += 'Please login to ReadySpectGO to accept this Inspection.';
                } else if (inspectionConfig.Notification_on_Assignment_Accept__c && wo.Status == 'Assignment Accepted') {
                    emailBody += 'Hi,<br/><br/>';
                    emailBody += wo.Subject + ' is Accepted by ' + wo.Inspector_Name__c + '<br/>'; 
                    emailBody += 'Inspection Date: ' + stDateWO + '<br/>';
                    emailBody += 'Inspector: ' + wo.Inspector_Name__c + '<br/>';                                
                    emailBody += 'Please review this inspection: <a href="' + recLink + '">' + recLink + '</a>';
                } else if (inspectionConfig.Notification_on_Assignment_Reject__c && wo.Status == 'Assignment Rejected') {
                    emailBody += 'Hi, <br/><br/>';
                    emailBody += wo.Subject + ' is Rejected by ' + wo.Inspector_Name__c + '.<br/>'; 
                    emailBody += 'The reason is: ' + wo.Rejected_Reason__c + '<br/>';
                    emailBody += 'Please review this Inspection: ' + '<a href="' + recLink + '">' + recLink + '</a>';                    
                    woListToBeUpdated.add(new WorkOrder(Id = wo.Id, Inspector__c = NULL)); //Need to clear Agent from Assignment once it is rejected.
                } else if (inspectionConfig.Notification_on_Submit__c && wo.Status == 'Submitted') {
                    emailBody += 'Hi, <br/><br/>';
                    emailBody += wo.Subject + ' is Submitted by ' + wo.Inspector_Name__c + '.<br/>'; 
                    emailBody += 'Inspection Date: ' + Date.today().format() + '<br/>';
                    emailBody += 'Please review this Inspection: ' + '<a href="' + recLink + '">' + recLink + '</a>';
                } else if (inspectionConfig.Notification_on_Inspection_Approve__c && wo.Status == 'Inspection Approved') {
                    emailBody += 'Hi ' + wo.Inspector_Name__c + ',<br/><br/>';
                    emailBody += 'Please review this Inspection in ReadySpectGO under Approved Inspections folder.';
                } else if (inspectionConfig.Notification_on_Inspection_Reject__c && wo.Status == 'Inspection Rejected') {
                    emailBody += 'Hi ' + wo.Inspector_Name__c + ',<br/><br/>'; 
                    emailBody += 'Your Manager has rejected the ' + wo.Subject + '.<br/>'; 
                    emailBody += 'Please review this in ReadySpectGO Rejected Inspections folder.';
                }
                
                System.debug('emailBody ## '+emailBody);
                
                if (String.isNotEmpty(emailBody)) {
                
                    String status = (wo.Status.contains('Assignment')) ? wo.Status.remove('Assignment') : (wo.Status.contains('Inspection')) ? wo.Status.remove('Inspection') : wo.Status;
                    String subject = wo.Subject + ' is ' + status;
                
                    if (inspectionConfig.Send_Notification_to__c != 'Other') {
                    
                        Email_Log__c emailLog = new Email_Log__c();
                        
                        if (wo.Status == 'Assigned' || wo.Status == 'Inspection Approved' || wo.Status == 'Inspection Rejected') {
                            System.debug('wo.Inspector__c ## '+wo.Inspector__c);
                            if (inspectorMap.containsKey(wo.Inspector__c)) {
                                if (inspectorMap.get(wo.Inspector__c).startsWith('003')) {
                                    emailLog.Contact__c = inspectorMap.get(wo.Inspector__c);
                                    emailLogFldSet.add('Contact__c');
                                } else {
                                    emailLog.User_1__c = inspectorMap.get(wo.Inspector__c);
                                    emailLogFldSet.add('User_1__c');
                                }
                            }
                        } else {
                            if (inspectionConfig.Send_Notification_to__c == 'User') {
                                System.debug('inspectionConfig.User_Contact_Id__c ## '+inspectionConfig.User_Contact_Id__c);
                                if (String.isNotEmpty(inspectionConfig.User_Contact_Id__c)) {
                                    List<String> userNames = new List<String>();
                                    if (String.isNotEmpty(inspectionConfig.User_Contact_Name__c)) {
                                        userNames = inspectionConfig.User_Contact_Name__c.split(',');    
                                    }
                                    Integer i=1;
                                    for (String userId : inspectionConfig.User_Contact_Id__c.split(',')) { 
                                        String fieldApi = 'User_' + i + '__c';
                                        emailLog.put(fieldApi, userId); 
                                        emailLogFldSet.add(fieldApi);
                                        userIdAndNameMap.put(userId, userNames[i-1]);
                                        i++;                                           
                                    }
                                }             
                            } else if (inspectionConfig.Send_Notification_to__c == 'Contact') {                    
                                emailLog.Contact__c = inspectionConfig.User_Contact_Id__c;
                                emailLogFldSet.add('Contact__c');
                            }
                        }
                        
                        emailLog.Subject__c = subject;
                        emailLog.Email_Body__c = emailBody;
                        emailLogs.add(emailLog);           
                    } else if (String.isNotEmpty(inspectionConfig.Email_Addresses__c)) {                    
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();   
                        mail.setPlainTextBody(emailBody);
                        mail.setHTMLBody(emailBody);
                        mail.setSubject(subject);
                        mail.setSaveAsActivity(FALSE);                    
                        mail.setToAddresses(inspectionConfig.Email_Addresses__c.split(','));
                        emails.add(mail); 
                    }
                }
            }
            if (woListToBeUpdated.size() > 0) {
                //accessCtlr.assertAuthorizedToUpdate(WorkOrder.getSObjectType(), new List<String> {'rsg__Inspector__c'});
                //Commented on 5/8 because of package fail.
                update woListToBeUpdated;
            }
            if (emailLogs.size() > 0) {
                List<String> emailLogsFldList = new List<String>();
                emailLogsFldList.addAll(emailLogFldSet);
                System.debug('I am here');
                //if(accessCtlr.isAuthorizedToCreate(Email_Log__c.getSObjectType(), emailLogsFldList)){
                    insert emailLogs;         
                //}       
            } else if (emails.size() > 0) {
                Messaging.sendEmail(emails);
            }
        }
    }
}