/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        June 2025
 * @description An example of using the metadata API WSDL methods to create a 
 *              connection to the current org for secure API access.
 * 
 * @note        !! ONLY USE IN SANDBOXES AND NEVER USE THIS IN PRODUCTION OR FULL SANDBOX 	!!
 *              !! SPEAK WITH YOUR SECURITY EXPERTS ON HOW TO SECURELY IMPLEMENT 			!!
 * 
 * @Steps       01 - Create a Certificate
 *              02 - Create a Permission Set
 *              03 - Create a Remote Site Setting to the Home Org
 *              04 - Read the Certificate content so it can be used in the External Client App
 *              05 - Create ExternalClientApplication metadata
 * 				06 - Create ExtlClntAppConfigurablePolicies metadata
 * 				07 - Create ExtlClntAppOauthSettings metadata
 * 				08 - Create ExtlClntAppGlobalOauthSettings metadata
 * 				09 - Create ExtlClntAppOauthConfigurablePolicies metadata
 *              10 - Read the connected app and extract the connected app Id
 *              11 - Create an external credential
 *              12 - Create a named credential
 *              13 - Update the permission set with external credential principal access
 *              14 - Assign the permission set to the running user
 *              15 - Email org details to a recipient (could be a web-service callout)
 * 
 * @note        Once the external client has been created and the permission set assigned
 *              you can also create a SAML SSO configuration to the home org using
 *              the newly used named credential see the create_saml_to_home_org.apex file in 
 *              the examples folder
 */
// App settings
String appName  = 'Home_Org';
String appLabel = 'Home Org';

// Email recipient who get's the details of what has been created
String emailRecipient = UserInfo.getUserEmail();

// Temporary variables
String certificateContent;
String connectedAppId;

/**
 * 01- CREATE THE CERTIFICATE TO BE USED BY THE CONNECTED APP
 */
try {
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
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
        .getXsr()
    ; 
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'Certificate')){
        System.debug(result);
    }
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 02 - CREATE THE PERMISSION SET FOR THE CONNECTED APP
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'PermissionSet',
            new Map<String,Object>{
                'fullName'      => appName,
                'label'         => appLabel,
                'description'   => 'Provides access to the ' + appLabel + ' External Client App and Named Credential'
            }
        )
        .getXsr()
    ;
	
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'PermissionSet')){
        System.debug(result);
    }
    
    
    //System.debug('Successfully upserted Permission Set');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 03 - CREATE THE REMOTE SITE SETTING
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'RemoteSiteSetting',
            new Map<String,Object>{
                'fullName'                  => appName  + '_My_Domain_Url',
                'description'               => appLabel + ' My Domain URL',
                'disableProtocolSecurity'   => false,
                'isActive'                  => true,
                'url'                       => Url.getOrgDomainUrl().toExternalForm()
            }
        )
        .getXsr()
    ;

	for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'RemoteSiteSetting')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 04 - READ THE CERTIFICATE METADATA TO GET THE CERTIFICATE DATA
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('Certificate')
        .addItemMetadataFullName(appName)
        .getXsr()
    ;
    
    certificateContent = soap.Util.readSingleValue(xsr, 'content');
    
    System.debug('Successfully read the Certificate content. Lenght: ' + certificateContent.length());
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 05 - CREATE EXTERNAL CLIENT APP
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExternalClientApplication',
            new Map<String,Object>{
                'fullName'              => appName,
                'label'                 => appLabel,
                'description'           => 'External Client Application that connects to the "Home" Org.',
                'contactEmail'          => UserInfo.getUserEmail(),
                'distributionState'     => 'Local',
                'orgScopedExternalApp'  => UserInfo.getOrganizationId() + ':' + appName
            }
        )    
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExternalClientApplication')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 06 - CREATE EXTL_CLNT_APP_CONFIGURABLE_POLICIES
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExtlClntAppConfigurablePolicies',
            new Map<String,Object>{
                'fullName'              	=> appName + '_plcy',
                'label'                 	=> appName + '_plcy',
                'externalClientApplication' => appName,
                'isEnabled'           		=> true,
                'isOauthPluginEnabled'      => true
            }
        )    
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExtlClntAppConfigurablePolicies')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 07 - CREATE EXTL_CLNT_APP_OAUTH_SETTINGS
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExtlClntAppOauthSettings',
            new Map<String,Object>{
                'fullName'                  => appName + '_oauth',
                'commaSeparatedOauthScopes' => 'Api, Web, Chatter, RefreshToken, SFApiPlatform, CDP',
                'externalClientApplication' => appName,
                'isFirstPartyAppEnabled'    => false,
                'label'                     => appName + '_oauth'
            }
        )
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExtlClntAppOauthSettings')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 08 - CREATE EXTL_CLNT_APP_GLOBAL_OAUTH_SETTINGS
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExtlClntAppGlobalOauthSettings',
            new Map<String,Object>{
                'fullName'                          => appName + '_glbloauth',
                'label'                             => appName + '_glbloauth',
                'callbackUrl'                       => Url.getOrgDomainUrl().toExternalForm() + '/services/oauth2/callback',
                'certificate'                       => certificateContent,
                'externalClientApplication'         => appName,
                'isClientCredentialsFlowEnabled'    => false,
                'isCodeCredFlowEnabled'             => false,
                'isCodeCredPostOnly'                => false,
                'isConsumerSecretOptional'          => false,
                'isDeviceFlowEnabled'               => false,
                'isIntrospectAllTokens'             => false,
                'isNamedUserJwtEnabled'             => false,
                'isPkceRequired'                    => true,
                'isRefreshTokenRotationEnabled'     => false,
                'isSecretRequiredForRefreshToken'   => true,
                'isSecretRequiredForTokenExchange'  => true,
                'isTokenExchangeEnabled'            => false,
                'shouldRotateConsumerKey'           => false,
                'shouldRotateConsumerSecret'        => false
            }
        )
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExtlClntAppGlobalOauthSettings')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 09 - CREATE EXTL_CLNT_APP_OAUTH_CONFIGURABLE_POLICIES
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
         .addCredMetadata(
            'ExtlClntAppOauthConfigurablePolicies',
            new Map<String,Object>{
                'fullName'                        	=> appName + '_oauthPlcy',
                'label'                         	=> appName + '_oauthPlcy',
                'externalClientApplication'        	=> appName,
                'commaSeparatedPermissionSet'    	=> appName,
                'ipRelaxationPolicyType'        	=> 'Enforce',
                'isClientCredentialsFlowEnabled'	=> false,
                'isGuestCodeCredFlowEnabled'    	=> false,
                'isTokenExchangeFlowEnabled'    	=> false,
                'permittedUsersPolicyType'        	=> 'AdminApprovedPreAuthorized',
                'refreshTokenPolicyType'        	=> 'SpecificLifetime',
                'refreshTokenValidityPeriod'    	=> '365',
                'refreshTokenValidityUnit'        	=> 'Days',
                'requiredSessionLevel'            	=> 'STANDARD'
            }
        )       
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExtlClntAppOauthConfigurablePolicies')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 10 - READ THE CONNECTED APP ID TO BE USED IN THE NAMED CREDENTIAL
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('ExtlClntAppGlobalOauthSettings')
        .addItemMetadataFullName(appName + '_glbloauth')
        .getXsr()
    ;

    connectedAppId = soap.Util.readSingleValue(xsr, 'consumerKey');
    
    System.debug('Successfully read the Connected App Id:' + connectedAppId);

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}

/**
 * 11 - CREATE EXTERNAL CREDENTIAL
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExternalCredential',
            new Map<String,Object>{
                'fullName'                 => appName,
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
                        'parameterValue'  => connectedAppId
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
                    },
                    new Map<String,Object>{
                        'parameterGroup'  => 'PER_USER_PRINCIPAL',
                        'parameterName'   => 'PER_USER_PRINCIPAL',
                        'parameterType'   => 'PerUserPrincipal',
                        'sequenceNumber'  => 2
                    }
                }
            }
        )
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'ExternalCredential')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}
   

/**
 * 12 - CREATE NAMED CREDENTIAL
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'NamedCredential',
            new Map<String,Object>{
                'fullName'                    => appName,
                'label'                       => appLabel,
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
                        'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('lwt' ))).substring(0,14),
                        'parameterType'   => 'AllowedManagedPackageNamespaces',
                        'parameterValue'  => 'lwt'
                    },
                    new Map<String,Object>{
                        'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('idp' ))).substring(0,14),
                        'parameterType'   => 'AllowedManagedPackageNamespaces',
                        'parameterValue'  => 'idp'
                    },
                    new Map<String,Object>{
                        'parameterName'   => 'AllowedNamespace_' +  EncodingUtil.convertToHex(Crypto.generateDigest('sha256',Blob.valueOf('soap'))).substring(0,14),
                        'parameterType'   => 'AllowedManagedPackageNamespaces',
                        'parameterValue'  => 'soap'
                    },
                    new Map<String,Object>{
                        'sequenceNumber'  => 1,
                        'parameterName'   => 'x-lightweight-id',
                        'parameterType'   => 'HttpHeader',
                        'parameterValue'  => 'lwt-soap-0-1-2'
                    }
                }
            }
        )
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'NamedCredential')){
        System.debug(result);
    }
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}
   

/**
 * 13 - UPDATE THE PERMISSION SET WITH EXTERNAL CREDENTIAL ACCESS
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'PermissionSet',
            new Map<String,Object>{
                'fullName'                              => appName,
                'label'                                 => appLabel,
                'description'                           => 'Provides access to the ' + appLabel + ' External Client App, Named Credential and External Credential',
                'externalCredentialPrincipalAccesses'   => new Object[]{
                    new Map<String,Object>{
                        'enabled'                       => true,
                        'externalCredentialPrincipal'   => appName + '-NAMED_PRINCIPAL'
                    },
                    new Map<String,Object>{
                        'enabled'                       => true,
                        'externalCredentialPrincipal'   => appName + '-PER_USER_PRINCIPAL'
                    }
                }
            }
        )
        .getXsr()
    ;
    
    for(soap.Util.MdtCrudResult result : soap.Util.handleMdtCrudResponse(xsr, 'PermissionSet')){
        System.debug(result);
    }

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 14 - ASSIGN PERMISSION SET
 */
String permSetId = [SELECT Id FROM PermissionSet WHERE Name = :appName LIMIT 1].Id;

// Assign the permission set if it is not already assigned
if([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :permSetId AND AssigneeId = :UserInfo.getUserId() LIMIT 1]?.Id == null){
    insert new PermissionSetAssignment(
        AssigneeId = UserInfo.getUserId(),
        PermissionSetId = permSetId
    );

    System.debug('Inserting new permission set assignment');
    
// We can only test a callout to our new endpoint connection if we have the permission set assigned
// So run the test afterwards, this should work instantly
}else{
    
    System.debug('Permission Set Already exists. Performing test callout:');

    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:' + appName + '/services/data');
    req.setMethod('GET');
    req.setHeader('X-PrettyPrint', '1');
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug(res.getBody());
}


/**
 * 15 - SEND AND EMAIL TO THE ADMIN TO NOTIFY  A NEW ORG IS READY FOR CONNECTION
 */
try{
    System.debug('Sending Email With External Client App Details...');

    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.setSaveAsActivity(false);
    message.toAddresses   = new String[] { emailRecipient };
    message.subject       = 'New Org Connected - ' + appLabel;

    // Create the email body
    message.plainTextBody = 'Org domain url: '   + URL.getOrgDomainUrl()  + '\n';
    message.plainTextBody+= 'Connected App Id: ' + connectedAppId         + '\n';
    message.plainTextBody+= 'User name: '        + UserInfo.getUserName();

    // Send the messages
    Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {message});

}catch(System.EmailException e){
    System.debug('Email error: ' + e.getMessage());
}