global class AssetAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful {

	public String  strSelLvl2Assets;
	public AssetsAssignmentListWrapper assetWrp = new AssetsAssignmentListWrapper();

    public AssetAssignmentBatch(Set<Id> inputSelLvl2s, Id workOrderId){
        assetWrp.workOrderId    = workOrderId;
		assetWrp.processResult  = '** Assignment Creation Started **\n';
		assetWrp.processResult += 'Start Time '+string.valueof(datetime.now()+'\n\n\n');
		strSelLvl2Assets = AssetAssignmentClass.convertSetToString(inputSelLvl2s);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'SELECT Id, Name, ParentId, Parent.ParentId, AssetLevel ';
    	query += 'FROM Asset WHERE Id IN '+strSelLvl2Assets;

		return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<Asset> processAssets = (List<Asset>)scope;
		AssetAssignmentClass.createWOLineItems(assetWrp, processAssets);
		assetWrp.batchNumber++;
    }

    global void finish(Database.BatchableContext bc) {
    	assetWrp.emailSubject = 'Asset Assignment Line Items Creation';
    	assetWrp.emailSenderDisplayName = 'Asset Assignment Batch Job';
    	assetWrp.toEmailIds.add(UserInfo.getUserEmail());
		assetWrp.processResult += '\n\n** Assignment Creation Completed **\n';
		assetWrp.processResult += 'End Time '+string.valueof(datetime.now()+'\n');

    	AssetAssignmentClass.sendJobStatusEmail(assetWrp);
    }
}