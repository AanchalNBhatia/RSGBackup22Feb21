@isTest
public class CreateAnswerVersion_Test {
	@testSetup
    public static void setup()
    {
        List<Question__c> quesList = TestDataUtil.createQuestions();
        for(Question__c quesRec:quesList)
        {
            quesRec.Status__c = 'Published';
        }
        update quesList;
        List<Inspection_Question__c> iqList = TestDataUtil.createInspectionQuestions(quesList);
        List<Question_Answer_Options__c> qaList = TestDataUtil.createQuesAnsOptions(quesList[0].id);
        
        Account accRec = TestDataUtil.createAccount();
        WorkOrder woRec = TestDataUtil.createWorkOrders(accRec.id);
        WorkOrderLineItem woliRec = new WorkOrderLineItem();
        woliRec.WorkOrderId = woRec.id;
       	woliRec.Template__c = iqList[0].Inspection_Template__c;
        insert woliRec;
    }
    
    @isTest
    public static void testCloneAnswer()
    {
        List<Answer_Option__c> ansList = [select id from Answer_Option__c];
        
        CreateAnswerVersion.cloneAnswer(ansList[0].Id);
    }
    
    @isTest
    public static void testDeleteClone()
    {
        List<Answer_Option__c> ansList = [select id from Answer_Option__c];
        CreateAnswerVersion.deleteClone((String)ansList[0].id);
    }
    
    
    @isTest
    public static void testMarkPublished()
    {
        List<Answer_Option__c> ansList = [select id, publish_status__c from Answer_Option__c];
        
        ansList[0].publish_status__c = 'Draft';
        update ansList[0];
        CreateAnswerVersion.markPublished((String)ansList[0].id);
        
    }

    @isTest
    public static void testUpdateQuestionRecords()
    {
        List<Answer_Option__c> ansList = [select id, publish_status__c, Parent_Answer__c from Answer_Option__c];
        ansList[0].Parent_Answer__c = ansList[1].id;
        update ansList[0];
        UpdateQuestions.updateQuestionRecords(ansList[0].id);
    }

}