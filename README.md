# salesforce-integration-message-incoming

A system integration design. Another system can opt-in to receiving error messages due to message application failure, or leave the error to the Salesforce admins.

## Context

Integrations of multiple systems usually occur across a network and consist of messages flowing between the systems to adjust their data in a certain desired way.

Integration concerns:

- Failed Message Delivery - This solution does **not** have a solution for messages from an external system which fail to reach the Salesforce system. It's expected that the external system itself verify delivery of a message and to re-send it if it fails.
- Duplicate Message Delivery - This solution does **not** have a solution for an external system which intends to send a single message but the Salesforce system receives that message twice. It's expected that the design of messages sent by the external system is such that duplicate application is acceptable.
- Mis-ordered Message Application - This solution does **not** _currently_ have a solution for an external system sending two messages in a certain order and the Salesforce system receiving them in a different order. This solution _currently_ is optimistic that this does not happen, or that the external systems design their messages in a way that message ordering is not significant.
- Message Application Failure - This solution supports either the external system or the Salesforce system to handle a message whose application to the Salesforce system failed due to reasons such as violation of a record's state machine, permissions violations, or other data constraints.
- (Please document other integration concerns here, and how this solution responds to them.)

## Design

An `Integration_Message_Incoming__c` record tracks the application of a change request to the Salesforce system. If the external system is interested in the result of the message, it can either (A) set the `Run_Async__c` property to "false" to be notified immediately of errors in its application, or (B) set the property to "true" and poll the status of that `Integration_Message_Incoming__c` item to ensure the `Processing_Stage__c` picklist field moves to the "Processed" state and that the `Execution_Error__c` text field is empty. It should take 1-3 seconds for this message to be processed asynchronously.

### Dev Guide

To add a new command:

- Add an appropriately named picklist item for the command to the `Integration_Message_Incoming__c.Command__c` field.
- Update the `Integration_Message_Handlers.commandToHandlerTypeName` Apex property to map this picklist item to the name of a program in the Salesforce org which is intended to apply the command to the org. A program can be:
  - An Apex class which implements the standard [`Callable`](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_interface_System_Callable.htm) interface and executes on the "run" action with a `List<Integration_Message_Incoming__c>` as a parameter named "Params".
  - A Flow which receives a collection of `Integration_Message_Incoming__c` records on the "Params" input variable.
- Update the `Integration_Message_Handlers.commandToArgType` Apex property to map the picklist item to the schema used for that command's argument, which is serialized in JSON format in the `Integration_Message_Incoming__c.Command_Argument__c` field.


### Admin Guide

Set up appropriate automation on the `Integration_Message_Incoming__c` object to ensure admins are notification of any records which have a non-empty `Integration_Message_Incoming__c.Execution_Error__c` field. Admins should decide an appropriate way to adjust the Salesforce system or data to ensure successful application of the error message and future ones like it.
