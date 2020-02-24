@IsTest
private class Integration_Message_HandlersTest {
    @IsTest
    static void testIMI() {

        String createComments = 'Test Create Opp';
        
        Test.startTest();
        String oppExternalId = '123abc';
        Opportunity oppBefore = new Opportunity(
                Name = 'TestOpp',
                External_ID__c = oppExternalId,
                StageName = 'Draft',
                CloseDate = System.today().addMonths(1)
        );
        insert new Integration_Message_Incoming__c(
                Command__c = 'Create_Opportunity',
                Command_Argument__c = JSON.serialize(new IMI_Create_Opportunity_Arg(oppExternalId, oppBefore))
        );
        Test.stopTest();

        Opportunity oppAfter = [SELECT Id, Name FROM Opportunity WHERE External_ID__c = :oppExternalId];
        System.assertEquals(1, oppAfter.size());
    }

}
