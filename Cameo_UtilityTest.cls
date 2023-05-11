/**
 * @description Tests for the Cameo_Utility class
 */
@isTest
public class Cameo_UtilityTest {
    /**
     * @description Tests the setOtherCountryToBlank method to ensure the field
     * is set to blank (no value).
     */
    @isTest
    private static void testSetOtherCountryToBlank() {
        Contact contact = new Contact(firstname = 'Test', lastname = 'Class');
        insert contact;

        Test.startTest();

        Cameo_Utility.setOtherCountryToBlank(contact.Id);

        Test.stopTest();

        System.assert(String.isBlank(contact.OtherCountry), 'OtherCountry should be blank');
    }

    /**
     * @description Tests when truncation is not needed
     */
    @isTest
    private static void testTruncateStringNoTruncation() {
        String testTruncation = 'test';

        Test.startTest();
        String result = Cameo_Utility.truncateString(testTruncation, 5);
        Test.stopTest();

        System.assertEquals(testTruncation, result, 'No truncation should be the same string');
    }

    /**
     * @description Tests when truncation is needed
     */
    @isTest
    private static void testTruncateStringTruncation() {
        String testTruncation = 'testing';

        Test.startTest();
        String result = Cameo_Utility.truncateString(testTruncation, 4);
        Test.stopTest();

        System.assertEquals('test', result, 'Truncation occurs string should be "test"');
    }

    /**
     * @description Test removing non digit characters with empty string
     */
    @isTest
    private static void testRemoveNonDigitCharactersEmptyString() {
        String testString = '';

        Test.startTest();
        String result = Cameo_Utility.removeNonDigitCharacters(testString);
        Test.stopTest();

        System.assertEquals('', result, 'Result should still be an empty string');
    }

    /**
     * @description Test removing non digit characters with a non empty string
     */
    @isTest
    private static void testRemoveNonDigitCharacters() {
        String testString = '1a2B3c4';

        Test.startTest();
        String result = Cameo_Utility.removeNonDigitCharacters(testString);
        Test.stopTest();

        System.assertEquals('1234', result, 'Result should be 1234');
    }

    /**
     * @description Test formating an empty phone number
     */
    @isTest
    private static void testFormatPhoneNumberEmpty() {
        String testString = '';

        Test.startTest();
        String result = Cameo_Utility.formatPhoneNumber(testString);
        Test.stopTest();

        System.assertEquals('', result, 'Result should be empty string');
    }

    /**
     * @description test formatting a phone number
     */
    @isTest
    private static void testFormatPhoneNumberDomestic() {
        String testString = '5554443333';

        Test.startTest();
        String result = Cameo_Utility.formatPhoneNumber(testString);
        Test.stopTest();

        System.assertEquals('(555) 444-3333', result, 'Result should be (555) 444-3333');
    }
    /*
     * @description test removing special characters
     */
    @isTest
    private static void testRemoveSpecialCharacters() {
        String testString = 'John1234';

        Test.startTest();
        String result = Cameo_Utility.removeSpecialCharacters(testString);
        Test.stopTest();

        System.assertEquals('John', result, 'Result does not match');
    }
    /**
     * @description Test formating an empty String
     */
    @isTest
    private static void testRemoveSpecialCharactersEmpty() {
        String testString = '';

        Test.startTest();
        String result = Cameo_Utility.removeSpecialCharacters(testString);
        Test.stopTest();

        System.assertEquals('', result, 'Result should be empty string');
    }

    /**
     * @description Test logACMNErrorTestSuccess
     */
    @isTest
    private static void logACMNErrorTestSuccess() {
        String className = 'test1';
        String errorMessage = 'test';
        String otherDetails = 'test2';
        String errorRecordType = MBMS_RecordTypeUtilities.getMBMSErrorRecordTypeId();

        Test.startTest();
        ACMN_Error_Log__c result = Cameo_Utility.logACMNError(
            className,
            errorMessage,
            otherDetails
        );
        Test.stopTest();

        ACMN_Error_Log__c error = [
            SELECT Id
            FROM ACMN_Error_Log__c
            WHERE RecordTypeId = :errorRecordType AND Class_Name__c = :className
        ];

        System.assertEquals(error.Id, result.Id, 'Result and error are not the same.');
    }

    /**
     * @description Test logACMNErrorTestFailure
     */
    @isTest
    private static void logACMNErrorTestFailure() {
        User user = MBMS_UtilityTest.createChatterUser();
        String className = 'test1';
        String errorMessage = 'test';
        String otherDetails = 'test2';
        String errorRecordType = MBMS_RecordTypeUtilities.getMBMSErrorRecordTypeId();
        ACMN_Error_Log__c result = new ACMN_Error_Log__c();
        Test.startTest();
        System.runAs(user) {
            result = Cameo_Utility.logACMNError(className, errorMessage, otherDetails);
        }
        Test.stopTest();

        System.assertEquals(result, null, 'Result should be null.');
    }

    /**
     * @description Test isSalesforceIdSuccess
     */
    @isTest
    private static void isSalesforceIdSuccess() {
        User user = MBMS_UtilityTest.createChatterUser();
        Test.startTest();
        Boolean idBoolean = Cameo_Utility.isSalesforceId(user.Id);
        Test.stopTest();

        System.assertEquals(true, idBoolean, 'Id is not a match.');
    }

    /**
     * @description Test isSalesforceIdFailure
     */
    @isTest
    private static void isSalesforceIdFailure() {
        Test.startTest();
        Boolean idBoolean = Cameo_Utility.isSalesforceId('asdsadsadsad');
        Test.stopTest();

        System.assertEquals(false, idBoolean, 'Id is a match.');
    }

    /**
     * @description Test getContactDetailsId where no ID should be returned
     */
    @isTest
    private static void testGetContactDetailsIdNoId() {
        Contact testContact = new Contact();
        testContact.FirstName = 'test';
        testContact.LastName = 'test';
        insert testContact;
        Test.startTest();
        String resultId = Cameo_Utility.getContactDetailsId(testContact.Id);
        Test.stopTest();

        System.assertEquals('', resultId, 'Id is not empty');
    }

    /**
     * @description Test getContactDetailsId where record should be returned
     */
    @isTest
    private static void testGetContactDetails() {
        Contact testContact = new Contact();
        testContact.FirstName = 'test';
        testContact.LastName = 'test';
        insert testContact;
        CARMA_Contact_Relationship__c carmaContact = new CARMA_Contact_Relationship__c();
        carmaContact.Related_Contact__c = testContact.Id;
        carmaContact.RecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
        insert carmaContact;
        Test.startTest();
        CARMA_Contact_Relationship__c result = Cameo_Utility.getContactDetails(testContact.Id);
        Test.stopTest();
        System.assert(result != null, 'result is not empty');
    }

    /**
     * @description Test getContactDetailsId where record should not be returned
     */
    @isTest
    private static void testGetContactDetailsNull() {
        Test.startTest();
        CARMA_Contact_Relationship__c result = Cameo_Utility.getContactDetails(null);
        Test.stopTest();
        System.assertEquals(null, result, 'result is not empty');
    }

    /**
     * @description Test getContactDetailsId where passed in value is blank
     */
    @isTest
    private static void testGetContactDetailsIdContactNull() {
        Test.startTest();
        String resultId = Cameo_Utility.getContactDetailsId(null);
        Test.stopTest();

        System.assertEquals('', resultId, 'Id is not empty');
    }

    /**
     * @description Test getContactDetailsId where an ID should be returned
     */
    @isTest
    private static void testGetContactDetailsIdHasId() {
        Contact testContact = new Contact();
        testContact.FirstName = 'test';
        testContact.LastName = 'test';
        insert testContact;
        CARMA_Contact_Relationship__c carmaContact = new CARMA_Contact_Relationship__c();
        carmaContact.Related_Contact__c = testContact.Id;
        carmaContact.RecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
        insert carmaContact;
        Test.startTest();
        String resultId = Cameo_Utility.getContactDetailsId(testContact.Id);
        Test.stopTest();

        System.assertEquals(carmaContact.Id, resultId, 'Id is not empty');
    }

    /**
     * @description Test constructDate success
     */
    private static void testConstructDateSuccess() {
        String inputDate = '1990-12-25';

        Test.startTest();

        Date returnValue = Cameo_Utility.constructDate(inputDate);

        Test.stopTest();

        System.assertNotEquals(null, returnValue, 'Expected return value to not be null.');
        System.assertEquals(12, returnValue.month(), 'Expected return value month to be 12');
        System.assertEquals(1990, returnValue.year(), 'Expected return value year to be 1990');
        System.assertEquals(25, returnValue.day(), 'Expected return value day to be 25');
    }

    /**
     * @description Test constructDate failure
     */
    private static void testConstructDateFailure() {
        String inputDate1 = '90-12-25';
        String inputDate2 = '1990-1-25';
        String inputDate3 = '1990-12-2';
        String inputDate4 = '';
        String inputDate5 = null;

        Test.startTest();

        Date returnValue1 = Cameo_Utility.constructDate(inputDate1);
        Date returnValue2 = Cameo_Utility.constructDate(inputDate2);
        Date returnValue3 = Cameo_Utility.constructDate(inputDate3);
        Date returnValue4 = Cameo_Utility.constructDate(inputDate4);
        Date returnValue5 = Cameo_Utility.constructDate(inputDate5);

        Test.stopTest();

        System.assertEquals(null, returnValue1, 'Expected return value 1 to be null.');
        System.assertEquals(null, returnValue2, 'Expected return value 2 to be null.');
        System.assertEquals(null, returnValue3, 'Expected return value 3 to be null.');
        System.assertEquals(null, returnValue4, 'Expected return value 4 to be null.');
        System.assertEquals(null, returnValue5, 'Expected return value 5 to be null.');
    }

    /**
     * @description Test getGroupDetails where Group object should be returned
     */
    @isTest
    private static void testGetGroupDetails() {
        String groupType = 'Queue';
        String groupName = 'MBMS_SchedulingSupervisorRequestsQueue';

        Test.startTest();
        Group result = Cameo_Utility.getGroupDetails(groupType, groupName);
        Test.stopTest();
        system.assertEquals(result.DeveloperName, groupName, 'Group names are same');
    }

    /**
     * @description Test getCaseDetails where MBMS_Case_Details__c object should be returned
     */
    @isTest
    private static void testGetCaseDetails() {
        MBMS_Case_Details__c testCaseDetail = new MBMS_Case_Details__c();
        insert testCaseDetail;

        Test.startTest();
        MBMS_Case_Details__c result = Cameo_Utility.getCaseDetails(testCaseDetail.Id);
        Test.stopTest();
        system.assertEquals(result.Id, testCaseDetail.Id, 'Id is not empty');
    }

    /**
     * @description Test getCaseDetails where MBMS_Case_Details__c object should be returned
     */
    @isTest
    private static void testCameoUserCreation() {
        Cameo_Utility setup = new Cameo_Utility();
        List<User> userList = setup.createCameoUser(1, 0, 'Scheduling Agent');
        List<User> userList1 = setup.createCameoUser(1, 1, 'Eligibility Analyst');
        List<User> userList2 = setup.createCameoUser(1, 2, 'Eligibility Supervisor');
        List<User> userList3 = setup.createCameoUser(1, 3, 'Scheduling Supervisor');
    }
}