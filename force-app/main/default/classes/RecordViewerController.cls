public without sharing class RecordViewerController {
    
    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> getRecords(String sObjectName) {
        List<RecordWrapper> resultList = new List<RecordWrapper>();
        String query;

        if (String.isBlank(sObjectName) || sObjectName == null) {
            throw new AuraHandledException('Object type is null');
        }
        
        if (sObjectName == 'Account') {
            query = 'SELECT Id, Name, Owner.Name, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate, Website FROM Account';
        } else if (sObjectName == 'Contact') {
            query = 'SELECT Id, Name, Owner.Name, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate, Phone FROM Contact';
        } else if (sObjectName == 'Opportunity') {
            query = 'SELECT Id, Name, Owner.Name, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate, Amount FROM Opportunity';
        } else {
            throw new AuraHandledException('Unsupported object type');
        }

        query += ' ORDER BY LastModifiedDate DESC LIMIT 100';

        List<SObject> records = Database.query(query);
        system.debug('records::'+records);

        Map<Id, UserRecordAccess> accessMap = new Map<Id, UserRecordAccess>();
        if (!records.isEmpty()) {
            Set<Id> recordIds = new Set<Id>();
            for (SObject rec : records) {
                recordIds.add(rec.Id);
            }
        
            accessMap = new Map<Id, UserRecordAccess>([
                SELECT RecordId, HasReadAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId()
                AND RecordId IN :recordIds
            ]);
        }

        for (SObject rec : records) {
            Boolean hasAccess = accessMap.containsKey(rec.Id) ? accessMap.get(rec.Id).HasReadAccess : false;
            resultList.add(new RecordWrapper(rec, hasAccess));
        }

        return resultList;
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