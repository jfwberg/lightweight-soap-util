/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that contains a set of Salesforce SOAP API  Utilities
 * @note           This class is to be used in a managed package and contains Global methods that
 *                 should be made public or private in org based implementations or unlocked
 *                 packages.
 *                 Can be modified to make smaller in your own implementation
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.ApexDoc ')
global with sharing class Util {

    /**
     * @description Method to create a full, namespaced API name for the metadata
     * @param fullName The metadata name (without namespace)
     * @return      The full, namespaced API name for the metadata  
     */
    global static String getNamespacedMetadataName(String fullName){
        return String.isNotBlank(Constant.VAL_NAMESPACE) ? Constant.VAL_NAMESPACE + '__' + fullName : fullName;
    }


    /**
     * @description Method to create a full, namespaced API name for the metadata
     * @param fullName      The metadata name (without namespace)
     * @param namespaceName The name of the namespace
     * @return      The full, namespaced API name for the metadata  
     */
    global static String getNamespacedMetadataName(String fullName, String namespaceName){
        return String.isNotBlank(namespaceName) ? namespaceName + '__' + fullName : fullName;
    }


    /**
     * @description Utility method to fetch a single value from an XML element
     * @param xsr     The XmlStreamReader to traverse
     * @param tagName The name of the tag you want to retrieve the value from
     * @return      The value of the FIRST tag with a matching tag name
     */
    global static String readSingleValue(XmlStreamReader xsr, String tagName){
        while(true){
            if(xsr.getEventType()==XmlTag.START_ELEMENT && xsr.getLocalName() == tagName){
                xsr.next();
                if(xsr.getEventType() == XmlTag.CHARACTERS){
                    return xsr.getText();
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return null;
    }


     /**
     * @description Utility method to fetch a single value from an XML element in a list
     * @param xsr           The XmlStreamReader to traverse
     * @param parentElement The name of the repeated parent element that is a list
     * @param tagName       The name of the tag you want to retrieve the value from
     * @return      A list of of the first value for each parent element
     */
    global static String[] readSingleValueOnList(XmlStreamReader xsr, String parentElement, String tagName){
        
        String[] output = new String[]{};
        
        while(true){
            if(xsr.getEventType()==XmlTag.START_ELEMENT && xsr.getLocalName() == parentElement){
               output.add(readSingleValue(xsr, tagName));
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return output;
    }


    /**
     * @description Utility method to fetch a single value from an XML element
     * @param xsr      The XmlStreamReader to traverse
     * @param tagNames The list of tag names to get the data for
     * @return      The value of the FIRST tag with a matching tag name
     */
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts')
    global static Map<String,String> readMultipleValues(XmlStreamReader xsr, Set<String> tagNames){
        
        // Count the number of max values, because we can stop if all values are found
        Integer maxValues = tagNames.size();

        // The output map
        Map<String,String> output = new Map<String,String>();
        
        while(true){
            
            if(xsr.getEventType()==XmlTag.START_ELEMENT && tagNames.contains(xsr.getLocalName())){

                String localName = xsr.getLocalName();

                xsr.next();
                if(xsr.getEventType() == XmlTag.CHARACTERS){
                    
                    // Add value to the output
                    output.put(localName, xsr.getText());

                    // Stop if all values are found
                    if(output.size() == maxValues){
                        break;
                    }
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return output;
    }


    /**
     * @description Utility method to fetch a single value from an XML element
     * @param xsr      The XmlStreamReader to traverse
     * @param tagNames The list of tagnames to geet the data for
     * @return      The value of the FIRST tag with a matching tag name
     */
    global static List<Map<String,String>> readMultipleValuesOnList(XmlStreamReader xsr, String parentElement, Set<String> tagNames){
    
        // The output map
        List<Map<String,String>> output = new List<Map<String,String>>();
        
        while(true){
            if(xsr.getEventType()==XmlTag.START_ELEMENT && xsr.getLocalName() == parentElement){
                output.add(readMultipleValues(xsr,tagNames));
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return output;
    }


    /**
     * @description Method handle a crud rsult
     * @param xsr           The XmlStreamReader to traverse
     * @param metadataType  The metadataType to inform the user about the type
     * @return       A list of metadata upsert results
     */
    global static MdtCrudResult[] handleMdtCrudResponse(XmlStreamReader xsr, String metadataType){

        // List of results to return
        MdtCrudResult[] results = new MdtCrudResult[]{};

        // Temporary variable for each individual result
        MdtCrudResult result;

        // Stream throught the XML Elements and handle accordingly
        while(true){
            switch on xsr.getEventType(){
                when START_ELEMENT {
                    switch on xsr.getLocalName(){
                        
                        when  'result'{
                            result = new MdtCrudResult(metadataType);
                        }
                        
                        when 'created' {
                            xsr.next();
                            result.created = xsr.getText()?.equals('true');
                        }

                        when 'success' {
                            xsr.next();
                            result.success = xsr.getText()?.equals('true');
                        }

                        when 'fullName'{
                            xsr.next();
                            result.fullName = xsr.getText();
                        }

                        when 'errors'{
                            xsr.next();
                            handleErrors(xsr, result);
                        }
                    }
                }
                when END_ELEMENT {
                    if(xsr.getLocalName() == 'result'){
                        results.add(result);
                        result = null;
                    }
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return results;
    }


    /**
     * @description Method to create a map between mdt fullname (key) and Id (Value)
     *              This is ideal when creating metadata picklists. Not all metadata has
     *              an Id though, so keep that in mind.
     * @param xsr   The XmlStreamReader to traverse
     * @return      The value of the tag
     */
    global static Map<String,String> getFullNameIdMapFromMetadataListResult(XmlStreamReader xsr){

        // Output map
        Map<String,String> fullNameIdMap = new Map<String,String>();

        // Temporary variables
        String myId;
        String myFullName;

        // Stream throught the XML Elements and handle accordingly
        while(true){
            switch on xsr.getEventType() {
                when START_ELEMENT{
                    switch on xsr.getLocalName() {
                        when 'fullName'{
                            xsr.next();
                            if(xsr.getEventType() == XmlTag.CHARACTERS){
                                myFullName = xsr.getText();
                            }
                        }
                        when 'id' {
                            xsr.next();
                            if(xsr.getEventType() == XmlTag.CHARACTERS){
                                myId = xsr.getText();
                            }
                        }
                    }
                }
                when END_ELEMENT{
                    if(xsr.getLocalName() == 'result'){
                        
                        // Prevent null values (they should not occur, but just in case)
                        // It's valid for Ids to be null, there is no filtering here
                        if(String.isNotBlank(myFullName)){
                            fullNameIdMap.put(myFullName,myId);

                            // Prevent any cary over
                            myFullName = null;
                            myId = null;
                        }
                    }
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return fullNameIdMap;
    }


    /**
     * @description Method to create a map between the fields based on the tag name
     * @param xsr       The XmlStreamReader to traverse
     * @param tagName   Name of the repeated parent tag
     * @param keyTag    Value for the map key
     * @param valueTag  Value for the map value
     * @return      A key value map based on two fields in the XML response
     */
    global static Map<String,String> getKeyValueMapForElement(XmlStreamReader xsr, String tagName, String keyTag, String valueTag){
        
        // The output data
        Map<String,String> output = new Map<String,String>();

        // temporary variables
        String key;
        String value;

        while(true){
            switch on (xsr.getEventType()) {
                when START_ELEMENT{
                    if(xsr.getLocalName() == keyTag){
                        xsr.next();
                        key = xsr.getText();
                    }else if(xsr.getLocalName() == valueTag){
                        xsr.next();
                        value = xsr.getText();
                    }
                }
                when END_ELEMENT{
                    if(xsr.getLocalName() == tagName){
                        output.put(key, value);
                        key   = null;
                        value = null;
                    }
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
        return output;
    }


    /** **************************************************************************************************** **
     **                                      RESPONSE HANDLING METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method to add crud data to a result
     * @param xsr      The XmlStreamReader to traverse
     * @param result   The results to add the data to
     */
    private static void handleErrors(XmlStreamReader xsr, MdtCrudResult result){
        while(true){

            // Stop if the end of an error is reached
            if(xsr.getEventType()==XmlTag.END_ELEMENT && xsr.getLocalName() == 'errors'){
                break;
            }

            // Get the error message
            if(xsr.getEventType()==XmlTag.START_ELEMENT){

                // Output the name of the metadata
                if(xsr.getLocalName() == 'message'){
                    xsr.next();
                    result.errorMessage = xsr.getText();
                    break;
                }
            }
            if(xsr.hasNext()){xsr.next();}else{break;}
        }
    }


    /** **************************************************************************************************** **
     **                                       DATA STRUCTURE CLASSES                                         **
     ** **************************************************************************************************** **/
    /**
     * @description A data structure to output the Metadata CRUD result
     *              in a nice way to the end user
     */
     global class MdtCrudResult{
        @AuraEnabled
        global String fullname;

        @AuraEnabled
        global String type;

        @AuraEnabled
        global String errorMessage;

        @AuraEnabled
        global Boolean created;

        @AuraEnabled
        global Boolean success;

        /**
         * @description Main constructor
         * @param type  The metadata type the CRUD is applied to
         */
        global MdtCrudResult(String type){
            this.type = type;
        }
    }
}