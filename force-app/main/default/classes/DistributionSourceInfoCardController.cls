/**
 * DistributionSourceInfoCardController
 * @description: 
 * @author: Anthony Martinez
 */
public class DistributionSourceInfoCardController {
    /**
     * @description:
     * @param distributionSourceId:
     * @return: Information about the distribution source including its Name
     */
    @AuraEnabled(cacheable=true)
    public static DistributionSourceInfo getDistributionSourceInfo(Id distributionSourceId) {
        try {
            DistributionSourceInfo distributionSourceInfo = new DistributionSourceInfo();

            if (distributionSourceId.getSObjectType() == Group.SObjectType) {
                List<QueueSobject> relatedSobjectTypeList = [
                    SELECT Queue.Name,
                        SobjectType
                    FROM QueueSobject
                    WHERE QueueId = :distributionSourceId
                ];

                for (QueueSobject relatedSobjectType : relatedSobjectTypeList) {
                    RelatedSObjectTypeOwnedRecordCount untalliedRelatedSObjectTypeOwnedRecordCount = new RelatedSObjectTypeOwnedRecordCount();
                    
                    untalliedRelatedSObjectTypeOwnedRecordCount.sObjectTypeName = relatedSobjectType.SobjectType;

                    distributionSourceInfo.distributionSourceName = relatedSobjectType.Queue.Name;
                    distributionSourceInfo.untalliedRelatedSObjectTypeOwnedRecordCountList.add(untalliedRelatedSObjectTypeOwnedRecordCount);
                }

                distributionSourceInfo.distributionSourceType = 'Queue';
            } else{
                distributionSourceInfo.distributionSourceType = 'User';
            } 

            return distributionSourceInfo;
        } catch (Exception caughtException) {
            AuraHandledException auraHandledException = new AuraHandledException(caughtException.getMessage());
            auraHandledException.setMessage(caughtException.getMessage());
            throw auraHandledException;
        }
    }

    /**
     * @description:
     * @param distributionSourceId:
     * @param relatedSobjectType:
     * @return: Number of records owned by the distribution source of the specified type
     */
    @AuraEnabled(cacheable=true)
    public static RelatedSObjectTypeOwnedRecordCount getOwnedRecordCount(Id distributionSourceId, String relatedSobjectType) {
        try {
            RelatedSObjectTypeOwnedRecordCount talliedRelatedSObjectTypeOwnedRecordCount = new RelatedSObjectTypeOwnedRecordCount();

            talliedRelatedSObjectTypeOwnedRecordCount.sObjectTypeName = relatedSobjectType;
            talliedRelatedSObjectTypeOwnedRecordCount.ownedRecordCount = Database.query(
                'SELECT Id ' +
                'FROM ' + relatedSobjectType + ' ' +
                'WHERE OwnerId = :distributionSourceId'
            ).size();

            return talliedRelatedSObjectTypeOwnedRecordCount;
        } catch (Exception caughtException) {
            AuraHandledException auraHandledException = new AuraHandledException(caughtException.getMessage());
            auraHandledException.setMessage(caughtException.getMessage());
            throw auraHandledException;
        }
    }

    /**
     * DistributionSourceInfo
     * @description: LWC server call response model
     */
    public class DistributionSourceInfo {
        @AuraEnabled 
        public String distributionSourceName;
        @AuraEnabled 
        public String distributionSourceType;
        @AuraEnabled 
        public List<RelatedSObjectTypeOwnedRecordCount> untalliedRelatedSObjectTypeOwnedRecordCountList = new List<RelatedSObjectTypeOwnedRecordCount>();
    }

    /**
     * RelatedSObjectTypeOwnedRecordCount
     * @description: Tuple for displaying record counts per related SObjectTypes
     */
    public class RelatedSObjectTypeOwnedRecordCount {
        @AuraEnabled 
        public String sObjectTypeName;
        @AuraEnabled 
        public Integer ownedRecordCount;
    }
}
