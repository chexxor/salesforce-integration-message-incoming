public with sharing class Integration_Message_Handlers {

    public static Map<String, String> commandToHandlerTypeName = new Map<String, String> {
            'Create_Opportunity' => 'IMI_Create_Opportunity',
            'Add_Contact' => 'IMI_Add_Contact'
    };
    public static Map<String, Type> commandToArgType = new Map<String, Type> {
            'Create_Opportunity' => IMI_Create_Opportunity_Arg.class,
            'Add_Contact' => IMI_Add_Contact_Arg.class
    };

    public static Map<Id, String> handleCommand(String command, List<Integration_Message_Incoming__c> messages) {
        Map<Id, String> messageIdToError = new Map<Id, String>();
        List<Integration_Message_Incoming__c> syncMessages = new List<Integration_Message_Incoming__c>();
        List<Integration_Message_Incoming__c> asyncMessages = new List<Integration_Message_Incoming__c>();
        for (Integration_Message_Incoming__c message : messages) {
            if (commandToHandlerTypeName.containsKey(command) == false) {
                System.debug('Unsupported command: ' + command + ' with arguments: ' + message.Command_Argument__c);
                continue;
            }
            if (String.isBlank(message.Command_Argument__c)) {
                System.debug('No Command_Argument on message: ' + JSON.serialize(message));
                continue;
            }
            // Pre-parse the argument to notify the sender of this basic request error.
            Type argType = commandToArgType.get(command);
            List<Object> results = validateCommandArg(message.Command_Argument__c, argType);
            String parseError = (String) results.get(0);
            if (String.isNotBlank(parseError)) {
                messageIdToError.put(message.Id, 'Error parsing argument: ' + message.Command_Argument__c + ' for command ' + command + '. Error Message: ' + parseError);
            } else {
                if (message.Run_Async__c) {
                    asyncMessages.add(message);
                } else {
                    syncMessages.add(message);
                }
            }
        }
        // Execute the messages
        if (!asyncMessages.isEmpty()) {
            runCommandFuture(command, JSON.serialize(messages));
        } else if (!syncMessages.isEmpty()) {
            runCommand(command, messages);
        } else { System.debug('Expected sync or async messages, but none found. This should not have happened.'); }
        return messageIdToError;
    }

    // Return value: First element is an error string or null, second element is valid arguments.
    public static List<Object> validateCommandArg(String argString, Type argType) {
        // Parse argument.
        String parseError;
        Object arg;
        try {
            arg = JSON.deserialize(argString, argType);
        } catch (Exception e) {
            parseError = e.getMessage();
        }
        if (String.isNotBlank(parseError)) {
            return new List<Object> { parseError, new Map<String, Object>() };
        }
        // Validate arguments.
        Callable argValidator = (Callable) arg;
        // Return value: First element is an error string or null, second element is valid arguments.
        Object validatedArgResultObject = argValidator.call('validate', new Map<String, Object> {
                'validate' => arg
        });
        // Support an arg with no extra validator.
        if (validatedArgResultObject == null) {
            return new List<Object> { null, arg };
        }
        List<Object> validatedArgResult = (List<Object>) validatedArgResultObject;
        return validatedArgResult;
    }


    public static void runHandler(String command, String handlerTypeName, List<Integration_Message_Incoming__c> messages) {
        if (String.isBlank(handlerTypeName)) {
            throw new IMI_Exception('Found no handler type name for command "' + command + '". Contact your Salesforce administrator for assistance.');
        }
        // Is it an Apex handler?
        String apexHandlerErrorMessage;
        Type handlerType = Type.forName(null, handlerTypeName);
        if (handlerType != null) {
            Object handlerObject;
            try {
                handlerObject = handlerType.newInstance();
            } catch (Exception e) {
                apexHandlerErrorMessage = 'Unable to create handler "' + handlerTypeName + '" for command "' + command + '". Contact your Salesforce administrator for assistance.';
//                throw new IMI_Exception(apexHandlerErrorMessage);
            }
            if (handlerObject != null) {
                Callable handler = (Callable) handlerObject;
                handler.call('run', new Map<String, Object>{ 'Params' => messages });
                return;
            }
        }
        // Or a Flow handler?
        String errorMessageUser;
        Flow.Interview flo;
        try {
            flo = Flow.Interview.createInterview(null, handlerTypeName, new Map<String, Object> {
                    'Params' => messages
            });
            flo.start();
        } catch (Exception e) {
            String errorMessageSalesforce = e.getTypeName() + ' ' + e.getMessage() + ' ' + e.getCause() + ' ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, errorMessageSalesforce);
            errorMessageUser = 'Error processing request: ' + e.getMessage() + ' ' + e.getCause();
        }
        if (flo == null) {
            String noHandlerErrorMessage = 'Found no handler type for command "' + command + '". Contact your Salesforce administrator for assistance.';
            throw new IMI_Exception(noHandlerErrorMessage);
        }
    }

    // Execute in a future to ensure the sender won't receive a failure to do Salesforce-internal errors.
    //   e.g. processes which are triggered on this change/DML.
    @Future
    public static void runCommandFuture(String command, String messagesString) {
        List<Integration_Message_Incoming__c> messages = (List<Integration_Message_Incoming__c>) JSON.deserialize(messagesString, List<Integration_Message_Incoming__c>.class);
        runCommand(command, messages);
    }

    public static void runCommand(String command, List<Integration_Message_Incoming__c> messages) {
        String handlerTypeName = commandToHandlerTypeName.get(command);
        runHandler(command, handlerTypeName, messages);
    }
    
    public class IMI_Exception extends Exception {}
}
