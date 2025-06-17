/**
 * @description Example on how to create a key/value pair for a list of child elements
 *              In this example all external credential parameters for an external credential
 *              are listed and in a second example all metadata names with their created date
 */
XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('ExternalCredential')
    .addItemMetadataFullName(soap.Util.getNamespacedMetadataName('Agent_Api_v1'))
    .getXsr()
;

Map<String,String> keyValueMap = soap.Util.getKeyValueMapForElement(
    xsr,
    'externalCredentialParameters',
    'parameterName',
    'parameterValue'
);
System.debug(JSON.serializePretty(keyValueMap));



XmlStreamReader xsr2 = new soap.MdtWsdl('listMetadata')
    .addListMetadata('CustomObject')
    .getXsr()
;

Map<String,String> keyValueMap2 = soap.Util.getKeyValueMapForElement(
    xsr2,
    'result',
    'fullName',
    'lastModifiedDate'
);

System.debug(JSON.serializePretty(keyValueMap2));