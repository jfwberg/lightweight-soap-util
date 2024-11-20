/**
 * @author      Justus van den Berg (jfwberg@gmail.com)
 * @date        November 2024
 * @description Example on how to get the debug lines from a debug log only.
 */
// Debug log entry regex pattern
static final String  DEBUG_LINE_REGEX    = '^\\d\\d:\\d\\d:\\d\\d.\\d+\\s\\(\\d*\\)\\|[A-Z_]*\\|.*$';
static final Pattern DEBUG_LINE_PATTERN  = Pattern.compile(DEBUG_LINE_REGEX);

// Full line for replacing start of the debug lines to create smooth output
static final String  FULL_DEBUG_LINE_REGEX   = '\\d\\d:\\d\\d:\\d\\d.\\d+\\s\\(\\d*\\)\\|[A-Z_]*\\|\\[\\d*\\]\\|[A-Z]*\\|';
static final Pattern FULL_DEBUG_LINE_PATTERN = Pattern.compile(FULL_DEBUG_LINE_REGEX);

// Apex code to execute
String code = 'System.debug(JSON.serializePretty([SELECT Id,Name, Username FROM User LIMIT 5]));';

// Execute anonymous
XmlStreamReader xsr = new soap.ApxWsdl('executeAnonymous')
    .setLogLevel('DEBUG')
    .setLogCategory('APEX_CODE')
    .setCode(code)
    .getXsr() 
;

// Set to true or each line line in the debug log is a separate XSR element
// when true the text is treated as a single block
xsr.setCoalescing(true);

// Stream throught the XML Elements and handle accordingly
while(xsr.hasNext()){
    if(xsr.getEventType()==XmlTag.START_ELEMENT){
        if(xsr.getLocalName()=='debugLog'){
            xsr.next();
            
            System.debug('\n-----------\n' + getDebugLines(xsr.getText()) + '\n-----------\n' );
            
            break;
        }
    }
    xsr.next();
}


/**
 * Method to extract the debug lines from a debug log
 */
String getDebugLines(String debugLog){

    // Valiable
    String[] outputLines = new String[]{};

    // Get the lines from the debug log and go through them
    String[] lines = debugLog.split('\n');

    // Indicator if the previous line was a debug line,this is so we can handle debug statements
    // that are spread over multiple lines in the debug log. A bit of hack but it works.
    // This is mainly used to cleanly output JSON payloads
    Boolean previousLineIsDebug = false;

    // Validate the lines start with the base pattern
    // Measure the speed over a large number of lines in the future
    for(Integer i=0,max=lines.size(); i<max; i++){
        if((DEBUG_LINE_PATTERN.matcher(lines[i]).matches())){
            if(lines[i].contains('USER_DEBUG')){

                // Clear the start of the debug lines
                outputLines.add(lines[i].replaceAll(FULL_DEBUG_LINE_REGEX,''));
                previousLineIsDebug = true;
            }else{
                previousLineIsDebug = false;
            }
        }else{
            if(previousLineIsDebug){
                outputLines.add(lines[i]);
            }
        }
    }
    return String.join(outputLines,'\n');
}