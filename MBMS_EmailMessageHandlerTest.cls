/**
 * Tests for the MBMS_EmailMessageHandler class.
 */
@isTest
private class MBMS_EmailMessageHandlerTest {
    /**
     * @description Test data setup method.
     */
    @testSetup
    private static void setup() {
        Cameo_Utility setup = new Cameo_Utility();
        List<User> userList = setup.createCameoUser(1, 0, 'Eligibility Analyst');
    }

    @isTest
    private static void testDeleteEmail() {
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');

        Test.startTest();
        System.runAs(user) {
            EmailMessage email = MBMS_UtilityTest.createEmailMessageWithSender(user);
            try {
                delete email;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = (e.getMessage()
                        .contains('Email cannot be deleted.'))
                    ? true
                    : false;
                System.AssertEquals(true, expectedExceptionThrown, e.getMessage());
            }
        }

        Test.stopTest();

        List<EmailMessage> emailQuery = [
            SELECT Id
            FROM EmailMessage
            WHERE FromAddress = :user.email
        ];

        System.assertEquals(1, emailQuery.size(), 'Email should not be deleted.');
    }

    @isTest
    private static void testDisableTriggersFlag() {
        String uniqueStr = DateTime.now().format('YYYMMDDhhmmss');

        // Create PermissionSet with Custom Permission and assign it to the User.
        PermissionSet ps = new PermissionSet(
            Name = 'Disable_Triggers_Flag_PS_' + uniqueStr,
            Label = 'Disable_Triggers_Flag_PS'
        );
        insert ps;

        List<CustomPermission> permissions = [
            SELECT Id
            FROM CustomPermission
            WHERE DeveloperName = :MBMS_Permissions.DISABLE_TRIGGER_FLAG
        ];

        System.assertEquals(1, permissions.size());

        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = permissions[0].Id
        );
        insert sea;

        Profile p = [SELECT Id, Name FROM Profile WHERE Name LIKE 'Standard User'];

        User u = new User(
            Alias = 'standt',
            Email = 'stduser' + ps.name + '@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Permission',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            FederationIdentifier = 'ad_' + ps.name + '@testorg.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'ad_' + ps.name + '@testorg.com'
        );
        insert u;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        Test.startTest();

        System.runAs(u) {
            EmailMessage email = MBMS_UtilityTest.createEmailMessageWithSender(u);
            delete email;
        }
        Test.stopTest();
        List<EmailMessage> emailQuery = [SELECT Id FROM EmailMessage WHERE FromAddress = :u.email];

        System.assertEquals(0, emailQuery.size(), 'Email should  be deleted.');
    }
}