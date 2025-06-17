/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        November 2024
 * @description An example of using the metadata API WSDL methods to create a 
 *              connection to the current org for secure API access.
 * 
 * @Steps       01 - Create a new messaging channel
 */
/**
 * 01 - CREATE A NEW LIGHTNING MESSAGING CHANNEL
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
        .call()
        .handleErrors()
    ;

    // Output a list of results
    soap.Util.MdtCrudResult[] MdtCrudResults = soap.Util.handleMdtCrudResponse(
        createLightningMessageChannelAction.getResponse()?.getXmlStreamReader(),
        'LightningMessageChannel'
    );
    
    // Output the response body
    System.debug(createLightningMessageChannelAction.getResponse()?.getBody());
    
    // Output the handled results
    System.debug(JSON.serializePretty(MdtCrudResults));

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}