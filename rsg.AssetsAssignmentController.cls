public with sharing class AssetsAssignmentController {

    private ApexPages.StandardController controller {get;set;}
    public Id           workOrderId                 {get;set;}
    public Id           wkAccountId                 {get;set;}
    public Boolean      createDisable               {get;set;}
    public Boolean      selectDisable               {get;set;}
    public Boolean      editDisplay                 {get;set;}
    public Boolean      cancelDisplay               {get;set;}
    public List<Asset>  level1List                  {get;set;}
    public List<Asset>  level2List                  {get;set;}
    public String       siteName                    {get;set;}
    public Set<Id>      createdAssets               {get;set;}
    public Integer      lineItemsCreatedCount       {get;set;}
    public Integer      totalLineItemsCount         {get;set;}

    public List<level2ListWrapper> level2WrpList    {get;set;}
    public Map<Id, Asset> level1Map      = new Map<Id, Asset>();
    public Map<Id, Asset> level2Map      = new Map<Id, Asset>();
    public Map<Id, Asset> level3Map      = new Map<Id, Asset>();
    public Map<Id, Asset> level4Map      = new Map<Id, Asset>();
    public Map<Id, Id>    lvl3CreatedMap = new Map<Id, Id>();
    public List<Asset>    assetsList     = new List<Asset>();
    public List<WorkOrderLineItem> woLinesMasterList = new List<WorkOrderLineItem>();
    public List<WorkOrderLineItem> addNewWOLinesList = new List<WorkOrderLineItem>();

    public AssetsAssignmentController(ApexPages.StandardController stdController) {
        workOrderId    = ApexPages.CurrentPage().getparameters().get('Id');
 
        level1List     = new List<Asset>();
        level2List     = new List<Asset>();
        createDisable  = false;
        editDisplay    = false;
        cancelDisplay  = false;
        createdAssets = new Set<Id>();

        fetchAccountId();

        generateWOLineItemsMasterList();

        generateAssetHirearchyMap();

        generateAssetHirearchyList();

        getItemsCreatedCount();

        if(totalLineItemsCount == 0){
            createDisable  = true;
            selectDisable  = true;
        }

        siteName = 'Location : '+level1List[0].Name;
    }

    public PageReference createAssignment() {
        createDisable  = true;
        selectDisable  = true;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Asset Assignments are being created in a background Process and you will receive an email once the Job is completed!!!'));

        Set<Id> selectedParentIds = new Set<Id>();
        for(level2ListWrapper llwrpRec : level2WrpList){
            if (llwrpRec.wrpLevel2List.AssetLevel == 3 && llwrpRec.lnItmCreated == false && llwrpRec.selectInd == true){
                selectedParentIds.add(llwrpRec.wrpLevel2List.Id);
            }
        }

        AssetAssignmentBatch asstBatch = new AssetAssignmentBatch(selectedParentIds, workOrderId);
        Database.executeBatch(asstBatch, 50);

        return null;
    }

    public void getItemsCreatedCount(){
        lineItemsCreatedCount = 0;
        totalLineItemsCount   = 0;
        
        for(level2ListWrapper llwrpRec : level2WrpList){
            if (llwrpRec.wrpLevel2List.AssetLevel == 3){
                if(llwrpRec.lnItmCreated){
                    lineItemsCreatedCount++;
                }
                else{
                    totalLineItemsCount++;
                }
            }
        }
    }

    public PageReference editAssignment() {
        return null;
    }

    public PageReference selectAllAssignments() {
        for(level2ListWrapper llwrpRec : level2WrpList){
            if (llwrpRec.wrpLevel2List.AssetLevel == 3 && llwrpRec.lnItmCreated == false && llwrpRec.selectInd == false){
                llwrpRec.selectInd = true;
            }
        }

        return null;
    }

    public void fetchAccountId(){
        WorkOrder wkRec = [Select Id, AccountId FROM WorkOrder Where id = :workOrderId];
        wkAccountId = wkRec.AccountId;
    }

    public void generateAssetHirearchyMap(){
        assetsList = [SELECT Id, Name, ParentId, Parent.Name, Parent.Parent.Name, AssetLevel 
                        FROM Asset 
                       WHERE Accountid = :wkAccountId  
                    ORDER BY AssetLevel, commonLevel__c,Name];

        for(Asset astRec : assetsList){
            if(astRec.AssetLevel == 1){
                level1Map.put(astRec.Id, astRec);
            }else if(astRec.AssetLevel == 2){
                level2Map.put(astRec.Id, astRec);
            }else if(astRec.AssetLevel == 3){
                level3Map.put(astRec.Id, astRec);
                createdAssets.add(astRec.Id);
            }else if(astRec.AssetLevel == 4){
                level4Map.put(astRec.Id, astRec);
            }
        }
    }

    public void generateAssetHirearchyList(){

        for(Asset asstRec : level1Map.values()){
            level1List.add(asstRec);
        }

        level2WrpList  = new List<level2ListWrapper>();

        generateCreatedWOLinesMap();

        for(Asset asstRec2 : level2Map.values()){
            level2List.add(asstRec2);
            level2ListWrapper llwrp = new level2ListWrapper(false, false, asstRec2);
            level2WrpList.add(llwrp);
            for(Asset asstRec3 : level3Map.values()){
                if(asstRec2.Id == asstRec3.ParentId){
                    level2List.add(asstRec3);
                    if(lvl3CreatedMap.containsKey(asstRec3.Id)){
                        llwrp = new level2ListWrapper(true, true, asstRec3);
                    }
                    else{
                        llwrp = new level2ListWrapper(false, false, asstRec3);
                    }
                    level2WrpList.add(llwrp);
                    for(Asset asstRec4 : level4Map.values()){
                        if(asstRec3.Id == asstRec4.ParentId){
                            level2List.add(asstRec4);
                            llwrp = new level2ListWrapper(false, false, asstRec4);
                            level2WrpList.add(llwrp);
                        }
                    }
                }
            }
        }
    }

    // Wrapper Class Construction 
    public class level2ListWrapper{
        public Boolean selectInd       {get;set;}
        public Boolean lnItmCreated    {get;set;}
        public Asset   wrpLevel2List   {get;set;}

        public level2ListWrapper(Boolean selectInd, Boolean lnItemCr, Asset parmLevel2List){
            this.selectInd      = selectInd;
            this.lnItmCreated   = lnItemCr;
            this.wrpLevel2List  = parmLevel2List;
        }
    }

    public void generateCreatedWOLinesMap(){
        for(WorkOrderLineItem woLNRec : woLinesMasterList){
            lvl3CreatedMap.put(woLNRec.rsg__AssetLevel3ID__c, woLNRec.Id);
        }
    }

    public void generateWOLineItemsMasterList(){
        woLinesMasterList = [SELECT Id, AssetId, rsg__AssetLevel3ID__c, WorkOrderId
                               FROM WorkOrderLineItem
                              WHERE WorkOrderId = :workOrderId];
    }
}