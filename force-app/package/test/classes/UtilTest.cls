/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Util methods
 */
@IsTest
private with sharing class UtilTest {

    @IsTest
    static void testGetNamespacedMetadataName(){

        Assert.areEqual(
            Constant.VAL_NAMESPACE + '__Metadata_Name',
            Util.getNamespacedMetadataName('Metadata_Name'),
            Constant.MSG_TEST_UNEXPECTED_VALUE
        );

        Assert.areEqual(
            'custom_ns__Metadata_Name',
            Util.getNamespacedMetadataName('Metadata_Name','custom_ns'),
            Constant.MSG_TEST_UNEXPECTED_VALUE
        );
    }


    @IsTest
    static void testReadSingleValue(){
        
        // Assertion variables
        String consumerKey;

        // Setup test data
        String xml          = '<data><childData><consumerKey>KEY</consumerKey></childData></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        consumerKey  = Util.readSingleValue(xsr, 'consumerKey');
        Test.stopTest();

        // Asserts
        Assert.areEqual('KEY', consumerKey, Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void testReadSingleValueWitNull(){
        
        // Assertion variables
        String consumerKey;

        // Setup test data
        String xml          = '<data><childData><consumerKey>KEY</consumerKey></childData></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        consumerKey  = Util.readSingleValue(xsr, 'nonExisting');
        Test.stopTest();

        // Asserts
        Assert.areEqual(null, consumerKey, Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void readSingleValueOnList(){
        
        // Assertion variables
        String[] valueList;

        // Setup test data
        String xml          = '<data><childData><consumerKey>KEY_01</consumerKey></childData><childData><consumerKey>KEY_02</consumerKey></childData></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        valueList  = Util.readSingleValueOnList(xsr,'childData','consumerKey');
        Test.stopTest();

        // Asserts
        Assert.areEqual('KEY_01', valueList[0], Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('KEY_02', valueList[1], Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void readMultipleValues(){
        
        // Assertion variables
        Map<String,String> values;

        // Setup test data
        String xml = '<data><salesforceLoginUrl>LOGIN_URL</salesforceLoginUrl><oauthTokenEndpoint>TOKEN_ENDPOINT</oauthTokenEndpoint></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);
        
        // Execute tests
        Test.startTest();
        values = Util.readMultipleValues(
            xsr,
            new Set<String>{
                'salesforceLoginUrl',
                'oauthTokenEndpoint'
            }
        );
        Test.stopTest();

        // Asserts
        Assert.areEqual('LOGIN_URL',      values.get('salesforceLoginUrl'), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('TOKEN_ENDPOINT', values.get('oauthTokenEndpoint'), Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void readMultipleValuesOnList(){
        
        // Assertion variables
        List<Map<String,String>> listOfValues;

        // Setup test data
        String xml = '<data><loginIpRanges><startAddress>START_ADDRESS_01</startAddress><endAddress>END_ADDRESS_01</endAddress><description>DESCRIPTION_01</description></loginIpRanges><loginIpRanges><startAddress>START_ADDRESS_02</startAddress><endAddress>END_ADDRESS_02</endAddress><description>DESCRIPTION_02</description></loginIpRanges></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        listOfValues = Util.readMultipleValuesOnList(
            xsr,
            'loginIpRanges',
            new Set<String>{
                'startAddress',
                'endAddress',
                'description'
            }
        );
        Test.stopTest();

        // Asserts
        Assert.areEqual('START_ADDRESS_01', listOfValues[0].get('startAddress'), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('END_ADDRESS_01',   listOfValues[0].get('endAddress'  ), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('DESCRIPTION_01',   listOfValues[0].get('description' ), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('START_ADDRESS_02', listOfValues[1].get('startAddress'), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('END_ADDRESS_02',   listOfValues[1].get('endAddress'  ), Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('DESCRIPTION_02',   listOfValues[1].get('description' ), Constant.MSG_TEST_UNEXPECTED_VALUE);
    }

   
    @IsTest
    static void testHandleMdtCrudResponse(){
        
        // Assertion variables
        Util.MdtCrudResult[] results;

        // Setup test data
        String xml = '<Body><upsertMetadataResponse><result><created>true</created><fullName>Salesforce_Connection_Toolkit</fullName><success>true</success></result><result><created>false</created><errors><message>ERROR_MESSAGE</message><statusCode>STATUS_CODE</statusCode></errors><fullName>Salesforce__Connection_Toolkit</fullName><success>false</success></result></upsertMetadataResponse></Body>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        results = Util.handleMdtCrudResponse(xsr,'LightningMessageChannel');
        Test.stopTest();

        // Asserts
        Assert.areEqual('Salesforce_Connection_Toolkit',    results[0].fullname,     Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('LightningMessageChannel',          results[0].type,         Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(true,                               results[0].success,      Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(true,                               results[0].created,      Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(null,                               results[0].errorMessage, Constant.MSG_TEST_UNEXPECTED_VALUE);
        
        Assert.areEqual('Salesforce__Connection_Toolkit',   results[1].fullname,     Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('LightningMessageChannel',          results[1].type,         Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(false,                              results[1].success,      Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(false,                              results[1].created,      Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('ERROR_MESSAGE',                    results[1].errorMessage, Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void testHandleMdtCrudResponseNoMessage(){
        
        // Assertion variables
        Util.MdtCrudResult[] results;

        // Setup test data
        String xml = '<Body><upsertMetadataResponse><result><created>true</created><fullName>Salesforce_Connection_Toolkit</fullName><success>true</success></result><result><created>false</created><errors><statusCode>STATUS_CODE</statusCode></errors><fullName>Salesforce__Connection_Toolkit</fullName><success>false</success></result></upsertMetadataResponse></Body>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        results = Util.handleMdtCrudResponse(xsr,'LightningMessageChannel');
        Test.stopTest();

        // Asserts
        Assert.areEqual(null, results[1].errorMessage, Constant.MSG_TEST_UNEXPECTED_VALUE);
    }


    @IsTest
    static void testGetFullNameIdMapFromMetadataListResult(){
        
        // Assertion variables
        Map<String,String> results;

        // Setup test data
        String xml = '<data><result><fullName>FULL_NAME_01</fullName><id>ID_01</id></result><result><fullName>FULL_NAME_02</fullName><id>ID_02</id></result></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        results = Util.getFullNameIdMapFromMetadataListResult(xsr);
        Test.stopTest();
    
        // Asserts
        Assert.areEqual(true,    results.containsKey('FULL_NAME_01'),   Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(true,    results.containsKey('FULL_NAME_02'),   Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('ID_01', results.get('FULL_NAME_01'),           Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('ID_02', results.get('FULL_NAME_02'),           Constant.MSG_TEST_UNEXPECTED_VALUE);
        
    }


    @IsTest
    static void testGetKeyValueMapForElement(){
        
        // Assertion variables
        Map<String,String> results;

        // Setup test data
        String xml = '<data><result><fullName>FULL_NAME_01</fullName><id>ID_01</id></result><result><fullName>FULL_NAME_02</fullName><id>ID_02</id></result></data>';
        XmlStreamReader xsr = new XmlStreamReader(xml);

        // Execute tests
        Test.startTest();
        results = Util.getKeyValueMapForElement(xsr,'result','fullName','id');
        Test.stopTest();
    
        // Asserts
        Assert.areEqual(true,    results.containsKey('FULL_NAME_01'),   Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual(true,    results.containsKey('FULL_NAME_02'),   Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('ID_01', results.get('FULL_NAME_01'),           Constant.MSG_TEST_UNEXPECTED_VALUE);
        Assert.areEqual('ID_02', results.get('FULL_NAME_02'),           Constant.MSG_TEST_UNEXPECTED_VALUE);
    }
}