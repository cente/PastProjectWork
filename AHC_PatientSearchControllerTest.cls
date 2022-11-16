@isTest
private class AHC_PatientSearchControllerTest {
    
    @isTest static void validatePatientSearch() {
        User u = AHC_TestDataFactory.getUser();
        System.runas(u) {
            AHC_PatientSearchController patientSearch =new AHC_PatientSearchController();
            String parameter ='{"zipCode":"","firstName":"temporary","lastName":"temporary","dob":"","phone":"","email":"temporary"}';
            AHC_PatientSearchController.AHC_SearchWrapperAccount searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
            
            String accountRecordTypeId =AHC_PatientSearchController.fetchRecordTypeId(AHC_ConstantsUtility.ACCOUNT_API, 'PersonAccount');
            List<Account> accountList = AHC_TestDataFactory.createAccountTestRecords(AHC_ConstantsUtility.PATIENTSEARCHQUERYLIMIT,accountRecordTypeId);
            List<String> picklistValues = new List<String>();
            
            Account searchResultAccount =new Account();
            Test.startTest();
            try{
                parameter ='{"zipCode":"","firstName":"","lastName":"Tester","dob":"","phone":"87788","email":""}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
                parameter ='{"zipCode":"121","firstName":"","lastName":"","dob":"","phone":"","email":""}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
                parameter ='{"zipCode":"","firstName":"","lastName":"","dob":"","phone":"","email":""}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
            }catch(Exception e){
                //exception logging
                system.debug('Exception Occured '+e.getMessage());
            }
            
            Account insertAcc = new Account(LastName='Tester '+AHC_ConstantsUtility.PATIENTSEARCHQUERYLIMIT,RecordTypeId=accountRecordTypeId);
            insert insertAcc;
            List<Id> fixedSearchResults= new List<Id>();
            fixedSearchResults.add(insertAcc.id);
            Test.setFixedSearchResults(fixedSearchResults);
            
            try{
                parameter ='{"zipCode":"Male","firstName":"","lastName":"","dob":"2020-08-12","phone":"","email":"Tester"}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
                parameter ='{"zipCode":"Male","firstName":"","lastName":"","dob":"","phone":"","email":"Tester"}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
                parameter ='{"zipCode":"","firstName":"","lastName":"","dob":"","phone":"Tester","email":""}';
                searchWrapper=AHC_PatientSearchController.searchAccount(parameter);
                
            }catch(Exception e){
                //exception logging
                system.debug('Exception Occured '+e.getMessage());
            }
            
            //Negative Scenario
            try{
                accountRecordTypeId =AHC_PatientSearchController.fetchRecordTypeId(AHC_ConstantsUtility.ACCOUNT_API, 'Personal_12Account');
            }catch(Exception e){
                //exception logging
                system.debug('Exception Occured '+e.getMessage());
            }
            
            
            searchResultAccount = (Account)searchWrapper.accountListOnPages[0][0];
            Test.stopTest();
            
            String accountName=searchResultAccount.Name.substring(0,searchResultAccount.Name.length()-2).trim();
            System.assertEquals(accountName, 'Tester','Positive case testing');
        }
    }

    @isTest static void patientSearchEmpiTest() {
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.setMock(HttpCalloutMock.class, new EmpiSearchAuthenticationMockCallout());
            insertCustomSetting();
            Test.startTest();
            try {
                String parameter ='{"zipCode":"110078","firstName":"Calment","lastName":"Cleo","dob":"13-08-1994","phone":"3242423232","email":"cc@sa.com"}';
                Map<String,String> responseMap =AHC_PatientSearchController.patientSearchEmpiAuthentication(parameter);
                String jsonBody = responseMap.get('Success');
                //System.assertNotEquals(null, jsonBody, 'Authentication failed');
                AHC_PatientSearchController.AHC_SearchWrapperAccount searchWrapper =AHC_PatientSearchController.patientSearchEmpi(jsonBody);
                System.assertNotEquals(null,searchWrapper.accountListOnPages,'Response is empty');
                System.assertNotEquals(0,searchWrapper.accountListOnPages.size(),'Response list is empty');
            } catch(Exception e) {
                System.debug('Exception Occured '+e.getMessage());
            }
            Test.stopTest();
        }
    }
    
    @isTest static void getPatienRecordIdTest() {
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Test.setMock(HttpCalloutMock.class, new EmpiSearchEhrPatientDataMockCallout());
            insertCustomSetting();
            Test.startTest();
            try {
                String patientRecordType = Label.AHC_PatientRecordTypeDeveloperName;
                Id personAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(patientRecordType).getRecordTypeId();
                Account newAcc = AHC_TestDataFactory.createPersonAccount('Empi Patient search test',personAccRecordTypeId);
                newAcc.AHC_EUID__c = '01344555';
                newAcc.FirstName = 'Empi Patient';
                newAcc.MiddleName = 'Test Acc';
                newAcc.PersonBirthdate = Date.Today();
                newAcc.HealthCloudGA__Gender__pc = 'M';
                newAcc.PersonHomePhone = '3175143198';
                newAcc.PersonMobilePhone = '8663178457';
                newAcc.PersonEmail = 'JHARVEYSMITH007@GMAIL.COM';
                newAcc.PersonMailingStreet = '6513 SPARROWWOOD CT';
                newAcc.PersonMailingCity = 'INDIANAPOLIS';
                newAcc.PersonMailingCountry = 'USA';
                newAcc.PersonMailingPostalCode = '462368122';
                newAcc.PersonMailingState = 'IN';
                AHC_TestDataFactory.createEhrPatient(newAcc,'NodeA_1_10861&347092');

                //Case details
                Case_Detail__c newCaseDetail = new Case_Detail__c(Affected_Party_First_Name__c='Emp', 
                    Affected_Party_Last_Name__c='Test Acc', Patient_DOB__c = Date.Today());
                insert newCaseDetail;

                //Case creation
                Case newCase = new Case(Subject='Test Case for patient search', AccountId=newAcc.id, Case_Detail__c=newCaseDetail.id);
                insert newCase;                

                //Case RecoveryDetails
                AHC_PatientSearchController.recoveryCaseInnerClass innCls = new AHC_PatientSearchController.recoveryCaseInnerClass();
                innCls = AHC_PatientSearchController.getRecoveryCaseDetails(newCase.Id);

                //String accrecordId =AHC_PatientSearchController.getPatienRecordId(newAcc);
                String accrecordId =AHC_PatientSearchController.getPatienRecordId(newAcc,'External',String.valueOf(newCase.Id),
                    AHC_PatientSearchController.getObjectName(newCase.id)); //External
                System.assertNotEquals(null,accrecordId,'Account record not inserted as expected');
                String accrecordId1 =AHC_PatientSearchController.getPatienRecordId(newAcc,'Internal',String.valueOf(newCase.Id),
                    AHC_PatientSearchController.getObjectName(newCase.id)); //Internal
            } catch(Exception e) {
                System.debug('Exception Occured '+e.getMessage());
            }
            Test.stopTest();
        }
        
    }
    private static void insertCustomSetting() {
        AHC_oAuthCredentials__c oAuthCredentials = new AHC_oAuthCredentials__c();
        oAuthCredentials.EndPoint__c = 'https://login.microsoftonline.com/5414f27f-7c12-4272-b344-50f900c60728/oauth2/v2.0/token';
        oAuthCredentials.Client_ID__c = '7ca6f7ea-41d9-4358-91ee-157f04f2e7dd';
        oAuthCredentials.Scope__c = 'https://idqa.onmicrosoft.com/empi-api/.default';
        oAuthCredentials.Client_Secret__c = 'k.tog6YZBwN..e6gP4ZtgePXo4_d3LdpD1';
        oAuthCredentials.Grant_Type__c = 'client_credentials';
        oAuthCredentials.Content_Type__c = 'application/x-www-form-urlencoded';
        oAuthCredentials.Host__c = 'ogin.microsoft.com';
        oAuthCredentials.API_Key__c = '7ca6f7ea-41d9-4358-91ee-157f04f2e7dd';
        insert oAuthCredentials;

        AHC_empiCalloutInfo__c calloutInfo = new AHC_empiCalloutInfo__c();
        calloutInfo.Endpoint__c = 'https://test-api.redacted.org/empi/node-c/mm/PersonRS/search';
        calloutInfo.retrieveSBRs__c = 'true';
        calloutInfo.retrieveLIDs__c = 'true';
        calloutInfo.searchType__c = 'GUI-SEARCH';
        calloutInfo.Content_Type__c = 'application/json';
        insert calloutInfo;

        Nextgate_Credentials__c nextGate = new Nextgate_Credentials__c();
        nextGate.Endpoint__c = 'https://test-api.redacted.org/empi/node-c/mm/PersonRS/enterpriserecords';
        nextGate.Content_Type__c = 'application/json';
        nextGate.Endpoint_extension__c = 'systemrecords/SALESFORCE';
        insert nextGate;
    }
}