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
    public static List<AssigneeInfo> getDistributionList(Id distributionSourceId) {
        try {
            List<AssigneeInfo> assigneeInfoList = new List<AssigneeInfo>();
            Set<Id> groupMemberIdSet = new Set<Id>();
            Map<Id, Integer> assigneeIdToAssignmentCountMap = new Map<Id, Integer>();

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

            for (AggregateResult distributionAggregateForToday : [
                SELECT COUNT(Id) Distribution_Count,
                    Assignee__c
                FROM Distribution_Log__c
                WHERE CreatedDate = TODAY
                    AND Assignee__c IN :groupMemberIdSet
                GROUP BY Assignee__c
                ORDER BY Assignee__c
            ]) {
                Id assigneeId = (Id) distributionAggregateForToday.get('Assignee__c');
                Integer distributionCount = (Integer) distributionAggregateForToday.get('Distribution_Count');

                assigneeIdToAssignmentCountMap.put(assigneeId, distributionCount);
            }

            for (User assignee : [
                SELECT Name,
                    SmallPhotoUrl
                FROM User
                WHERE Id IN :groupMemberIdSet
                ORDER BY Id
            ]) {
                AssigneeInfo assigneeInfo = new AssigneeInfo();

                assigneeInfo.assignee = assignee;
                assigneeInfo.assignedRecordCount = assigneeIdToAssignmentCountMap.containsKey(assignee.Id)
                    ? assigneeIdToAssignmentCountMap.get(assignee.Id)
                    : 0;
                assigneeInfoList.add(assigneeInfo);
            }

            return assigneeInfoList;
        } catch (Exception caughtException) {
            AuraHandledException auraHandledException = new AuraHandledException(caughtException.getMessage());
            auraHandledException.setMessage(caughtException.getMessage());
            throw auraHandledException;
        }
    }

    /**
     * AssigneeInfo
     * @description: LWC server call response model
     */
    public class AssigneeInfo {
        @AuraEnabled 
        public User assignee;
        @AuraEnabled 
        public Integer assignedRecordCount;
    }
}
