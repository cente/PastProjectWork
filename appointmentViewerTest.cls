@istest
public with sharing class appointmentViewerTest {
    @TestSetup static void setup(){

        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Redacted_Healthcare_Patient').getRecordTypeId();

        system.debug('devRecordTypeId: ' + devRecordTypeId);
        List<Account> testAccts = new List<Account>();
        List<AHC_Appointment__c> testAppts = new List<AHC_Appointment__c>();

        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(LastName = 'TestAcct'+i, recordTypeId = devRecordTypeId));
        }
        insert testAccts;
        
        for (Account acct : [select id from Account]) {
            for(Integer i=0;i<20;i++) {
                string randommonth = String.valueof(Integer.valueof(Math.random()*6)+1);
                string randomday = String.valueof(Integer.valueof(Math.random()*27)+1);
                string randomyear = '2019';
                Datetime newdate = Datetime.parse(randommonth + '/' + randomday + '/' + randomyear + ',' + ' 12:00 AM');
                testAppts.add(new AHC_Appointment__c(AHC_StartDateTime__c =  newdate, AHC_PatientName__c = acct.id, AHC_External_Id__c = 'id'+Math.random()*10, AHC_Source_System_Id__c ='id'+Math.random()*10 ));
            }
        }
        
        insert testAppts;
    }

    @istest static void testGetDates() {
        Account acct = [select name, recordTypeId,id from Account limit 1];
        system.debug(acct.recordTypeId + ', ' + acct.name);
        Id acctid = Id.valueOf(acct.id);
        Test.startTest();
        String result = appointmentViewer.getAppointments(acctid);
        Test.stopTest();

        system.debug('result: ' + result);
        system.assert(result != null);
    
    }


    public static Id getRecordTypeId(String ObjectName,String recordTypeName){

        Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe() ;
        Schema.SObjectType s = sObjectMap.get(ObjectName) ; 
        Schema.DescribeSObjectResult resSchema = s.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = resSchema.getRecordTypeInfosByName(); 
        Id rtId = recordTypeInfo.get(recordTypeName).getRecordTypeId();
        return rtId;

    }

    @isTest
    static void testMainPageRecordLimit()
    {
        List<Account> lstacct = new List<Account>([select id from Account]);
        Decimal expected;
        AHC_Appointment_Viewer__mdt[] mdt = [Select Main_Page_Record_Limit__c From AHC_Appointment_Viewer__mdt Where DeveloperName='Main_Page_Configs'];
        for (AHC_Appointment_Viewer__mdt singledata: mdt) {
            expected = singledata.Main_Page_Record_Limit__c;
            break;
        }

        String actual = appointmentViewer.getMainPageLimit(lstacct[0].id);

        System.assertEquals(String.valueOf(expected),actual);
    }

    @isTest
    static void testMainPageNoApptsMsg()
    {
        List<Account> lstacct = new List<Account>([select id from Account]);

        String expected;
        AHC_Appointment_Viewer__mdt[] mdt = [Select Main_Page_No_Appts_Message__c From AHC_Appointment_Viewer__mdt Where DeveloperName='Main_Page_Configs'];
        for (AHC_Appointment_Viewer__mdt singledata: mdt) {
            expected = singledata.Main_Page_No_Appts_Message__c;
            break;
        }
        String actual = appointmentViewer.getNoApptsMessage(lstAcct[0].id);

        System.assertEquals(expected,actual);
    }    
}