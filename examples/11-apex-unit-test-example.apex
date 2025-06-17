public class MetadataHandler{

    public static String getConnectedAppCertificate(String fullName){
        
        // Set the mock response identifier in your main logic 
        soap.Wsdl soapResult = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ConnectedApp')
            .addItemMetadataFullName(fullName)
            .setMockResponseIdentifier('CONNECTED_APP_RESPONSE')
            .call()
            .handleErrors()
        ;

        return soap.Util.readSingleValue(
            soapResult.getResponse().getXmlStreamReader(),
            'certificate'
        );
    }
}


@IsTest
private class MetadataHandlerTest{

    @IsTest
    static void testCreateConnectedAppMetadata(){
    
        // Configure the response identifier with a mock response
        // in the test method where you need it
        soap.Wsdl.addNamedMockResponse(
            'CONNECTED_APP_RESPONSE',
            200,
            '<certificate>CERT_DATA</certificate>'
        );

        // Execute the method we want to test
        String certificate = MetadataHandler.getConnectedAppCertificate('soap__My_Connected_App');

        // Validate the data is the same
        Assert.areEqual('CERT_DATA', certificate);
    }
}










public class MetadataHandler{

    public static String getConnectedAppCertificate(String fullName){
        
        // Response for the test !! Should not really be in main code !!
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('<certificate>CERT_DATA</certificate>');
        
        // Set the mock response identifier in your main logic 
        soap.Wsdl soapResult = new soap.MdtWsdl('readMetadata')
            .setItemMetadataType('ConnectedApp')
            .addItemMetadataFullName(fullName)
            .setMockResponse(mockResponse)
            .call()
            .handleErrors()
        ;

        return soap.Util.readSingleValue(
            soapResult.getResponse().getXmlStreamReader(),
            'certificate'
        );
    }
}

@IsTest
private class MetadataHandlerTest{

    @IsTest
    static void testCreateConnectedAppMetadata(){
    
        // Execute the method we want to test
        String certificate = MetadataHandler.getConnectedAppCertificate('soap__My_Connected_App');

        // Validate the data is the same
        Assert.areEqual('CERT_DATA', certificate);
    }
}