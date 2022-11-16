import { LightningElement, api, track, wire} from 'lwc';
import getAppointments from '@salesforce/apex/appointmentViewer.getAppointments';
import getMainPageLimit from '@salesforce/apex/appointmentViewer.getMainPageLimit';
import getNoApptsMessage from '@salesforce/apex/appointmentViewer.getNoApptsMessage';

const columns = [
     {label: 'Date', fieldName: 'sfId', type: 'url', typeAttributes: {label: {fieldName: 'datetimeStringFormatted'}, target: '_self'}},
     {label: 'Location', fieldName: 'location', type: 'text'},
     {label: 'Type', fieldName: 'type', type: 'text'}
];

let data = [];
let dataMain = [];

export default class AppointmentViewer extends LightningElement
{
    @track modalContainer=false;
    @track showViewAllButton=false;
    @track showNoAppointmentsMsg=false;

    @api recordId;
    columns = columns; //Columns
    data = data; //Complete set of returned appointments
    dataMain = dataMain; //Appointments limited set for main page display only
    noApptsMessage; //No appointments message

    connectedCallback()
    {
        this.invokeApexMethods();
    }

    //Call the relevant methods ascynhronously that will prepare the appointments list
    async invokeApexMethods()
    {
        const limitOnMain = await getMainPageLimit({recordId: this.recordId });
        this.noApptsMessage = await getNoApptsMessage({recordId: this.recordId});
        const result = await getAppointments({ recordId: this.recordId });

        if (result!=null && result!='') //Avoid the use (result.length == 0) due to the potential of undesired exceptions
        {
            //Populate complete collection
            this.data = JSON.parse(result);

            if (this.data.length==0)
                this.displayNoAppointments();
            else
            {
                //Populate main area
                var mainColl = [];

                var i=0;
                while (i<limitOnMain)
                {
                    if (i<this.data.length)
                        mainColl.push(this.data[i]);
                    i++;
                }
                this.dataMain = mainColl;

                //Open up section for complete results, if needed
                if (this.data.length>limitOnMain)
                    this.showViewAllButton=true;
            }
        }
        else
            this.displayNoAppointments();
    }

    /*No appointments message*/
    displayNoAppointments()
    {
        this.error = this.noApptsMessage;//'No Appointments found';
        this.showNoAppointmentsMsg=true;        
    }

    /*Container method to handle all records*/
    handleAllRecords(event)
    {
        this.modalContainer=true;
    }

    /*Container method to close the pop style div*/
    closeModalAction()
    {
        this.modalContainer=false;
    }    
}