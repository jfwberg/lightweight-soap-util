/**
 * @description Examples on how to use the Apex WSDL methods
 *              - executeAnonymous (ae) Executes Anonymous Apex in the Org 
 *              - compileClasses   (cc) Compiles a list of Apex classes
 *              - compileTriggers  (ct) Compiles a list of Apex triggers
 * 
 * @note        The Soap class methods need to be called AFTER the WSDL specific methods.
 *              These are call(), setClientId() and setDefaultNamespace().
 *              This is because these methods return a Soap Class instance that does not
 *              contain the method that are specified in the extened class instances and 
 *              the compiler does not like that.
 */
// Execute anonymous
soap.Wsdl eaAction = new soap.ApxWsdl('executeAnonymous')
    .setLogLevel('DEBUG')
    .setLogCategory('APEX_CODE')
    .setCode('System.debug(19);')
    .setDefaultNamespace('soap')
    .call() 
;


// Compile Apex Classes
soap.Wsdl ccAction = new soap.ApxWsdl('compileClasses')
    .setLogLevel('DEBUG')
    .setLogCategory('APEX_CODE')
    .addScript('public class MyFirstTest {}')
    .addScript('public class MySecondTest{}')
    .setDefaultNamespace('soap')
    .call() 
;


// Compile Apex triggers
soap.Wsdl ctAction = new soap.ApxWsdl('compileTriggers')
    .setLogLevel('DEBUG')
    .setLogCategory('APEX_CODE')
    .addScript('trigger MyFirstRandomUserTrigger  on User(before update){}')
    .addScript('trigger MySecondRandomUserTrigger on User(before update){}')
    .setDefaultNamespace('soap')
    .call() 
;


// Output each callout and parsing execution time
System.debug('Execute Anonymous Callout took                   : ' + eaAction.getExecutionTime() + 'ms');
System.debug('Compile Classes Callout took                     : ' + ccAction.getExecutionTime() + 'ms');
System.debug('Compile Triggers Callout took                    : ' + ctAction.getExecutionTime() + 'ms');