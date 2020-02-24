global with sharing class IMI_Create_Opportunity_Arg implements Callable {
    global IMI_Create_Opportunity_Arg() { }
    global IMI_Create_Opportunity_Arg(String opportunityExternalId, Opportunity opp) {
        this.opportunityExternalId = opportunityExternalId;
        this.opp = opp;
    }

    @AuraEnabled
    @InvocableVariable
    global String opportunityExternalId;

    @AuraEnabled
    @InvocableVariable
    global Opportunity opp;

    public static Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'validate' {
                IMI_Create_Opportunity_Arg arg = (IMI_Create_Opportunity_Arg) args.get('validate');
                List<String> errors = new List<String>();
                if (String.isBlank(arg.opportunityExternalId)) {
                    errors.add('The "opportunityExternalId" value is empty. This is a required argument');
                } else {
                    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE External_Id__c = :arg.opportunityExternalId];
                    if (opps == null || opps.isEmpty()) {
                        errors.add('No Opportunity has the specified "External ID" of "' + arg.opportunityExternalId + '"');
                    }
                }
                if (arg.opp == null) {
                    errors.add('"opp" value of "null" is invalid. This is a required argument');
                }

                if (!errors.isEmpty()) {
                    return new List<Object> { String.join(errors, ', '), new Map<String, Object>() };
                }
                return new List<Object> { null, arg };
            }
            when else {
                return null;
            }
        }
    }
}
