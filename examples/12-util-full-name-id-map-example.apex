/**
 * @description Method to demonstrate the most efficient way to get a 
 *              Metadata mapping between the full name and the Id
 */
try{

    // Create
    Map<String,String> fullNameIdMap = soap.Util.getFullNameIdMapFromMetadataListResult(
        new soap.MdtWsdl('listMetadata')
        .addListMetadata('CustomObject')
        .setMockResponseIdentifier('LIST_CUSTOM_OBJECTS')
        .getXsr()
    );

    // A map ready for useage with picklists
    System.debug(JSON.serializePretty(fullNameIdMap));

}catch(Exception e){
    System.debug('Unexpected payload issue: ' + e.getMessage());
}