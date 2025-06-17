/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Wsdl class
 */
@Istest
private with sharing class WsdlTest {
    
    @IsTest
    static void testHandleErrorsNoErrors() {
        
        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(200);
        res.setBody('<all>Good</all>');

        // Start the test
        Test.startTest();
         
        // Create the soapActionResult
        Wsdl soapActionResult = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
            .call()
        ;

        // Validate that the returned soapActionResult is the same as the input Wsdl
        Wsdl errorHandlerResponseWsdl = soapActionResult.handleErrors();

        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            soapActionResult,
            errorHandlerResponseWsdl,
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }
    

    @IsTest
    static void testHandleErrorsCodeCoverage() {
        
        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status to 999 specifically to hit code coverage and validate all other
        // statements are ignored
        res.setStatusCode(999);
        res.setBody('<all>Good</all>');

        // Start the test
        Test.startTest();
         
        // Create the soapActionResult
        Wsdl soapActionResult = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
            .call()
        ;

        // Validate that the returned soapActionResult is the same as the input Wsdl
        Wsdl errorHandlerResponseWsdl = soapActionResult.handleErrors();

        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            soapActionResult,
            errorHandlerResponseWsdl,
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }  


    @IsTest
    static void testHandleErrorsEmptyResponseBody() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status to 999 specifically to hit code coverage and validate evrything is ignored
        res.setStatusCode(19);
        
        // Start the test
        Test.startTest();         
        try{
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;

            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            Wsdl.MSG_HTTP_CALLOUT_ISSUE,
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }  


    @IsTest
    static void testHandleErrorsInvalidResponseCode() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(401);
        res.setBody('Unexpected response code body content');

        // Start the test
        Test.startTest();
        try{
            
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format(Wsdl.MSG_UNKNOWN_HTTP_STATUS_CODE,new String[]{'401','Unexpected response code body content'}),
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }   


    @IsTest
    static void testHandleErrorsInvalidXml() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('Invalid XML Body');

        // Start the test
        Test.startTest();
        try{
            
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.isTrue(
            exceptionToAssert.getMessage().startsWith(Wsdl.MSG_INVALID_XML_RESPONSE.substringBefore('{0}')),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }   


    @IsTest
    static void testHandleErrorsUnknownErrorResponse(){
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('<error>Unknown Error</error>');

        // Start the test
        Test.startTest();
        try{
            
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format(Wsdl.MSG_UNKNOWN_ERROR_RESPONSE,new String[]{'<error>Unknown Error</error>'}),
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }   


    @IsTest
    static void testHandleErrorsExpectedErrorResponse(){
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sf="urn:fault.partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><soapenv:Fault><faultcode>sf:INVALID_LOGIN</faultcode><faultstring>INVALID_LOGIN: Invalid username, password, security token; or user locked out.</faultstring><detail><sf:LoginFault xsi:type="sf:LoginFault"><sf:exceptionCode>INVALID_LOGIN</sf:exceptionCode><sf:exceptionMessage>Invalid username, password, security token; or user locked out.</sf:exceptionMessage></sf:LoginFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>');

        // Start the test
        Test.startTest();
        try{
            
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format('{0} :: {1}',new String[]{'INVALID_LOGIN','INVALID_LOGIN: Invalid username, password, security token; or user locked out.'}),
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }


    @IsTest
    static void testGetXsr(){
        
        // Variables to assert
        String faultToAssert;

        // The response body
        String responseBody = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sf="urn:fault.partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><soapenv:Fault><faultcode>sf:INVALID_LOGIN</faultcode><faultstring>INVALID_LOGIN: Invalid username, password, security token; or user locked out.</faultstring><detail><sf:LoginFault xsi:type="sf:LoginFault"><sf:exceptionCode>INVALID_LOGIN</sf:exceptionCode><sf:exceptionMessage>Invalid username, password, security token; or user locked out.</sf:exceptionMessage></sf:LoginFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>';

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody(responseBody);
        
        // Start the test
        Test.startTest();

        // Read metadata example: get the data for the User Object
        Wsdl soapActionResult = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObject')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
            .setTimeout(100000)
        ;

        // Execute through reader
        XmlStreamReader xsr = soapActionResult.getXsr(); 

        // Stream throught the XML Elements and handle accordingly
        while(xsr.hasNext()){
            if(xsr.getEventType()==XmlTag.START_ELEMENT){
                if(xsr.getLocalName() == 'faultstring'){
                    xsr.next();
                    faultToAssert = xsr.getText();
                    break;
                }
            }
            xsr.next();
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            'INVALID_LOGIN: Invalid username, password, security token; or user locked out.',
            faultToAssert,
            'Unexpected XML Element value'
        );

        // Check the execution time is set for the getXsr()
        Assert.isTrue(
            soapActionResult.getExecutionTime() > -1,
            'Unexpected execution time'
        );

        // There should be no response body stored for this method
        Assert.areEqual(
            null,
            soapActionResult.getResponse(),
            'Unexpected response Body'
        );
    }


    @IsTest
    static void testMockResponses(){

        // Add response
        Wsdl.addNamedMockResponse(
            'TEST_MOCK_ID',
            200,
            'TEST_MOCK_DATA'
        );

        // Create the soapActionResult
        Wsdl soapActionResult = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponseIdentifier('TEST_MOCK_ID')
            .call()
            .handleErrors()
        ;

        // Validate response
        Assert.areEqual(200,              soapActionResult.getResponse().getStatusCode(), 'Invalid status code'  );
        Assert.areEqual('TEST_MOCK_DATA', soapActionResult.getResponse().getBody(),       'Invalid response body');
    }


    @IsTest
    static void testMockResponseWithInvalidMockId(){
        
        // Assertion variables
        Wsdl.SoapUtilException exceptionToAssert;

        // Start the test
        Test.startTest();
        try{
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponseIdentifier('TEST_MOCK_ID')
                .call()
                .handleErrors()
            ;

            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapUtilException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Assert
        Assert.areEqual(
            String.format(
                Wsdl.MSG_INVALID_MOCK_RESPONSE_ID,
                new String[]{'TEST_MOCK_ID'}
            ),
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }


    @IsTest
    static void testXsrMockResponse(){

        // Add response
        Wsdl.addNamedMockResponse(
            'TEST_MOCK_ID',
            200,
            '<data>TEST_MOCK_DATA</data>'
        );

        // Create the soapActionResult
        XmlStreamReader xsr = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponseIdentifier('TEST_MOCK_ID')
            .getXsr()
        ;

        // Skip to the data contents
        xsr.next(); // <data>
        xsr.next(); // TEST_MOCK_DATA

        // Validate response
        Assert.areEqual('TEST_MOCK_DATA', xsr.getText(), 'Invalid response body');
    }


    @IsTest
    static void testXsrMockResponseWithInvalidMockId(){
        
        // Assertion variables
        Wsdl.SoapUtilException exceptionToAssert;

        // Start the test
        Test.startTest();
        try{
            // Create the soapActionResult
            new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponseIdentifier('TEST_MOCK_ID')
                .getXsr()
            ;

            // Safeguard
            throw new StringException(Wsdl.MSG_TEST_EXCEPTION_SAFEGUARD);

        }catch(Wsdl.SoapUtilException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Assert
        Assert.areEqual(
            String.format(
                Wsdl.MSG_INVALID_MOCK_RESPONSE_ID,
                new String[]{'TEST_MOCK_ID'}
            ),
            exceptionToAssert.getMessage(),
            Wsdl.MSG_TEST_UNEXPECTED_EXCEPTION
        );
    }
}