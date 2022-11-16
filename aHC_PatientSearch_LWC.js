import { api, LightningElement, track, wire } from 'lwc';
import fetchRecordTypeId from '@salesforce/apex/AHC_PatientSearchController.fetchRecordTypeId';
import searchAccount from '@salesforce/apex/AHC_PatientSearchController.searchAccount';
//import patientSearchExternal from '@salesforce/apex/AHC_PatientSearchController.patientSearchExternal';
import getPatienRecordId from '@salesforce/apex/AHC_PatientSearchController.getPatienRecordId';
import patientSearchEmpiAuthentication from '@salesforce/apex/AHC_PatientSearchController.patientSearchEmpiAuthentication';
import patientSearchEmpi from '@salesforce/apex/AHC_PatientSearchController.patientSearchEmpi';
import AHC_PatientRecordTypeDeveloperName from '@salesforce/label/c.AHC_PatientRecordTypeDeveloperName';
import AHC_Patient_Search_Error_Message from '@salesforce/label/c.AHC_Patient_Search_Error_Message';
import AHC_Patient_Search_Error_Message1 from '@salesforce/label/c.AHC_Patient_Search_Error_Message1';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { updateRecord } from 'lightning/uiRecordApi';
import getRecoveryCaseDetails from '@salesforce/apex/AHC_PatientSearchController.getRecoveryCaseDetails';
import getObjectName from '@salesforce/apex/AHC_PatientSearchController.getObjectName';

export default class AHC_PatientSearch_LWC extends NavigationMixin(LightningElement) {

    @api recordId; //Record id

    caseRecoveryDetails; //case recovery details
    caseAffectedPartyFirstName; //case recovery first name
    caseAffectedPartyLastName; //case recovery last name
    casePatientDOB; //case recovery dob
    objectNameString; //object name
 
    @track  accountListOnPage;
    @track  accountListofAllPages;
    @track  pageNumber=1;
    @track  searchCard=false;
    @track  errorMessage='';
    @track  showError=false;
    @track  AHC_PatientSearchParameterWrapper={firstName:'', lastName:'', dob:'', phone:'', email:'', zipCode:''};//, dobMonth:'' };
    @track  accountWrapperObject;
    @track columnsForSearch = [
        {
            type: "button",
            initialWidth: 150,
            typeAttributes: {
                label: 'Select Patient',
                name: 'select_patient',
                disabled: false,
                variant: 'brand'
            }
        },
        {
            label: 'NAME',
            fieldName: 'RecordLink',
            type: 'url',
            initialWidth: 200,
            typeAttributes: { label: { fieldName: 'Name' }, tooltip: 'Name', target:"_self" }
        },
        {
            label: 'DATE OF BIRTH',
            fieldName: 'PersonBirthdate',
            type: 'datetime',
            initialWidth: 110
        },
        {
            label: 'GENDER',
            fieldName: 'HealthCloudGA__Gender__pc',
            initialWidth: 100
        },
        {
            label: 'PHONE',
            fieldName: 'PersonHomePhone',
            type: 'phone',
            initialWidth: 120
        },
        {
            label: 'MOBILE',
            fieldName: 'PersonMobilePhone',
            type: 'phone',
            initialWidth: 120
        },
        {
            label: 'EMAIL',
            fieldName: 'PersonEmail',
            type: 'email',
            initialWidth: 150
        },
        {
            label: 'PRIMARY ADDRESS',
            fieldName: 'PersonMailingAddress',
            type: 'address',
            initialWidth: 200,
            wrapText: true
        }
    ];
    @track columnsForNetwork = [
        {
            type: "button",
            initialWidth: 150,
            typeAttributes: {
                label: 'Load Patient',
                name: 'load_patient',
                disabled: false,
                variant: 'brand'
            }
        },
        {
            label: 'NAME',
            fieldName: 'Name',
            wrapText: true,
            initialWidth: 200
        },
        {
            label: 'DATE OF BIRTH',
            fieldName: 'PersonBirthdate',
            type: 'datetime',
            initialWidth: 110
        },
        {
            label: 'GENDER',
            fieldName: 'HealthCloudGA__Gender__pc',
            initialWidth: 100
        },
        {
            label: 'PHONE',
            fieldName: 'PersonHomePhone',
            type: 'phone',
            initialWidth: 120
        },
        {
            label: 'MOBILE',
            fieldName: 'PersonMobilePhone',
            type: 'phone',
            initialWidth: 120
        },
        {
            label: 'EMAIL',
            fieldName: 'PersonEmail',
            type: 'email',
            initialWidth: 150
        },
        {
            label: 'PRIMARY ADDRESS',
            fieldName: 'PersonMailingAddress',
            type: 'address',
            wrapText: true,
            fixedWidth: 200
        }
    ];

    searchExternal=false;
    search=false;
    resultType='';
    patientDetail = '';
    empiSearchRecords;
    showSpinner = false;
    patientRecordId;

    async connectedCallback()
    {
        console.log('Patient search Record Id: ' + this.recordId);

        this.objectNameString = await getObjectName({recId:this.recordId});
        console.log('this.objectNameString: ' + this.objectNameString);

        //If object is Case, get Case Recovery Details
        if (this.objectNameString == 'Case')
        {
            await getRecoveryCaseDetails({caseId:this.recordId}).then(result => {
                this.caseRecoveryDetails = result;
                console.log('Case Recovery details: ' + this.caseRecoveryDetails);

                if (this.caseRecoveryDetails!=null && this.caseRecoveryDetails!='')
                {
                    this.caseAffectedPartyFirstName = this.caseRecoveryDetails.affectedPartyFirstName;
                    this.caseAffectedPartyLastName = this.caseRecoveryDetails.affectedPartyLastName;
                    this.casePatientDOB = this.caseRecoveryDetails.patientDOB;

                    if (this.caseAffectedPartyFirstName!=null && this.caseAffectedPartyFirstName!='')
                        this.AHC_PatientSearchParameterWrapper.firstName = this.caseAffectedPartyFirstName;
                    if (this.caseAffectedPartyLastName!=null && this.caseAffectedPartyLastName!='')
                        this.AHC_PatientSearchParameterWrapper.lastName = this.caseAffectedPartyLastName;
                    if (this.casePatientDOB!=null && this.casePatientDOB!='')
                        this.AHC_PatientSearchParameterWrapper.dob = this.casePatientDOB;
                }
            })
        }
    }
    
    @wire(fetchRecordTypeId, { objectName: 'Account', developerName: AHC_PatientRecordTypeDeveloperName }) accountRecordTypeId;

    keyCheck(component, event, helper){
        if (component.which == 13){
            this.handleClick();
        }
    }

    handleFirstName(event){
        this.AHC_PatientSearchParameterWrapper.firstName = event.target.value;
    }
    handleLastName(event){
        this.AHC_PatientSearchParameterWrapper.lastName =  event.target.value;
    }
    handleDob(event){
        var entry = event.target.value;

        if (entry.length==2 || entry.length==5)
            entry = entry + '/';

        this.AHC_PatientSearchParameterWrapper.dob =  entry;
    }    
    handlePhone(event){
        this.AHC_PatientSearchParameterWrapper.phone =  event.target.value;
    }
    handleEmail(event){
        this.AHC_PatientSearchParameterWrapper.email =  event.target.value;
    }
    handleZipCode(event){
        this.AHC_PatientSearchParameterWrapper.zipCode =  event.target.value;
    }

    handleReset(event){
        this.template.querySelectorAll('lightning-input').forEach(element => {
                if(element.type === 'checkbox' || element.type === 'checkbox-button'){
                    element.checked = false;
                } else {
                    element.value = null;
                }
            }
        )
        this.searchCard=false;
        this.template.querySelector("lightning-input[data-id=patientFirstName]").focus();
        // eval("$A.get('e.force:refreshView').fire();");
    }
    
    handleClick(event){

        var filledFieldCount=0;
        this.showError = false;
        var checkInputValidity=false;
        this.template.querySelectorAll('lightning-input.valInput').forEach(element => {
            element.checkValidity()
            element.reportValidity();
            if(element.value){
                checkInputValidity=true;
                filledFieldCount = filledFieldCount + 1;

            }


        });
        if (filledFieldCount >= 2) {  // Check the field count separately so we don't hit the DB unnecessarily
            if(checkInputValidity){
                searchAccount({inputParameter: JSON.stringify(this.AHC_PatientSearchParameterWrapper)})
                    .then(result => {
                        this.accountWrapperObject = result;
                    this.resultType='';
                    this.searchExternal=false;
                        if(result.moreRecords==true){
                            this.showError = true;
                            this.errorMessage = AHC_Patient_Search_Error_Message1;
                            this.searchCard=false;
                            this.accountListofAllPages=undefined;
                            this.accountListOnPage=undefined;
                        }
                        else{
                            this.showError = false;
                            this.errorMessage = undefined;
                            this.accountListofAllPages=result.accountListOnPages;
                            this.searchCard=true;
                            this.columns = this.columnsForSearch;
                            if(result.totalPages>0){
                                this.pageNumber=1;
                                this.handlePersonAccountData(this.accountListofAllPages);
                                //this.accountListOnPage=result.accountListOnPages[0];
                            }
                            else {
                                this.handlePersonAccountData(this.accountListofAllPages);
                            }
                        }
                    })
                    .catch(error => {
                        if (Array.isArray(error.body)) {
                            this.errorMessage = error.body.map(e => e.message).join(', ');
                        } else if (typeof error.body.message === 'string') {
                            this.errorMessage = error.body.message;
                        }
                        this.showError = true;
                        this.searchCard=false;
                        this.accountListofAllPages=undefined;
                        this.accountListOnPage=undefined;
                    this.resultType='';
                    this.searchExternal=false;
                    });

            }
            else{
                this.showError = true;
                this.errorMessage = AHC_Patient_Search_Error_Message;
                this.searchCard=false;
            }
        } else {
            this.showError = true;
            this.errorMessage = "Two fields are required.";
            this.searchCard=false;
        }
    }
    
    handlePatientRecord(event) {
        this.showSpinner = true;
        const actionName = event.detail.action.name;
        const rowIndex = JSON.stringify(event.detail.row.counter);
        switch (actionName) {
            case 'load_patient':
                console.log('========');
                this.getPatientRecordInfo(rowIndex, event, 'external');
                break;
            case 'select_patient':
                console.log('========');
                this.getPatientRecordInfo(rowIndex, event, 'internal');
                break;
            default:
        }
    }

    getPatientRecordInfo(rowIndex, event, flag) {
        console.log('::: '+rowIndex);
        var key = 'Name';
        if(this.pageNumber >= 2) {
            rowIndex = rowIndex - ((parseInt(this.pageNumber)-1) * 10);
        }
        var accountListOnPageWithoutName = this.accountListOnPage[rowIndex];
        delete accountListOnPageWithoutName[key];

        if (flag=='internal')
        {
            getPatienRecordId({patient: accountListOnPageWithoutName, 
                flag:'internal', recordId: this.recordId, objName: this.objectNameString})
            .then(result => {
                this.patientRecordId = result;
                this.showSpinner = false;

                if (this.objectNameString == 'Case')
                {
                    updateRecord({ fields: { Id: this.recordId } }); //for refresh
                    this.navigateToCase();
                    this.handleReset(event);
                }
                else
                {
                    this.navigateToAccount();
                    this.handleReset(event);
                }

            })
            .catch(error => {
                console.log(error);
            });            
        }
        else if (flag=='external')
        {
            getPatienRecordId({patient: accountListOnPageWithoutName, 
                flag:'external', recordId: this.recordId, objName: this.objectNameString})
            .then(result => {
                this.patientRecordId = result;
                this.showSpinner = false;

                if (this.objectNameString == 'Case')
                {
                    updateRecord({ fields: { Id: this.recordId } }); //for refresh
                    this.navigateToCase();
                    this.handleReset(event);
                }
                else
                {
                    this.navigateToAccount();
                    this.handleReset(event);
                }
            })
            .catch(error => {
                console.log(error);
            });
        }
    }

    navigateToCase() {
        console.log('Navigating to ' + this.recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }

    navigateToAccount() {
        console.log(this.patientRecordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.patientRecordId,
                actionName: 'view',
            },
        });
    }

    get displayTable(){
        return this.accountWrapperObject.totalPages != 0 && Boolean(this.accountListOnPage);
    }
    get enablePaginagtion(){
        return Boolean(this.accountWrapperObject.totalPages>1);
    }
    get disablePrev(){
        return Boolean(this.pageNumber == 1);
    }
    get disableNext(){
        return Boolean(this.pageNumber == this.accountWrapperObject.totalPages);
    }
    navigateAccount(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.name,
                actionName: 'view',
            },
        });
    }
    handlePrevious(){
        this.accountListOnPage=this.accountListofAllPages[this.pageNumber-2];
        this.pageNumber=this.pageNumber-1;
    }
    handleNext(){
        this.accountListOnPage=this.accountListofAllPages[this.pageNumber];
        this.pageNumber=this.pageNumber+1;
    }
    get disableExternalSearch(){
        return this.searchExternal;
    }
    get disableSearch(){
        return this.search;
    }
    handleExternalSearch(){
        this.showSpinner = true;
		this.patientDetail = JSON.stringify(this.AHC_PatientSearchParameterWrapper);
        this.searchExternal=true;
        this.search=true;
             patientSearchEmpiAuthentication({inputParameter: this.patientDetail})
                .then(result => {
                    for(let key in result) {
                        if(key == 'Success') {
                            console.log('Success');
                            console.log(result.Success);
                            this.search=false;
                            this.searchCard = true;
                            this.resultType='EMPI';
                            this.showError = false;
                            this.errorMessage = undefined;
                            this.empiSearchRecords = result.Success;
                            this.handlePatientSearchEmpi();
                            console.log('EMPI '+this.empiSearchRecords);
                        }
                        else if(key == 'Failed') {
                            console.log('Failed');
                            this.showError = true;
                            this.errorMessage = result[key];
                            this.searchCard=false;
                            this.showSpinner = false;
                        }
                    }
                    if(this.empiSearchRecords == undefined) {
                        this.showSpinner = false;
                    }
                    
                })
                .catch(error => {
                    if (Array.isArray(error.body)) {
                        this.errorMessage = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        this.errorMessage = error.body.message;
                    }
                    this.showError = true;
                    this.searchCard=false;
                    this.searchExternal=false;
                    this.search=false;
                    this.resultType='EMPI';
                    this.showSpinner = false;
                });
    }

    handlePatientSearchEmpi() {
        patientSearchEmpi({responseJsonBody: this.empiSearchRecords})
        .then(result => {
            this.search=false;
            this.accountWrapperObject = result;
            this.resultType='EMPI';
            if(result.moreRecords==true){
                console.log('moreRecords');
                this.showError = true;
                this.errorMessage = AHC_Patient_Search_Error_Message1;
                this.searchCard=false;
                this.accountListofAllPages=undefined;
                this.accountListOnPage=undefined;
            }
            else{
                this.showError = false;
                this.errorMessage = undefined;
                this.accountListofAllPages=result.accountListOnPages;
                this.searchCard=true;
                this.columns = this.columnsForNetwork;
                if(result.totalPages>0){
                    this.pageNumber=1;
                    this.handlePersonAccountData(this.accountListofAllPages);
                    //this.accountListOnPage=result.accountListOnPages[0];
                }
                else {
                    this.handlePersonAccountData(this.accountListofAllPages);
                }
            }
        })
        .catch(error => {
            if (Array.isArray(error.body)) {
                this.errorMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.errorMessage = error.body.message;
            }
            this.showError = true;
            this.searchExternal=false;
            this.search=false;
            this.resultType='EMPI';
        });
        this.showSpinner = false;
    }

    handlePersonAccountData(accountListofAllPages) {
        let accountListofAllPagesForChange = [];
        let counter = 0;
        for(let key in accountListofAllPages) {
            let accountListOnPage = [];
            for(let keys in accountListofAllPages[key])  {
                let accountListOnEachPage = {};
                var account = accountListofAllPages[key];
                console.log('{{{{{{');
                console.log(accountListOnEachPage.FirstName);
                accountListOnEachPage.Id = account[keys].Id;
                accountListOnEachPage.RecordTypeId = undefined;
                accountListOnEachPage.FirstName = account[keys].FirstName;
                accountListOnEachPage.MiddleName = account[keys].MiddleName;
                console.log('mN '+accountListOnEachPage.FirstName);
                accountListOnEachPage.LastName = account[keys].LastName;
                console.log('lN '+accountListOnEachPage.FirstName);
                console.log(account[keys].Name);
                if(account[keys].Name != undefined) {
                    accountListOnEachPage.Name = account[keys].Name;
                }
                else {
                    if(accountListOnEachPage.FirstName != undefined) {
                        accountListOnEachPage.Name = accountListOnEachPage.FirstName;
                    }
                    if(accountListOnEachPage.MiddleName != undefined) {
                        if(accountListOnEachPage.Name != undefined) {
                            accountListOnEachPage.Name += ' ' + accountListOnEachPage.MiddleName;
                        }
                        else {
                            accountListOnEachPage.Name = accountListOnEachPage.MiddleName;
                        }
                    }
                    if(accountListOnEachPage.LastName != undefined) {
                        if(accountListOnEachPage.Name != undefined) {
                            accountListOnEachPage.Name += ' ' + accountListOnEachPage.LastName;  
                        }
                        else {
                            accountListOnEachPage.Name = accountListOnEachPage.LastName;
                        }
                    }
                }
                accountListOnEachPage.PersonBirthdate = account[keys].PersonBirthdate;
                accountListOnEachPage.HealthCloudGA__Gender__pc = account[keys].HealthCloudGA__Gender__pc;
                accountListOnEachPage.PersonHomePhone = account[keys].PersonHomePhone;
                accountListOnEachPage.PersonMobilePhone = account[keys].PersonMobilePhone;
                accountListOnEachPage.PersonEmail = account[keys].PersonEmail;
                accountListOnEachPage.PersonMailingAddress = (account[keys].PersonMailingStreet ? account[keys].PersonMailingStreet : '') + '' +
                                                         (account[keys].PersonMailingCity ? '\n' + account[keys].PersonMailingCity : '') + ', '
                                                         + (account[keys].PersonMailingCountry ? account[keys].PersonMailingCountry : '') + ' '
                                                         + (account[keys].PersonMailingState ? account[keys].PersonMailingState : '') + ' ' +
                                                         (account[keys].PersonMailingPostalCode ? account[keys].PersonMailingPostalCode : '');
                accountListOnEachPage.AHC_EUID__c = account[keys].AHC_EUID__c;
                accountListOnEachPage.RecordLink = '/' + account[keys].Id;
                accountListOnEachPage.counter = counter;
                counter++;
                console.log(accountListOnEachPage);
                accountListOnPage.push(accountListOnEachPage);
                console.log(accountListOnPage);
            }
            accountListofAllPagesForChange.push(accountListOnPage);
        }
        this.accountListOnPage = accountListofAllPagesForChange[0];
        this.accountListofAllPages = accountListofAllPagesForChange; 
    }
}