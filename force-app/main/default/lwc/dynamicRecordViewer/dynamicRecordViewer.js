import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableObjects from '@salesforce/apex/DynamicRecordViewerController.getAvailableObjects';
import getRecords from '@salesforce/apex/DynamicRecordViewerController.getRecords';

export default class DynamicRecordViewer extends LightningElement {
    @track objectOptions = [];
    @track selectedObject;
    @track records = [];
    @track hasNoRecords = false;

    @wire(getAvailableObjects)
    wiredObjects({ error, data }) {
        if (data) {
            this.objectOptions = data;
        } else if (error) {
            this.showToast('Error', 'Failed to load object list', 'error');
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.records = [];
        this.hasNoRecords = false;
    }

    handleSubmit() {
        if (!this.selectedObject) {
            this.records = [];
            this.hasNoRecords = true;
            this.showToast('Warning', 'Please select an object', 'warning');
            return;
        }

        getRecords({ sObjectName: this.selectedObject })
            .then(result => {
                // Process records to include individual fields
                this.records = result.map(record => {
                    const fields = [];
                    // Iterate over keys in recordData to get fieldName and value
                    for (const fieldName in record.recordData) {
                        // Exclude standard Salesforce attributes and Id/Name if already displayed
                        if (fieldName !== 'attributes' && fieldName !== 'Id' && fieldName !== 'Name') {
                            fields.push({
                                fieldName: fieldName,
                                value: record.recordData[fieldName]
                            });
                        }
                    }
                    return {
                        ...record, // Keep existing properties like recordId, name, hasAccess
                        detailedFields: fields // Add a new property for detailed fields
                    };
                });

                this.hasNoRecords = this.records.length === 0;

                if (this.records.length > 0) {
                    this.showToast('Success', `${this.records.length} records fetched`, 'success');
                } else {
                    this.showToast('Info', 'No records found.', 'info');
                }
            })
            .catch(error => {
                this.records = [];
                this.hasNoRecords = true;
                this.showToast('Error', error?.body?.message || 'Unknown error', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get visibleRecords() {
        return this.records?.filter(rec => rec.hasAccess);
    }

    get lockedRecords() {
        return this.records?.filter(rec => !rec.hasAccess);
    }

}