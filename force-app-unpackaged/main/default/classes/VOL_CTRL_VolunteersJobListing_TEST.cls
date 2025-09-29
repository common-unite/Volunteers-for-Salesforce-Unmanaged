/*
    Copyright (c) 2016, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

@IsTest
private with sharing class VOL_CTRL_VolunteersJobListing_TEST {

    //==================== TEST METHOD(s) ======================================
    private static void shouldCheckCreateAccessAndInsertHours() {
        VOL_Access_TEST.Stub accessMock = new VOL_Access_TEST.Stub();
        PageReference volunteersJobListPage = Page.VolunteersJobListing;
        Test.setCurrentPage(volunteersJobListPage);
        VOL_CTRL_VolunteersJobListing.access = (VOL_Access) Test.createStub(VOL_Access.class, accessMock);
        VOL_CTRL_VolunteersJobListing jobListingCtrl = new VOL_CTRL_VolunteersJobListing();

        jobListingCtrl.contact = UTIL_UnitTest.createContact('Signup Insert ' + DateTime.now().getTime());

        jobListingCtrl.VolunteerShiftSignUp();
        // The contact creation is completed by a separate class, VOL_SharedCode
        accessMock.assertMethodCalled('checkCreateAccess', Volunteer_Hours__c.SObjectType);
        accessMock.assertMethodCalled('insertRecords', Volunteer_Hours__c.SObjectType);
    }

    /*******************************************************************************************************
    * @description test the visualforce page controller, running as the Sites Guest User, if such as user
    * exists.  if not, will run under the current user.
    * @return void
    ********************************************************************************************************/
    @IsTest
    private static void testPageWithSitesGuestUser() {
        /** Without the ability to create sharing records in apex when owd sharing is public read/write or controlled by parent, we can no longer
         * run this test as the guest user and will only run it as the admin. Commenting out so that we can reinstate
         * if / when the ability to do so becomes available
         * List<User> listU = [Select Username, UserType, Name, IsActive, Id From User where IsActive = true and UserType = 'Guest' and
        Name like '%Site Guest User%'];
        if (listU.size() > 0) {
            UTIL_UnitTest.enableElevateGuestUserAccess();
            System.debug('Running test as Sites Guest User: ' + listU[0]);
            System.runAs(listU[0]) {
                UnitTest1();
            }
        } else {
        */
            System.debug('Running test as System.');
            UnitTest1();
        //}
    }

    private static void UnitTest1() {

        // set up intial test data
        Account acc = new Account(name='Test Individual Bucket Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Firstname='Test', Email='test@testy.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Job Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;        
        
        // specify our settings        
        System.assert(VOL_SharedCode.VolunteersSettings != null);
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Creates_Contacts_If_No_Match__c = false; // this shouldn't affect this page!
        settings.Signup_Matches_Existing_Contacts__c = false;   // this shouldn't affect this page!
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        PageReference pageRef = Page.VolunteersJobListing;
        pageRef.getParameters().put('ShowJobName', '1');
        pageRef.getParameters().put('ShowDescription', '1');
        pageRef.getParameters().put('ShowLocationAddress', '1');
        pageRef.getParameters().put('ShowLocationInfo', '1');
        pageRef.getParameters().put('ShowShifts', '1');
        pageRef.getParameters().put('ShowSkills', '1');
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_VolunteersJobListing ctrl = new VOL_CTRL_VolunteersJobListing();
        System.assertEquals(null, ctrl.campaignIdFilter);
        System.assertEquals(true, ctrl.ShowJobName);
        System.assertEquals(true, ctrl.ShowDescription);
        System.assertEquals(true, ctrl.ShowLocationAddress);
        System.assertEquals(true, ctrl.ShowLocationInfo);
        System.assertEquals(true, ctrl.ShowShifts);
        System.assertEquals(true, ctrl.ShowSkills);
        System.assertEquals(null, ctrl.contact.Id);
        System.assertEquals(null, ctrl.jobIdSignUp);
        System.assertEquals(null, ctrl.shiftIdSignUp);
        System.assertEquals(1, ctrl.vhTemp.Number_of_Volunteers__c);
        System.assertEquals(null, ctrl.strJobDisplayName);
        System.assertEquals(null, ctrl.strShiftDisplayName);
        System.assertEquals(null, ctrl.contactIdSignUp);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
        System.assert(ctrl.listVolunteerJobs.size() > 0);
        
        Integer cJobs = ctrl.listVolunteerJobs.size();
        Volunteer_Job__c job2 = new Volunteer_Job__c(name='Job2', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job2;
        ctrl.listVolunteerJobs = null;
        System.assertEquals(cJobs + 1, ctrl.listVolunteerJobs.size());

        ctrl.ClearVolunteerHoursIdSignUp();
        
        // sign someone up
        System.assertEquals(null, ctrl.contact.Id);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        ctrl.contact.FirstName = 'Test';
        ctrl.contact.LastName = 'Testy';
        ctrl.contact.Email = 'test@testy.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;     
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(con.Id, ctrl.contactIdSignUp);
        System.assert(ctrl.volunteerHoursIdSignUp != null);
        
        // pass cmp.Id as filter, verify only 2 jobs.
        // pass Show params with 0, verify values.
        pageRef = Page.VolunteersJobListing;
        pageRef.getParameters().put('ShowJobName', '0');
        pageRef.getParameters().put('ShowDescription', '0');
        pageRef.getParameters().put('ShowLocationAddress', '0');
        pageRef.getParameters().put('ShowLocationInfo', '0');
        pageRef.getParameters().put('ShowShifts', '0');
        pageRef.getParameters().put('ShowSkills', '0');
        pageRef.getParameters().put('campaignId', cmp.Id);
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        ctrl = new VOL_CTRL_VolunteersJobListing();
        System.assertEquals(2, ctrl.listVolunteerJobs.size());
        System.assertEquals(cmp.Id, ctrl.campaignIdFilter);
        
        // create hours for new person, verify contact created
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person';
        ctrl.contact.LastName = 'New person for my test';
        ctrl.contact.Email = 'newperson@volunteersjoblisting.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.VolunteerShiftSignUp();
        System.assert(ctrl.contactIdSignUp != null);
        System.assert(ctrl.volunteerHoursIdSignUp != null);

        // test permissions checks
        Integer cContact = [SELECT COUNT() FROM CONTACT];
        UTIL_Describe.throwException = true;
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person2';
        ctrl.contact.LastName = 'New person2 for my test';
        ctrl.contact.Email = 'newperson2@volunteersjoblisting.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(null, ctrl.contactIdSignUp);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.assertEquals(cContact, [SELECT COUNT() FROM CONTACT]);

    }

    private static testmethod void testCampaignHierarchies() {

		//create our test data
		map<string, Campaign> mapCmp = VOL_SharedCode_TEST.mapCampaignTestHierarchy();
		ID cmpIdGrandparent = mapCmp.get('Grandparent').Id;
		System.assertNotEquals(null, cmpIdGrandparent);
    
		// verify w/ no hierarchy
        PageReference pageRef = Page.VolunteersJobListing;
        pageRef.getParameters().put('campaignId', cmpIdGrandparent);
        Test.setCurrentPage(pageRef); 
        VOL_CTRL_VolunteersJobListing ctrl = new VOL_CTRL_VolunteersJobListing();
		System.assertEquals(1, ctrl.listVolunteerJobs.size());

		// verify w/ hierarchy
        PageReference pageRef2 = Page.VolunteersJobListing;
        pageRef2.getParameters().put('campaignId', cmpIdGrandparent);
        pageRef2.getParameters().put('ShowCampaignHierarchy', '1');
        Test.setCurrentPage(pageRef2); 
        VOL_CTRL_VolunteersJobListing ctrl2 = new VOL_CTRL_VolunteersJobListing();
		System.assertEquals(mapCmp.size(), ctrl2.listVolunteerJobs.size());
    }

}