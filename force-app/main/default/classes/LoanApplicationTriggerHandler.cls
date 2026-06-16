// LoanApplicationTriggerHandler.cls
/**
 * @description Domain / trigger-handler class for Loan_Application__c records.
 *              Extends fflib_SObjectDomain to plug into the fflib trigger framework.
 *              Handles defaulting of Status__c on insert and guards against
 *              edits after disbursement.
 */
public with sharing class LoanApplicationTriggerHandler extends fflib_SObjectDomain {

    /**
     * @description Constructs a LoanApplicationTriggerHandler wrapping
     *              the provided records.
     * @param records List of Loan_Application__c records from the trigger context.
     */
    public LoanApplicationTriggerHandler(List<Loan_Application__c> records) {
        super(records);
    }

    /**
     * @description Factory method used by the fflib trigger dispatcher.
     * @param records List of Loan_Application__c records.
     * @return New LoanApplicationTriggerHandler domain instance.
     */
    public static LoanApplicationTriggerHandler newInstance(
            List<Loan_Application__c> records) {
        return new LoanApplicationTriggerHandler(records);
    }

    /**
     * @description Before-insert handler. Sets Status__c to 'Draft' when
     *              the field is blank on any incoming record.
     */
    public override void onBeforeInsert() {
        for (Loan_Application__c app :
                (List<Loan_Application__c>) Records) {
            if (String.isBlank(app.Status__c)) {
                app.Status__c = 'Draft';
            }
        }
    }

    /**
     * @description Before-update handler. Prevents any field changes on a
     *              Loan_Application__c whose Status__c is 'Disbursed'.
     * @param existingRecords Map of record Id to the prior SObject state.
     */
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        for (Loan_Application__c app :
                (List<Loan_Application__c>) Records) {
            Loan_Application__c oldApp =
                (Loan_Application__c) existingRecords.get(app.Id);
            if (oldApp != null && oldApp.Status__c == 'Disbursed') {
                app.addError(
                    'A disbursed loan application cannot be modified.'
                );
            }
        }
    }

    /**
     * @description Constructor provider used by fflib_SObjectDomain
     *              to instantiate this handler via the trigger dispatcher.
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        /**
         * @description Constructs a LoanApplicationTriggerHandler from a
         *              generic SObject list.
         * @param sObjectList List of SObjects (Loan_Application__c records).
         * @return New fflib_SObjectDomain instance.
         */
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new LoanApplicationTriggerHandler(
                (List<Loan_Application__c>) sObjectList
            );
        }
    }
}
