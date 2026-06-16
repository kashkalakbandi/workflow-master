// PaymentTransactionTrigger.trigger
trigger PaymentTransactionTrigger on Payment_Transaction__c (after insert, after update) {
    fflib_SObjectDomain.triggerHandler(PaymentTransactionHandler.class);
}
