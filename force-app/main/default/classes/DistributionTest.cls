/**
 * DistributionTest
 * @description: Test class for distribution process
 * @author: Anthony Martinez
 */
@IsTest
class DistributionTest {
	/**
     * @description: Setup common test data
     */
    @TestSetup
    static void setupTestData() {
        AggregateResult testQueueAggregate = [
            SELECT COUNT(Id),
                GroupId
            FROM GroupMember
            WHERE Group.Type = 'Queue'
            GROUP BY GroupId
            HAVING COUNT(Id) > 1
            LIMIT 1
        ];
        
        GroupMember testAssignee = [
        	SELECT GroupId 
            FROM GroupMember
            WHERE GroupId = :(Id) testQueueAggregate.get('GroupId')
            LIMIT 1
        ];
        
        insert new Distribution_Rule__c(
        	Active__c = true,
            Distribution_Source_Id__c = testAssignee.GroupId,
            Daily_Cap__c = 2
        );
        
        insert new List<Lead>{
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'Adam',
                LastName = 'McTest',
                Company = 'Test Company2'
            ),
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'Josh',
                LastName = 'Todd',
                Company = 'TC3'
            ),
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'jason',
                LastName = 'freddie',
                Company = 'sfdc'
            ),
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'Marcus',
                LastName = 'Baily',
                Company = 'Robiinhood'
            ),
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'Freddie',
                LastName = 'Mercury',
                Company = 'Queen'
            ),
            new Lead(
                OwnerId = testAssignee.GroupId,
                Status = 'New',
                FirstName = 'Cooper',
                LastName = 'Williams',
                Company = 'QCRP'
            )
        };
    }
    
    /**
     * @description: 
     */
    @IsTest
    static void testDistributionBatchSchedule() {
        String jobName = 'Test Distribution Batch';
        String cronExpression = '0 0 * * * ?';

        System.assert([
            SELECT Id 
            FROM CronTrigger
            WHERE CronExpression = :cronExpression
                AND CronJobDetail.Name = :jobName
        ].isEmpty(), 'Job already exists');

        // Act
        Test.startTest();
            System.schedule(jobName, cronExpression, new DistributionBatch());
        Test.stopTest();

        // Assert - verify results     
        System.assertEquals(1, [
            SELECT Id 
            FROM CronTrigger
            WHERE CronExpression = :cronExpression
                AND CronJobDetail.Name = :jobName
        ].size(), 'Job not created or too many jobs created');
    }

    /**
     * @description: 
     */
    @IsTest
    static void testDistributionBatch() { 
        // Act - 
        Test.startTest();
        	Database.executeBatch(new DistributionBatch());
        Test.stopTest();
        
        // Assert - Assert that Distribution logs were created
        List<Distribution_Log__c> distributionLogList = [
            SELECT Assignee__c,
            	Assigned_Record_Id__c,
            	Distribution_Rule__c
            FROM Distribution_Log__c
        ];
        
        System.assert(!distributionLogList.isEmpty(), 'No Leads were distributed');
    }
    
    /**
     * @description: 
     */
    @IsTest
    static void testDistributionBatchSecondRun() { 
        // Arrange - Run first distribution
        Database.executeBatch(new DistributionBatch());
        
        // Act - 
        Test.startTest();
        	Database.executeBatch(new DistributionBatch());
        Test.stopTest();
        
        // Assert - Assert that Distribution logs were created
        List<Distribution_Log__c> distributionLogList = [
            SELECT Assignee__c,
            	Assigned_Record_Id__c,
            	Distribution_Rule__c
            FROM Distribution_Log__c
        ];
        
        System.assert(!distributionLogList.isEmpty(), 'No Leads were distributed');
    }
}