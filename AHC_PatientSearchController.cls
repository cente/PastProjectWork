public with sharing class AHC_PatientSearchController 
{
    /*Determine object where LWC is loaded*/
    @AuraEnabled
    public static String getObjectName(string recId)
    {
        Id recIdCasted = recId;
        String sObjName = recIdCasted.getSObjectType().getDescribe().getName();

        return sObjName;
    }

    //Get Recovery Case Details based on case
    @AuraEnabled
    public static recoveryCaseInnerClass getRecoveryCaseDetails(String caseId) 
    {
        recoveryCaseInnerClass rClass = new recoveryCaseInnerClass();

        if (String.isNotBlank(caseId))
        {
            /*Service_Recovery_Case_Detail__c caseDetail = [Select Affected_Party_First_Name__c, 
                Affected_Party_Last_Name__c, Patient_DOB__c From Service_Recovery_Case_Detail__c 
                Where Case__c = :caseId];*/
            
            /*Case caseDetail = [Select SR_Case_Detail__r.Affected_Party_First_Name__c, 
                SR_Case_Detail__r.Affected_Party_Last_Name__c, SR_Case_Detail__r.Patient_DOB__c 
                From Case Where id = :caseId];*/
            Case caseDetail = [Select Case_Detail__r.Affected_Party_First_Name__c, 
                Case_Detail__r.Affected_Party_Last_Name__c, Case_Detail__r.Patient_DOB__c 
                From Case Where id = :caseId];
            
            if (!String.isBlank(caseDetail.Case_Detail__r.Affected_Party_First_Name__c))
                rClass.affectedPartyFirstName = caseDetail.Case_Detail__r.Affected_Party_First_Name__c;
            
            if (!String.isBlank(caseDetail.Case_Detail__r.Affected_Party_Last_Name__c))
                rClass.affectedPartyLastName = caseDetail.Case_Detail__r.Affected_Party_Last_Name__c;

            String fDate;
            if (!String.isBlank(String.valueof(caseDetail.Case_Detail__r.Patient_DOB__c)))
            {
                fDate = String.valueof(caseDetail.Case_Detail__r.Patient_DOB__c).substring(0, 10);
                if (fDate.length()==10)
                    rClass.patientDOB = fDate.mid(5,2)+'/'+fDate.mid(8,2)+'/'+fDate.mid(0,4);
            }
        }

        return rClass;
    }

    @TestVisible
    public class recoveryCaseInnerClass
    {
        @AuraEnabled public String affectedPartyFirstName;
        @AuraEnabled public String affectedPartyLastName;
        @AuraEnabled public String patientDOB;
    }

     @AuraEnabled
     public static AHC_SearchWrapperAccount searchAccount(String inputParameter) {
         try{
             System.debug('(TESTING SEARCH) inputParameter: ' + inputParameter);
             //convert input JSON to a record of AHC_PatientSearchParameterWrapper wrapper class
             AHC_PatientSearchParameterWrapper parameters = (AHC_PatientSearchParameterWrapper)system.JSON.deserializeStrict(inputParameter, AHC_PatientSearchParameterWrapper.class);
             
             //frame dyanamic SOSL
             String sosl='FIND';
             String searchQuery='';
             String searchFieldsFilter=' where IsPersonAccount=true';
             
             if(String.isNotBlank(parameters.firstName)){
                 searchQuery=' {'+String.escapeSingleQuotes(parameters.firstName).replace('-','\\-');
             }
             if(String.isNotBlank(parameters.lastName)){
                 if(String.isNotBlank(searchQuery)){
                     searchQuery += ' AND '+String.escapeSingleQuotes(parameters.lastName).replace('-','\\-');
                 }
                 else{
                     searchQuery=' {'+String.escapeSingleQuotes(parameters.lastName).replace('-','\\-');
                 }
             }
             if(String.isNotBlank(parameters.email)){
                 if(String.isNotBlank(searchQuery)){
                     searchQuery += ' AND '+parameters.email.replace('-','\\-');
                 }
                 else{
                     searchQuery=' {'+parameters.email.replace('-','\\-');
                 }
             }
             if(String.isNotBlank(parameters.phone)){
                 if(String.isNotBlank(searchQuery)){
                     searchQuery += ' AND '+parameters.phone.replace('-','\\-');
                 }
                 else{
                     searchQuery=' {'+parameters.phone.replace('-','\\-');
                 }
             }
             if(String.isNotBlank(parameters.zipCode)){
                 if(String.isNotBlank(searchQuery)){
                     searchQuery += ' AND '+parameters.zipCode.replace('-','\\-');
                 }
                 else{
                     searchQuery=' {'+parameters.zipCode.replace('-','\\-');
                 }
             }
             if(String.isNotBlank(searchQuery)){
                 searchQuery += '}';
                 sosl+=searchQuery+' IN ALL FIELDS RETURNING ';
             }
             
             if(String.isNotBlank(parameters.dob)){
                 System.debug('parameters.dob: ' + parameters.dob);
                 //Format conversion from MM/DD/YYYY to YYYY-MM-DD
                 String formattedDate=
                 parameters.dob.subString(6,10)+'-'+parameters.dob.subString(0,2)+'-'+
                 parameters.dob.subString(3,5);
                 System.debug('formattedDate:' + formattedDate);
                 
                     //searchFieldsFilter += ' and PersonBirthdate = '+parameters.dob;
                     searchFieldsFilter += ' and PersonBirthdate = '+formattedDate;
             }
             
       
             Integer patientSearchLimit=AHC_ConstantsUtility.PATIENTSEARCHQUERYLIMIT;
             Integer remainingQueryRows=AHC_Utility.getRemainingQueryRows();
             Integer searchLimit= patientSearchLimit<=remainingQueryRows ? patientSearchLimit : remainingQueryRows;
                     
             sosl += 'Account('+AHC_ConstantsUtility.ACCOUNT_FIELDS+searchFieldsFilter+' ) limit '+searchLimit; 
             
             if(String.isBlank(searchQuery)){
                 sosl='';
             }
             System.debug('*** sosl query'+sosl);
             List<List<sObject>> searchRecords = search.query(sosl);
             // sosl returned records are sent to be organised
             return organizeRecordsForComponent(searchRecords[0],patientSearchLimit);
             
         }Catch(Exception e){
             // exception logging
              throw new AuraHandledException(e.getMessage());
         }
         
     }
     
     
        
     public static AHC_SearchWrapperAccount organizeRecordsForComponent(List<Sobject> recordsList,Integer recordLimit) {
         try{
             
             //Number of records to diplay per each page
             Integer pageRecordSize=AHC_ConstantsUtility.PS_PAGE_RECORD_SIZE;
             
             //convert soql result to a record of AHC_SearchWrapperAccount wrapper class
             AHC_SearchWrapperAccount accWrapList = new AHC_SearchWrapperAccount();
             
             //if records returned size is same of query limit then it denotes more records are available for the search query
             if(recordsList!=null && recordsList.size()>=recordLimit){
                 accWrapList.moreRecords=true;
             }
             else{
                 accWrapList.moreRecords=false;
             }
             List<List<Account>> accListsForEachPage = new List<List<Account>>();
             Integer numberOfRecords;
             
             //calculate total number of pages
             if(recordsList==null || recordsList.isEmpty()){
                 accWrapList.totalPages=0;
             }
             else{
                 
                 if(math.mod(recordsList.size(),pageRecordSize)==0){
                     accWrapList.totalPages=recordsList.size()/pageRecordSize;
                     numberOfRecords=recordsList.size()/pageRecordSize;
                 }
                 else{
                     Integer divideRes=(recordsList.size()/pageRecordSize)+1;
                     accWrapList.totalPages=divideRes;
                     numberOfRecords=divideRes;
                 }  
             }
             
             //calculate records to be displayed in each page
             if(recordsList!=null && recordsList.size()>0){
                 Integer startIteration=0;
                 for(Integer i=0; i<numberOfRecords; i++){
                     List<SObject> tempAccList = new List<SObject>();
                     Integer endIteration=startIteration+pageRecordSize;
                     for(Integer j=startIteration;j<endIteration && j<recordsList.size();j++){
                         tempAccList.add(recordsList[j]);
                     }
                     startIteration+=pageRecordSize;
                     accListsForEachPage.add(tempAccList);
                 }
                 accWrapList.accountListOnPages=accListsForEachPage;
                 //Wrapping records list per each page
             }
             
             return accWrapList;
             
         }Catch(Exception e){
             // exception logging
             throw new AuraHandledException(e.getMessage());
         }
         
     }
     
     //This method used to get authentication from Empi
     @AuraEnabled(cacheable=true)
     public static Map<String,String> patientSearchEmpiAuthentication(String inputParameter) {
         try{
             AHC_PatientSearchParameterWrapper parameters = (AHC_PatientSearchParameterWrapper)system.JSON.deserializeStrict(inputParameter, AHC_PatientSearchParameterWrapper.class);
             //Added by Kranthi to convert MM/DD/YYYY to YYYY-MM-DD
             if(String.isNotBlank(parameters.dob)){
                String formattedDate=parameters.dob.subString(6,10)+'-'+parameters.dob.subString(0,2)+'-'+
                                      parameters.dob.subString(3,5);
                parameters.dob=formattedDate;
             }
             Map<String,String> responseMap = EmpiSearchAuthentication.getEmpiSearchRecords(parameters); 
             return responseMap;
             
         }Catch(Exception e){
             // exception logging
             throw new AuraHandledException(e.getMessage());
         }
         
         
     }
     
     //Getting records from Empi based on search criteria
     @AuraEnabled(cacheable=true)
     public static AHC_SearchWrapperAccount patientSearchEmpi(String responseJsonBody) {
         try{
             List<Account> patientAccountList = EmpiSearchAuthentication.parseEmpiJsonResponse(responseJsonBody);
             Integer patientSearchLimit=AHC_ConstantsUtility.PATIENTSEARCHQUERYLIMIT;
             return organizeRecordsForComponent(patientAccountList,patientSearchLimit);
             
         }Catch(Exception e){
             // exception logging
             throw new AuraHandledException(e.getMessage());
             
         }
     }


     //Process patient record: existing or new. For new, send back sfid to nextgen
     @AuraEnabled
     public static String getPatienRecordId(Account patient, String flag, String recordId, String objName)
     {
         String returnId;

         if (flag=='internal')
         {
             System.debug('(Internal)patientpatient'+patient);

             if (objName=='Case')
                updateCase(recordId, patient.Id); //Update the case with patient

             returnId = patient.Id;
         }
         else if (flag=='external')
         {
            System.debug('(External)patientpatient'+patient);
            System.debug('(External)patient.AHC_EUID__c'+patient.AHC_EUID__c);
            List<Account> accountSearchList = [SELECT id FROM Account WHERE AHC_EUID__c =:patient.AHC_EUID__c];
            System.debug('(External)patientpatientobjName'+objName);
            if(!accountSearchList.isEmpty())
            {
                if (objName=='Case')
                    updateCase(recordId, accountSearchList[0].Id); //Update the case with patient

                System.debug('Found the existing record for the patient');
                //return accountSearchList[0].Id;
                returnId = accountSearchList[0].Id;
            } 
            else
            {    
                try{
                    AHC_empiCalloutInfo__c empiCalloutInfo = AHC_empiCalloutInfo__c.getInstance(UserInfo.getUserId());
                    String integrationUserName = empiCalloutInfo.Integration_User_Name__c;
                    List<User> integrationUserList = [SELECT Id FROM User WHERE name=:integrationUserName];
                    Id integrationUserId = null;
                    if(!integrationUserList.isEmpty()) {
                        integrationUserId = integrationUserList[0].Id;
                    }
                    String patientRecordType = Label.AHC_PatientRecordTypeDeveloperName;
                    Id personAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(patientRecordType).getRecordTypeId();
                    patient.RecordTypeId = personAccRecordTypeId;
                    if(integrationUserId != null) {
                        patient.OwnerId = integrationUserId;
                    }
                    insert patient;

                    System.debug('Inserted: ' + patient.id);

                    if (objName=='Case')
                        updateCase(recordId, patient.id); //Update the case with newly added patient

                    EmpiSearchAuthentication.getEhrPatientData(patient.AHC_EUID__c,patient.Id);
                    EmpiSearchAuthentication.sendPatientData(patient.Id);
                    //return patient.Id;
                    returnId = patient.Id;
                }catch(Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }
            }
        }

        return returnId;
     }

    private static void updateCase(String caseRecordId, String patientId)
    {
        Case cs = [Select Id, AccountId from Case Where id = :caseRecordId];
        cs.AccountId = patientId;
        update cs;
    }
     
    public class AHC_PatientSearchParameterWrapper {
         @AuraEnabled
         public String firstName {get; set;}
         @AuraEnabled
         public String lastName {get; set;}
         @AuraEnabled
         public String dob {get; set;}
         @AuraEnabled
         public String phone  {get; set;}
         @AuraEnabled
         public String email {get; set;}
         @AuraEnabled
         public String zipCode {get; set;}
     }
     
     public class AHC_SearchWrapperAccount {
         @AuraEnabled
         public Boolean moreRecords {get; set;}
         @AuraEnabled
         public List<List<Sobject>> accountListOnPages {get; set;}
         @AuraEnabled
         public Integer totalPages {get; set;}
         
     }
     
     
     @AuraEnabled(cacheable=true)       
     public static Id fetchRecordTypeId(String objectName,String developerName) {
         try{
             return AHC_Utility.fetchRecordTypeId(objectName,developerName);
         }Catch(Exception e){
             // exception logging
             throw new AuraHandledException(e.getMessage());
         } 
     }
 }