import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Queue.Name';

export default class DistributionSourceInfoCard extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: [ NAME_FIELD ] } )
    distributionSource
}