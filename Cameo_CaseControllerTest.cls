/**
 * @description Tests for the Cameo_CaseControllerTest class.
 */
@isTest
private class Cameo_CaseControllerTest {
    /**
     * @description Test setup to insert MBMS settings.
     */
    @testSetup
    private static void setup() {
        MBMS_UtilityTest.insertMbmsSettings();
        Cameo_Utility setup = new Cameo_Utility();
        List<User> userList = setup.createCameoUser(1, 0, 'Scheduling Agent');
        userList.addAll(setup.createCameoUser(1, 1, 'Eligibility Analyst'));
        userList.addAll(setup.createCameoUser(1, 2, 'Eligibility Supervisor'));
    }

    /**
     * @description Testing the create case method returns a case. Successfull.
     */
    @isTest
    private static void createCaseSuccessTest() {
        Test.startTest();

        Case caseRecord = Cameo_CaseController.createCaseRecord();

        Test.stopTest();

        System.assertNotEquals(null, caseRecord.id, 'Case record id returned should not be null');

        Case caseFound = [SELECT Id FROM Case WHERE Case.Id = :caseRecord.id];

        System.assertNotEquals(null, caseFound, 'Case returned should not be null');
    }

    /**
     * @description Testing the create case method returns null since it is run from a user who doesnt have permission. Failure.
     */
    @isTest
    private static void createCaseFailureTest() {
        User userChatterFree = MBMS_UtilityTest.createChatterUser();

        System.runAs(userChatterFree) {
            Test.startTest();

            Case caseRecord = Cameo_CaseController.createCaseRecord();

            Test.stopTest();

            System.assertEquals(null, caseRecord.id, 'Case record id returned should be null');
        }
    }

    /**
     * @description Testing the generate boss id works. Failure.
     */
    @isTest
    private static void generateBOSSIdFailTest() {
        Test.setMock(HttpCalloutMock.class, Cameo_ApiDecedentGatewayMock.createFailureIdMock());

        Test.startTest();

        String bossId = Cameo_CaseController.generateBossId();

        Test.stopTest();

        System.assertEquals(null, bossId, 'Boss id returned should be null');
    }

    /**
     * @description Testing the generate boss id works. Success.
     */
    @isTest
    private static void generateBOSSIdSuccessTest() {
        Test.setMock(HttpCalloutMock.class, Cameo_ApiDecedentGatewayMock.createSuccessfulIdMock());

        Test.startTest();

        String bossId = Cameo_CaseController.generateBossId();

        Test.stopTest();

        System.assertNotEquals(null, bossId, 'Boss id returned should not be null');
    }

    /**
     * @description Testing the get Case Detail History method with no History records.
     */
    @isTest
    private static void getCaseDetailHistoryEmptyTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        update caseDetails;

        List<MBMS_Case_Details__History> historyList = new List<MBMS_Case_Details__History>();
        MBMS_Case_Details__History historyOne = new MBMS_Case_Details__History(
            Field = 'Case_Status__c'
        );
        historyList.add(historyOne);

        Test.startTest();
        List<Cameo_CaseController.CaseDetailsHistoryTracking> histories = Cameo_CaseController.getCaseDetailHistory(
            caseDetails.Id
        );
        List<Cameo_CaseController.CaseDetailsHistoryTracking> fakseHistories = Cameo_CaseController.processHistoryList(
            historyList
        );
        Test.stopTest();

        System.assertEquals(0, histories.size(), 'Returned list of histories size should be 0');
        System.assertEquals('Case Status', fakseHistories.get(0).Field);
        System.assertEquals(null, fakseHistories.get(0).LabelName);
    }

    /**
     * @description Testing the processHistoryList method with a History record.
     * Tried updating a Case Details record but since none of the data is actually committed
     * during a Unit Test, it is not possible to fully unit test Field History Tracking
     */
    @isTest
    private static void processHistoryListTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        List<Cameo_CaseController.CaseDetailsHistoryTracking> historyWrapper;
        Test.startTest();
        System.runAs(user) {
            List<MBMS_Case_Details__History> historyList = new List<MBMS_Case_Details__History>();
            caseDetails.Case_Status__c = 'CE';
            update caseDetails;
            caseDetails.Case_Status__c = 'EL';
            update caseDetails;
            MBMS_Case_Details__History historyOne = new MBMS_Case_Details__History(
                Field = 'Case_Status__c',
                ParentId = caseDetails.Id
            );
            historyList.add(historyOne);
            historyWrapper = Cameo_CaseController.processHistoryList(historyList);
        }
        Test.stopTest();
        System.assertEquals(1, historyWrapper.size(), 'List of historyWrapper size should be 1');
    }

    /**
     * @description Testing the searchDecedent method
     */
    @isTest
    private static void searchDecedentTestMixtureBOSS() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '6506514'
        );
        MBMS_Case_Details__c caseDetailsTwo = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '1231231'
        );
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createSuccessfulSearchMock()
        );

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'JON' }
        );

        Test.stopTest();

        Cameo_CaseSearchController.SearchResult sr = (Cameo_CaseSearchController.SearchResult) wrapper.results1[0];
        System.assertEquals('JON', sr.firstName, 'Expecting the first name of the single result');
        System.assert(sr.showDisabled, 'Expecting the showDisabled field to be false');
    }

    /**
     * @description Testing the searchDecedent method
     */
    @isTest
    private static void searchDecedentTestMixtureEOAS() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '6506514'
        );
        MBMS_Case_Details__c caseDetailsTwo = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '1231231'
        );
        Test.setMock(HttpCalloutMock.class, Cameo_ApiEoasGatewayMock.createSuccessfulSearchMock());

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'JON' }
        );

        Test.stopTest();

        Cameo_CaseSearchController.SearchResult sr = (Cameo_CaseSearchController.SearchResult) wrapper.results1[0];
        System.assertEquals('JON', sr.firstName, 'Expecting the first name of the single result');
        System.assert(sr.showDisabled, 'Expecting the showDisabled field to be false');
    }

    /**
     * @description Testing the searchDecedent method
     */
    @isTest
    private static void searchDecedentTestNoResults() {
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createSuccessfulSearchMockWithNoResults()
        );

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'NoResults' }
        );

        Test.stopTest();

        List<Cameo_CaseSearchController.SearchResult> sr = (List<Cameo_CaseSearchController.SearchResult>) wrapper.results1;
        System.assertEquals(0, sr.size(), 'Expecting 0 results');
    }

    /**
     * @description Testing the searchDecedent method
     */
    @isTest
    private static void searchDecedentTestFailure() {
        Test.setMock(HttpCalloutMock.class, Cameo_ApiDecedentGatewayMock.createFailureSearchMock());

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'NoResults' }
        );

        Test.stopTest();

        List<Cameo_CaseSearchController.SearchResult> sr = (List<Cameo_CaseSearchController.SearchResult>) wrapper.results1;
        System.assertEquals(0, sr.size(), 'Expecting 0 results');
    }

    /**
     * @description Testing the searchPreviousDecedent method
     */
    @isTest
    private static void searchPreviousDecedentNoResults() {
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createSuccessfulSearchMockWithNoResults()
        );

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchPreviousDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'NoResults' }
        );

        Test.stopTest();

        List<Cameo_CaseSearchController.SearchResult> sr = (List<Cameo_CaseSearchController.SearchResult>) wrapper.results1;
        System.assertEquals(0, sr.size(), 'Expecting 0 results');
    }

    /**
     * @description Testing the searchPreviousDecedent method
     */
    @isTest
    private static void searchPreviousDecedentFailure() {
        Test.setMock(HttpCalloutMock.class, Cameo_ApiDecedentGatewayMock.createFailureSearchMock());

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchPreviousDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'NoResults' }
        );

        Test.stopTest();

        List<Cameo_CaseSearchController.SearchResult> sr = (List<Cameo_CaseSearchController.SearchResult>) wrapper.results1;
        System.assertEquals(0, sr.size(), 'Expecting 0 results');
    }

    /**
     * @description Testing the searchPreviousDecedent method
     */
    @isTest
    private static void searchPreviousDecedentMixureBOSS() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '6506514'
        );
        MBMS_Case_Details__c caseDetailsTwo = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '1231231'
        );
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createSuccessfulSearchMock()
        );

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchPreviousDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'JON' }
        );

        Test.stopTest();

        Cameo_CaseSearchController.SearchResult sr = (Cameo_CaseSearchController.SearchResult) wrapper.results1[0];
        System.assertEquals('JON', sr.firstName, 'Expecting the first name of the single result');
        System.assert(!sr.showDisabled, 'Expecting the showDisabled field to be true');
    }

    /**
     * @description Testing the searchPreviousDecedent method
     */
    @isTest
    private static void searchPreviousDecedentMixureEOAS() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '6506514'
        );
        MBMS_Case_Details__c caseDetailsTwo = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '1231231'
        );
        Test.setMock(HttpCalloutMock.class, Cameo_ApiEoasGatewayMock.createSuccessfulSearchMock());

        Test.startTest();

        Cameo_SearchResultsWrapper wrapper = Cameo_CaseController.searchPreviousDecedent(
            new Map<String, String>{ 'cemeteryPageModalFirstName' => 'JON' }
        );

        Test.stopTest();

        Cameo_CaseSearchController.SearchResult sr = (Cameo_CaseSearchController.SearchResult) wrapper.results1[0];
        System.assertEquals('JON', sr.firstName, 'Expecting the first name of the single result');
        System.assert(!sr.showDisabled, 'Expecting the showDisabled field to be true');
    }

    /**
     * @description Testing the get case status works. Success.
     */
    @isTest
    private static void getCaseStatusSuccessTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        caseDetails.Case_Status__c = 'NV';
        update caseDetails;

        Test.startTest();

        String caseStatus = Cameo_CaseController.getCaseStatus(caseDetails.Id);

        Test.stopTest();
        System.assertEquals('CE', caseStatus, 'The case status returned should be CE');
    }

    /**
     * @description Testing the get case status works. Failure.
     */
    @isTest
    private static void getCaseStatusFailureTest() {
        String caseDetailsId = null;

        Test.startTest();

        String caseStatus = Cameo_CaseController.getCaseStatus(caseDetailsId);

        Test.stopTest();
        System.assertEquals(null, caseStatus, 'The case status returned should be null');
    }

    /**
     * @description Test valid case migration
     */
    @isTest
    public static void testValidCaseMigration() {
        MBMS_Case_Details__c caseDetails = Cameo_CaseMigrationServiceTest.generateFullCaseDetails();
        Test.setMock(
            HttpCalloutMock.class,
            cameo_apiDecedentGatewayMock.createSuccessfulMigrateDecedentCasetoLegacyMock()
        );

        Test.startTest();
        Cameo_CaseMigrationService.DecedentCaseMigrationResultsWrapper results = Cameo_CaseController.migrateDecedentCase(
            caseDetails.Id
        );
        Test.stopTest();

        System.assert(!results.hasError, 'Should not have any errors');
        System.assert(results.results.valid, 'Should be valid');
        System.assertEquals(201, results.statusCode, 'Status code should be 201');
    }

    /**
     * Test method for getDecedentDetailsSuccess
     */
    @isTest
    private static void testGetDecedentDetailsSuccess() {
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createSuccessDecedentDetailsMock()
        );

        Test.startTest();

        String details = Cameo_CaseController.getMoreDecedentInfo('123456');

        Test.stopTest();

        System.assertNotEquals('', details, 'Response for decedent details was not correct.');
    }

    /**
     * Test method for getDecedentDetailsFailure
     */
    @isTest
    private static void testGetDecedentDetailsFailure() {
        Test.setMock(
            HttpCalloutMock.class,
            Cameo_ApiDecedentGatewayMock.createFailureDecedentDetailsMock()
        );

        Test.startTest();

        String details = Cameo_CaseController.getMoreDecedentInfo('123456');

        Test.stopTest();
        System.assertEquals('', details, 'Response for decedent details was not correct.');
    }

    /**
     * Test method for getDecedentDetailsFailure
     */
    @isTest
    private static void testGetDecedentDetailsFailureTwo() {
        Test.setMock(
            HttpCalloutMock.class,
            cameo_apiDecedentGatewayMock.createFailureDecedentDetailsMock()
        );

        Test.startTest();

        String details = Cameo_CaseController.getMoreDecedentInfo(null);

        Test.stopTest();

        System.assertEquals('', details, 'Response for decedent details was not correct.');
    }

    /**
     * Test method for captureCurrentScreen and getCurrentScreen.
     */
    @isTest
    public static void testGetAndSetCurrentScreenNumber() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
            'JON',
            'SMITH',
            '6506514'
        );
        Test.startTest();
        Cameo_CaseController.captureCurrentScreen(caseDetails.Id, 3);
        String screenNum = Cameo_CaseController.getCurrentScreen(caseDetails.Id);
        Test.stopTest();
        System.assertEquals('3', screenNum);
        MBMS_Case_Details__c caseDetailsResult = [
            SELECT Id, MBMS_LatestCaseEstablishmentStep__c
            FROM MBMS_Case_Details__c
            WHERE Id = :caseDetails.Id
        ];
        System.assertEquals('3', caseDetailsResult.MBMS_LatestCaseEstablishmentStep__c);
    }

    /**
     * Test method for captureCurrentScreen and getCurrentScreen with no screen value
     */
    @isTest
    public static void testGetAndSetInvalidCurrentScreenNumber() {
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        MBMS_Case_Details__c caseDetailsResult;
        String screenNum;
        Test.startTest();
        System.runAs(user) {
            MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetailsWithName(
                'JON',
                'SMITH',
                '6506514'
            );
            caseDetails.MBMS_LatestCaseEstablishmentStep__c = '';
            update caseDetails;
            screenNum = Cameo_CaseController.getCurrentScreen(caseDetails.Id);
            Cameo_CaseController.captureCurrentScreen(caseDetails.Id, 3);

            caseDetailsResult = [
                SELECT Id, MBMS_LatestCaseEstablishmentStep__c
                FROM MBMS_Case_Details__c
                WHERE Id = :caseDetails.Id
            ];
        }
        Test.stopTest();
        System.assertEquals('0', screenNum, 'Last step should default to 0');
        System.assertEquals(
            '3',
            caseDetailsResult.MBMS_LatestCaseEstablishmentStep__c,
            'Last step should update to 3'
        );
    }

    /**
     * @description Testing the fetchCaseDetails method (Success)
     */
    @isTest
    private static void fetchCaseDetailsTestSuccess() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        Contact veteran = MBMS_UtilityTest.createVetRecord();
        caseDetails.MBMS_Veteran__c = veteran.Id;
        update caseDetails;
        String caseDetailsId = caseDetails.Id;
        Test.startTest();

        Cameo_CaseController.ReturnWrapper result = Cameo_CaseController.fetchCaseDetails(
            caseDetailsId
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Only one case record should be returned');
    }

    /**
     * @description Testing the fetchCaseDetails method (No Results)
     */
    @isTest
    private static void fetchCaseDetailsTestNoReults() {
        String caseDetailsId = 'test';
        Test.startTest();

        Cameo_CaseController.ReturnWrapper result = Cameo_CaseController.fetchCaseDetails(
            caseDetailsId
        );

        Test.stopTest();

        System.assertEquals(null, result, 'No case record should be returned');
    }

    /**
     * @description Testing the On Case Reactivation Workflow Rule
     */
    @isTest
    private static void testCaseStatusWorkfowRule() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        caseDetails.Case_Status__c = 'CA';
        update caseDetails;

        Test.startTest();
        caseDetails.Case_Status__c = 'EL';
        update caseDetails;
        Test.stopTest();

        MBMS_Case_Details__c caseDetailsResult = [
            SELECT Id, Reactivation_Date_and_Time__c, MBMS_Remarks__c
            FROM MBMS_Case_Details__c
            WHERE Id = :caseDetails.Id
        ];
        System.assertEquals(
            caseDetailsResult.MBMS_Remarks__c,
            String.valueOf(caseDetailsResult.Reactivation_Date_and_Time__c),
            'Workflow rule should have updated the remarks field.'
        );
    }

    /**
     * @description Testing the Validation Rule Case_Status_Change_Comments
     */
    @isTest
    private static void testCaseStatusValidationRule() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();

        cf_Case_Status_Reason__c case_status = new cf_Case_Status_Reason__c();
        case_status.Comment_Required__c = true;
        case_status.Name = 'Cancel Reason: Other';
        case_status.New_Status_Code__c = 'CA';
        insert case_status;

        Test.startTest();
        caseDetails.Status_Update_Reason__c = case_status.Id;
        caseDetails.Status_Update_Comment__c = '';
        try {
            update caseDetails;
        } catch (Exception e) {
            System.Assert(
                e.getMessage()
                    .contains(
                        'Comments are required when selecting this Case Status Reason change.'
                    ),
                'Validation rule should have been encountered.'
            );
        }
        Test.stopTest();
    }

    /**
     * @description Testing the Validation Rule  Status_Comment_Updated
     */
    @isTest
    private static void StatusUpdateReasonandCommentValidationRuleTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();

        Test.startTest();
        caseDetails.Status_Update_Comment__c = 'Test';
        try {
            update caseDetails;
        } catch (Exception e) {
            System.Assert(
                e.getMessage()
                    .contains(
                        'Status Update Reason cannot be blank if Status Update Comment is entered.'
                    ),
                'Validation rule should have been encountered.'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Testing the getDecedentDates method return NULL Dates
     */
    @isTest
    private static void testGetDecedentDatesReturnNullDates() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        String caseDetailsId = caseDetails.Id;

        Test.startTest();

        List<Date> result = Cameo_CaseController.getDecedentDates(caseDetailsId);

        Test.stopTest();

        System.assertEquals(result[0], null, 'Null Dates');
    }

    /**
     * @description Testing the getDecedentDates method return ModifiedBirthDate
     */
    @isTest
    private static void testGetDecedentDatesReturnWithModifiedBirthDate() {
        Contact veteren = new Contact(
            FirstName = 'first',
            MiddleName = 'middle',
            LastName = 'last',
            Birthdate = Date.newInstance(1970, 2, 17)
        );
        insert veteren;

        String carmaContactRecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
        CARMA_Contact_Relationship__c decedentModifiedDetails = new CARMA_Contact_Relationship__c(
            Date_of_Birth__c = Date.newInstance(1990, 2, 17),
            Related_Contact__c = veteren.Id,
            RecordTypeId = carmaContactRecordTypeId
        );
        insert decedentModifiedDetails;

        MBMS_Case_Details__c caseDetails = new MBMS_Case_Details__c();
        caseDetails.MBMS_Veteran__c = veteren.Id;
        caseDetails.MBMS_Decedent_Detail__c = decedentModifiedDetails.Id;
        insert caseDetails;

        String caseDetailsId = caseDetails.Id;
        Date expectedRes = Date.newInstance(1990, 2, 17);

        Test.startTest();

        List<Date> result = Cameo_CaseController.getDecedentDates(caseDetailsId);

        Test.stopTest();

        System.assertEquals(result[0], expectedRes, 'Dates Matched succesfully');
    }

    /**
     * @description Testing the getDecedentDates method return Birthdate
     */
    @isTest
    private static void testGetDecedentDatesReturnWithoutModifiedBirthDate() {
        Contact veteren = new Contact(
            FirstName = 'first',
            MiddleName = 'middle',
            LastName = 'last',
            Birthdate = Date.newInstance(1970, 2, 17)
        );
        insert veteren;

        String carmaContactRecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
        CARMA_Contact_Relationship__c decedentModifiedDetails = new CARMA_Contact_Relationship__c(
            Address_City__c = 'Atlanta',
            Related_Contact__c = veteren.Id,
            RecordTypeId = carmaContactRecordTypeId
        );
        insert decedentModifiedDetails;

        MBMS_Case_Details__c caseDetails = new MBMS_Case_Details__c();
        caseDetails.MBMS_Veteran__c = veteren.Id;
        caseDetails.MBMS_Decedent_Detail__c = decedentModifiedDetails.Id;
        insert caseDetails;

        String caseDetailsId = caseDetails.Id;
        Date expectedRes = Date.newInstance(1970, 2, 17);

        Test.startTest();

        List<Date> result = Cameo_CaseController.getDecedentDates(caseDetailsId);

        Test.stopTest();

        System.assertEquals(result[0], expectedRes, 'Dates Matched succesfully');
    }

    /**
     * @description Testing the getDecedentDates method return without modified fields
     */
    @isTest
    private static void testGetDecedentDatesReturnWithoutModifiedFields() {
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        List<Date> result;
        Test.startTest();
        System.runAs(user) {
            Contact veteren = new Contact(
                FirstName = 'first',
                MiddleName = 'middle',
                LastName = 'last',
                Birthdate = Date.newInstance(1970, 2, 17)
            );
            insert veteren;
            MBMS_Case_Details__c caseDetails = new MBMS_Case_Details__c();
            caseDetails.MBMS_Veteran__c = veteren.Id;
            MBMS_UtilityTest.createMilitaryServiceWithWarPeriods(veteren.Id);
            insert caseDetails;
            String caseDetailsId = caseDetails.Id;
            result = Cameo_CaseController.getDecedentDates(caseDetailsId);
        }
        Test.stopTest();
        System.assertEquals(2, result.size(), 'Should return 2 dates, birthdate and EOD date');
    }

    /**
     * @description Testing the getDecedentDates method with fake case Id
     */
    @isTest
    private static void testGetDecedentDatesWithInvalidCaseId() {
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        List<Date> result;
        Test.startTest();
        System.runAs(user) {
            result = Cameo_CaseController.getDecedentDates('1');
        }
        Test.stopTest();
        System.assertEquals(null, result, 'Null list should be returned');
    }

    /**
     * @description Testing the Validation Rule  Status_Update_Reason_Not_Blank
     */
    @isTest
    private static void StatusUpdateReasonValidationRuleTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();

        cf_Case_Status_Reason__c objCSR = new cf_Case_Status_Reason__c();
        objCSR.Name = 'Cancel Reason Testing';
        insert objCSR;

        Test.startTest();
        caseDetails.Status_Update_Reason__c = objCSR.Id;
        caseDetails.Status_Update_Comment__c = 'testing comment';
        try {
            update caseDetails;
            caseDetails.Status_Update_Comment__c = '';
            caseDetails.Status_Update_Reason__c = null;
            update caseDetails;
        } catch (Exception e) {
            System.Assert(
                e.getMessage().contains('Complete this field.'),
                'Validation rule should have been encountered.'
            );
        }

        Test.stopTest();
    }
    /**
     * @description Testing the getCemeteryDetails method with null value
     */
    @isTest
    private static void getCemeteryDetailsNoResultsTest() {
        String cemeteryId = '';
        Test.startTest();
        String result = Cameo_CaseController.getCemeteryDetailsId(cemeteryId);
        Test.stopTest();
        System.assertEquals(null, result, 'No cemetery record should be returned');
    }
    /**
     * @description Testing the getCemeteryDetails method with cemeteryId value
     */
    @isTest
    private static void getCemeteryDetailsTest() {
        Account acc = new Account();
        acc.Name = 'Test Account for Cemetry';
        acc.RecordTypeId = MBMS_RecordTypeUtilities.getAccountRecordTypeId(
            'WH_VA_Call_Center_Veteran'
        );
        insert acc;
        CERRT_Cemetery_Detail__c cemObj = new CERRT_Cemetery_Detail__c(Cemetery_Lookup__c = acc.Id);
        insert cemObj;
        String CemeteryId = acc.id;
        Test.startTest();
        String result = Cameo_CaseController.getCemeteryDetailsId(CemeteryId);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Only one case record should be returned');
    }

    /**
     * @description Testing the getCemeteryDetails method with exception thrown
     */
    @isTest
    private static void getCemeteryDetailsExceptionTest() {
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User usr = new User(
            LastName = 'notMBMS',
            FirstName = 'notMBMS',
            Alias = 'fnotMBMS',
            Email = 'f.notMBMS@notMBMS.com',
            Username = 'f.notMBMS@notMBMS.com',
            ProfileId = profileId.id,
            FederationIdentifier = 'f.notMBMS@notMBMS.com',
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US'
        );
        insert usr;
        Account acc = new Account();
        acc.Name = 'Test Account for Cemetry';
        acc.RecordTypeId = MBMS_RecordTypeUtilities.getAccountRecordTypeId(
            'WH_VA_Call_Center_Veteran'
        );
        insert acc;
        CERRT_Cemetery_Detail__c cemObj = new CERRT_Cemetery_Detail__c(Cemetery_Lookup__c = acc.Id);
        insert cemObj;
        String CemeteryId = acc.id;
        Test.startTest();
        System.runAs(usr) {
            try {
                String result = Cameo_CaseController.getCemeteryDetailsId(CemeteryId);
            } catch (AuraHandledException e) {
                System.assertEquals(
                    'Script-thrown exception',
                    e.getMessage(),
                    'Should have Script-thrown exception.'
                );
            }
        }

        Test.stopTest();
    }

    /**
     * @description Testing the validateLoggedInUser method as Scheduling User.
     */
    @isTest
    private static void validateLoggedInUserTest() {
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        Test.startTest();
        System.runAs(user) {
            Cameo_CaseController.validateLoggedInUser();
        }
        Test.stopTest();
    }

    /**
     * @description Testing the saveSummaryChanges method when a Scheduling Agent
     *              updates values in CE while the Case is in the Eligibility Queue
     */
    @isTest
    private static void saveSummaryChangesInEligibilityWithNCSOAgentTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        caseDetails.OwnerId = [SELECT Id FROM Group WHERE Name = 'Eligibility Requests Queue'].Id;
        caseDetails.EligibilityReviewStatus__c = 'New';
        caseDetails.Case_Status__c = 'EL';
        Test.startTest();
        System.runAs(user) {
            update caseDetails;
            caseDetails.MBMS_Remains_Type__c = 'C';
            caseDetails.MBMS_Burial_Activity_Type__c = 'I';
            update caseDetails;
            String changedFieldNames = 'MBMS_Remains_Type__c;MBMS_Burial_Activity_Type__c';
            Cameo_CaseController.saveSummaryChanges(changedFieldNames, caseDetails.Id);
        }
        Test.stopTest();
        Task testTask = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :user.Id LIMIT 1];
        System.assertEquals(user.id, testTask.OwnerId, 'Task should be created and owned by user');
    }

    /**
     * @description Testing the saveSummaryChanges method when a Scheduling Agent
     *              updates values in CE while the Case is NOT in the Eligibility Queue
     */
    @isTest
    private static void saveSummaryChangesNotInEligibilityWithNCSOAgentTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        caseDetails.OwnerId = user.Id;
        caseDetails.Case_Status__c = 'CE';
        Test.startTest();
        System.runAs(user) {
            update caseDetails;
            caseDetails.MBMS_Remains_Type__c = 'C';
            caseDetails.MBMS_Burial_Activity_Type__c = 'I';
            caseDetails.EligibilityReviewStatus__c = '';
            update caseDetails;
            String changedFieldNames = 'MBMS_Remains_Type__c;MBMS_Burial_Activity_Type__c';
            Cameo_CaseController.saveSummaryChanges(changedFieldNames, caseDetails.Id);
        }
        Test.stopTest();
        List<Task> testTask = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :user.Id];
        System.assertEquals(0, testTask.size(), 'Task should not be created');
    }

    /**
     * @description Testing the saveSummaryChanges method with fake case Id
     */
    @isTest
    private static void saveSummaryChangesWithInvalidCaseId() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        User user = Cameo_Utility.getUser('testCameoFirstName0', 'testCameoLastName0');
        caseDetails.OwnerId = user.Id;
        caseDetails.Case_Status__c = 'CE';
        Test.startTest();
        System.runAs(user) {
            update caseDetails;
            caseDetails.MBMS_Remains_Type__c = 'C';
            caseDetails.MBMS_Burial_Activity_Type__c = 'I';
            update caseDetails;
            String changedFieldNames = 'MBMS_Remains_Type__c;MBMS_Burial_Activity_Type__c';
            Cameo_CaseController.saveSummaryChanges(changedFieldNames, '1');
        }
        Test.stopTest();
        List<Task> testTask = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :user.Id];
        System.assertEquals(0, testTask.size(), 'Task should not be created');
    }

    /**
     * @description Testing the saveSummaryChanges method when an Eligibility Analyst(formerly 'Eligibility Agent')
     *              updates values in CE
     */
    @isTest
    private static void saveSummaryChangesAsEligibilityTest() {
        MBMS_Case_Details__c caseDetails = MBMS_UtilityTest.createCaseDetails();
        User elAgentUser = Cameo_Utility.getUser('testCameoFirstName1', 'testCameoLastName1');
        User elSupervisorUser = Cameo_Utility.getUser('testCameoFirstName2', 'testCameoLastName2');
        System.runAs(elSupervisorUser) {
            caseDetails.OwnerId = [SELECT Id FROM Group WHERE Name = 'Eligibility Requests Queue']
            .Id;
            caseDetails.EligibilityReviewStatus__c = 'New';
            caseDetails.Case_Status__c = 'EL';
            update caseDetails;
        }
        Test.startTest();
        System.runAs(elAgentUser) {
            caseDetails.MBMS_Remains_Type__c = 'C';
            caseDetails.MBMS_Burial_Activity_Type__c = 'I';
            update caseDetails;
            String changedFieldNames = 'MBMS_Remains_Type__c;MBMS_Burial_Activity_Type__c';
            Cameo_CaseController.saveSummaryChanges(changedFieldNames, caseDetails.Id);
        }
        Test.stopTest();
        List<Task> testTask = [SELECT Id, OwnerId FROM Task WHERE OwnerId = :elAgentUser.Id];
        System.assertEquals(0, testTask.size(), 'Task should not be created');
    }
}