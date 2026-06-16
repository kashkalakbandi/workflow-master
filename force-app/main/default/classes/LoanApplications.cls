// LoanApplications.cls
/**
 * @description Domain class for Loan_Application__c records.
 *              Extends fflib_SObjectDomain and implements ILoanApplications.
 *              Handles validation and defaulting logic as part of the
 *              fflib enterprise patterns.
 */
public with sharing class LoanApplications
        extends fflib_SObjectDomain
        implements ILoanApplications {

    /**
     * @description Constructs a LoanApplications domain instance
     *              wrapping the provided list of records.
     * @param records List of Loan_Application__c records to operate on.
     */
    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }

    /**
     * @description Factory method that creates a new LoanApplications instance.
     * @param records List of Loan_Application__c records.
     * @return New ILoanApplications domain instance.
     */
    public static ILoanApplications newInstance(List<Loan_Application__c> records) {
        return new LoanApplications(records);
    }

    /**
     * @description Called by the fflib framework during record validation.
     *              Delegates to validateCreditScore and applyInterestRateFromConfig.
     */
    public override void onValidate() {
        validateCreditScore();
        validateLoanAmount();
        applyInterestRateFromConfig();
    }

    /**
     * @description Validates each application's Credit_Score__c against the
     *              minimum score configured in Loan_Configuration__mdt.
     *              Adds a field-level error on Credit_Score__c when the score
     *              is below the minimum for the application's loan type.
     */
    public void validateCreditScore() {
        Map<String, Loan_Configuration__mdt> configByLoanType = getLoanConfigMap();
        for (Loan_Application__c app : (List<Loan_Application__c>) Records) {
            if (String.isBlank(app.Loan_Type__c)) {
                continue;
            }
            Loan_Configuration__mdt config = configByLoanType.get(app.Loan_Type__c);
            if (config == null || !config.Is_Active__c) {
                continue;
            }
            Decimal minScore = config.Min_Credit_Score__c;
            if (minScore == null) {
                continue;
            }
            Decimal appScore = app.Credit_Score__c != null ? app.Credit_Score__c : 0;
            if (appScore < minScore) {
                app.Credit_Score__c.addError(
                    'Credit score ' + appScore
                    + ' is below the minimum required score of '
                    + minScore
                    + ' for loan type ' + app.Loan_Type__c + '.'
                );
            }
        }
    }

    /**
     * @description Sets Annual_Interest_Rate__c from Base_Interest_Rate__c in
     *              Loan_Configuration__mdt when the field is null on the record.
     */
    public void applyInterestRateFromConfig() {
        Map<String, Loan_Configuration__mdt> configByLoanType = getLoanConfigMap();
        for (Loan_Application__c app : (List<Loan_Application__c>) Records) {
            if (app.Annual_Interest_Rate__c != null) {
                continue;
            }
            if (String.isBlank(app.Loan_Type__c)) {
                continue;
            }
            Loan_Configuration__mdt config = configByLoanType.get(app.Loan_Type__c);
            if (config == null || !config.Is_Active__c) {
                continue;
            }
            if (config.Base_Interest_Rate__c != null) {
                app.Annual_Interest_Rate__c = config.Base_Interest_Rate__c;
            }
        }
    }

    /**
     * @description Validates each application's Requested_Amount__c against the
     *              maximum loan amount configured in Loan_Configuration__mdt.
     *              Adds a field-level error on Requested_Amount__c when the amount
     *              exceeds the maximum for the application's loan type.
     */
    public void validateLoanAmount() {
        Map<String, Loan_Configuration__mdt> configByLoanType = getLoanConfigMap();
        for (Loan_Application__c app : (List<Loan_Application__c>) Records) {
            if (String.isBlank(app.Loan_Type__c)) {
                continue;
            }
            Loan_Configuration__mdt config = configByLoanType.get(app.Loan_Type__c);
            if (config == null || !config.Is_Active__c) {
                continue;
            }
            Decimal maxAmount = config.Max_Loan_Amount__c;
            if (maxAmount == null) {
                continue;
            }
            Decimal requested = app.Requested_Amount__c != null ? app.Requested_Amount__c : 0;
            if (requested > maxAmount) {
                app.Requested_Amount__c.addError(
                    'Requested amount ' + requested
                    + ' exceeds the maximum allowed amount of '
                    + maxAmount
                    + ' for loan type ' + app.Loan_Type__c + '.'
                );
            }
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * @description Builds a map of Loan_Configuration__mdt keyed by Loan_Type__c.
     * @return Map<String, Loan_Configuration__mdt> of active configurations.
     */
    private Map<String, Loan_Configuration__mdt> getLoanConfigMap() {
        List<Loan_Configuration__mdt> configs = [
            SELECT Loan_Type__c,
                   Base_Interest_Rate__c,
                   Max_Loan_Amount__c,
                   Min_Credit_Score__c,
                   Max_Tenure_Months__c,
                   Is_Active__c
            FROM Loan_Configuration__mdt
            WHERE Is_Active__c = TRUE
            LIMIT 1000
        ];
        Map<String, Loan_Configuration__mdt> configMap =
            new Map<String, Loan_Configuration__mdt>();
        for (Loan_Configuration__mdt cfg : configs) {
            configMap.put(cfg.Loan_Type__c, cfg);
        }
        return configMap;
    }

    /**
     * @description Constructor provider used by fflib_SObjectDomain
     *              to instantiate the domain class via the trigger handler.
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        /**
         * @description Constructs a LoanApplications instance from a generic SObject list.
         * @param sObjectList List of SObjects (Loan_Application__c records).
         * @return New fflib_SObjectDomain instance wrapping the provided records.
         */
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new LoanApplications((List<Loan_Application__c>) sObjectList);
        }
    }
}
