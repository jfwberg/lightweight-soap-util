/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2025 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that contains constants used throughout the app
 */
public with sharing class Constant {
    
    // SOAP Api setup variables
    public static final String  VAL_DEFAULT_API_VERSION      = 'v64.0';
    public static final Integer VAL_DEFAULT_API_TIMEOUT      = 120000;

    // Standard Salesforce API format like v64.0
    public static final String  VAL_API_VERSION_PATTERN      = '[v]\\d\\d[.][0]';

    // Execution contexts that use the lightning session id instead of the standard session id
    // AURA for Lightning Web Components and INVOCABLE_ACTION for Agentforce actions
    // Using a name credential for your connection is still the recommended approach
    public static final Set<Quiddity> VAL_LIGHTNING_CONTEXTS = new Set<Quiddity>{
        Quiddity.AURA,
        Quiddity.INVOCABLE_ACTION
    };

    // Test constants
    public static final String VAL_TEST_NAMESPACE_NAME       = 'test_ns';
    public static final String VAL_NAMESPACE                 = Test.isRunningTest() ? VAL_TEST_NAMESPACE_NAME : [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;

    // Test messages
    public static final String MSG_TEST_UNEXPECTED_VALUE     = 'Unexpected value for assert';
}