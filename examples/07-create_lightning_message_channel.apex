/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        November 2024
 * @description An example of using the metadata API WSDL methods to create a 
 *              connection to the current org for secure API access.
 * 
 * @Steps       01 - Update the Admin profile with a full range of IP addresses
 *              02 - Read the admin profile and extract the IP ranges
 */
/**
 * 01 - UPDATE IP RANGES ON ADMIN PROFILE
 */
try{
    // Update metadata
    soap.Wsdl createLightningMessageChannelAction = new soap.MdtWsdl('upsertMetadata')
        .addCredMetadata(
            'LightningMessageChannel',
            new Map<String,Object>{
                'fullName'		=> 'Salesforce_Connection_Toolkit',
                'description'	=> 'Salesforce Connection Toolkit channel for communication between the different LWCs in the toolkit.',
                'isExposed' 	=> false,
                'masterLabel' 	=> 'Salesforce Connection Toolkit',
                'lightningMessageFields' => new Object[] {
                    new Map<String,Object>{
                        'fieldName'		=> 'messageType',
                        'description'	=> 'Different types of messages can be send, specifiy the type in here i.e. "ConnectionUpdate"'
                    },
                    new Map<String,Object>{
                        'fieldName'		=> 'connnectionUpdated',
                        'description'	=> 'Indicator if a connection has been created / updated or deleted and and action needs to happen. i.e. "true" or "false"'
                    }
                }
            }
        )
        .setDefaultNamespace('soap')
        .call()
        .handleErrors()
    ;

    System.debug(createLightningMessageChannelAction.getResponse()?.getBody());

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}