@isTest 
public class EventCreationCtrlComm_Test 
{
    @testSetup
    public static void setup()
    {
        Account testAccount = TestDataUtil.createAccount();
        
        List<Contact> contList = TestDataUtil.createContacts(testAccount.Id);
		
        WorkOrder wo = TestDataUtil.createWorkOrders(testAccount.Id);
        List<Inspector__c> inspectors = TestDataUtil.createInspectors(contList[0].id, testAccount.Id);
        wo.Subject = 'Test Subject';
        update wo;
        
        List<Event> eventList = TestDataUtil.createEventsForContact(inspectors[0].Inspector_Contact__c, wo.Id);
    }
    
	static testMethod void testMethod1() 
	{
		WorkOrder wo = [select id from WorkOrder];
		List<Inspector__c> inspectors = [select id from Inspector__c];
        Date startDtae = Date.newInstance(2020, 2, 15);
        Date endDate = Date.newInstance(2020, 2, 15);
		
		
		Test.StartTest(); 

        ApexPages.currentPage().getParameters().put('workorder', String.valueOf(wo.Id));
        ApexPages.currentPage().getParameters().put('inspector', String.valueOf(inspectors[0].Id));
        EventCreationCtlrComm  testEvent = new EventCreationCtlrComm();
        testEvent.eventSubject = 'Test Subject';
        testEvent.eventStartDate = startDtae;
        testEvent.eventEndDate = endDate;
        testEvent.selectedStartTime = '01:00';
        testEvent.selectedEndTime = '02:00';
        testEvent.selectedStartAMPM = 'PM';
        testEvent.selectedEndAMPM = 'PM';
        
       	testEvent.doInit();
        testEvent.createEvent();
		
        Test.StopTest();
	}
    
    
    
    static testMethod void testMethod2() 
	{
		WorkOrder wo = [select id, Subject from WorkOrder];
        wo.Subject = null;
        update wo;
		List<Inspector__c> inspectors = [select id from Inspector__c];
        Date startDtae = Date.newInstance(2020, 2, 15);
        Date endDate = Date.newInstance(2020, 2, 15);
		
		
		Test.StartTest(); 

        ApexPages.currentPage().getParameters().put('workorder', String.valueOf(wo.Id));
        ApexPages.currentPage().getParameters().put('inspector', String.valueOf(inspectors[0].Id));
        EventCreationCtlrComm  testEvent = new EventCreationCtlrComm();
        testEvent.eventSubject = 'Test Subject';
        testEvent.eventStartDate = startDtae;
        testEvent.eventEndDate = endDate;
        testEvent.selectedStartTime = '02:00';
        testEvent.selectedEndTime = '02:00';
        testEvent.selectedStartAMPM = 'PM';
        testEvent.selectedEndAMPM = 'PM';
        
       	testEvent.doInit();
        testEvent.createEvent();
		
        Test.StopTest();
	}
    
    static testMethod void testMethod3() 
	{
		WorkOrder wo = [select id from WorkOrder];
		List<Inspector__c> inspectors = [select id from Inspector__c];
        Date startDtae = Date.newInstance(2020, 2, 15);
        Date endDate = Date.newInstance(2020, 2, 15);
		
		
		Test.StartTest(); 

        ApexPages.currentPage().getParameters().put('workorder', String.valueOf(wo.Id));
        ApexPages.currentPage().getParameters().put('inspector', String.valueOf(inspectors[0].Id));
        EventCreationCtlrComm  testEvent = new EventCreationCtlrComm();
        testEvent.eventSubject = 'Test Subject';
        testEvent.eventStartDate = startDtae;
        testEvent.eventEndDate = endDate;
        testEvent.selectedStartTime = '01:00';
        testEvent.selectedEndTime = '02:00';
        testEvent.selectedStartAMPM = 'AM';
        testEvent.selectedEndAMPM = 'AM';
        
       	testEvent.doInit();
        testEvent.createEvent();
        testEvent.cancel();
		
        Test.StopTest();
	}
}