//global with sharing class EventCreationCtlr {
global without sharing class EventCreationCtlr {

    public String subjectOptions { get; set; }
    public String assignmentAndAgentDetail { get; set; }
    
    global class EventClass {
        String inspection;
        String subject;
        String description;
        Datetime startDate;
        Datetime endDate;
        
        EventClass(String inspection, String subject, String description, Datetime startDate, Datetime endDate) {
            this.inspection = inspection;
            this.subject = subject;
            this.description = description;
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
    
    global class AssignmentAndAgentClass {
        String timezone;
        String woName;
        String inspectorName;
        String inspectorId; //This is to store user or contact id
        String inspectorRecId; //This is to store inspector record id
        Decimal inspectionTime;
        Datetime assignmentDate;
    }
    
    public EventCreationCtlr() {
    
        SFDCAccessController accessCtlr = new SFDCAccessController();
        AssignmentAndAgentClass assAndAgent = new AssignmentAndAgentClass();
    
        assAndAgent.timezone = String.valueOf(UserInfo.getTimeZone());
        
        List<String> subjList = new List<String>();
        Schema.DescribeFieldResult subjectFldResult = Event.Subject.getDescribe();
        if (subjectFldResult.isAccessible()) {
            for(Schema.PicklistEntry picklist : subjectFldResult.getPicklistValues()) {        
                subjList.add(picklist.getValue());    
            }
        }
        subjectOptions = JSON.serialize(subjList); 
        
        String woId = ApexPages.currentPage().getParameters().get('workorder');
        assAndAgent.inspectorRecId = ApexPages.currentPage().getParameters().get('inspector');
        
        accessCtlr.assertAuthorizedToView(WorkOrder.getSObjectType(), new List<String>{'StartDate', 'Subject', 'rsg__Inspector__c', 'rsg__Assignment_Type__c', 'Status'});
        accessCtlr.assertAuthorizedToView(rsg__Inspection_Template__c.getSObjectType(), new List<String> {'rsg__Total_Inspection_Time__c'});
        accessCtlr.assertAuthorizedToView(rsg__Inspector__c.getSObjectType(), new List<String>{'Name', 'rsg__Inspector_Contact__c', 'rsg__Inspector_Contact__c'});
        accessCtlr.assertAuthorizedToView(Contact.getSObjectType(), new List<String>{'Name'});
        accessCtlr.assertAuthorizedToView(User.getSObjectType(), new List<String>{'Name'});
        List<WorkOrder> workorder = [ SELECT Id, StartDate, rsg__Inspection_Template__r.rsg__Total_Inspection_Time__c, Subject, rsg__Inspector__c, rsg__Inspector__r.Name, rsg__Inspector__r.rsg__Inspector_Contact__c, rsg__Inspector__r.rsg__Inspector_Contact__r.Name, rsg__Inspector__r.rsg__Inspector_User__c, rsg__Inspector__r.rsg__Inspector_User__r.Name FROM WorkOrder WHERE Id = :woId ];
        if (!workorder.isEmpty()) {
            assAndAgent.woName = workorder[0].Subject;
            assAndAgent.assignmentDate = workorder[0].StartDate;
            assAndAgent.inspectionTime = workorder[0].rsg__Inspection_Template__r.rsg__Total_Inspection_Time__c;
        }
        
        if (String.isNotEmpty(assAndAgent.inspectorRecId)) {
            
            List<rsg__Inspector__c> inspector = [SELECT Id, Name, rsg__Inspector_User__c, rsg__Inspector_User__r.Name, rsg__Inspector_User__r.ContactId, rsg__Inspector_Contact__c, rsg__Inspector_Contact__r.Name FROM rsg__Inspector__c WHERE Id = :assAndAgent.inspectorRecId ];
            if (!inspector.isEmpty()) {
                assAndAgent.inspectorId = (String.isNotEmpty(inspector[0].rsg__Inspector_Contact__c)) ? inspector[0].rsg__Inspector_Contact__c : inspector[0].rsg__Inspector_User__c;    
                assAndAgent.inspectorName = (String.isNotEmpty(inspector[0].rsg__Inspector_Contact__c)) ? inspector[0].rsg__Inspector_Contact__r.Name : inspector[0].rsg__Inspector_User__r.Name; 
            }
        }
        assignmentAndAgentDetail = JSON.serialize(assAndAgent);
    }
    
    @RemoteAction
    global static List<EventClass> getAllEvents(String inspectorId) {
        
        SFDCAccessController accessCtlr = new SFDCAccessController();
        List<EventClass> events = new List<EventClass>();
        List<Event> eventList = new List<Event>();
        Map<Id, String> woMap = new Map<Id, String>();
        
        List<Event> eventListTemp = new List<Event>();
        String inspectionType = String.valueOf(WorkOrder.getSObjectType());
        accessCtlr.assertAuthorizedToView(Event.getSObjectType(), new List<String> {'StartDateTime', 'Subject', 'Description', 'EndDateTime', 'WhatId', 'OwnerId'});
        if (inspectorId.startsWith('003')) {
            eventListTemp = [ SELECT StartDateTime, Subject, Description, EndDateTime, WhatId, What.Type FROM EVENT WHERE WhoId = :inspectorId AND StartDateTime > TODAY AND What.Type = :inspectionType ORDER BY StartDateTime ];            
        } else if (inspectorId.startsWith('005')) {
            eventListTemp = [ SELECT StartDateTime, Subject, Description, EndDateTime, WhatId, OwnerId, What.Type FROM EVENT WHERE OwnerId = :inspectorId AND WhoId = NULL AND StartDateTime > TODAY AND What.Type = :inspectionType ORDER BY StartDateTime ];
        }
        for (Event evt : eventListTemp) {
            eventList.add(evt);
            woMap.put(evt.WhatId, '');
        }
        if (woMap.size() > 0) { 
            accessCtlr.assertAuthorizedToView(WorkOrder.getSObjectType(), new List<String>{'Subject'});           
            for (WorkOrder wo : [ SELECT Id, Subject FROM WorkOrder WHERE Id IN :woMap.keySet() ] ) {
                woMap.put(wo.Id, wo.Subject);
            }    
        }
        for (Event evt : eventList) {
            events.add(new EventClass(woMap.get(evt.WhatId), evt.Subject, evt.Description, evt.StartDateTime, evt.EndDateTime));
        }
       
        return events;
    }
    
    @RemoteAction
    global static Event createEvent(String eventData, String inspectorRecId) {
    
        SFDCAccessController accessCtlr = new SFDCAccessController();
        Event eventRecToBeInserted = (Event) JSON.deserialize(eventData, Event.class);
        eventRecToBeInserted.IsVisibleInSelfService = true;
        List<String> eventFldsToCheck = new List<String> { 'Subject', 'WhatId', 'OwnerId', 'WhoId', 'StartDateTime', 'EndDateTime' };
        List<String> woFldsToCheck = new List<String> { 'rsg__Inspector__c', 'Status' };
        List<String> usrFldsToCheck = new List<String> { 'Id', 'ContactId' };
        
        accessCtlr.assertAuthorizedToCreate(Event.getSObjectType(), eventFldsToCheck);
        insert eventRecToBeInserted;
        accessCtlr.assertAuthorizedToUpdate(WorkOrder.getSObjectType(), woFldsToCheck);
        update new WorkOrder(Id = eventRecToBeInserted.WhatId, rsg__Inspector__c = inspectorRecId, Status = 'Assigned');
        
        if(eventRecToBeInserted.WhoId != Null){
            List<User> usrList = new List<User>();
            if(accessCtlr.isAuthorizedToView(User.getSObjectType(), usrFldsToCheck)){
                usrList = [SELECT Id FROM User WHERE ContactId = :eventRecToBeInserted.WhoId];
                if(usrList.size()>0)
                pushService.sendMessage(usrList[0].Id, 'New Inspection Assigned!');
            }
        }else{
            pushService.sendMessage(eventRecToBeInserted.OwnerId , 'New Inspection Assigned!');
        }
        
        return eventRecToBeInserted;
    }
}