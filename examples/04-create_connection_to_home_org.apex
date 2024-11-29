/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        November 2024
 * @description An example of using the metadata API WSDL methods to create a 
 *              connection to the current org for secure API access.
 * 
 * @Steps       01 - Create a Certificate
 *              02 - Create a Permission Set
 *              03 - Create a Remote Site Setting to the Home Org
 *              04 - Read the Certificate content so it can be used in the connected app
 *              05 - Create a Connect App to the Home Org
 *              06 - Read the connected app and extract the connected app Id
 *              07 - Create an external credential
 *              08 - Create a named credential
 *              09 - Update the permission set with external credential principal access
 *              10 - Assign the permission set to the running user
 *              11 - Email org details to a recipient (could be a web-service callout)
 * 
 * @note        Once the connected app has been created and the permission set assigned
 *              you can also create a SAML SSO configuration to the home org using
 *              the newly used named credential see the create_saml_to_home_org.apex file in 
 *              the examples folder
 */
// App settings
String appName  = 'Home_Org';
String appLabel = 'Home Org';

// Only use on scratch orgs that have a namespace attached to it
// Make sure to NOT add the underscores at the end like "ns__" or the permission set update will fail
// Make it an empty string like '' if you do not use a namespace
String appNamespace = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;

// Email recipient who get's the details of what has been created
String emailRecipient = 'jfwberg+soap-demo@gmail.com';

// Certificate content from the new certificate we created
String certificateContent;

// The connected App Id for the newly connected app
String connectedAppId;

// Indicator if an error has occurred during the execution to prevent any further damage
Boolean hasError = false;

// Create a new map to hold the status of actions so things can be rolled back
Map<Integer,Boolean> orchestration = new Map<Integer,Boolean>();

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
                'expirationDate'       => String.valueOf(Datetime.now().addYears(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')),
                'keySize'              => 4096,
                'privateKeyExportable' => true,
                'masterLabel'          => appLabel
            }
        )
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createCertificateAction.getResponse()?.getBody());
    System.debug('Successfully upserted Certificate');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 02 - CREATE THE PERMISSION SET FOR THE CONNECTED APP
 */
try{
    soap.Wsdl createPermissionSetAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'PermissionSet',
            new Map<String,Object>{
                'fullName'      => appName,
                'label'         => appLabel,
                'description'   => 'Provides access to the ' + appLabel + ' Connected App'
            }
        )
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createPermissionSetAction.getResponse()?.getBody());
    System.debug('Successfully upserted Permission Set');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 03 - CREATE THE REMOTE SITE SETTING
 */
try{
    soap.Wsdl createRemoteSiteSettingAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'RemoteSiteSetting',
            new Map<String,Object>{
                'fullName'		            => appName  + '_My_Domain_Url',
                'description'               => appLabel + ' My Domain URL',
                'disableProtocolSecurity'   => false,
                'isActive'                  => true,
                'url'                       => Url.getOrgDomainUrl().toExternalForm()
            }
        )
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createRemoteSiteSettingAction.getResponse()?.getBody());
    System.debug('Successfully upserted Remote Site Setting');

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
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .getXsr()
    ;
    
    // Stream throught the XML Elements and handle accordingly
    while(xsr.hasNext()){
        if(xsr.getEventType()==XmlTag.START_ELEMENT){
            if(xsr.getLocalName() == 'content'){
                xsr.next();
                if(xsr.getEventType() == XmlTag.CHARACTERS){
                    certificateContent = xsr.getText();
                break;
                }
            }
        }
        xsr.next();
    }

    System.debug('Successfully read the Certificate content');
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 05 - CREATE A CONNECTED APP
 */
try{
    soap.Wsdl createConnectedApp = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ConnectedApp',
            new Map<String,Object> {
                'fullName'		=> appName,
                'label'			=> appLabel,
                'description'	=> 'A connected App to the '+ appLabel +' in order to use of API that are used by Lightning (Web) components',
                'contactEmail'	=> UserInfo.getUserEmail(),
                'oauthConfig'	=> new Map<String,Object> {
                    'callbackUrl'				=> Url.getOrgDomainUrl().toExternalForm() + '/services/oauth2/callback',
                    'certificate'				=> certificateContent,
                    'isAdminApproved'			=> true,
                    'isConsumerSecretOptional'	=> false,
                    'isIntrospectAllTokens'		=> false,
                    'scopes'					=> new Object[]{
                        'Api',
                        'Web',
                        'RefreshToken'
                    }
                },
                'oauthPolicy' => new Map<String,Object>{
                    'ipRelaxation'		=> 'ENFORCE',
                    'refreshTokenPolicy'=> 'infinite'
                },
                'profileName' => new Object[]{
                    'System Administrator'
                },
                'permissionSetName' => new Object[]{
                    appLabel
                },
                'ipRanges' => new Object[]{
                    new Map<String,Object>{
                        'start'			=>'10.0.0.0',
                        'end'			=>'10.255.255.255',
                        'description'  => 'Salesforce Internal IP Address range'
                    }
                },
                'attributes' => new Object[]{
                    new Map<String,Object>{
                        'key'		=>'validationKey',
                        'formula'	=>'\'EMTX1\''
                    },
                    new Map<String,Object>{
                        'key'		=>'verificationKey',
                        'formula'	=>'\'EMTX2\''
                    }
                }  
            }
        )
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createConnectedApp.getResponse()?.getBody());
    System.debug('Successfully upserted Connected App');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}
    

/**
 * 06 - READ THE CONNECTED APP ID TO BE USED IN THE NAMED CREDENTIAL
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('ConnectedApp')
        .addItemMetadataFullName(appName)
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .getXsr()
    ;
    
    // Stream throught the XML Elements and handle accordingly
    while(xsr.hasNext()){
        if(xsr.getEventType()==XmlTag.START_ELEMENT){
            if(xsr.getLocalName() == 'consumerKey'){
                xsr.next();
                if(xsr.getEventType() == XmlTag.CHARACTERS){
                    connectedAppId = xsr.getText();
                break;
                }
            }
        }
        xsr.next();
    }

    System.debug('Successfully read the Connected App Id:' + connectedAppId);

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 07 - CREATE EXTERNAL CREDENTIAL
 */
try{
    soap.Wsdl createExternalCredentialAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'ExternalCredential',
            new Map<String,Object>{
                'fullName'		         => appName,
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
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createExternalCredentialAction.getResponse()?.getBody());
    System.debug('Successfully upserted External Credential');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}
   

/**
 * 08 - CREATE NAMED CREDENTIAL
 */
try{
    soap.Wsdl createNamedCredentialAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'NamedCredential',
            new Map<String,Object>{
                'fullName'		              => appName,
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
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(createNamedCredentialAction.getResponse()?.getBody());
    System.debug('Successfully upserted Named Credential');
    
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}
   

/**
 * 09 - UPDATE THE PERMISSION SET WITH EXTERNAL CREDENTIAL ACCESS
 */
try{
    soap.Wsdl updatePermissionSetAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'PermissionSet',
            new Map<String,Object>{
                'fullName'                              => appName,
                'label'                                 => appLabel,
                'description'                           => 'Provides access to the ' + appLabel + ' Connected App',
                'externalCredentialPrincipalAccesses'   => new Object[]{
                    new Map<String,Object>{
                        'enabled'                       => true,
                        'externalCredentialPrincipal'   => ((String.isNotBlank(appNamespace)) ? appNamespace + '__' : '') + appName + '-NAMED_PRINCIPAL'
                    },
                    new Map<String,Object>{
                        'enabled'                       => true,
                        'externalCredentialPrincipal'   => ((String.isNotBlank(appNamespace)) ? appNamespace + '__' : '') + appName + '-PER_USER_PRINCIPAL'
                    }
                }
            }
        )
        .setDefaultNamespace(appNamespace) // Only required for namespaced scratch orgs or working with packages
        .call()
        .handleErrors()
    ;

    System.debug(updatePermissionSetAction.getResponse()?.getBody());
    System.debug('Successfully updated Permission Set');

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 10 - ASSIGN PERMISSION SET
 */
String permSetId = [SELECT Id FROM PermissionSet WHERE Name = :appName LIMIT 1].Id;

// Assign the permission set if it is not already assigned
if([SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :permSetId AND AssigneeId = :UserInfo.getUserId() LIMIT 1]?.Id == null){
    insert new PermissionSetAssignment(
        AssigneeId = UserInfo.getUserId(),
        PermissionSetId = permSetId
    );

// We can only test a callout to our new endpoint connection if we have the permission set assigned
// So run the test afterwards, this should work instantly
}else{
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:'+ ((String.isNotBlank(appNamespace)) ? appNamespace + '__' : '') + appName+'/services/data');
    req.setMethod('GET');
    Http http = new Http();
    HttpResponse res = http.send(req);
    System.debug(res.getBody());
}


/**
 * 11 - SEND AND EMAIL TO THE ADMIN TO NOTIFY  A NEW ORG IS READY FOR CONNECTION
 */
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