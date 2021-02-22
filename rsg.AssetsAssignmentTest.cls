@isTest
public class AssetsAssignmentTest {
    @testSetup static void setupMaster(){
        Account testAccount = TestDataUtil.createAccount();
		WorkOrder woRecord = TestDataUtil.createWorkOrders(testAccount.Id); 
		Asset asstRec1  = TestDataUtil.createAssets(testAccount.Id, 1, null);
		Asset asstRec2  = TestDataUtil.createAssets(testAccount.Id, 2, asstRec1.Id);
		Asset asstRec3  = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3A = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3B = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3C = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3D = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3E = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3F = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3G = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);
		Asset asstRec3H = TestDataUtil.createAssets(testAccount.Id, 3, asstRec2.Id);

		List<Asset> asstRecA  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3A.Id);
		List<Asset> asstRecB  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3B.Id);
		List<Asset> asstRecC  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3C.Id);
		List<Asset> asstRecD  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3D.Id);
		List<Asset> asstRecE  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3E.Id);
		List<Asset> asstRecF  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3F.Id);
		List<Asset> asstRecG  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3G.Id);
		List<Asset> asstRecH  = TestDataUtil.createAssetsRooms(testAccount.Id, asstRec3H.Id);
	}

	static testMethod void testAssetAssignment(){
        ApexPages.StandardController stcParent;

        WorkOrder woRecord = [Select Id From WorkOrder];
        stcParent = new ApexPages.StandardController(woRecord);
        PageReference testPage = Page.AssetsAssignment;
        testPage.getParameters().put('Id',woRecord.Id);
        Test.setCurrentPage(testPage);

        AssetsAssignmentController asstController = new AssetsAssignmentController(stcParent);
        asstController.selectAllAssignments();
        asstController.createAssignment();
        asstController.editAssignment();
	}
}