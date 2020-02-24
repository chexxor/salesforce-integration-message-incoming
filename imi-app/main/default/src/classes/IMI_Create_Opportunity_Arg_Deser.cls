global with sharing class IMI_Create_Opportunity_Arg_Deser {

    @InvocableMethod(
        Label='Deserialize a IMI_Create_Opportunity_Arg value from a String.'
    )
    global static List<IMI_Create_Opportunity_Arg> invoke(List<String> strings) {
        List<IMI_Create_Opportunity_Arg> args = new List<IMI_Create_Opportunity_Arg>();
        for (String s : strings) {
            args.add((IMI_Create_Opportunity_Arg)JSON.deserialize(s, IMI_Create_Opportunity_Arg.class));
        }
        return args;
    }
}
