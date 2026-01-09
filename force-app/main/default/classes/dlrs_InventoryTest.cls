/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_InventoryTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_InventoryTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Inventory__c());
    }
}