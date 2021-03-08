import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import DISTRIBUTION_SOURCE_ID_FIELD from '@salesforce/schema/Distribution_Rule__c.Distribution_Source_Id__c';

export default class DistributionSourceInfoCard extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [ DISTRIBUTION_SOURCE_ID_FIELD ] 
    }) distributionRule;
}