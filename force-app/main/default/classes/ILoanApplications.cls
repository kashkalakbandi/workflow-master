// ILoanApplications.cls
/**
 * @description Interface for the LoanApplications domain class.
 *              Extends fflib_ISObjectDomain to participate in the
 *              fflib Application factory pattern.
 */

 // Adding another comment
public interface ILoanApplications extends fflib_ISObjectDomain {
    /**
     * @description Validates the credit score on each Loan_Application__c
     *              against the minimum required score defined in
     *              Loan_Configuration__mdt for the application's loan type.
     *              Adds a field error on Credit_Score__c when the score
     *              is below the configured minimum.
     */
    void validateCreditScore();

    /**
     * @description Populates Annual_Interest_Rate__c from the matching
     *              Loan_Configuration__mdt record when the field is null,
     *              using Base_Interest_Rate__c as the default rate.
     */
    void applyInterestRateFromConfig();

    /**
     * @description Validates Requested_Amount__c against the maximum loan amount
     *              defined in Loan_Configuration__mdt for the application's loan type.
     *              Adds a field error on Requested_Amount__c when the amount exceeds
     *              the configured maximum.
     */
    void validateLoanAmount();
}
