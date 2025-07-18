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
    soap.Wsdl updateIpRangesOnAdminProfileAction = new soap.MdtWsdl('updateMetadata')
        .addCredMetadata(
            'Profile',
            new Map<String,Object>{
                'fullName'      => 'Admin',
                'loginIpRanges' => new Object[]{
                    new Map<String,Object>{
                        'description'  => 'The full range',
                        'startAddress' => '0.0.0.0',
                        'endAddress'   => '255.255.255.255'
                    }
                }
            }
        )
        .setDefaultNamespace('soap')
        .call()
        .handleErrors()
    ;

    System.debug(updateIpRangesOnAdminProfileAction.getResponse()?.getBody());
    System.debug(updateIpRangesOnAdminProfileAction.getRequest()?.getBody());

}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}


/**
 * 02 - READ IP RANGES ON ADMIN PROFILE
 */
try{
    XmlStreamReader xsr = new soap.MdtWsdl('readMetadata')
        .setItemMetadataType('Profile')
        .addItemMetadataFullName('Admin')
        .getXsr()
    ;

    List<Map<String,String>> values = soap.Util.readMultipleValuesOnList(
        xsr,
        'loginIpRanges',
        new Set<String>{
            'startAddress',
            'endAddress',
            'description'
        }
    );

    System.debug(JSON.serializePretty(values));
   
   
}catch(soap.Wsdl.SoapApiException e){
    System.debug(e.getMessage());
}