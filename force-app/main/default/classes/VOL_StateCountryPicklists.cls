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
      FROM this software without specific prior written permission.
 
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

public with sharing class VOL_StateCountryPicklists {


    /*******************************************************************************************************
    * @description Utility to copy Address fields between Contacts and Accounts (or vice-versa).
    * Handles instances WHERE State and Country picklists are enabled.  Does not copy a source field if it
    * is null.
    * @param sobjSrc the source Contact or Account
    * @param strFieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param sobjDst the destination Contact or Account
    * @param strFieldPrefixDst the address fields to copy to, ie., Mailing, Other, Shipping, Billing
    * @return void
    */
    public static void copyAddressStdSObj(SObject sobjSrc, String strFieldPrefixSrc, SObject sobjDst, String strFieldPrefixDst) {
        String strVal;
        if ((strVal = (String) sobjSrc.get(strFieldPrefixSrc + 'Street')) != null) sobjDst.put(strFieldPrefixDst + 'Street', strVal);
        if ((strVal = (String) sobjSrc.get(strFieldPrefixSrc + 'City')) != null) sobjDst.put(strFieldPrefixDst + 'City', strVal);
        if ((strVal = (String) sobjSrc.get(strFieldPrefixSrc + 'PostalCode')) != null) sobjDst.put(strFieldPrefixDst + 'PostalCode', strVal);

        /****
        string strMsg;
        strMsg = 'before copy Country: ' + sobjSrc.get(strFieldPrefixSrc + 'Country') + ' State: ' + sobjSrc.get(strFieldPrefixSrc + 'State');
        if (isStateCountryPicklistsEnabled)
            strMsg += ' CountryCode: ' + sobjSrc.get(strFieldPrefixSrc + 'CountryCode') + ' StateCode: ' + sobjSrc.get(strFieldPrefixSrc + 'StateCode');
        ****/

        if (!isStateCountryPicklistsEnabled) {
            if ((strVal = (String) sobjSrc.get(strFieldPrefixSrc + 'State')) != null) sobjDst.put(strFieldPrefixDst + 'State', strVal);
            if ((strVal = (String) sobjSrc.get(strFieldPrefixSrc + 'Country')) != null) sobjDst.put(strFieldPrefixDst + 'Country', strVal);
        } else {
            // try to deal gracefully with Country
            String strCountry = (String) sobjSrc.get(strFieldPrefixSrc + 'Country');
            if (strCountry == null) strCountry = 'United States';
            if (validCountriesByLabel.containsKey(strCountry)) {
                sobjDst.put(strFieldPrefixDst + 'Country', strCountry);
                sobjDst.put(strFieldPrefixDst + 'CountryCode', validCountriesByLabel.get(strCountry));
            } else if (validCountriesByCode.containsKey(strCountry.toUpperCase())) {
                sobjDst.put(strFieldPrefixDst + 'CountryCode', strCountry.toUpperCase());
                sobjDst.put(strFieldPrefixDst + 'Country', validCountriesByCode.get(strCountry.toUpperCase()));
            } else sobjDst.put(strFieldPrefixDst + 'Country', strCountry);
            // allow the invalid country to be placed in the country field, so Salesforce will generate the error.

            // try to deal gracefully with State
            String strState = (String) sobjSrc.get(strFieldPrefixSrc + 'State');
            if (strState != null) {
                // best to make sure first letter is capitalized.
                strState = strState.capitalize();
                if (validStatesByLabel.containsKey(strState)) {
                    sobjDst.put(strFieldPrefixDst + 'State', strState);
                    sobjDst.put(strFieldPrefixDst + 'StateCode', validStatesByLabel.get(strState));
                } else sobjDst.put(strFieldPrefixDst + 'StateCode', strState.toUpperCase());
                // too expensive for us to create the map of CountryCode|StateCode to StateLabel
                // so we will just try to save any state that isn't a label as a code.
            }
        }

        /****        
		strMsg += ' after copy Country: ' + sobjDst.get(strFieldPrefixDst + 'Country') + ' State: ' + sobjDst.get(strFieldPrefixDst + 'State');	
		if (isStateCountryPicklistsEnabled)	    		
			strMsg += ' CountryCode: ' + sobjDst.get(strFieldPrefixDst + 'CountryCode') + ' StateCode: ' + sobjDst.get(strFieldPrefixDst + 'StateCode');   		
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, strMsg));
    	****/
    }

    /*******************************************************************************************************
    * @description specifies whether state and country picklists are enabled in this org.
    * @return true if enabled
    */
    public static Boolean isStateCountryPicklistsEnabled {
        get {
            if (isStateCountryPicklistsEnabled == null) isStateCountryPicklistsEnabled = initValidStateCountryCodes();
            return isStateCountryPicklistsEnabled;
        }
        private set;
    }

    // The maps to convert the State/Country Code to a State/Country Label and Vice-Versa
    private static Map<String, String> validCountriesByLabel = new Map<String, String>();
    private static Map<String, String> validStatesByLabel = new Map<String, String>();
    private static Map<String, String> validCountriesByCode = new Map<String, String>();

    @TestVisible
    private static void putCountryPicklist(String label,String value,Boolean isActive) {
        if(!isActive) return;
        validCountriesByLabel.put(label,value);
        validCountriesByCode.put(value,label);
    }

    @TestVisible
    private static void putStatePicklist(String label,String value,Boolean isActive) {
        if(!isActive) return;
        validStatesByLabel.put(label,value);
    }
    /*******************************************************************************************************
    * @description utility to determine if the "State and Country Picklist" field feature is enabled in Salesforce
    * @return true if enabled; Fills 4 sets<> with a list of value codes and labels for each field
    */
    @TestVisible
    private static Boolean initValidStateCountryCodes() {
        // If State & Country Picklists are enabled in the org, build maps of the
        // valid Labels and Codes for each field to use for validation
        Map<String, Schema.SObjectField> acctFields = Account.getSObjectType().getDescribe().fields.getMap();
        Boolean isCodesEnabled = acctFields.containsKey('BillingCountryCode');
        if (isCodesEnabled || Test.isRunningTest()) {
            List<Schema.PicklistEntry> countryPLValues = (acctFields.containsKey('BillingCountryCode')) ? acctFields.get('BillingCountryCode').getDescribe().getPicklistValues() : new List<PicklistEntry>();
            for (Schema.PicklistEntry p : countryPLValues) putCountryPicklist(p.getLabel(), p.getValue(), p.isActive());
            List<Schema.PicklistEntry> statePLValues = (acctFields.containsKey('BillingStateCode')) ? acctFields.get('BillingStateCode').getDescribe().getPicklistValues() : new List<PicklistEntry>();
            for (Schema.PicklistEntry p : statePLValues) putStatePicklist(p.label,p.value,p.isActive());
            // we can't have a map of valid StateCodes, because they are not unique.
            // ideally we would have a map of CountryCode + StateCode -> StateLabel
            // but Salesforce provides us no way of figuring out picklist dependencies efficiently.
        }
        return isCodesEnabled;
    }

}