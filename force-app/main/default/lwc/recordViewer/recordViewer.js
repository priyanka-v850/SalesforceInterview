import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import getRecords from '@salesforce/apex/RecordViewerController.getRecords';

export default class RecordViewer extends NavigationMixin(LightningElement) {
    @track selectedObject = 'Account'; 
    @track records = [];
    @track hasNoRecords = false;

    currentPageReference;
    initialUrlHandled = false;

    objectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Case', value: 'Case' }
    ];


    connectedCallback() {
        if (!this.initialUrlHandled) {
            setTimeout(() => {
                if (this.currentPageReference) {
                    const obj = this.currentPageReference.state?.c__object;
                    if (obj && ['Account', 'Contact', 'Opportunity'].includes(obj)) {
                        this.selectedObject = obj;
                    } else {
                        this.updateURLParameter();
                    }
                    this.initialUrlHandled = true;
                }
            }, 0);
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageRef) {
        if (currentPageRef) {
            this.currentPageReference = currentPageRef;
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.records = []; 
        this.hasNoRecords = false; 
        this.updateURLParameter(); 
    }

    handleSubmit() {
        console.log('handleSubmit called for:', this.selectedObject);
        if (!this.selectedObject) {
            this.records = [];
            this.hasNoRecords = true; 
            this.showToast('Warning', 'Please select an object to display records.', 'warning');
            return;
        }
        
         

        getRecords({ sObjectName: this.selectedObject })
            .then(result => {
                this.records = [...result]; 
                this.hasNoRecords = result.length === 0;

                if (result.length > 0) {
                    this.showToast('Success', `${result.length} records fetched successfully for ${this.selectedObject}.`, 'success');
                    console.log('getRecords success::',JSON.stringify(this.records));
                    console.log('records.length success::',this.records.length);
                } else {
                    this.showToast('Info', `No records found for ${this.selectedObject}.`, 'info');
                }
            })
            .catch(error => {
                this.records = [];
                this.hasNoRecords = true;
                console.error('Error fetching records:', error);

                let errorMessage = 'An unknown error occurred.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                } else if (error.message) {
                    errorMessage = error.message;
                }
                this.showToast('Error', `Error fetching records for ${this.selectedObject}: ${errorMessage}`, 'error');
            });
    }

    updateURLParameter() {
        if (!this.currentPageReference) {
            console.warn('currentPageReference is not available yet. Cannot update URL.');
            return;
        }
        console.log('updateURLParameter called for:', this.selectedObject);
        const pageRef = {
            type: this.currentPageReference.type,
            attributes: {
                ...this.currentPageReference.attributes,
            },
            state: {
                ...this.currentPageReference.state,
                c__object: this.selectedObject 
            }
        };
        
        this[NavigationMixin.Navigate](pageRef, false);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    get isAccount() {
        return this.selectedObject === 'Account';
    }

    get isContact() {
        return this.selectedObject === 'Contact';
    }

    get isOpportunity() {
        return this.selectedObject === 'Opportunity';
    }
}