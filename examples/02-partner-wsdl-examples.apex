/**
 * @description Examples on how to use the Partner WSDL methods
 *              - login            (li) Login to an API using Username and Password 
 *              - getUserInfo      (ui) Get logged in user info
 *              - describeGlobal   (dg) Describe Global
 *              - describeSObject  (do) Describe single sObject (legacy)
 *              - describeSObjects (ds) Describe multiple sObjects (Preferred method)
 *              - setPassword      (sp) Set a user's password
 *              - resetPassword    (rp) Reset a user's password
 *              - logout           (lo) Logout from the current session
 * 
 * @note        The Soap class methods need to be called AFTER the WSDL specific methods.
 *              These are call(), setClientId() and setDefaultNamespace().
 *              This is because these methods return a Soap Class instance that does not
 *              contain the method that are specified in the extened class instances and 
 *              the compiler does not like that.
 */
// Login
soap.Wsdl liAction = new soap.ParWsdl('login')
    .setUsername(UserInfo.getUserName())
    .setPassword('S@P3R_S3CR3T_PHR@SE_NUMBER_01g4ax4xjmpnlZhNBjkvdJySm9')
    .call() 
;


// Get logged in user info
soap.Wsdl uiAction = new soap.ParWsdl('getUserInfo')
    .call() 
;


// Get the global describe
soap.Wsdl dgAction = new soap.ParWsdl('describeGlobal')
    .call() 
;


// Describe an object
soap.Wsdl doAction = new soap.ParWsdl('describeSObject')
    .setSObjectType('User')
    .call() 
;


// Describe multiple objects (Use this one) 
soap.Wsdl dsAction = new soap.ParWsdl('describeSObjects')
    .addSObjectType('User')
    .addSObjectType('Organization')
    .call() 
;


// Set a password for a user
soap.Wsdl spAction = new soap.ParWsdl('setPassword')
    .setUserId(UserInfo.getUserId())
    .setPassword('S@P3R_S3CR3T_PHR@SE_NUMBER_02')
    .call() 
;


// Reset a password for a user
soap.Wsdl rpAction = new soap.ParWsdl('resetPassword')
    .setUserId(UserInfo.getUserId())
    .call() 
;


// Log a user out
soap.Wsdl loAction = new soap.ParWsdl('logout')
    .call() 
;


// Output each callout and parsing execution time
System.debug('Login (LI) Executing Callout   took            : ' + liAction.getExecutionTime() + 'ms');
System.debug('Get User Info (UI) Executing Callout   took    : ' + uiAction.getExecutionTime() + 'ms');
System.debug('Describe Global (DG) Executing Callout   took  : ' + dgAction.getExecutionTime() + 'ms');
System.debug('Describe sObject (DO) Executing Callout   took : ' + doAction.getExecutionTime() + 'ms');
System.debug('Describe sObjects (DS) Executing Callout   took: ' + dsAction.getExecutionTime() + 'ms');
System.debug('Logout (LO) Executing Callout   took           : ' + loAction.getExecutionTime() + 'ms');