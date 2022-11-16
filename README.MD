# appointmentViewer.cls

This is a Lightning Web Component that searches for a doctor's appointment and displays all appointments in many places (it's a component that can be placed in several built-in areas). Super helpful for the call center it was made for, used in many roles. 

# aHC_PatientSearch_LWC

This is a Lightning Web Component that searches for patient information. We actually have it triggered by the internal call application, so any time a "patient" calls in to their customer service line, the agent gets a popup that is either complete information that's already populated in the system (Patient Accounts) or in the event of no previous data, is pulled from the company's external application API (written in Python; I had a heavy responsibility to manage their team and ensure they were coding to our specifications). Since I first earned my stripes in API work, this is an example of something I've done very frequently (although I would typically advise most companies to avoid API interaction in favor of keeping it all in one highly focused operations product).

# redshift_to_hubspot.py

Showing that I certainly go into other languages as necessary. This synchronizes a Redshift AWS data backup and the Hubspot CRM (I have similar scripts for Salesforce too but they're much more complicated). You'll see the usage of Python and some very long SQL statements. I like this one because of the heavy usage of instanciated objects as connections.

# ticketflow.png

This is an example of a very simple (early phase) BMPN document I generally use to do process analysis. A company wanted to wrap their heads around the processes they use to handle internal ticketed technology problems. The symbols have very firm logical meaning, which means that processes are only allowed very specific results after each step. I elaborate these kinds of charts out to handle all processes within a specific end goal and then take each step and see if we can match it up with technology. This keeps the process specialists (the workers) in charge of the accuracy of the tech-free process map, and allows us tech nerds the flexibility of accommodating each step with creative solutions without being hindered by hard requirements from people who don't know how our system really works. You end up with super fast, super good solutions that show off what we can do. 