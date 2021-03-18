import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDistributionSourceInfo from '@salesforce/apex/DistributionSourceInfoCardController.getDistributionSourceInfo';
import getOwnedRecordCount from '@salesforce/apex/DistributionSourceInfoCardController.getOwnedRecordCount';

import DISTRIBUTION_SOURCE_ID_FIELD from '@salesforce/schema/Distribution_Rule__c.Distribution_Source_Id__c';

export default class DistributionSourceInfoCard extends LightningElement {
    @api recordId;
    
    @track distributionSourceInfo;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            DISTRIBUTION_SOURCE_ID_FIELD
        ]
    }) distributionRule;
    
    @wire(getDistributionSourceInfo, { 
        distributionSourceId: '$distributionSourceId'
    }) getDistributionSourceInfo({ error, data }) {
        if (data) {
            this.distributionSourceInfo = JSON.parse(JSON.stringify(data));

            Promise.all(
                this.distributionSourceInfo.untalliedRelatedSObjectTypeOwnedRecordCountList.map(untalliedRelatedSObjectTypeOwnedRecordCount => {
                    return getOwnedRecordCount({
                        distributionSourceId: this.distributionSourceId,
                        relatedSobjectType: untalliedRelatedSObjectTypeOwnedRecordCount.sObjectTypeName
                    });
                })
            ).then(talliedRelatedSObjectTypeOwnedRecordCounts => {
                this.distributionSourceInfo.talliedRelatedSObjectTypeOwnedRecordCounts = talliedRelatedSObjectTypeOwnedRecordCounts;
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: `Unable to determine number of ${relatedSobjectType} records owned by this distribution source`,
                        message: error.body.message,
                        variant: 'error'
                    }
                ));
            });
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to fetch distribution source information',
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