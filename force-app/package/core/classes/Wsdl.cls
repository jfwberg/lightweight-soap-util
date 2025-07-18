/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that contains a set of Salesforce SOAP API  Utilities
 * @note           This class is to be used in a managed package and contains Global methods that
 *                 should be made public or private in org based implementations or unlocked
 *                 packages.
 *                 Can be modified to make smaller in your own implementation
 */
@JsonAccess(serializable='never' deserializable='never')
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock, PMD.TooManyFields, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.ApexSuggestUsingNamedCred, PMD.ApexDoc, PMD.CognitiveComplexity')
global virtual with sharing class Wsdl {

    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // The named credential API name
    private String namedCredential;

    // Base URL (My domain URL for Salesforce API)
    private String baseUrl;

    // The Bearer token (Session Id for Salesforce API)
    // Transient to remove any secret data during serialization
    private transient String bearerToken;

    // Default API Configuration
    private String apiVersion = Constant.VAL_DEFAULT_API_VERSION;

    // Set the default time out to the maximum amount
    private Integer timeout   = Constant.VAL_DEFAULT_API_TIMEOUT;

    // An custom identifier to specify what mock to use in Apex Unit Tests
    private String mockResponseIdentifier;

    // The HTTP Request that is going to be send and the returned response
    // Transient to remove any secret data during serialization
    private transient HttpRequest  request;
    private transient HttpResponse response;

    // For testing purposes in external packages there is the option to
    // override the callout response with a custom mock response
    private transient HttpResponse mockResponse;

    // Variable to hold the execution time of the last API call
    private Integer executionTime;

    // CallOptions Header variables
    private String clientId;
    private String defaultNamespace;

    // The soap operation, populated through constructor
    private String soapAction;

    // String for holding the SOAP request XML body, populated through the XML Writer
    // Transient to remove any secret data during serialization
    private transient String soapRequestBody;

    // API Service specific namespace info, populated by API specific override methods
    private String apiServiceEndpoint;
    private String serviceNamespacePrefix;
    private String serviceNamespace;

    // Soap action mapping for specific API service, populated by API specific override methods
    private Map<String, String> soapActionMap;

    // Map for holding the different soap header elements, populated by the XML Writer
    private Map<String,Object> soapHeaderMap      = new Map<String,Object>();

    // Map holding different soap namespaces, populated by the XML Writer
    private Map<String,String> namespaceHeaderMap = new Map<String,String>();


    /** **************************************************************************************************** **
     **                                      PRIVATE STATIC VARIABLES                                        **
     ** **************************************************************************************************** **/
    // Map that contains the mock response that are specified using a 
    // name as identifier. Used with the set NamedMockResponse
    private static Map<String, HttpResponse> namedMockResponses = new Map<String, HttpResponse>();


    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Merge variable when using the API with a named credentials
    @TestVisible private static final String VAL_NC_TOKEN_MERGE_VARIABLE        = '{!$Credential.OAuthToken}';

    // Test related constants
    @TestVisible private static final String VAL_BEARER_TOKEN_HIDDEN_MESSAGE    = '[BEARER_TOKEN_HIDDEN]';

    // (error) Messages - (Move to Labels)
    @TestVisible private static final String MSG_API_INVALID_API_VERSION_FORMAT = 'Supplied API Version format is invalid. Please make the format follows: "vXX.X", i.e. "{0}"';
    @TestVisible private static final String MSG_INVALID_SOAP_ACTION            = 'Invalid SOAP ACTION specified';
    @TestVisible private static final String MSG_INVALID_MY_DOMAIN_URL          = 'Invalid My Domain URL format: Urls should start with "https://" and end with ".my.salesforce.com"';
    @TestVisible private static final String MSG_HTTP_CALLOUT_ISSUE             = 'HTTP Response is null. There either was an error during Http Callout or the call() or getXsr() methods have not executed yet';
    @TestVisible private static final String MSG_INVALID_MOCK_RESPONSE_ID       = 'Invalid mock response identifier "{0}"';

    // SOAP Api Error Messages
    @TestVisible private static final String MSG_UNKNOWN_HTTP_STATUS_CODE       = 'The SOAP API returned an unknown HTTP Status code. Http Status Code: "{0}". Response body: {1}';
    @TestVisible private static final String MSG_EMPTY_RESPONSE_BODY            = 'The SOAP API response body is empty';
    @TestVisible private static final String MSG_INVALID_XML_RESPONSE           = 'The SOAP API response body is invalid XML. XmlException Message: {0}';
    @TestVisible private static final String MSG_UNKNOWN_ERROR_RESPONSE         = 'The SOAP API returned an unknown error response body. Response body: {0}';
    
    // Test Messages
    @TestVisible private static final String MSG_TEST_UNEXPECTED_EXCEPTION      = 'Unexpected exception message';
    @TestVisible private static final String MSG_TEST_EXCEPTION_SAFEGUARD       = 'This part of the test should not be reached: An exception should have been thrown';


    /** **************************************************************************************************** **
     **                                             CONSTRUCTORS                                             **
     ** **************************************************************************************************** **/
    /**
     * Empty constuctor required for virtual method overrides
     * Public so it can NOT be constructed outside of the managed package
     */
    public Wsdl(){}


    /** **************************************************************************************************** **
     **                                          CONSTRUCTOR LOGIC                                           **
     ** **************************************************************************************************** **/
    /**
     * @description Method to setup the Soap Api for use with a named credential
     */
    public void setupNamedCredential(String namedCredential){

        // Set name
        this.setNamedCredential(namedCredential);

        // (re)Set My domain / session Id
        this.setBaseUrl(null);
        this.setBearerToken(Wsdl.VAL_NC_TOKEN_MERGE_VARIABLE);
    }


    /**
     * @description Method to setup the Soap Api for use with a my domain url and a session id
     */
    public void setupMyDomain(String baseUrl, String bearerToken){

        // (re)Set Named Credential
        this.setNamedCredential(null);

        // (re)Set My domain / session Id, when using null values, connect to the current org
        this.setBaseUrl(    String.isNotBlank(baseUrl)    ? baseUrl     : URL.getOrgDomainUrl().toExternalForm());
        this.setBearerToken(String.isNotBlank(bearerToken)? bearerToken : this.getApiEnabledSessionId());
    }


    /** **************************************************************************************************** **
     **                                           PRIVATE SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set the session Id value used the header
     *              There is no matching getter method as for security we do not want to expose
     *              the session Id externaly in any way. It can only be used inside the class
     */
    private void setBearerToken(String bearerToken){
        this.bearerToken = bearerToken;
    }


    /**
     * @description Method to set the soap request body
     */
    public void setSoapRequestBody(String soapRequestBody){
        this.soapRequestBody = soapRequestBody;
    }

    public void setApiServiceEndpoint(String apiServiceEndpoint){
        this.apiServiceEndpoint = apiServiceEndpoint;
    }

    public void setServiceNamespacePrefix(String serviceNamespacePrefix){
        this.serviceNamespacePrefix = serviceNamespacePrefix;
    }

    public void setServiceNamespace(String serviceNamespace){
        this.serviceNamespace = serviceNamespace;
    }

    public void setSoapActionMap(Map<String, String> soapActionMap){
        this.soapActionMap = soapActionMap;
    }


    /** **************************************************************************************************** **
     **                                            GLOBAL SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set the api version
     */
    global Wsdl setApiVersion(String apiVersion){

        // Validate the API version has the expected format
        if(String.isBlank(apiVersion) || !Pattern.matches(Constant.VAL_API_VERSION_PATTERN, apiVersion)){
            throw new SoapUtilException(
                String.format(
                    Wsdl.MSG_API_INVALID_API_VERSION_FORMAT,
                    new String[]{Constant.VAL_DEFAULT_API_VERSION}
                )
            );
        }

        // Set the API version
        this.apiVersion = apiVersion;

        // Return self
        return this;
    }


    /**
     * @description Method to set the clientId value used in the CallOptions header
     *              Client Id is used for API activation in professional edition
     */
    global Wsdl setClientId(String clientId){

        // Set the value
        this.clientId = clientId;

        // Return self
        return this;
    }


    /**
     * @description Method to set the defaultNamespace value used in the CallOptions header
     *              Default namespace can be used to auto prefix all fields in a namespaced org
     *              This is very handy for package orgs or scratch orgs with a namespace
     */
    global Wsdl setDefaultNamespace(String defaultNamespace){

        // Set the value
        this.defaultNamespace = defaultNamespace;

        // Return self
        return this;
    }


    /**
     *    @description    Setter method to set the soapAction value and validate the action is valid
     *    @param          soapAction The name of the API soapAction attribute
     *    @return         self
     */
    global Wsdl setSoapAction(String soapAction){
        if(this.soapActionMap.keySet().contains(soapAction)){
            this.soapAction = soapAction;
        }else{
            throw new SoapUtilException(Wsdl.MSG_INVALID_SOAP_ACTION);
        }
        return this;
    }


    /**
     *    @description    Setter method to set the mockResponse value
     *    @param          mockResponse The HttpResponse object to be returned by the call() method
     *    @return         self
     */
    global Wsdl setMockResponse(HttpResponse mockResponse){
        
        // Added a new HttpResponse in case of accidental null input
        // throwing null pointer exceptions for arguments
        this.mockResponse = mockResponse ?? new HttpResponse();
        
        return this;
    }


    /**
     *    @description  Setter method to initiate the mockResponse object
     *    @param        mockResponseIdentifier The key for the Mock HttpResponse
     *                  object to be returned by the call() method
     *    @note         Virtual due to package upgrade limitations
     *    @return       self
     */
    global virtual Wsdl setMockResponseIdentifier(String mockResponseIdentifier){
        
        // Configure the response identifier
        this.mockResponseIdentifier = mockResponseIdentifier;

        return this;
    }


    /**
     * @description Method to set the api timeout
     */
    global virtual Wsdl setTimeout(Integer timeout){

        // Set the timeout
        this.timeout = timeout ?? 120000;

        return this;
    }


    /** **************************************************************************************************** **
     **                                        GLOBAL STATIC SETTERS                                         **
     ** **************************************************************************************************** **/
    /**
     * description Method to add a mock response from a test class
     * @param mockResponseIdentifier    The mock identifier
     * @param statusCode                The mock status code
     * @param body                      The mock body
     * @note This is global so it can be used from external test classes
     */
    global static void addNamedMockResponse(String mockResponseIdentifier, Integer statusCode, String body){

        // Create a new resposne
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(statusCode);
        mockResponse.setBody(body);

        // Create a new HttpResponse object to match the identifier
        Wsdl.namedMockResponses.put(
            mockResponseIdentifier,
            mockResponse
        );
    }


    /** **************************************************************************************************** **
     **                                       GLOBAL SUPPORT METHODS                                         **
     ** **************************************************************************************************** **/
    /**
     * @description Method to generate and execute the HTTP request
     * @return      self
     */
    global Wsdl call(){

        // Generate the http request
        this.setupRequest();

        // Set start date
        Integer startDateTime = Datetime.now().millisecond();

        // If we are in a test and have a response identifier populated, validate that the response exists
        if(Test.isRunningTest() && String.isNotBlank(this.mockResponseIdentifier) && !Wsdl.namedMockResponses.containsKey(mockResponseIdentifier)){
            throw new SoapUtilException(
                String.format(
                    Wsdl.MSG_INVALID_MOCK_RESPONSE_ID,
                    new String[]{mockResponseIdentifier})
            );
        }

        // Send the request or send a Mock Response whilst running an apex test
        // Is NOT Test? --> Execute Http Callout
        // Is Test and this.Mock Response = NOT NULL? --> Return this.mockResponse
        // Else return named mock response based on identifier
        this.response = (!Test.isRunningTest()) ? new Http().send(this.request) : 
                        this.mockResponse ?? Wsdl.namedMockResponses.get(this.mockResponseIdentifier);

        // Calculate call duration in milliseconds
        this.executionTime = Datetime.now().millisecond() - startDateTime;

        // Remove the bearer token from the request after a callout
        this.request.setBody(this.request.getBody().replace(this.bearerToken, VAL_BEARER_TOKEN_HIDDEN_MESSAGE));

        // Santaize the bearer token to prevent data leakage
        this.bearerToken = VAL_BEARER_TOKEN_HIDDEN_MESSAGE;

        // Return self
        return this;
    }


    /**
     * @description Method to setup the SOAP API HTTP Request
     *              The use of this is optional and can be overwritten if you need special logic
     *              The aim for the library is to always use the standard way, but allow for exceptions
     * @return      self
     */
    global virtual Wsdl setupRequest(){

        // Reset the request
        this.request = new HttpRequest();

        // Set the default time-out value
        this.request.setTimeout(this.timeout);

        // Set the method, body and endpoint
        this.request.setMethod('POST');
        this.request.setBody(this.getSoapRequestBody());
        this.request.setEndpoint(this.getApiEndpoint());

        // Set the mandatory headers
        this.request.setHeader('soapAction',   this.getSoapAction());
        this.request.setHeader('Content-Type', 'text/xml; charset=UTF-8;');

        // Return self
        return this;
    }


    /**
     * @description Optional method to handle the response by throwing an exception
     *              on a 500 status code. The soap api throws a 500 for basically any
     *              type of error.
     * @return      self
     */
    global virtual Wsdl handleErrors(){

        // Validate there has been a callout and handle common HTTP Error Status Codes
        if(String.isBlank(this.response?.getBody())){
            throw new SoapApiException(Wsdl.MSG_HTTP_CALLOUT_ISSUE);
        }

        // Validate
        switch on this.response.getStatusCode(){

            // Do nothing on a succesful call except
            when 200 {
                return this;
            }

            // SOAP API Error, throw a new exception with the SOAP API Details
            when 500 {

                // Parse the error response
                this.parseSoapApiErrorResponse(this.response.getXmlStreamReader());
            }

            // For code coverage only to please the compiler at the end
            // Could also be used for ignoring any error handling for test purposes
            when 999{}

            // Unknown error
            when else{
                throw new SoapApiException(
                    String.format(
                        Wsdl.MSG_UNKNOWN_HTTP_STATUS_CODE,
                        new String[]{
                            this.response.getStatusCode().toString(),
                            this.response.getBody()
                        }
                    )
                );
            }
        }

        // This will never be reached but is here to please to compiler
        return this;
    }


    /** **************************************************************************************************** **
     **                                            GLOBAL GETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to get the HttpRequest related to the current rest callout
     * @return      Soap API Request
     */
    global HttpRequest getRequest(){
        return this.request;
    }


    /**
     * @description Method to get the HttpResponse related to the current rest callout
     *              Use this after the callout has been executed
     * @return      The current HttpResponse object
     */
    global HttpResponse getResponse(){
        return this.response;
    }


    /**
     * @description Method to get the execution time
     * @return      The number of milliseconds it took to execute the request
     */
    global Integer getExecutionTime(){
        return this.executionTime;
    }


    /**
     * @description Method to execute the SOAP API call and return the response
     *              as an XmlStreamReader object bypassing any error handling.
     *              Executes the sanization of the auth headers before return.
     * @note        Use this method when you run into heap size issues and want the
     *              most memory efficient way of handling SOAP API responses
     * @return      The SOAP API Response as an XmlStreamReader class instance
     */
    global XmlStreamReader getXsr(){

        // Generate the http request
        this.setupRequest();

        // Set start date
        Integer startDateTime = Integer.valueOf(Datetime.now().millisecond());

        // If we are in a test and have a response identifier populated, validate that the response exists
        if(Test.isRunningTest() && String.isNotBlank(this.mockResponseIdentifier) && !Wsdl.namedMockResponses.containsKey(mockResponseIdentifier)){
            throw new SoapUtilException(
                String.format(
                    Wsdl.MSG_INVALID_MOCK_RESPONSE_ID,
                    new String[]{mockResponseIdentifier})
            );
        }

        // Call the handler to clean up the bearer token and calculate the exection time
        return this.handleGetXsr(
            (!Test.isRunningTest()) ? new Http().send(this.request)?.getXmlStreamReader() : this.mockResponse?.getXmlStreamReader() ?? Wsdl.namedMockResponses.get(this.mockResponseIdentifier)?.getXmlStreamReader(),
            startDateTime
        );
    }


    /** **************************************************************************************************** **
     **                                            PUBLIC SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to write the session header to the SOAP Header
     */
    public void setSessionHeader(){
        this.soapHeaderMap.put(
            'SessionHeader',
            new Map<String,Object>{
                'sessionId' => this.bearerToken
            }
        );
    }


    /**
     * @description Method to write the call options header to the SOAP Header
     */
    public void setCallOptionsHeader(){
        this.soapHeaderMap.put(
            'CallOptions',
            new Map<String,Object>{
                'client'           => this.clientId         ?.toString() ?? '' ,
                'defaultNamespace' => this.defaultNamespace ?.toString() ?? ''
            }
        );
    }


    /** **************************************************************************************************** **
     **                                            PUBLIC GETTERS                                            **
     ** **************************************************************************************************** **/
    public String getSoapAction(){
        return this.soapAction;
    }

    public String getServiceNamespacePrefix(){
        return this.serviceNamespacePrefix;
    }

    public String getServiceNamespace(){
        return this.serviceNamespace;
    }

    public Map<String, String> getSoapActionMap(){
        return this.soapActionMap;
    }

    public Map<String,Object> getSoapHeaderMap(){
        return this.soapHeaderMap;
    }

    public Map<String,String> getNamespaceHeaderMap(){
        return this.namespaceHeaderMap;
    }


    /** **************************************************************************************************** **
     **                                           PRIVATE SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set a named credential API name
     */
    private void setNamedCredential(String namedCredential){
        // Set the named credential name
        this.namedCredential = namedCredential;
    }


    /**
     * @description Method to set the login URL specifically to a custom my domain URL
     *              for use with the partner api login function or for use with salesforce connections
     *              that have already been established after logging using the partner API (or any other way)
     */
    private void setBaseUrl(String baseUrl){
        if(String.isNotBlank(baseUrl) && !baseUrl?.toLowerCase()?.startsWith('https://') && !baseUrl?.toLowerCase()?.endsWith('.my.salesforce.com')){
            throw new SoapUtilException(Wsdl.MSG_INVALID_MY_DOMAIN_URL);
        }
        // Set the my domain variable
        this.baseUrl = baseUrl?.removeEnd('//');
    }


    /** **************************************************************************************************** **
     **                                        PRIVATE SUPPORT METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method to generate the endpoint for the Metadata SOAP request
     * @return      The API endpoint based on the home org or named credential
     */
    private String getApiEndpoint(){
        return
        (
            // If there is a named credential, use the named credential
            (String.isNotBlank(this.namedCredential)) ?
                'callout:' + this.namedCredential :

                // Is a custom base URL set? Use that, else go with the home org domain url
                (String.isNotBlank(this.baseUrl)) ?
                    this.baseUrl :
                    Url.getOrgDomainUrl().toExternalForm()

        // Add the srvice endpoint and api version without the V
        ) + this.apiServiceEndpoint + this.apiVersion?.removeStart('v');
    }


    /**
     * @description Method to get a VF API enabled session Id for local session.
     *              Calls a VF page and extracts the session Id, this is quite a hack but allowed in AppExchange reviews
     *              It is required for lightning components to communicate with the Salesforce API directy
     *              Ideally you would always use a Named credential for each connection, even to the local org
     * @return      An API enabled Session Id
     */
    private String getApiEnabledSessionId(){
        return(
            (Test.isRunningTest()) ?
                Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE :
                (Constant.VAL_LIGHTNING_CONTEXTS.contains(System.Request.getCurrent().getQuiddity())) ?
                    Page.getSoapApiSessionId?.getContent()?.toString()?.trim() :
                    UserInfo.getSessionId()
        );
    }


    /**
     * @description Method to generate the SOAP XML Body
     */
    private String getSoapRequestBody(){

        // Write the updated body
        XmlWriter.writeFullSoapRequestBody(this);

        // Return the newly updated body
        return this.soapRequestBody;
    }


    /**
     * @description Parses the error response and throws an exception
     * @param       xsr The XML Stream Reader
     */
    private void parseSoapApiErrorResponse(XmlStreamReader xsr){

        // Combine all parts of a string into a single block, required for the error messages
        xsr.setCoalescing(true);

        // Flag to check if the response has a fault code and fault string to validate it a valid error response
        Boolean faultCodeFound   = false;
        Boolean faultStringFound = false;

        // Variables to construct the fault string for the exception
        String   exceptionMessageFormat = '{0} :: {1}';
        String[] exceptionMessageValues =  new String[]{};

        // Try/Catch block specifically for Catching XML errors
        try{
            // Iterate the XML to find the fault code and fault string
            while(true){
                if(xsr.getEventType() == XmlTag.START_ELEMENT ){

                    // Get the fault code first
                    if(xsr.getLocalName() == 'faultcode' ){

                        // Indicate it has been found
                        faultCodeFound = true;

                        // Move to the text
                        xsr.next();

                        // Get the text
                        exceptionMessageValues.add(xsr.getText());

                        // Mote the to the fault string (if valid XML)
                        xsr.next();
                    }

                    // Move on to the fault string and break the loop when found
                    if(xsr.getLocalName() == 'faultstring'){

                        // Indicate it has been found
                        faultStringFound = true;

                        // Move to the text
                        xsr.next();

                        // Add the text;
                        exceptionMessageValues.add(xsr.getText());

                        // Break the process as we are done
                        break;
                    }
                }
                if(xsr.hasNext()){xsr.next();}else{break;}
            }

            // Throw an error if the default exceptions have been found
            if(faultCodeFound && faultStringFound){
                throw new SoapApiException(String.format(
                    exceptionMessageFormat,
                    exceptionMessageValues
                ).removeStart('sf:'));

            // Something went wrong, the response is XML but not as expected
            }else{
                throw new SoapApiException(String.format(
                    wsdl.MSG_UNKNOWN_ERROR_RESPONSE,
                    new String[]{this.response.getBody()}
                ));
            }

        // The response contains invalid XML
        }catch(XmlException e){
            throw new SoapApiException(String.format(
                MSG_INVALID_XML_RESPONSE,
                new String[]{e.getMessage()}
            ));
        }
    }


    /**
     * @description Method to execute the SOAP API call and return the response
     *              as an XmlStreamReader object bypassing any error handling.
     *              Executes the sanization of the auth headers before return.
     * @param       xsr           The XmlStreamReader instance to return the response as
     * @param       startDateTime The start date time in milliseconds to calculate the execution time
     * @return      The SOAP API Response as an XmlStreamReader class instance
     */
    private XmlStreamReader handleGetXsr(XmlStreamReader xsr, Integer startDateTime){

        // Combine all parts of a string into a single block, required for most of the text handling
        xsr.setCoalescing(true);

        // Remove the bearer token from the request after a callout
        this.request.setBody(this.request.getBody().replace(this.bearerToken, VAL_BEARER_TOKEN_HIDDEN_MESSAGE));

        // Santaize the bearer token to prevent data leakage
        this.bearerToken = VAL_BEARER_TOKEN_HIDDEN_MESSAGE;

        // Calculate call duration in milliseconds
        this.executionTime = (Datetime.now().millisecond() - startDateTime);

        // Return self
        return xsr;
    }


    /** **************************************************************************************************** **
     **                                          XML WRITER METHODS                                          **
     ** **************************************************************************************************** **/
    /**
     * @description Method to generate the SOAP Header for the Metadata SOAP request
     *              This is not part of the XML Writer as XML attributes and namespace are very different
     *              it would be very complicated to build something generic for that
     *              Best solution here was to keep the specific XML Write logic in the respective API Class
     */
    public virtual void writeSoapHeaderContent(XmlStreamWriter w){}


    /**
     * @description Method to generate the XML Body for the Metadata SOAP request
     *              This is not part of the XML Writer as XML attributes and namespace are very different
     *              it would be very complicated to build something generic for that
     *              Best solution here was to keep the specific XML Write logic in the respective API Class
     */
    public virtual void writeSoapBodyContent(XmlStreamWriter w){}


    /** **************************************************************************************************** **
     **                                          EXCEPTION CLASSES                                           **
     ** **************************************************************************************************** **/
    global class SoapApiException  extends Exception{}
    global class SoapUtilException extends Exception{}


    /** **************************************************************************************************** **
     **                                              INTERFACES                                              **
     ** **************************************************************************************************** **/
    public interface IWsdl {
        // Methods required to setup the service for a specific API
        void setApiServiceEndpoint();
        void setServiceNamespaceDetails();
        void setSoapActionMap();

        // Methods required to setup the contents of the Soap request
        void writeSoapHeaderContent(XmlStreamWriter w);
        void writeSoapBodyContent(XmlStreamWriter w);
    }
}