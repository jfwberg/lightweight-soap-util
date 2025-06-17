/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        March 2025
 * @description An example of using the metadata API WSDL methods to create a 
 *              connected app that can be used with the Agent(force) API
 *              and a Named and External Credential to connect from Apex
 * 
 * @note        !! ONLY USE IN SANDBOXES AND NEVER USE THIS IN PRODUCTION OR FULL SANDBOX !!
 *              !! SPEAK WITH YOUR SECURITY EXPERTS ON HOW TO SECURELY IMPLEMENT !!
 * 
 * @steps       00 - Uncomment steps below and run 1 by 1, make sure each step completes successfully (see debug logs)
 *              01 - Set the app name and label
 *              02 - Run the method "setupConnectedApp();"
 *              03 - Run the method "getConnectedAppEditPolicyPageUrl()";
 *              04 - !! MANUAL STEP !! Open the LINK generated in step 03, this opens the edit policy page
 *                   At the bottom of the edit page click the checkbox in front of "Issue JSON Web Token (JWT)-based access tokens" 
 *                   Press Save
 *              05 - Execute "setupNamedCredential()";
 *              06 - Run test (check the bearer token is a JWT and not just a session Id)
 *              07 - !! MANUAL STEP !! Update your agent with the connected app and you're ready to go
 * 
 * @test        See test script here that can be run from anonymous apex
 *              https://gist.github.com/jfwberg/ca20279173a026b1f269d0a502bb7c4d
 */
/* STEP 01 */
String appName      = 'Agent_Api_v1';
String appLabel     = 'Agent Api v1';

/* STEP 02 */
// setupConnectedApp();

/* STEP 03 */
// System.debug(getConnectedAppEditPolicyPageUrl(appName, appLabel));

/* STEP 05 */
// setupNamedCredential();

/* STEP 06 */
// testJwtAsBearer();

/** *********************************************************************** **
 *                              SETUP METHODS
 ** *********************************************************************** **/
void setupConnectedApp(){
    upsertCertificate(appName, appLabel);
    upsertPermissionSet(appName, appLabel);
    upsertRemoteSiteSetting(appName, appLabel);
    upsertConnectedApp(appName, appLabel);
}


void setupNamedCredential(){
    upsertExternalCredential(appName,appLabel);
    upsertNamedCredential(appName,appLabel);
    updatePermissionSet(appName,appLabel);
    assignPermissionSet(appName);
}


void testJwtAsBearer(){
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:'+  appName +'_debug/api/echo');
    req.setMethod('GET');
    HttpResponse res = new Http().send(req);

    System.debug(req);
    System.debug(res);
    System.debug(res.getBody());
}


/** *********************************************************************** **
 *                              METADATA METHODS
 ** *********************************************************************** **/
void upsertCertificate(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'Certificate',
                new Map<String,Object>{
                    'fullName'             => appName,
                    'caSigned'             => false,
                    'expirationDate'       => Datetime.now().addYears(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'').toString(),
                    'keySize'              => 4096,
                    'privateKeyExportable' => true,
                    'masterLabel'          => appLabel
                }
            )
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted Certificate');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void upsertPermissionSet(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'      => appName,
                    'label'         => appLabel,
                    'description'   => 'Provides access to the ' + appLabel + ' Connected App'
                }
            )
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted Permission Set');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void upsertRemoteSiteSetting(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'                  => appName  + '_api',
                    'description'               => appLabel + ' - Api',
                    'disableProtocolSecurity'   => false,
                    'isActive'                  => true,
                    'url'                       => 'https://api.salesforce.com'
                }
            )
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'                  => appName  + '_home_org',
                    'description'               => appLabel + ' - Home Org',
                    'disableProtocolSecurity'   => false,
                    'isActive'                  => true,
                    'url'                       => Url.getOrgDomainUrl().toExternalForm()
                }
            )
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'                  => appName  + '_debug',
                    'description'               => appLabel + ' - Debug',
                    'disableProtocolSecurity'   => false,
                    'isActive'                  => true,
                    'url'                       => 'https://prod.pineapple.tools'
                }
            )
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted Remote Site Setting');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void upsertConnectedApp(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'ConnectedApp',
                new Map<String,Object> {
                    'fullName'     => appName,
                    'label'        => appLabel,
                    'description'  => 'A connected App to the '+ appLabel +' in order to use of API that are used by Lightning (Web) components',
                    'contactEmail' => UserInfo.getUserEmail(),
                    'oauthConfig'  => new Map<String,Object> {
                        'callbackUrl'                       => Url.getOrgDomainUrl().toExternalForm() + '/services/oauth2/callback',
                        'certificate'                       => getCertificateContent(appName),
                        'isAdminApproved'                   => true,
                        'isClientCredentialEnabled'         => false,
                        'isCodeCredentialEnabled'           => false,
                        'isConsumerSecretOptional'          => true,
                        'isIntrospectAllTokens'             => false,
                        'isNamedUserJwtEnabled'             => true,
                        'isPkceRequired'                    => false,
                        'isRefreshTokenRotationEnabled'     => false,
                        'isSecretRequiredForRefreshToken'   => false,
                        'isSecretRequiredForTokenExchange'  => false,
                        'isTokenExchangeEnabled'            => false,
                        'scopes' => new Object[]{
                            'Api',
                            'Web',
                            'RefreshToken', 
                            'Chatbot',
                            'SFAP'
                        }
                    },
                    'oauthPolicy' => new Map<String,Object>{
                        'ipRelaxation'       => 'ENFORCE',
                        'refreshTokenPolicy' => 'infinite'
                    },
                    'profileName' => new Object[]{
                        'System Administrator'
                    },
                    'permissionSetName' => new Object[]{
                        appLabel
                    }  
                }
            )
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted Connected App');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void upsertExternalCredential(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'ExternalCredential',
                new Map<String,Object>{
                    'fullName'               => appName,
                    'label'                  => appLabel,
                    'authenticationProtocol' => 'Oauth',
                    'externalCredentialParameters' => new Object[]{
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'Oauth',
                            'parameterType'   => 'AuthProtocolVariant',
                            'parameterValue'  => 'JwtBearer'
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'AuthProviderUrl',
                            'parameterType'   => 'AuthProviderUrl',
                            'parameterValue'  => Url.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token'
                        },
                        new Map<String,Object>{
                            'certificate'     => appName,
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'SigningCertificate',
                            'parameterType'   => 'SigningCertificate'
                        },
                        new Map<String,Object>{
                            'description'     => 'Audience',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'aud',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => ([SELECT IsSandbox FROM Organization LIMIT 1]?.IsSandbox) ? '"https://test.salesforce.com"' : '"https://login.salesforce.com"'
                        },
                        new Map<String,Object>{
                            'description'     => 'Subject',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'sub',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => UserInfo.getUserName()
                        },
                        new Map<String,Object>{
                            'description'     => 'Issuer',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iss',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => getConnectedAppId(appName)
                        },
                        new Map<String,Object>{
                            'description'     => 'Expiration Time',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'exp',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400 + 300))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Algorithm',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'alg',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'RS256'
                        },
                        new Map<String,Object>{
                            'description'     => 'Type',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'typ',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => 'JWT'
                        },
                        new Map<String,Object>{
                            'description'     => 'Issued At',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'iat',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Not Before',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'nbf',
                            'parameterType'   => 'JwtBodyClaim',
                            'parameterValue'  => '{!Text(FLOOR((NOW() - DATETIMEVALUE("1970-01-01 00:00:00")) * 86400))}'
                        },
                        new Map<String,Object>{
                            'description'     => 'Key ID',
                            'parameterGroup'  => 'DefaultGroup',
                            'parameterName'   => 'kid',
                            'parameterType'   => 'JwtHeaderClaim',
                            'parameterValue'  => appName
                        },
                        new Map<String,Object>{
                            'parameterGroup'  => 'NAMED_PRINCIPAL',
                            'parameterName'   => 'NAMED_PRINCIPAL',
                            'parameterType'   => 'NamedPrincipal',
                            'sequenceNumber'  => 1
                        }
                    }
                }
            )
            .call()
            .handleErrors()
        ;

        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted External Credential');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void upsertNamedCredential(String appName, String appLabel){
    try{
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'NamedCredential',
                new Map<String,Object>{
                    'fullName'                    => appName  + '_api',
                    'label'                       => appLabel + ' - Api',
                    'allowMergeFieldsInBody'      => true,
                    'allowMergeFieldsInHeader'    => true,
                    'calloutStatus'               => 'Enabled',
                    'generateAuthorizationHeader' => true,
                    'namedCredentialType'         => 'SecuredEndpoint',
                    'namedCredentialParameters'   => new Object[]{
                        new Map<String,Object>{
                            'parameterName'     => 'Url',
                            'parameterType'     => 'Url',
                            'parameterValue'    => 'https://api.salesforce.com'
                        },
                        new Map<String,Object>{
                            'externalCredential'=> appName,
                            'parameterName'     => 'ExternalCredential',
                            'parameterType'     => 'Authentication'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('utl' ))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'utl'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('soap'))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'soap'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('agentforce1'))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'agentforce1'
                        },
                        new Map<String,Object>{
                            'sequenceNumber'  => 1,
                            'parameterName'   => 'x-lightweight-soap-id',
                            'parameterType'   => 'HttpHeader',
                            'parameterValue'  => 'lwt-soap-0-2-1'
                        }
                    }
                }
            )
            .addCredMetadata(
                'NamedCredential',
                new Map<String,Object>{
                    'fullName'                    => appName + '_home_org',
                    'label'                       => appLabel + ' - Home Org',
                    'allowMergeFieldsInBody'      => true,
                    'allowMergeFieldsInHeader'    => true,
                    'calloutStatus'               => 'Enabled',
                    'generateAuthorizationHeader' => true,
                    'namedCredentialType'         => 'SecuredEndpoint',
                    'namedCredentialParameters'   => new Object[]{
                        new Map<String,Object>{
                            'parameterName'     => 'Url',
                            'parameterType'     => 'Url',
                            'parameterValue'    => Url.getOrgDomainUrl().toExternalForm()
                        },
                        new Map<String,Object>{
                            'externalCredential'=> appName,
                            'parameterName'     => 'ExternalCredential',
                            'parameterType'     => 'Authentication'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('utl' ))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'utl'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('soap'))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'soap'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('agentforce1'))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'agentforce1'
                        },
                        new Map<String,Object>{
                            'sequenceNumber'  => 1,
                            'parameterName'   => 'x-lightweight-soap-id',
                            'parameterType'   => 'HttpHeader',
                            'parameterValue'  => 'lwt-soap-0-2-1'
                        }
                    }
                }
            )
            .addCredMetadata(
                'NamedCredential',
                new Map<String,Object>{
                    'fullName'                    => appName + '_debug',
                    'label'                       => appLabel + ' - Debug',
                    'allowMergeFieldsInBody'      => true,
                    'allowMergeFieldsInHeader'    => true,
                    'calloutStatus'               => 'Enabled',
                    'generateAuthorizationHeader' => true,
                    'namedCredentialType'         => 'SecuredEndpoint',
                    'namedCredentialParameters'   => new Object[]{
                        new Map<String,Object>{
                            'parameterName'     => 'Url',
                            'parameterType'     => 'Url',
                            'parameterValue'    => 'https://prod.pineapple.tools'
                        },
                        new Map<String,Object>{
                            'externalCredential'=> appName,
                            'parameterName'     => 'ExternalCredential',
                            'parameterType'     => 'Authentication'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('utl' ))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'utl'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('lwt' ))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'lwt'
                        },
                        new Map<String,Object>{
                            'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('agentforce1'))).substring(0,14),
                            'parameterType'   => 'AllowedManagedPackageNamespaces',
                            'parameterValue'  => 'agentforce1'
                        },
                        new Map<String,Object>{
                            'sequenceNumber'  => 1,
                            'parameterName'   => 'x-lightweight-soap-id',
                            'parameterType'   => 'HttpHeader',
                            'parameterValue'  => 'lwt-soap-0-2-1'
                        }
                    }
                }
            )
            .call()
            .handleErrors()
        ;
    
        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully upserted Named Credential');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void updatePermissionSet(String appName, String appLabel){
    try{
        // Permisison sets are a bit funky with namespaces
        String namespacedFullname = getMetadataNamespacedFullname(appName);
        
        // Execute the soap action
        soap.Wsdl soapAction = new soap.MdtWsdl('upsertMetadata')
            .addCredMetadata(
                'PermissionSet',
                new Map<String,Object>{
                    'fullName'                              => appName,
                    'label'                                 => appLabel,
                    'description'                           => 'Provides access to the ' + appLabel + ' Connected App',
                    'externalCredentialPrincipalAccesses'   => new Object[]{
                        new Map<String,Object>{
                            'enabled'                       => true,
                            'externalCredentialPrincipal'   => namespacedFullname + '-NAMED_PRINCIPAL'
                        }
                    }
                }
            )
            .call()
            .handleErrors()
        ;
        
        // Handle metadata API response
        CrudResult result = handleCrudResponse(soapAction.getResponse().getXmlStreamReader())[0];

        System.debug(result);
        System.debug('Successfully updated Permission Set');

    }catch(Exception e){
        System.debug(e.getMessage());
    }
}


void assignPermissionSet(String appName){
    
    // Query the permission set
    String permSetId = [SELECT Id FROM PermissionSet WHERE Name = :appName LIMIT 1].Id;

    // Assign the permission set if it is not already assigned
    if([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :permSetId AND AssigneeId = :UserInfo.getUserId() LIMIT 1]?.Id == null){
        insert as system new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = permSetId
        );
    }
}


String getCertificateContent(String fullName){

    soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('Certificate')
        .addItemMetadataFullName(fullName)
        .call()
        .handleErrors()
    ;

    return readSingleValue(
        soapAction.getResponse().getXmlStreamReader(),
        'content'
    );
}


String getConnectedAppId(String fullName){

    soap.Wsdl soapAction = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('ConnectedApp')
        .addItemMetadataFullName(getMetadataNamespacedFullname(fullName))
        .call()
        .handleErrors()
    ;
    
    return readSingleValue(
        soapAction.getResponse().getXmlStreamReader(),
        'consumerKey'
    );
}


String getMetadataNamespacedFullname(String fullName){
    String namespace = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;
    return (String.isBlank(namespace) ? '' : namespace + '__') + fullName;
}


String getConnectedAppEditPolicyPageUrl(String appName, String appLabel){
    String urlEncodedAddressParam = EncodingUtil.UrlEncode(
        String.format(
            '/_ui/core/application/force/connectedapp/ForceConnectedApplicationPage/e?connectedAppId={0}&retURL={1}',
            new String[]{
                [SELECT Id FROM ConnectedApplication WHERE Name = :appLabel LIMIT 1]?.Id,
                EncodingUtil.UrlEncode('/lightning/setup/SetupOneHome/home','UTF-8')
            }
        ),
        'UTF-8'
    );
    return String.join(
        new String[]{
            Url.getOrgDomainUrl().toExternalForm(),
            '/lightning/setup/NavigationMenus/page?address=',
            urlEncodedAddressParam
        },
        ''
    );
}


String readSingleValue(XmlStreamReader xsr, String tagName){
    while(xsr.hasNext()){
        if(xsr.getEventType()==XmlTag.START_ELEMENT){
            if(xsr.getLocalName() == tagName){
                xsr.next();
                if(xsr.getEventType() == XmlTag.CHARACTERS){
                    return xsr.getText();
                }
            }
        }
        xsr.next();
    }
    return null;
}


void handleErrors(XmlStreamReader xsr, CrudResult result){
    while(xsr.hasNext()){

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
        xsr.next();
    }
}


CrudResult[] handleCrudResponse(XmlStreamReader xsr){

    CrudResult[] results = new CrudResult[]{};

    CrudResult result;

    // Stream throught the XML Elements and handle accordingly
    while(xsr.hasNext()){
        if(xsr.getEventType()==XmlTag.START_ELEMENT){

            // Output the name of the metadata
            if(xsr.getLocalName() == 'result'){
                result = new CrudResult();
                xsr.next();
            }

            // Basic error handling incase there is a soap error
            if(xsr.getLocalName() == 'created'){
                xsr.next();
                result.created = xsr.getText()?.equals('true');
                xsr.next();
            }

            // Basic error handling incase there is a soap error
            if(xsr.getLocalName() == 'fullName'){
                xsr.next();
                result.fullName = xsr.getText();
                xsr.next();
            }

            // Basic error handling incase there is a soap error
            if(xsr.getLocalName() == 'success'){
                xsr.next();
                result.success = xsr.getText()?.equals('true');
                xsr.next();
            }

            if(xsr.getLocalName() == 'errors'){
                handleErrors(xsr, result);
            }
        }

        if(xsr.getEventType()==XmlTag.END_ELEMENT){
            if(xsr.getLocalName() == 'result'){
                results.add(result);
                result = null;
            }
        }
        xsr.next();
    }
    return results;
}


class CrudResult{
    public String errorMessage;
    public String fullname;
    public Boolean created;
    public Boolean success;
}