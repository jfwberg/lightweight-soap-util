/**
 * @description Default error handling that throws a soap.Wsdl.SoapApiException 
 *              if something goes wrong
 */
 try{
    
    // Read metadata example: get the data for the User Object
    soap.Wsdl rdAction = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('CustomObject')
        .addItemMetadataFullName('User')
        .call()
        .handleErrors()
    ;

    // Output the XML body and handle the way you want to
    System.debug(rdAction.getResponse().getBody());

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * @description Memory efficient way to directly return an XmlStreamReader class
 *              If something goes wrong you have to manage the error handling yourself
 *              Use this in case of massive XML responses
 */
try{
    // Read metadata example: get the data for the User Object
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('CustomObject')
        .addItemMetadataFullName('User')
        .getXsr()
    ;

    // Stream throught the XML Elements and handle accordingly
    while(xsr.hasNext()){
        if(xsr.getEventType()==XmlTag.START_ELEMENT){

            // Basic error handling incase there is a soap error
            if(xsr.getLocalName() == 'faultstring'){
                xsr.next();
                System.debug(xsr.getText());
                break;
            }

            // Output the name of the metadata
            if(xsr.getLocalName() == 'fullName'){
                xsr.next();
                System.debug(xsr.getText());
                break;
            }
        }
        xsr.next();
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}