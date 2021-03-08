/**
 * DistributionService 
 * @description: Handles logic around distribution of records
 * @author: Anthony Martinez
 */
public class DistributionService {
    static final List<Distribution_Rule__c> activeDistributionRuleList = [
        SELECT Distribution_Source_Id__c,
            Daily_Cap__c,
            (
                SELECT Assignee__c
                FROM Distribution_Logs__r
                ORDER BY CreatedDate DESC
                LIMIT 1
            )
        FROM Distribution_Rule__c
        WHERE Active__c = true
    ];

    /**
     * @description: 
     * @param recordsToDistributeMap: Map of records that need to be distributed. 
     */
    public static void distributeRecords(Map<Id, SObject> recordsToDistributeMap) {
        Map<Id, Set<Id>> queueIdToMembershipIdSetMap = new Map<Id, Set<Id>>();

        for (Distribution_Rule__c distributionRule : activeDistributionRuleList) {
            queueIdToMembershipIdSetMap.put(distributionRule.Distribution_Source_Id__c, new Set<Id>());
        }
    
        if (!queueIdToMembershipIdSetMap.isEmpty()) {
            Map<Id, Set<Id>> queueIdToDistributableRecordIdSetMap = new Map<Id, Set<Id>>();
        
            for (SObject record : recordsToDistributeMap.values()) {
                if (queueIdToMembershipIdSetMap.containsKey((Id) record.get('OwnerId'))) {
                    Set<Id> distributableRecordIdSet = queueIdToDistributableRecordIdSetMap.containsKey((Id) record.get('OwnerId'))
                        ? queueIdToDistributableRecordIdSetMap.get((Id) record.get('OwnerId'))
                    	: new Set<Id>();
                    
                    distributableRecordIdSet.add(record.Id);
                    queueIdToDistributableRecordIdSetMap.put((Id) record.get('OwnerId'), distributableRecordIdSet);
                }
            }

            if (!queueIdToDistributableRecordIdSetMap.isEmpty()) {
                Map<String, Integer> distributorAndAssigneeIdConpositionToAssignmentCountMap = new Map<String, Integer>();
                Map<Id, Id> distributorIdToLastAssigneeIdMap = new Map<Id, Id>();
                Map<Id, SObject> recordUpdateMap = new Map<Id, SObject>();
                List<Distribution_Log__c> distributionLogInsertList = new List<Distribution_Log__c>();
    
                for (GroupMember queueMember : [
                    SELECT GroupId,
                        UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId IN :queueIdToMembershipIdSetMap.keySet()
                    ORDER BY GroupId, 
                        UserOrGroupId
                ]) {
                    if (queueMember.UserOrGroupId.getSObjectType() == User.SObjectType) {
                        Set<Id> queueMembershipIdSet = queueIdToMembershipIdSetMap.get(queueMember.GroupId);
    
                        queueMembershipIdSet.add(queueMember.UserOrGroupId);
                        queueIdToMembershipIdSetMap.put(queueMember.GroupId, queueMembershipIdSet);
                    }
                }
    
                for (AggregateResult distributionAggregateForToday : [
                    SELECT COUNT(Id) Distribution_Count,
                        Distribution_Rule__c,
                        Assignee__c
                    FROM Distribution_Log__c
                    WHERE CreatedDate = TODAY
                    GROUP BY Distribution_Rule__c,
                        Assignee__c
                ]) {
                    Id distributionRule = (Id) distributionAggregateForToday.get('Distribution_Rule__c');
                    Id assignee = (String) distributionAggregateForToday.get('Assignee__c');
                    Integer distributionCount = (Integer) distributionAggregateForToday.get('Distribution_Count');
    
                    distributorAndAssigneeIdConpositionToAssignmentCountMap.put(distributionRule + '' + assignee, distributionCount);
                }
    
                for (Distribution_Rule__c distributionRule : activeDistributionRuleList) {
                    Id queueId = distributionRule.Distribution_Source_Id__c;
                    List<Id> queueMembershipIdList = new List<Id>(queueIdToMembershipIdSetMap.get(queueId));
    
                    if (!queueMembershipIdList.isEmpty() && queueIdToDistributableRecordIdSetMap.containsKey(queueId)) {
                    	Set<Id> distributableRecordIdSet = queueIdToDistributableRecordIdSetMap.get(queueId);
                        Integer queueMembershipIdListIndex = 0;
                        
                        if (!distributionRule.Distribution_Logs__r.isEmpty()) {
                            Id lastAssigneeId = distributionRule.Distribution_Logs__r.get(0).Assignee__c;

                            if (queueMembershipIdList.contains(lastAssigneeId)) {
                                queueMembershipIdListIndex = queueMembershipIdList.indexOf(lastAssigneeId) + 1;

                                if (queueMembershipIdListIndex >= queueMembershipIdList.size()) {
                                    queueMembershipIdListIndex = 0;
                                }
                            }
                        }   
    
                        for (Id distributableRecordId : distributableRecordIdSet) {
                            if (!recordUpdateMap.containsKey(distributableRecordId)) {
                                Id assigneeId = queueMembershipIdList.get(queueMembershipIdListIndex);
                                String distributionKey = distributionRule.Id + '' + assigneeId;
                                Integer distributionCount = distributorAndAssigneeIdConpositionToAssignmentCountMap.containsKey(distributionKey)
                                    ? distributorAndAssigneeIdConpositionToAssignmentCountMap.get(distributionKey)
                                    : 0;
        
                                if (distributionCount < distributionRule.Daily_Cap__c) {
                                    SObject distributableRecord = recordsToDistributeMap.get(distributableRecordId);
                                    
                                    distributionLogInsertList.add(new Distribution_Log__c(
                                        Assigned_Record_Id__c = distributableRecordId,
                                        Distribution_Rule__c = distributionRule.Id,
                                        Assignee__c = assigneeId
                                    ));
        
                                    distributableRecord.put('OwnerId', assigneeId);
                                    distributableRecord.put('Last_Distributed_Timestamp__c', Datetime.now());
                                    recordUpdateMap.put(distributableRecordId, distributableRecord);
                                    distributorAndAssigneeIdConpositionToAssignmentCountMap.put(distributionKey, ++distributionCount);

                                    if (queueMembershipIdListIndex < queueMembershipIdList.size() - 1) {
                                        queueMembershipIdListIndex++;
                                    } else {
                                        queueMembershipIdListIndex = 0;
                                    }
                                }
                            }
                        }
                    }
                }
    
                if (!recordUpdateMap.isEmpty()) {
                    update recordUpdateMap.values();
                }
    
                if (!distributionLogInsertList.isEmpty()) {
                    insert distributionLogInsertList;
                }
            }
        }
    }

    /**
     * @description:
     * @return:
     */
    public static Set<Id> getDistributableRecordOwnerIdSet() {
        Set<Id> distributableRecordOwnerIdSet = new Set<Id>();

        for (Distribution_Rule__c activeDistributionRule : activeDistributionRuleList) {
            distributableRecordOwnerIdSet.add(activeDistributionRule.Distribution_Source_Id__c);
        }

        return distributableRecordOwnerIdSet;
    }
}