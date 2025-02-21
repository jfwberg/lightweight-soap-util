/**
 * @description Examples on how to use the Metadata WSDL
 *              - Describe(ds) Describe the metadata types availible in the org
 *              - List    (ls) List out all the metadata for a type or in a folder
 *              - Read    (rd) Get the specific metadata details
 *              - Create  (cr) Create new metadata
 *              - Update  (ud) Update the created metadata
 *              - Rename  (rn) Rename the created metadata
 *              - Upsert  (us) Upsert the created metadata
 *              - Delete  (dl) Delete the created metadata
 * 
 * @note        The Soap class methods need to be called AFTER the WSDL specific methods.
 *              These are call(), setClientId() and setDefaultNamespace().
 *              This is because these methods return a Soap Class instance that does not
 *              contain the method that are specified in the extened class instances and 
 *              the compiler does not like that.
*/
// Describe metadata
soap.Wsdl dsAction = new soap.MdtWsdl('describeMetadata')
    .call()
;


// List metadata with and without optional folders
soap.Wsdl lsAction = new soap.MdtWsdl('listMetadata')
    .setAllOrNone(true)
    .addListMetadata('Profile')
    .addListMetadata('Report','unfiled$public')	
    .call()
;


// Read metadata
soap.Wsdl rdAction = new soap.MdtWsdl('readMetadata')
    .setItemMetadataType('CustomObject')
    .addItemMetadataFullName('User')
    .addItemMetadataFullName('Account')
    .call() 
;


// Create metadata
soap.Wsdl crAction = new soap.MdtWsdl('createMetadata')
    .addCredMetadata(
        'RemoteSiteSetting',
        new Map<String,Object>{
            'fullName'		            => 'Remote_Org_My_Domain_Url',
            'description'               => 'Remote Salesforce Org My Domain URL',
            'disableProtocolSecurity'   => false,
            'isActive'                  => true,
            'url'                       => 'https://remote-org.my.salesforce.com'
        }
    )
    .call()
;


// Update metadata
soap.Wsdl udAction = new soap.MdtWsdl('updateMetadata')
    .addCredMetadata(
        'RemoteSiteSetting',
        new Map<String,Object>{
            'fullName'		            => 'Remote_Org_My_Domain_Url',
            'description'               => 'Home Salesforce Org My Domain URL',   // Update to home
            'disableProtocolSecurity'   => false,
            'isActive'                  => true,
            'url'                       => Url.getOrgDomainUrl().toExternalForm() // Update to current URL
        }
    )
    .call()
;


// Rename metadata
soap.Wsdl rnAction = new soap.MdtWsdl('renameMetadata')
    .setRenameMetadata(
        'RemoteSiteSetting',
        'Remote_Org_My_Domain_Url',
        'Home_Org_My_Domain_Url'
    )	
    .call()
;


// Upsert metadata
soap.Wsdl usAction = new soap.MdtWsdl('upsertMetadata')
    .addCredMetadata(
        'RemoteSiteSetting',
        new Map<String,Object>{
            'fullName'		            => 'Home_Org_My_Domain_Url',
            'description'               => 'Remote Salesforce Org My Domain URL',
            'disableProtocolSecurity'   => false,
            'isActive'                  => false,  // Update to false
            'url'                       => Url.getOrgDomainUrl().toExternalForm()
        }
    )	
    .call()
;


// Delete metadata
soap.Wsdl dlAction = new soap.MdtWsdl('deleteMetadata')
    .setItemMetadataType('RemoteSiteSetting')
    .addItemMetadataFullName('Home_Org_My_Domain_Url')
    .call()
;


// Output each callout and parsing execution time
System.debug('Describe Metadata (DM) Executing Callout took : ' + dsAction.getExecutionTime() + 'ms');
System.debug('List Metadata     (LS) Executing Callout took : ' + lsAction.getExecutionTime() + 'ms');
System.debug('Read Metadata     (RD) Executing Callout took : ' + rdAction.getExecutionTime() + 'ms');
System.debug('Create Metadata   (CR) Executing Callout took : ' + crAction.getExecutionTime() + 'ms');
System.debug('Update Metadata   (UD) Executing Callout took : ' + udAction.getExecutionTime() + 'ms');
System.debug('Rename Metadata   (RN) Executing Callout took : ' + rnAction.getExecutionTime() + 'ms');
System.debug('Upsert Metadata   (US) Executing Callout took : ' + usAction.getExecutionTime() + 'ms');
System.debug('Delete Metadata   (DL) Executing Callout took : ' + dlAction.getExecutionTime() + 'ms');