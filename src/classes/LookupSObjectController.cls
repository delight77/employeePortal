public with sharing class LookupSObjectController {
    @AuraEnabled
    public static List <User> fetchUsers(String searchKeyWord) {
        String searchKey = searchKeyWord + '%';
        List<User> users = new List<User>();
        List <User> lstOfUsers = [select id, Name, Email from User where Name LIKE :searchKey];
        for (User user: lstOfUsers) {
            users.add(user);
        }
        return users;
    }
}