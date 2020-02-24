trigger Integration_Message_Incoming on Integration_Message_Incoming__c (after insert) {
    // Bulkify the implementation of commands.
    Map<String, List<String>> commandToArguments = new Map<String, List<String>>();
    Map<String, List<Integration_Message_Incoming__c>> commandToMessages = new Map<String, List<Integration_Message_Incoming__c>>();
    for (Integration_Message_Incoming__c message : Trigger.new) {
        List<Integration_Message_Incoming__c> commandArgs = commandToMessages.get(message.Command__c);
        if (commandArgs == null) {
            commandArgs = new List<Integration_Message_Incoming__c>();
        }
        commandArgs.add(message);
        commandToMessages.put(message.Command__c, commandArgs);
    }
    // Execute the commands.
    Map<String, Map<Id, String>> commandToMessageIdToErrors = new Map<String, Map<Id, String>>();
    for (String command : commandToMessages.keySet()) {
        Map<Id, String> messageIdToError = new Map<Id, String>();
        messageIdToError = Integration_Message_Handlers.handleCommand(command, commandToMessages.get(command));
        if (messageIdToError != null) {
            commandToMessageIdToErrors.put(command, messageIdToError);
        }
    }
    // Put errors onto the records.
    for (Integration_Message_Incoming__c message : Trigger.new) {
        if (!commandToMessageIdToErrors.containsKey(message.Command__c)) {
            continue;
        }
        Map<Id, String> messageIdToError = commandToMessageIdToErrors.get(message.Command__c);
        if (!messageIdToError.containsKey(message.Id)) {
            continue;
        }
        // Add the message format error to the record to send back to the caller.
        message.addError(messageIdToError.get(message.Id));
    }
}
