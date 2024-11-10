

try{
    
    XmlStreamReader xsr = new XmlStreamReader('{invalid}<xl?l>');

    while (xsr.hasNext()) {
        
        xsr.next();
    }

}catch(XmlException e){
    System.debug(e.getMessage());
}