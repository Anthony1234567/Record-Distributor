# Record Distributor
Configure distribution of records to anyone!

## Using the App
To use the Record Distribution app, click on the app launcher from within Salesforce

![image](https://user-images.githubusercontent.com/6342285/110346260-3ac21100-7fe4-11eb-8df1-7e207589c5c8.png)

### Creating New Distribution Rules
To create a new distribution rule, navigate to Distribution Rules tab within the app and click on the New button on the upper left hand side of the page. Then, a modal like the following will pop up on the screen

![image](https://user-images.githubusercontent.com/6342285/110347022-0569f300-7fe5-11eb-884c-074d8f7480e4.png)

The following fields are required
* Name - Used in reporting
* Distribution Source ID - The ID of the bucket [Queue, User - Support in future release] to distribute from. 
    * For Queues, users in the queue will be assigned records in a round-robin fashion

The following fields are not required but will help with configuring the batches
* Active - Determines whether the distribution rule is considered during the batch runs
* Daily Cap - How many records can each user get (Maximum number of records assigned to individuals per day)
* Batch Job Frequency

### Controlling Access to the App
Access to the application is controlled via the **Record Distributor - Admin** permission set. Users assigned this permission set will be able to use the app and interact with relevant distributor configuration data 

To grant access to just view logs, assign the **Record Distributor - Reporting** permission set
