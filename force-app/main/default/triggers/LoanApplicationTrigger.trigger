// LoanApplicationTrigger.trigger
trigger LoanApplicationTrigger on Loan_Application__c (
    before insert, before update, after insert, after update
) {
    fflib_SObjectDomain.triggerHandler(LoanApplicationTriggerHandler.class);
}
