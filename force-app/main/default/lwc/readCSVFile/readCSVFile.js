import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import readCSV from '@salesforce/apex/CsvController.readCSVFile';

const columns = [
    //{ label: 'Name', fieldName: 'Name'},
    //{ label: 'Product Id', fieldName: 'Product2Id'},
    //{ label: 'Product Name', fieldName: 'Product2.Name'},
    { label: 'Name', fieldName: 'Name'},
    { label: 'ProductCode', fieldName: 'ProductCode'},
    { label: 'Quantity', fieldName: 'Quantity'},
    { label: 'UnitPrice', fieldName: 'UnitPrice'},
    { label: 'TotalPrice', fieldName: 'TotalPrice'},
    { label: 'S/S', fieldName: 'S_S__c'}, 
    { label: 'Parts No (S/S)', fieldName: 'Parts_No_S_S__c'},
    { label: 'Parts Name (S/S)', fieldName: 'Parts_Name_S_S__c'},
    { label: 'Sold in Packs', fieldName: 'Sold_In_Packs__c'}, 
    { label: 'Delivery', fieldName: 'Delivery__c'}
];

export default class ReadCSVFileInLWC extends LightningElement {
    @api recordId;
    @track error;
    @track columns = columns;
    @track data;

    // accepted parameters
    get acceptedFormats() {
        return ['.csv'];
    }
    
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;

        // calling apex class
        //console.log('recordId '+this.recordId);
        console.log('recordId ===> '+ this.recordId);
        readCSV({idContentDocument : uploadedFiles[0].documentId, recordId: this.recordId})
        .then(result => {
            console.log('result');
            console.log(result);
            this.data = result;
            this.error = null;
            console.log('this.data');
        console.log(this.data);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!!',
                    message: 'Spare Parts line items successfully uploaded!',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            //this.error = error;
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            console.log(this.error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: this.error,
                    variant: 'error',
                }),
            );     
        })
        

    }
}