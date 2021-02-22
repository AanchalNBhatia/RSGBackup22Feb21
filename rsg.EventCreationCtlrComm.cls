public class EventCreationCtlrComm {
    
    public inspector__c inspRec {get;set;}
    public WorkOrder woRec {get;set;}
    //public Time eventStartTime { get; set; }
    public Date eventStartDate {get;set;}
    //public Time eventEndTime { get; set; }
    public Date eventEndDate {get;set;}
    public Event eventRecToBeInserted {get;set;}
    public string eventSubject {get;set;}
    public List<String> timeList;
    public List<String> ampm;
    public String inspectorRecId;
    public String woId;
    public String uId;
    public String selectedStartTime {get;set;}
    public String selectedEndTime {get;set;}
    public String selectedStartAMPM {get;set;}
    public String selectedEndAMPM {get;set;}
    public List<SelectOption> options {get;set;}
    public List<SelectOption> optionsampm {get;set;}
    Id communityUserRectypeId;
    Id internalUserRectypeId;
    
    //private ApexPages.StandardController controller {get;set;}
    public void doInit()
    {
        
    	woId = ApexPages.currentPage().getParameters().get('workorder');
    	inspectorRecId = ApexPages.currentPage().getParameters().get('inspector');
    	//inspectorRecId = 'a063D0000036uUKQAY';
        //woId = '0WO3D000001HtQnWAK';
    	
        inspRec = [SELECT Id, RecordTypeId, Name, UserID__c, Inspector_User__c, Inspector_User__r.Name, Inspector_User__r.ContactId, Inspector_Contact__c, Inspector_Contact__r.Name FROM Inspector__c WHERE id =:inspectorRecId];
        woRec = [ SELECT Id, WorkOrderNumber, StartDate, Inspection_Template__r.Total_Inspection_Time__c, Subject, Inspector__c, Inspector__r.Name, Inspector__r.Inspector_Contact__c, Inspector__r.Inspector_Contact__r.Name, Inspector__r.Inspector_User__c, Inspector__r.Inspector_User__r.Name FROM WorkOrder WHERE Id = :woId ];
		
        communityUserRectypeId = Schema.SObjectType.Inspector__c.getRecordTypeInfosByName().get('Community User').getRecordTypeId();
		
		internalUserRectypeId = Schema.SObjectType.Inspector__c.getRecordTypeInfosByName().get('Internal User').getRecordTypeId();
        
        options = new List<SelectOption>();
        optionsampm = new List<SelectOption>();
        optionsampm.add(new SelectOption('AM','AM'));
        optionsampm.add(new SelectOption('PM','PM'));
        timeList = new List<String>{'01:00','01:30','02:00','02:30','03:00','03:30','04:00','04:30','05:00','05:30','06:00','06:30','07:00','07:30','08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30'};    
 	 	for(String str:timeList)
        {
            options.add(new SelectOption(str,str));
        }
    }
    
    public PageReference createEvent()
    {
        ApexPages.Message msg;
        PageReference pg;
		try
		{
			
			eventRecToBeInserted = new Event();
			eventRecToBeInserted.WhatId = woId;
			DateTime ST;
			DateTime ET;
			Datetime finalStartDate;
			Datetime finalEndDate;
			Boolean isError = false;
			Boolean startDateLessThanEndDate = false;
			Boolean isDupilcate = false;
			
		   
			System.debug('eventStartDate ## '+eventStartDate);
            System.debug('selectedStartTime ## '+selectedStartTime);
            System.debug('eventEndDate ## '+eventEndDate);
            System.debug('selectedEndTime ## '+selectedEndTime);
			
			String inspectorId = (String.isNotEmpty(inspRec.Inspector_Contact__c)) ? inspRec.Inspector_Contact__c : inspRec.Inspector_User__c;
            System.debug('inspectorId #### '+inspectorId);
            System.debug('inspRec.Inspector_User__c #### '+inspRec.Inspector_User__c);
            
            if (inspectorId.startsWith('005')) {
                eventRecToBeInserted.OwnerId = inspectorId;
            } else if (inspectorId.startsWith('003')) {
                eventRecToBeInserted.WhoId = inspectorId;
                eventRecToBeInserted.OwnerId = inspRec.UserID__c;
            }
			
			if(String.isNotBlank(woRec.Subject))
			{
				eventRecToBeInserted.Subject = woRec.Subject;    
			}
			else
			{
				isError = true;
				//msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please input Event Subject');   
			}
			
			if((String.isNotBlank(String.valueOf(eventStartDate)) && String.isNotBlank(String.valueOf(selectedStartTime))) && (String.isNotBlank(String.valueOf(eventEndDate)) && String.isNotBlank(String.valueOf(selectedEndTime))))
			{
				if(selectedStartAMPM=='PM')
				{
					Time startTime = Time.newInstance(Integer.valueOf(selectedStartTime.substringBefore(':'))+12, Integer.valueOf(selectedStartTime.substringAfter(':')), 0, 0);
					finalStartDate = DateTime.newInstance(eventStartDate, startTime);
				}
				else
				{
					Time startTime = Time.newInstance(Integer.valueOf(selectedStartTime.substringBefore(':')), Integer.valueOf(selectedStartTime.substringAfter(':')), 0, 0);
					finalStartDate = DateTime.newInstance(eventStartDate, startTime);
				}
				
				if(selectedEndAMPM=='PM')
				{
					Time endTime = Time.newInstance(Integer.valueOf(selectedEndTime.substringBefore(':'))+12, Integer.valueOf(selectedEndTime.substringAfter(':')), 0, 0);
					finalEndDate = DateTime.newInstance(eventEndDate, endTime);
				}
				else
				{
					Time endTime = Time.newInstance(Integer.valueOf(selectedEndTime.substringBefore(':')), Integer.valueOf(selectedEndTime.substringAfter(':')), 0, 0);
					finalEndDate = DateTime.newInstance(eventEndDate, endTime);
				}
				
				if(finalStartDate>finalEndDate)
				{
					startDateLessThanEndDate = true;
                    isError = true;
				}
				else 
				{
                    List<Event> evtList = [select id, Subject, StartDateTime, EndDateTime from Event where whoid = :inspRec.Inspector_Contact__c or ownerId =:inspRec.Inspector_User__c];
                    if(evtList!=null && evtList.size()>0)
                    {
                        for(Event evt:evtList)
                        {
                            
                            if((finalStartDate >= evt.StartDateTime && finalStartDate <= evt.EndDateTime) || (finalEndDate > evt.StartDateTime && finalEndDate <= evt.EndDateTime) || (finalStartDate >= evt.StartDateTime && finalEndDate<=evt.EndDateTime) || (finalStartDate <= evt.StartDateTime && finalEndDate>=evt.EndDateTime))
                            {
                                isDupilcate = true;
                                isError = true;
                            }
                        }
                        if(!isDupilcate)
                        {
                            eventRecToBeInserted.StartDateTime = finalStartDate;
                        	eventRecToBeInserted.EndDateTime = finalEndDate;
                        }
                    }
                    else
                    {
                        eventRecToBeInserted.StartDateTime = finalStartDate;
                        eventRecToBeInserted.EndDateTime = finalEndDate;
                    }
					
				}
				
			}
			else
			{
				isError = true;
			}
            System.debug('finalStartDate ## '+finalStartDate);
            System.debug('finalEndDate ## '+finalEndDate);
            System.debug('eventRecToBeInserted.StartDateTime ## '+eventRecToBeInserted.StartDateTime);
            System.debug('eventRecToBeInserted.EndDateTime ## '+eventRecToBeInserted.EndDateTime);
			
			if(!isError)
			{
				insert eventRecToBeInserted;
                msg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'EVENT CREATED');
                update new WorkOrder(Id = eventRecToBeInserted.WhatId, Inspector__c = inspectorRecId, Status = 'Assigned', rsg__Event_Start_Date_Time__c = eventRecToBeInserted.StartDateTime);
                if(eventRecToBeInserted.WhoId != Null){
                    //List<User> usrList = new List<User>();
                    //usrList = [SELECT Id FROM User WHERE ContactId = :eventRecToBeInserted.WhoId];
                    //if(usrList.size()>0)
                    //pushService.sendMessage(inspRec.UserID__c, 'New Inspection Assigned!');
                    
                }
                else{
                    //pushService.sendMessage(inspRec.UserID__c , 'New Inspection Assigned!');
                }
                
                pg = new PageReference('/'+woId);
                pg.setRedirect(true);
			}
            else if(isError)
			{
                if(startDateLessThanEndDate)
                {
                    msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Start Date and Time cant be after End Date and Time');
                }
                else if(isDupilcate)
                {
                    msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Event already exists for the selected date time, please choose another.');
                }
                else
                {
                    msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Subject, Start Date Time and End Date Time cannot be Blank');
                }
				
			}
            
		}
		catch(Exception e)
		{
			msg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
		}
        ApexPages.addmessage(msg);
        return pg;
        
    }
    
    public PageReference cancel()
    {
        woId = ApexPages.currentPage().getParameters().get('workorder');
        PageReference pg = new PageReference('/'+woId);
        pg.setRedirect(true);
        return pg;
    }

}