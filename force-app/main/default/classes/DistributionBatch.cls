/**
 * DistributionBatch
 * @description: Batch process to handle distribution process
 * @author: Anthony Martinez
 */
public class DistributionBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    /**
     * Schedulable
     */

    /**
     * @description: Schedules a batch to run
     */
    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new DistributionBatch());
    }
    
    /**
     * Batchable
     */

    /**
     * @description: Queries Leads that Need to be distributed
     * @param: BC - for tracking job progress/status
     * @return: Database.Querylocator used for tracking job progress
     */
    public Database.Querylocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator([
            SELECT OwnerId 
            FROM Lead
            WHERE OwnerId IN :DistributionService.getDistributableRecordOwnerIdSet()
            ORDER BY OwnerId,
            	Last_Distributed_Timestamp__c
        ]);
    }
    
    /**
     * @description: Calls on distribution service to perform distribution
     * @param: BC - for tracking job progress/status
     * @param: accountList - List of Account records to process
     */
    public void execute(Database.BatchableContext batchableContext, List<Lead> leadToDistributeList) {
        DistributionService.distributeRecords(new Map<Id, SObject>(leadToDistributeList));
    }
    
    /**
     * @description: Sends batch results email
     * @param: BC - for tracking job progress/status
     */
    public void finish(Database.BatchableContext batchableContext) {}
}