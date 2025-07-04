/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        November 2024
 * @description An example of using the metadata API WSDL methods to create a 
 *              SAML configuration so that external apps can connect automatically.
 * 
 * @note        !! ONLY USE IN SANDBOXES AND NEVER USE THIS IN PRODUCTION OR FULL SANDBOX !!
 *              !! SPEAK WITH YOUR SECURITY EXPERTS ON HOW TO SECURELY IMPLEMENT !!
 * 
 * @note        Run the creation of the named credential first using the 
 *              create_connection_to_home_org.apex file in the example folder.
 *              and keep the app settings the same. Or remove the name credentiol name
 * 
 * @Steps       01 - Create a Signing Certificate
 *              02 - Read the Signing Certificate Id so it can be used in the SAML configuration
 *              03 - Create a SAML SSO Configuration
 *              04 - Read SAML configuration to extract the login url and the oauth endpoint url
 *              05 - Send and email to the admin with the details of the new configuration
 */
// App settings
String appName  = 'Home_Org';
String appLabel = 'Home Org';

// Only use on scratch orgs that have a namespace attached to it
// Make sure to add the underscores at the end like "ns__" or the permission set update will fail
// Make it an empty string like '' if you do not use a namespace
String appNamespace = 'soap__';

// Email recipient who get's the details of what has been created
String emailRecipient = 'jfwberg+soap-demo@gmail.com';

// The Id for the signing the certificate. If you know the certificate Id
// you can pre-populate the certificate Id and no certificate is created
String requestSigningCertId;

// For SAML it makes most sense to use an existing certificate that is hosted in the 
// Identity provider (IDP). So in this case we populate the external IDP certificate
String validationCertContent = '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';

// Setup the issues and entity Id (these need to be unique for the org)
String issuer       = URL.getOrgDomainUrl().toExternalForm();
String samlEntityId = URL.getOrgDomainUrl().toExternalForm();

// Auto generated by Salesforce on creation
String salesforceLoginUrl;
String oauthTokenEndpoint;

/**
 * 01- CREATE THE CERTIFICATE TO BE USED BY THE CONNECTED APP
 */
try{   
    soap.Wsdl createCertificateAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'Certificate',
            new Map<String,Object>{
                'fullName'		       => appName,
                'caSigned'             => false,
                'expirationDate'       => Datetime.now().addYears(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'').toString(),
                'keySize'              => 4096,
                'privateKeyExportable' => true,
                'masterLabel'          => appLabel
            }
        )
        .setDefaultNamespace('soap')
        .call()
        .handleErrors()
    ;

    System.debug(createCertificateAction.getResponse()?.getBody());
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 02 - READ THE CERTIFICATE METADATA TO GET THE CERTIFICATE ID
 */
HttpRequest req = new HttpRequest();
    
// Query the certificate Id using the newly created named credential and the tooling API
req.setEndpoint('callout:'+appNamespace+appName+'/services/data/v64.0/tooling/query?q=SELECT+Id+FROM+Certificate+WHERE+DeveloperName=\''+appName+'\'+LIMIT+1');
req.setMethod('GET');

// Parse the records result and fetch the records
Object[] records = (Object[])((Map<String,Object>)JSON.deserializeUntyped(new Http().send(req).getBody())).get('records');

// Check if there is a record and assign the correct Id
if(records.size() ==1){
    requestSigningCertId = ((Map<String,Object>)records[0]).get('Id')?.toString().substring(0,15);
}
   

/**
 * 03 - CREATE SAML SSO CONFIGURATION
 */
try{
    soap.Wsdl createSamlAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'SamlSsoConfig',
            new Map<String,Object>{
                'fullName'		                => appName,
                'name'                          => appLabel,
                'identityLocation'              => 'SubjectNameId',
                'identityMapping'               => 'Username',
                'issuer'                        => issuer,
                'redirectBinding'               => false,
                'requestSignatureMethod'        => 1,
                'requestSigningCertId'          => requestSigningCertId,
                'samlEntityId'                  => samlEntityId,
                'samlVersion'                   => 'SAML2_0',
                'useConfigRequestMethod'        => true,
                'useSameDigestAlgoForSigning'   => true,
                'useSameDigestAlgoForSigning'   => false,
                'validationCert'                => validationCertContent
            }
        )
        .setDefaultNamespace('soap')
        .call()
        .handleErrors()
    ;

    System.debug(createSamlAction.getResponse()?.getBody());
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 04 - READ SAML SSO CONFIGURATION TO FETCH URLS
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('SamlSsoConfig')
        .addItemMetadataFullName(appName)
        .setDefaultNamespace('soap')
        .getXsr()
    ;

    Map<String,String> values = soap.Util.readMultipleValues(
        xsr,
        new Set<String>{
            'salesforceLoginUrl',
            'oauthTokenEndpoint'
        }
    );

    salesforceLoginUrl = values.get('salesforceLoginUrl');
    oauthTokenEndpoint = values.get('oauthTokenEndpoint');
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 05 - SEND AND EMAIL TO THE ADMIN TO NOTIFY  A NEW ORG IS READY FOR CONNECTION
 */
Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
message.setSaveAsActivity(false);
message.toAddresses   = new String[] { emailRecipient };
message.subject       = 'New Org Connected using SAML 2.0 - ' + appLabel;

// Create email body
message.plainTextBody = 'Entity Id: '                + samlEntityId       + '\n';
message.plainTextBody+= 'Issuer: '                   + issuer             + '\n';
message.plainTextBody+= 'login URL: '                + salesforceLoginUrl + '\n';
message.plainTextBody+= 'OAuth Token Endpoint URL: ' + oauthTokenEndpoint + '\n';
message.plainTextBody+= 'User name: '                + UserInfo.getUserName();

// Send the messages
Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});