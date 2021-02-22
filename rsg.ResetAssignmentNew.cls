public class ResetAssignmentNew {
	private ApexPages.StandardController controller {get;set;}
    
    public String inspectorRecId;
    public String woId;
    
    public PageReference doInit()
    {
        //SFDCAccessController accessCtlr = new SFDCAccessController();
        woId = ApexPages.currentPage().getParameters().get('workorder');
    	//inspectorRecId = ApexPages.currentPage().getParameters().get('inspector');
        
        //List<String> woFldsToCheck = new List<String> { 'rsg__Inspector__c', 'Status' };
        //accessCtlr.assertAuthorizedToUpdate(WorkOrder.getSObjectType(), woFldsToCheck);
        
        update new WorkOrder(Id = woId, rsg__Inspector__c = null, Status = 'New'); 
        delete [SELECT id FROM event WHERE WhatId =:woId];
        
        //pushService.sendMessage(inspectorRecId, 'Inspection Reassigned, Please sync your device!');
        PageReference pg = new PageReference('/'+woId);
        pg.setRedirect(true);
        return pg;
    }
}