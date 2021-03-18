/**
 * DistributionListCardController
 * @description: 
 * @author: Anthony Martinez
 */
public class DistributionListCardController {
    /**
     * @description:
     * @param distributionSourceId:
     * @return: List of users to distribute records to. In order.
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getDistributionList(Id distributionSourceId) {
        try {
            Set<Id> groupMemberIdSet = new Set<Id>();

            for (GroupMember groupMember : [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE GroupId = :distributionSourceId
                ORDER BY UserOrGroupId
            ]) {
                if (groupMember.UserOrGroupId.getSObjectType() == User.SObjectType) {
                    groupMemberIdSet.add(groupMember.UserOrGroupId);
                }
            }

            return [
                SELECT Name,
                    SmallPhotoURL
                FROM User
                WHERE Id IN :groupMemberIdSet
                ORDER BY Id
            ];
        } catch (Exception caughtException) {
            AuraHandledException auraHandledException = new AuraHandledException(caughtException.getMessage());
            auraHandledException.setMessage(caughtException.getMessage());
            throw auraHandledException;
        }
    }
}
