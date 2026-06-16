// ILoanApplicationSelector.cls
/**
 * @description Interface for the Loan Application selector.
 *              Extends fflib_ISObjectSelector to participate in the
 *              fflib Application factory and enforce field-level security.
 */
public interface ILoanApplicationSelector extends fflib_ISObjectSelector {
    /**
     * @description Retrieves Loan Application records by their record Ids.
     * @param idSet Set of Loan_Application__c record Ids to query.
     * @return List of Loan_Application__c records matching the provided Ids.
     */
    List<Loan_Application__c> selectById(Set<Id> idSet);

    /**
     * @description Retrieves Loan Application records filtered by one or more Status values.
     * @param statuses Set of Status__c picklist values to filter by.
     * @return List of Loan_Application__c records whose Status__c is in the provided set.
     */
    List<Loan_Application__c> selectByStatus(Set<String> statuses);
}
