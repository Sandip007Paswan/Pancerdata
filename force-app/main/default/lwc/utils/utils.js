import { ShowToastEvent } from 'lightning/platformShowToastEvent';

function showToast(cmp, variant, title, message) {
    const event = new ShowToastEvent({        
        variant: variant,
        title: title,
        message: message
    });
    cmp.dispatchEvent(event);
}

export { showToast }