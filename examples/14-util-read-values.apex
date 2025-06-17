/**
 * READ SINGLE VALUE
 */
XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('ConnectedApp')
    .addItemMetadataFullName(soap.Util.getNamespacedMetadataName('Agent_Api_v1'))
    .getXsr()
;

String connectedAppId = soap.Util.readSingleValue(xsr, 'consumerKey');
System.debug(connectedAppId);


/**
 * READ SINGLE VALUE ON A LIST
 */
XmlStreamReader xsr2 = new soap.MdtWsdl('listMetadata')
    .addListMetadata('CustomObject')
    .getXsr()
;

String[] sObjectList = soap.Util.readSingleValueOnList(xsr2,'result','fullName');
sObjectList.sort();
System.debug(sObjectList);


/**
 * READ MULTIPLE VALUES
 */
XmlStreamReader xsr3 = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('SamlSsoConfig')
    .addItemMetadataFullName(soap.Util.getNamespacedMetadataName('Home_Org'))
    .getXsr()
;

Map<String,String> values = soap.Util.readMultipleValues(
    xsr3,
    new Set<String>{
        'salesforceLoginUrl',
        'oauthTokenEndpoint'
    }
);

String salesforceLoginUrl = values.get('salesforceLoginUrl');
String oauthTokenEndpoint = values.get('oauthTokenEndpoint');

System.debug(salesforceLoginUrl);
System.debug(oauthTokenEndpoint);


/**
 * READ MULTIPLE VALUES ON A LIST
 */
XmlStreamReader xsr4 = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('Profile')
    .addItemMetadataFullName('Admin')
    .getXsr()
;

List<Map<String,String>> listOfValues = soap.Util.readMultipleValuesOnList(
    xsr4,
    'loginIpRanges',
    new Set<String>{
        'startAddress',
        'endAddress',
        'description'
    }
);

System.debug(JSON.serializePretty(listOfValues));