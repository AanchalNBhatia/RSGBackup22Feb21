/**
*	Lightning Component - CreateTemplateVersion.cmp
*	Visual Force page - NA
* 	Class Name - CreateQuestionVersion.apxc
*	Author - Ankit Chowhan
*	Description - This is controller class for CreateTemplateVersion. The component is used to create new version of Template object
*	Creation Date - 17th Jan, 2020
*	Last Modified Date - 20th Jan, 2020
*	Last Update Comment - None
*/

public class CreateTemplateVersion
{
    @AuraEnabled
    public static TemplateResponseWrapper createCloneRecords(String recordId)
    {
        TemplateResponseWrapper templateResponse = new TemplateResponseWrapper();
        rsg__Inspection_Template__c clonedTemplateRec = new rsg__Inspection_Template__c();
        List<rsg__Inspection_Question__c> clonedIqList = new List<rsg__Inspection_Question__c>();
        Map<String,String> quesToParentMap = new Map<String,String>();
        List<String> quesIdsToBeCloned = new List<String>();

        if (String.isNotBlank(recordId)) 
        {
            rsg__Inspection_Template__c templateRec = [select id, Name, rsg__Type__c, rsg__Total_Score__c, rsg__Total_Inspection_Time__c, rsg__Template_Version__c, rsg__Status__c, rsg__Section_Names__c, rsg__Score_of_Sections__c, rsg__Root_Parent__c, rsg__Publish_Status__c, rsg__Parent_Template__c, rsg__Date__c, rsg__Active__c, rsg__In_Use__c from rsg__Inspection_Template__c where id=:recordId];
            
            List<rsg__Inspection_Template__c> tempList = [select id, rsg__Parent_Template__c from rsg__Inspection_Template__c where rsg__Parent_Template__c =: templateRec.Id];

            if(templateRec!= null && templateRec.rsg__In_Use__c==true && tempList.size()==0)
            {
                clonedTemplateRec = templateRec.clone(false, true);
                clonedTemplateRec.rsg__Template_Version__c = templateRec.rsg__Template_Version__c+1;
                if(String.isNotBlank(String.valueOf(templateRec.rsg__Root_Parent__c)))
                {
                    clonedTemplateRec.rsg__Root_Parent__c = templateRec.rsg__Root_Parent__c;
                }
                else
                {
                    clonedTemplateRec.rsg__Root_Parent__c = recordId;
                }
                clonedTemplateRec.rsg__Parent_Template__c = recordId;
                clonedTemplateRec.rsg__Publish_Status__c = 'Draft';
                clonedTemplateRec.rsg__In_Use__c = FALSE;

                if(clonedTemplateRec!=null)
                {
                    insert clonedTemplateRec;
                    templateResponse.clonedRec = clonedTemplateRec;
                }
                
                List<rsg__Inspection_Question__c> iqListToBeCloned = [select id, Name, rsg__Website_URL__c,rsg__Type__c, rsg__Sub_Section__c, rsg__Section__c, rsg__Score__c, rsg__Question_Text__c, rsg__Question_Order__c, rsg__Question_Info__c, rsg__Question__c, rsg__Question__r.rsg__Answer_Options__c, rsg__IsRequired__c, rsg__Inspection_Template__c, rsg__Image_Capture__c, rsg__Dependent_Question_Order__c, rsg__Answer_Option_Scores__c, rsg__Active__c from rsg__Inspection_Question__c where rsg__Inspection_Template__c = :recordId];

                if(iqListToBeCloned!=null && iqListToBeCloned.size()>0)
                {
                    for(rsg__Inspection_Question__c iqRec: iqListToBeCloned)
                    {
                        quesIdsToBeCloned.add(iqRec.rsg__Question__c);
                    }

                    Set<String> clonedQuesIds = CreateQuestionVersion.createCloneRecords(quesIdsToBeCloned).keySet();

                    List<rsg__Question__c> clonedQuesRecsList = [select id, rsg__Parent_Question__c, rsg__Status__c from rsg__Question__c where id in :clonedQuesIds];

                    for(rsg__Question__c quesRec: clonedQuesRecsList)
                    {
                        if(!quesToParentMap.containsKey(quesRec.rsg__Parent_Question__c))
                        {
                            quesToParentMap.put(quesRec.rsg__Parent_Question__c, quesRec.id);
                        }
                        quesRec.rsg__Status__c = 'Published';
                    }

                    update clonedQuesRecsList;

                    for(rsg__Inspection_Question__c iqRec: iqListToBeCloned)
                    {
                        if(quesToParentMap.get(iqRec.rsg__Question__c) != null)
                        {
                            rsg__Inspection_Question__c tempIqRec = iqRec.clone(false, true);
                            tempIqRec.rsg__Question__c = quesToParentMap.get(iqRec.rsg__Question__c);
                            if(clonedTemplateRec!=null)tempIqRec.rsg__Inspection_Template__c = clonedTemplateRec.Id;
                            clonedIqList.add(tempIqRec);
                        }
                    }
                    
                }
                if(clonedIqList!=null && clonedIqList.size()>0)
                {
                    insert clonedIqList;
                    templateResponse.iqList = clonedIqList;
					System.debug('templateResponse #### '+templateResponse);
                }
                templateResponse.isError = false;
            }
            else 
            {
                templateResponse.isError = true;
				if(templateRec.In_Use__c==false){
					templateResponse.errorMsg = 'Template not In Use';
				}else if(tempList.size()>0){
					templateResponse.errorMsg = 'Template already have a draft or another Version';
				}
            }
        }
        return templateResponse;   
    }
    
    @AuraEnabled
    public static void deleteCloneRecords(String recordId, List<rsg__Inspection_Question__c> iqList)
    {
        System.debug('Record id #### '+recordId);
        System.debug('iqList id #### '+iqList);
        if(String.isNotBlank(recordId))
        {
            if(iqList!=null && iqList.size()>0)
            {
                delete iqList;
            }
           	rsg__Inspection_Template__c templateRec = [select id from rsg__Inspection_Template__c where id=:recordId];
            delete templateRec;
        }
    }
    
    @AuraEnabled
    public static void markPublished(String recordId)
    {
        String publishRecordType = Schema.SObjectType.rsg__Inspection_Template__c.getRecordTypeInfosByName().get('Published').getRecordTypeId();
        if(String.isNotBlank(recordId))
        {
            rsg__Inspection_Template__c templateRec = [select Id, rsg__publish_status__c, recordtypeid from rsg__Inspection_Template__c where Id=:recordId];
            templateRec.rsg__publish_status__c = 'Published';
            templateRec.recordtypeid = publishRecordType;
            update templateRec;
        }
    }

    public class TemplateResponseWrapper
    {
        @AuraEnabled public Boolean isError=false;
		@AuraEnabled public String errorMsg = '';
        @AuraEnabled public rsg__Inspection_Template__c clonedRec;
        @AuraEnabled public List<rsg__Inspection_Question__c> iqList;
        public TemplateResponseWrapper()
        {
            this.isError = isError;
            this.iqList = iqList;
            this.clonedRec = clonedRec;
        }

    }
}