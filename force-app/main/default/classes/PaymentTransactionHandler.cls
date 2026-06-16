// PaymentTransactionHandler.cls
/**
 * @description Domain / trigger-handler class for Payment_Transaction__c records.
 *              Extends fflib_SObjectDomain to plug into the fflib trigger framework.
 *              Handles post-insert balance updates and delinquency marking on
 *              status changes.
 */
public with sharing class PaymentTransactionHandler extends fflib_SObjectDomain {

    /**
     * @description Constructs a PaymentTransactionHandler wrapping the provided records.
     * @param records List of Payment_Transaction__c records from the trigger context.
     */
    public PaymentTransactionHandler(List<Payment_Transaction__c> records) {
        super(records);
    }

    /**
     * @description Factory method used by the fflib trigger dispatcher.
     * @param records List of Payment_Transaction__c records.
     * @return New PaymentTransactionHandler domain instance.
     */
    public static PaymentTransactionHandler newInstance(
            List<Payment_Transaction__c> records) {
        return new PaymentTransactionHandler(records);
    }

    /**
     * @description After-insert handler. For each Cleared transaction,
     *              reduces Outstanding_Balance__c on the parent Loan_Account__c
     *              by the transaction's Principal_Component__c.
     *              Uses a Unit of Work to batch the DML.
     */
    public override void onAfterInsert() {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType>{ Loan_Account__c.SObjectType }
        );
        Set<Id> loanAccountIds = new Set<Id>();
        for (Payment_Transaction__c txn :
                (List<Payment_Transaction__c>) Records) {
            if (txn.Payment_Status__c == 'Cleared'
                    && txn.Loan_Account__c != null) {
                loanAccountIds.add(txn.Loan_Account__c);
            }
        }
        if (loanAccountIds.isEmpty()) {
            return;
        }
        Map<Id, Loan_Account__c> accountMap = queryLoanAccounts(loanAccountIds);
        for (Payment_Transaction__c txn :
                (List<Payment_Transaction__c>) Records) {
            if (txn.Payment_Status__c != 'Cleared'
                    || txn.Loan_Account__c == null) {
                continue;
            }
            Loan_Account__c loanAccount = accountMap.get(txn.Loan_Account__c);
            if (loanAccount == null) {
                continue;
            }
            Decimal principalPaid = txn.Principal_Component__c != null
                ? txn.Principal_Component__c : 0;
            Decimal currentBalance = loanAccount.Outstanding_Balance__c != null
                ? loanAccount.Outstanding_Balance__c : 0;
            loanAccount.Outstanding_Balance__c =
                currentBalance - principalPaid;
            uow.registerDirty(loanAccount);
        }
        uow.commitWork();
    }

    /**
     * @description After-update handler. When a transaction's Payment_Status__c
     *              transitions to 'Bounced', marks the parent Loan_Account__c as
     *              'Delinquent'.
     * @param existingRecords Map of record Id to the prior SObject state.
     */
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        Set<Id> bouncedLoanAccountIds = new Set<Id>();
        for (Payment_Transaction__c txn :
                (List<Payment_Transaction__c>) Records) {
            Payment_Transaction__c oldTxn =
                (Payment_Transaction__c) existingRecords.get(txn.Id);
            if (txn.Payment_Status__c == 'Bounced'
                    && oldTxn.Payment_Status__c != 'Bounced'
                    && txn.Loan_Account__c != null) {
                bouncedLoanAccountIds.add(txn.Loan_Account__c);
            }
        }
        if (!bouncedLoanAccountIds.isEmpty()) {
            markAccountDelinquent(bouncedLoanAccountIds);
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * @description Queries Loan_Account__c records by Id and returns them as a map.
     * @param loanAccountIds Set of Loan_Account__c Ids to query.
     * @return Map of Id to Loan_Account__c.
     */
    private Map<Id, Loan_Account__c> queryLoanAccounts(
            Set<Id> loanAccountIds) {
        return new Map<Id, Loan_Account__c>([
            SELECT Id, Outstanding_Balance__c, Account_Status__c
            FROM Loan_Account__c
            WHERE Id IN :loanAccountIds
        ]);
    }

    /**
     * @description Sets Account_Status__c to 'Delinquent' on the provided
     *              Loan_Account__c records via a Unit of Work.
     * @param loanAccountIds Set of Loan_Account__c Ids to mark as delinquent.
     */
    private void markAccountDelinquent(Set<Id> loanAccountIds) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType>{ Loan_Account__c.SObjectType }
        );
        Map<Id, Loan_Account__c> accountMap =
            queryLoanAccounts(loanAccountIds);
        for (Loan_Account__c loanAccount : accountMap.values()) {
            loanAccount.Account_Status__c = 'Delinquent';
            uow.registerDirty(loanAccount);
        }
        uow.commitWork();
    }

    /**
     * @description Constructor provider used by fflib_SObjectDomain
     *              to instantiate this handler via the trigger dispatcher.
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        /**
         * @description Constructs a PaymentTransactionHandler from a generic SObject list.
         * @param sObjectList List of SObjects (Payment_Transaction__c records).
         * @return New fflib_SObjectDomain instance.
         */
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new PaymentTransactionHandler(
                (List<Payment_Transaction__c>) sObjectList
            );
        }
    }
}
