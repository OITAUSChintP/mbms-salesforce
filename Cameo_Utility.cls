/**
 * @description A general utility class for the MBMS CaMEO application.
 */
public with sharing class Cameo_Utility {
    /**
     * @description This method sets OtherCountry on the OtherAddress field to "blank".
     *
     * @param contactId Contact ID
     */
    @AuraEnabled
    public static void setOtherCountryToBlank(String contactId) {
        Contact[] contacts = [
            SELECT OtherCountry
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED
        ];
        if (contacts.size() > 0) {
            Contact contact = contacts[0];
            contact.OtherCountry = '';
            if (Schema.sObjectType.Contact.isUpdateable()) {
                update contact;
            }
        }
    }

    /**
     * @description This method checks if id is salesforece id.
     *
     * @param idString - Id to be verified.
     * @return {Boolean} - true if matches the pattern.
     */
    @AuraEnabled
    public static Boolean isSalesforceId(String idString) {
        return Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(idString).matches();
    }

    /**
     * @description This method logs ACMN errors.
     *
     * @param className className
     * @param errorMessage errorMessage
     * @param otherDetails otherDetails
     * @return ACMN_Error_Log__c
     */
    @AuraEnabled
    public static ACMN_Error_Log__c logACMNError(
        String className,
        String errorMessage,
        String otherDetails
    ) {
        String errorRecordType = MBMS_RecordTypeUtilities.getMBMSErrorRecordTypeId();
        ACMN_Error_Log__c errorRecord = new ACMN_Error_Log__c(
            RecordTypeId = errorRecordType,
            Class_Name__c = className,
            Error_Message__c = errorMessage,
            Other_Details__c = otherDetails
        );
        if (Schema.sObjectType.ACMN_Error_Log__c.isCreateable()) {
            insert errorRecord;
            return errorRecord;
        } else {
            return null;
        }
    }

    /**
     * @description This method gets the Carma Contact objects Id for the contact.
     *
     * @param contactId - Id of the contact object.
     * @return {String} - Id of the Carma Contact object.
     */
    @AuraEnabled
    public static String getContactDetailsId(String contactId) {
        if (String.isNotEmpty(contactId)) {
            String contactDetailsRecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
            List<CARMA_Contact_Relationship__c> contactDetailsIds = [
                SELECT Id
                FROM CARMA_Contact_Relationship__c
                WHERE RecordTypeId = :contactDetailsRecordTypeId AND Related_Contact__c = :contactId
                WITH SECURITY_ENFORCED
            ];
            if (contactDetailsIds.size() > 0) {
                return contactDetailsIds[0].Id;
            }
        }
        return '';
    }

    /**
     * @description This method gets the Carma Contact objects details for the contact.
     *
     * @param contactId - Id of the contact object.
     * @return {String} - Id of the Carma Contact object.
     */
    @AuraEnabled
    public static CARMA_Contact_Relationship__c getContactDetails(String contactId) {
        if (String.isNotEmpty(contactId)) {
            String contactDetailsRecordTypeId = MBMS_RecordTypeUtilities.getCARMAContactMBMSRecordTypeId();
            List<CARMA_Contact_Relationship__c> contactDetailsIds = [
                SELECT Id, Modify_Contact__c, Date_of_Birth__c
                FROM CARMA_Contact_Relationship__c
                WHERE RecordTypeId = :contactDetailsRecordTypeId AND Related_Contact__c = :contactId
                WITH SECURITY_ENFORCED
            ];
            if (contactDetailsIds.size() > 0) {
                return contactDetailsIds[0];
            }
        }
        return null;
    }

    /**
     * @description Truncates the string to the specified lenth if string is longer.
     *
     * @param text
     * @param length
     * @return {String}
     */
    public static String truncateString(String text, Integer length) {
        if (text.length() > length) {
            return text.substring(0, length);
        }
        return text;
    }

    /**
     * @description Remove all Non Digit Characters from the string
     *
     * @param text
     * @return {String}
     */
    public static String removeNonDigitCharacters(String text) {
        if (String.isNotEmpty(text)) {
            return text.replaceAll('[^0-9]', '');
        }
        return text;
    }

    /**
     * @description Phone formatting for domestic phone numbers. Foreign will format as digits only.
     *
     * @param phone
     * @return {String}
     */
    public static String formatPhoneNumber(String phone) {
        String phoneOnlyDigits = removeNonDigitCharacters(phone);
        if (String.isNotEmpty(phoneOnlyDigits) && phoneOnlyDigits.length() == 10) {
            String areaCode = phoneOnlyDigits.substring(0, 3);
            String phonePartOne = phoneOnlyDigits.substring(3, 6);
            String phonePartTwo = phoneOnlyDigits.substring(6);
            return '(' + areaCode + ') ' + phonePartOne + '-' + phonePartTwo;
        }
        return phoneOnlyDigits;
    }
    /**
     * @description Removes all Special Characters and digits from the string
     *
     * @param text
     * @return {String}
     */
    public static String removeSpecialCharacters(String text) {
        if (String.isNotEmpty(text)) {
            return text.replaceAll('[^a-zA-Z \\-\']', '');
        }
        return text;
    }

    /**
     * Accepts a string in YYYY-MM-DD and constructs an Apex Date Object
     *
     * @param {String} initialDate A date in YYYY-MM-DD format
     * @return {Date} Apex Date object constructed from initialDate
     */
    public static Date constructDate(String initialDate) {
        if (String.isNotEmpty(initialDate)) {
            List<String> splitDate = initialDate.split('-');

            if (
                splitDate != null &&
                splitDate.size() == 3 &&
                splitDate[0].length() == 4 &&
                splitDate[1].length() == 2 &&
                splitDate[2].length() == 2
            ) {
                return Date.newInstance(
                    Integer.valueOf(splitDate[0]),
                    Integer.valueOf(splitDate[1]),
                    Integer.valueOf(splitDate[2])
                );
            }
        }

        return null;
    }

    /**
     * Accepts a type and name
     *
     * @param {String} type
     * @param {String} name
     * @return {String} returns the group/Queue Object
     */
    @AuraEnabled
    public static Group getGroupDetails(String type, String developerName) {
        Group groupRes = new Group();
        return groupRes = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = :type AND DeveloperName = :developerName
            LIMIT 1
        ];
    }
    /**
     * Accepts a type and name
     *
     * @param {String} type
     * @param {String} name
     * @return {String} returns the group name
     */
    @AuraEnabled
    public static MBMS_Case_Details__c getCaseDetails(String caseDetailsId) {
        List<MBMS_Case_Details__c> caseDetails = [
            SELECT
                Id,
                CreatedDate,
                CreatedById,
                LastModifiedById,
                MBMS_Authority_for_Burial__c,
                MBMS_Birth_Sex__c,
                MBMS_BOSS_Decedent_ID__c,
                MBMS_Burial_Activity_Type__c,
                MBMS_Capital_Crime_Committed__c,
                MBMS_DBS__c,
                MBMS_Case_Status__c,
                MBMS_Case_Status_Code__c,
                MBMS_Cemetery__c,
                MBMS_Cemetery__r.MBMS_Cemetery_Station_Number__c,
                MBMS_Container_Size__c,
                MBMS_Cremains_Container_Dimensions__c,
                MBMS_Cremains_Type__c,
                MBMS_Date_of_Contact__c,
                Unclaimed_Remains__c,
                MBMS_Decedent__c,
                MBMS_Decedent__r.Birthdate,
                MBMS_Decedent__r.FirstName,
                MBMS_Decedent__r.MiddleName,
                MBMS_Decedent__r.LastName,
                MBMS_Decedent__r.Phone,
                MBMS_Decedent__r.Views_Gender__c,
                MBMS_Decedent__r.SSN__c,
                MBMS_Decedent__r.MBMS_Marital_Status__c,
                MBMS_Decedent__r.MBMS_Service_Area__c,
                MBMS_Decedent__r.MBMS_Suffix__c,
                MBMS_Decedent__r.MBMS_Address_Line_One__c,
                MBMS_Decedent__r.MBMS_Address_Line_Two__c,
                MBMS_Decedent__r.MBMS_Foreign_Address__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_City__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_Country__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_State__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_Zip_Code_4_Digit__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_Zip_Code_5_Digit__c,
                MBMS_Decedent__r.MBMS_Zip_Code_Lookup__r.MBMS_CountyCode__c,
                MBMS_Decedent__r.Other_Country__c,
                MBMS_Decedent__r.OtherCity,
                MBMS_Decedent__r.MBMS_Province__c,
                MBMS_Decedent__r.OtherCountry,
                MBMS_Decedent__r.OtherPostalCode,
                MBMS_Eligibility_Status__c,
                MBMS_Emblem__c,
                MBMS_Family_Request_Service__c,
                MBMS_Family_to_Witness_Interment__c,
                MBMS_First_or_Subsequent__c,
                MBMS_Funeral_Home__c,
                MBMS_Funeral_Home__r.Name,
                MBMS_Funeral_Home__r.MBMS_Phone_Number__c,
                MBMS_Funeral_Home__r.Fax,
                MBMS_Funeral_Home_Contact__c,
                MBMS_Liner_Size__c,
                MBMS_Liner_Type__c,
                MBMS_Memorials_Service_Schedule__c,
                MBMS_Military_Honors__c,
                MBMS_Next_of_Kin__c,
                MBMS_Next_of_Kin__r.FirstName,
                MBMS_Next_of_Kin__r.MiddleName,
                MBMS_Next_of_Kin__r.LastName,
                MBMS_Next_of_Kin__r.SSN__c,
                MBMS_Next_of_Kin__r.Phone,
                MBMS_Next_of_Kin__r.Email,
                MBMS_Next_of_Kin__r.MBMS_Relationship_to_Decedent__c,
                MBMS_Next_of_Kin__r.MBMS_Suffix__c,
                MBMS_Next_of_Kin__r.MBMS_Address_Line_One__c,
                MBMS_Next_of_Kin__r.MBMS_Address_Line_Two__c,
                MBMS_Next_of_Kin__r.MBMS_Foreign_Address__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_City__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_Country__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_State__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_Zip_Code_4_Digit__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_Zip_Code_5_Digit__c,
                MBMS_Next_of_Kin__r.MBMS_Zip_Code_Lookup__r.MBMS_CountyCode__c,
                MBMS_Next_of_Kin__r.Other_Country__c,
                MBMS_Next_of_Kin__r.OtherCity,
                MBMS_Next_of_Kin__r.MBMS_Province__c,
                MBMS_Next_of_Kin__r.OtherPostalCode,
                MBMS_Oversize_Dimensions__c,
                MBMS_Oversize_Text__c,
                MBMS_PreviousDecedentBOSSId__c,
                MBMS_Private_Vault_Name__c,
                MBMS_Remains_Type__c,
                MBMS_Remarks__c,
                MBMS_Relationship_to_Veteran__c,
                MBMS_Schedule_Time__c,
                MBMS_Sexual_Offense_Convicted__c,
                MBMS_Transfer_To_Cemetery__c,
                MBMS_DateOfDeath__c,
                MBMS_Veteran__c,
                Suspend_Rules__c,
                MBMS_Decedent_Detail__c,
                MBMS_Decedent_Detail__r.Modify_Contact__c,
                MBMS_Decedent_Detail__r.First_Name__c,
                MBMS_Decedent_Detail__r.Middle_Name__c,
                MBMS_Decedent_Detail__r.MBMS_No_Middle_Name__c,
                MBMS_Decedent_Detail__r.Last_Name__c,
                MBMS_Decedent_Detail__r.Phone_Number__c,
                MBMS_Decedent_Detail__r.Date_of_Birth__c,
                MBMS_Personal_Representative_Detail__c,
                MBMS_Personal_Representative_Detail__r.Modify_Contact__c,
                MBMS_Personal_Representative_Detail__r.First_Name__c,
                MBMS_Personal_Representative_Detail__r.Middle_Name__c,
                MBMS_Personal_Representative_Detail__r.MBMS_No_Middle_Name__c,
                MBMS_Personal_Representative_Detail__r.Last_Name__c,
                MBMS_Personal_Representative_Detail__r.Phone_Number__c,
                MBMS_Personal_Representative_Detail__r.Date_of_Birth__c,
                MBMS_Veteran_Detail__r.Modify_Contact__c,
                MBMS_Veteran_Detail__r.First_Name__c,
                MBMS_Veteran_Detail__r.Middle_Name__c,
                MBMS_Veteran_Detail__r.MBMS_No_Middle_Name__c,
                MBMS_Veteran_Detail__r.Last_Name__c,
                MBMS_Veteran_Detail__r.Phone_Number__c,
                MBMS_Veteran_Detail__r.Date_of_Birth__c,
                (
                    SELECT
                        Id,
                        MBMS_ContactID__r.FirstName,
                        MBMS_ContactID__r.MiddleName,
                        MBMS_ContactID__r.LastName,
                        MBMS_ContactID__r.MBMS_Suffix__c,
                        MBMS_ContactID__r.Birthdate,
                        MBMS_ContactID__r.SSN__c,
                        MBMS_ContactID__r.MBMS_Is_a_veteran__c,
                        MBMS_ContactID__r.MBMS_Set_Aside__c,
                        MBMS_ContactID__r.Phone,
                        MBMS_Relationship_to_Veteran__c,
                        MBMS_Contact_Detail__c,
                        MBMS_Contact_Detail__r.Modify_Contact__c,
                        MBMS_Contact_Detail__r.First_Name__c,
                        MBMS_Contact_Detail__r.Middle_Name__c,
                        MBMS_Contact_Detail__r.MBMS_No_Middle_Name__c,
                        MBMS_Contact_Detail__r.Last_Name__c,
                        MBMS_Contact_Detail__r.Phone_Number__c,
                        MBMS_Contact_Detail__r.Date_of_Birth__c
                    FROM MBMS_Adult_Dependents__r
                )
            FROM MBMS_Case_Details__c
            WHERE Id = :caseDetailsId
            WITH SECURITY_ENFORCED
        ];
        if (caseDetails.size() == 1) {
            return caseDetails[0];
        }
        return null;
    }

    /**
     * @description Create a number of users.
     * @param numberOfDetails Number of users
     * @param userType Type of User (Scheduling/Eligibility)
     * @return List Users
     */
    public List<User> createCameoUser(
        Integer numberOfDetails,
        Integer startingNumber,
        String userType
    ) {
        List<User> userList = new List<User>();
        userList.addAll(createUserStaticList(numberOfDetails, startingNumber));
        this.userList.addAll(userList);
        return assignCerrtPermissions(userList, userType);
    }

    public List<User> userList = new List<User>();
    /**
     * @description Create a number of users static method.
     * @param numberOfUsers Number of users
     * @param startingNumber Starting number of users
     * @return List Users
     */
    public static List<User> createUserStaticList(Integer numberOfUsers, Integer startingNumber) {
        List<User> userList = new List<User>();
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'VA Service Cloud Basic'
            WITH SECURITY_ENFORCED
        ];
        for (Integer i = startingNumber; i < numberOfUsers + startingNumber; i++) {
            String email = 'test-cameo-user' + i + '@va-mbms-test.gov';
            String firstName = 'testCameoFirstName' + i;
            String lastName = 'testCameoLastName' + i;
            User user = new User(
                UserName = email,
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Alias = 'cameoTES',
                FederationIdentifier = email,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocalesIdKey = 'en_US',
                TimezonesIdKey = 'America/Los_Angeles',
                ProfileId = profile.Id
            );
            userList.add(user);
        }
        if (Schema.sObjectType.User.isCreateable()) {
            insert userList;
        }
        return userList;
    }

    /**
     * @description Assign permission sets related to Cameo.
     * @param userListList of user records
     * @return userList List<Users>
     */
    public static List<User> assignCerrtPermissions(List<User> userList, String userType) {
        List<PermissionSetAssignment> permissionAssignments = new List<PermissionSetAssignment>();
        List<GroupMember> groupMemebers = new List<GroupMember>();
        for (User user : userList) {
            permissionAssignments.addAll(getSelfPermissionSets(user.Id, userType));
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            if (Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
                Database.insert(permissionAssignments, true);
            }
        }
        return userList;
    }

    /**
     * @description Assign permission sets related to Cameo.
     * @param userId user record Id
     * @return List<PermissionSetAssignment>
     */
    private static List<PermissionSetAssignment> getSelfPermissionSets(
        String userId,
        String userType
    ) {
        List<PermissionSetAssignment> permissionAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet pSet : getAllCameoPermisionSet(userType)) {
            PermissionSetAssignment psaCD = new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = pSet.Id
            );
            permissionAssignments.add(psaCD);
        }
        return permissionAssignments;
    }

    /**
     * @description Get all permission sets related to Cameo
     * @return List<PermissionSet>
     */
    private static List<PermissionSet> getAllCameoPermisionSet(String userType) {
        Map<String, List<String>> permissionSetMap = new Map<String, List<String>>();

        permissionSetMap.put(
            'Scheduling Agent',
            new List<String>{
                'MBMS_CaseEstablishmentV2',
                'MBMS_Core',
                'MBMS_Eligibility_Features',
                'MBMS_NCSO_Supervisor'
            }
        );

        permissionSetMap.put(
            'Scheduling Supervisor',
            new List<String>{
                'MBMS_CaseEstablishmentV2',
                'MBMS_Core',
                'MBMS_Eligibility_Features',
                'MBMS_Scheduling_Agent'
            }
        );

        permissionSetMap.put(
            'Eligibility Analyst',
            new List<String>{
                'MBMS_CaseEstablishmentV2',
                'MBMS_Core',
                'MBMS_Eligibility_Features',
                'MBMS_Eligibility_Analyst'
            }
        );

        permissionSetMap.put(
            'Eligibility Supervisor',
            new List<String>{
                'MBMS_CaseEstablishmentV2',
                'MBMS_Core',
                'MBMS_Eligibility_Core',
                'MBMS_Eligibility_Supervisor'
            }
        );

        if (permissionSetMap.containsKey(userType)) {
            return [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name IN :permissionSetMap.get(userType)
                WITH SECURITY_ENFORCED
            ];
        } else {
            return null;
        }
    }

    /**
     * @description Get a User.
     * @param firstName First Name
     * @param lastName Last Name
     * @return User
     */
    public static User getUser(String firstName, String lastName) {
        User user = [
            SELECT Id, FirstName, LastName, Username, Email, Title, Phone, CompanyName
            FROM User
            WHERE Firstname = :firstName AND LastName = :lastname
            WITH SECURITY_ENFORCED
        ];
        return user;
    }
}