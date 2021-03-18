import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDistributionList from '@salesforce/apex/DistributionListCardController.getDistributionList';

import DISTRIBUTION_SOURCE_ID_FIELD from '@salesforce/schema/Distribution_Rule__c.Distribution_Source_Id__c';

export default class DistributionListCard extends LightningElement {
    @api recordId;
    
    @track distributionList;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            DISTRIBUTION_SOURCE_ID_FIELD
        ]
    }) distributionRule;

    @wire(getDistributionList, { 
        distributionSourceId: '$distributionSourceId'
    }) getDistributionList({ error, data }) {
        if (data) {
            this.distributionList = data.map(user => {
                return {
                    ...user,
                    relativeURL: `/${user.Id}`
                };
            });
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to fetch distribution list',
                    message: error.body.message,
                    variant: 'error'
                }
            ));
        }
    }

    get distributionSourceId() {
        return getFieldValue(this.distributionRule.data, DISTRIBUTION_SOURCE_ID_FIELD);
    }
}