/**
 * !! WARNING This does expose the session Id so use with care !!
 */
// Read metadata
soap.Wsdl rdAction = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('CustomObject')
    .addItemMetadataFullName('User')
    .addItemMetadataFullName('Account')
    .setupRequest() 
;

System.debug(':: ENDPOINT ::');
System.debug('\n\n' + rdAction.getRequest().getEndpoint() + '\n\n');

System.debug(':: REQUEST BODY ::');
System.debug('\n\n' + rdAction.getRequest().getBody()+ '\n\n');