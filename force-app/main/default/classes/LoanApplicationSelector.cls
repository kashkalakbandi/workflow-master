// LoanApplicationSelector.cls
/**
 * @description Selector class for Loan_Application__c.
 *              Extends fflib_SObjectSelector to leverage automatic field security
 *              enforcement and QueryFactory-based query construction.
 */
public with sharing class LoanApplicationSelector
        extends fflib_SObjectSelector
        implements ILoanApplicationSelector {

    /**
     * @description Returns the SObjectType token for Loan_Application__c.
     * @return Schema.SObjectType token identifying Loan_Application__c.
     */
    public Schema.SObjectType getSObjectType() {
        return Loan_Application__c.SObjectType;
    }

    /**
     * @description Returns the list of SObjectFields included in all queries
     *              produced by this selector.
     * @return List of Schema.SObjectField tokens for Loan_Application__c.
     */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Loan_Application__c.Id,
            Loan_Application__c.Name,
            Loan_Application__c.Applicant__c,
            Loan_Application__c.Loan_Type__c,
            Loan_Application__c.Requested_Amount__c,
            Loan_Application__c.Approved_Amount__c,
            Loan_Application__c.Tenure_Months__c,
            Loan_Application__c.Annual_Interest_Rate__c,
            Loan_Application__c.Status__c,
            Loan_Application__c.Credit_Score__c,
            Loan_Application__c.Monthly_Income__c,
            Loan_Application__c.Rejection_Reason__c,
            Loan_Application__c.CreatedDate
        };
    }

    /**
     * @description Retrieves Loan_Application__c records by record Id,
     *              ordered by CreatedDate ascending.
     * @param idSet Set of Loan_Application__c Ids to retrieve.
     * @return List of matching Loan_Application__c records.
     */
    public List<Loan_Application__c> selectById(Set<Id> idSet) {
        assertIsAccessible();
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Id IN :idSet');
        queryFactory.addOrdering(
            Loan_Application__c.CreatedDate,
            fflib_QueryFactory.SortOrder.ASCENDING
        );
        return (List<Loan_Application__c>) Database.query(queryFactory.toSOQL());
    }

    /**
     * @description Retrieves Loan_Application__c records whose Status__c
     *              value is contained in the provided set.
     * @param statuses Set of Status__c picklist values to filter on.
     * @return List of matching Loan_Application__c records.
     */
    public List<Loan_Application__c> selectByStatus(Set<String> statuses) {
        assertIsAccessible();
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Status__c IN :statuses');
        queryFactory.addOrdering(
            Loan_Application__c.CreatedDate,
            fflib_QueryFactory.SortOrder.ASCENDING
        );
        return (List<Loan_Application__c>) Database.query(queryFactory.toSOQL());
    }
}
