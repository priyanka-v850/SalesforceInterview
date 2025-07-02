public without sharing class DynamicRecordViewerController {
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectOption> getAvailableObjects() {
        List<ObjectOption> options = new List<ObjectOption>();
        for (ObjectConfiguration__mdt config : [
            SELECT Object_Label__c, Object_API_Name__c 
            FROM ObjectConfiguration__mdt 
            WHERE Active__c = TRUE
        ]) {
            options.add(new ObjectOption(config.Object_API_Name__c, config.Object_Label__c));
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getRecords(String sObjectName) {
        ObjectConfiguration__mdt config = [
            SELECT Fields_to_Display__c 
            FROM ObjectConfiguration__mdt 
            WHERE Object_API_Name__c = :sObjectName AND Active__c = true 
            LIMIT 1
        ];
        
        if (config == null) {
            throw new AuraHandledException('Configuration for object not found or inactive');
        }
        
        List<String> fields = config.Fields_to_Display__c != null 
            ? config.Fields_to_Display__c.replaceAll('\\s+', '').split(',') 
            : new List<String>();
        fields.addAll(new List<String>{
            'Id', 'Name', 'OwnerId', 'CreatedById', 'LastModifiedById', 'CreatedDate', 'LastModifiedDate'
                });
        
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + sObjectName +
            ' ORDER BY LastModifiedDate DESC LIMIT 100';
        List<SObject> records = Database.query(query);
        
        Map<Id, UserRecordAccess> accessMap = new Map<Id, UserRecordAccess>();
        if (!records.isEmpty()) {
            Set<Id> recordIds = new Set<Id>();
            for (SObject rec : records) {
                recordIds.add(rec.Id);
            }
            accessMap = new Map<Id, UserRecordAccess>([
                SELECT RecordId, HasReadAccess 
                FROM UserRecordAccess 
                WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recordIds
            ]);
        }
        
        List<RecordWrapper> resultList = new List<RecordWrapper>();
        for (SObject rec : records) {
            Boolean hasAccess = false;
            if (accessMap.containsKey(rec.Id)) {
                hasAccess = accessMap.get(rec.Id).HasReadAccess;
            }
            resultList.add(new RecordWrapper(rec, hasAccess));
        }
        
        return resultList;
    }
    
    public class ObjectOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        
        public ObjectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    
    public class RecordWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean hasAccess;
        @AuraEnabled public SObject recordData;
        
        public RecordWrapper(SObject rec, Boolean access) {
            this.recordId = (String)rec.get('Id');
            this.name = (String)rec.get('Name');
            this.hasAccess = access;
            this.recordData = rec;
        }
    }
}