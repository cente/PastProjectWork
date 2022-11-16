public  class appointmentViewer
{
    @AuraEnabled
    public static string getAppointments(Id recordId) 
    {
        List<appointmentViewerKeyContainerClass> container = new List<appointmentViewerKeyContainerClass>();
        
        for (AHC_Appointment__c appointment : [select AHC_External_Id__c, AHC_PatientName__c, AHC_Location__c, AHC_StartDateTime__c, AHC_Type__c from AHC_Appointment__c where AHC_PatientName__c = :recordId])
        {
            appointmentViewerKeyContainerClass singleContainer = new appointmentViewerKeyContainerClass();
            
            singleContainer.recordId = appointment.AHC_External_Id__c;
            singleContainer.sfId = '/' + appointment.Id; 
            singleContainer.type = appointment.AHC_Type__c;
            singleContainer.location  = appointment.AHC_Location__c;

            if (appointment.AHC_StartDateTime__c<>NULL)
            {
                System.debug('appointment.AHC_StartDateTime__c: ' + appointment.AHC_StartDateTime__c);
                singleContainer.datetimeString = string.valueOf(appointment.AHC_StartDateTime__c);
                String conDate = (appointment.AHC_StartDateTime__c).format('M/dd/YYYY');
                String conTime = (appointment.AHC_StartDateTime__c).format('h:mm a');
                singleContainer.datetimeStringFormatted = conDate + ', ' + conTime;
                System.debug('singleContainer.datetimeStringFormatted: ' + singleContainer.datetimeStringFormatted);
            }
            container.add(singleContainer);
        }
        
        system.debug ('(appointmentViewer) container: ' + container);
        container.sort();
        String stringOutput = json.serialize(container);
        system.debug('(appointmentViewer) stringOutput: ' + stringOutput);
        return stringOutput;
    }

    //Returns limit of records allowed (reading from the custom metadata), before View All is selected.
    @AuraEnabled
    public static string getMainPageLimit(Id recordId)
    {
        String mainRecordMax=String.valueOf('10'); //default value

        List<AHC_Appointment_Viewer__mdt> lstAppt = 
            new List<AHC_Appointment_Viewer__mdt>([Select Main_Page_Record_Limit__c From AHC_Appointment_Viewer__mdt Where DeveloperName='Main_Page_Configs']);
        
        if (!lstAppt.isEmpty())
            mainRecordMax=String.valueOf(lstAppt[0].Main_Page_Record_Limit__c);

        return mainRecordMax;
    }

    //Returns the message to be displayed (reading from the custom metadata), when no appointments are returned.
    @AuraEnabled
    public static string getNoApptsMessage(Id recordId)
    {
        String mainNoApptsMsg='No appointments found in the system'; //default value

        List<AHC_Appointment_Viewer__mdt> lstAppt = 
            new List<AHC_Appointment_Viewer__mdt>([Select Main_Page_No_Appts_Message__c From AHC_Appointment_Viewer__mdt Where DeveloperName='Main_Page_Configs']);
        
        if (!lstAppt.isEmpty())
            mainNoApptsMsg=lstAppt[0].Main_Page_No_Appts_Message__c;

        return mainNoApptsMsg;
    }

}