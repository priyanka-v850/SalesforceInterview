@isTest
public class RecordViewerController_Test {
    
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account', Website = 'https://test.com');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Phone = '9999999999', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            Amount = 10000,
            AccountId = acc.Id
        );
        insert opp;
    }
    
    @isTest
    static void testGetRecords_Account() {
        Test.startTest();
        List<RecordViewerController.RecordWrapper> result = RecordViewerController.getRecords('Account');
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Account', result[0].name);
        System.assertNotEquals(null, result[0].hasAccess);
        System.assertNotEquals(null, result[0].recordData);
    }
    
    @isTest
    static void testGetRecords_Contact() {
        Test.startTest();
        List<RecordViewerController.RecordWrapper> result = RecordViewerController.getRecords('Contact');
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Contact', result[0].name);
    }
    
    @isTest
    static void testGetRecords_Opportunity() {
        Test.startTest();
        List<RecordViewerController.RecordWrapper> result = RecordViewerController.getRecords('Opportunity');
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('Test Opp', result[0].name);
    }
    
    @isTest
    static void testNullObjectType() {
        try {
            RecordViewerController.getRecords(null);
            System.assert(false, 'Expected exception for null object type');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Exception should mention null object type');
        }
    }
    
    @isTest
    static void testUnsupportedObjectType() {
        try {
            RecordViewerController.getRecords('Lead');
            System.assert(false, 'Expected exception for unsupported object type');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
    }
}