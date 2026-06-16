// LoanApplicationService.cls
/**
 * @description Service class for Loan_Application__c operations.
 *              All methods are static; this class has no instance state.
 *              Uses fflib_SObjectUnitOfWork for transactional DML and
 *              LoanApplications domain for validation.
 */
public with sharing class LoanApplicationService {
  /** @description Ordered list of SObject types for the Unit of Work. */
  private static final List<Schema.SObjectType> UOW_SOBJECT_TYPES = new List<Schema.SObjectType>{
    Loan_Application__c.SObjectType,
    Loan_Account__c.SObjectType
  };

  // -------------------------------------------------------------------------
  // Public service methods
  // -------------------------------------------------------------------------

  /**
   * @description Transitions the given Loan Applications to 'Submitted' status,
   *              runs domain validation, and persists changes via Unit of Work.
   * @param applicationIds Set of Loan_Application__c Ids to submit.
   */
  public static void submitApplication(Set<Id> applicationIds) {
    fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
      UOW_SOBJECT_TYPES
    );
    List<Loan_Application__c> apps = fetchApplications(applicationIds);
    ILoanApplications domain = LoanApplications.newInstance(apps);
    domain.validateCreditScore();
    domain.validateLoanAmount();
    for (Loan_Application__c app : apps) {
      app.Status__c = 'Submitted';
      uow.registerDirty(app);
    }
    uow.commitWork();
  }

  /**
   * @description Transitions the given Loan Applications to 'Approved' status
   *              and stamps the approved amount on each record.
   * @param applicationIds Set of Loan_Application__c Ids to approve.
   * @param approvedAmounts Map of application Id to approved Decimal amount.
   */
  public static void approveApplication(
    Set<Id> applicationIds,
    Map<Id, Decimal> approvedAmounts
  ) {
    fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
      UOW_SOBJECT_TYPES
    );
    List<Loan_Application__c> apps = fetchApplications(applicationIds);
    for (Loan_Application__c app : apps) {
      app.Status__c = 'Approved';
      if (approvedAmounts != null && approvedAmounts.containsKey(app.Id)) {
        app.Approved_Amount__c = approvedAmounts.get(app.Id);
      }
      uow.registerDirty(app);
    }
    uow.commitWork();
  }

  /**
   * @description Transitions the given Loan Applications to 'Rejected' status
   *              and records the rejection reason.
   * @param applicationIds Set of Loan_Application__c Ids to reject.
   * @param reason Textual reason for rejection stored on Rejection_Reason__c.
   */
  public static void rejectApplication(Set<Id> applicationIds, String reason) {
    fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
      UOW_SOBJECT_TYPES
    );
    List<Loan_Application__c> apps = fetchApplications(applicationIds);
    for (Loan_Application__c app : apps) {
      app.Status__c = 'Rejected';
      app.Rejection_Reason__c = reason;
      uow.registerDirty(app);
    }
    uow.commitWork();
  }

  /**
   * @description Transitions the given Loan Applications to 'Disbursed' status
   *              and creates a corresponding Loan_Account__c for each application.
   *              EMI is calculated using the standard reducing-balance formula.
   * @param applicationIds Set of Loan_Application__c Ids to disburse.
   */
  public static void disburseLoan(Set<Id> applicationIds) {
    fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
      UOW_SOBJECT_TYPES
    );
    List<Loan_Application__c> apps = fetchApplications(applicationIds);
    Date today = Date.today();
    for (Loan_Application__c app : apps) {
      app.Status__c = 'Disbursed';
      uow.registerDirty(app);
      Loan_Account__c account = buildLoanAccount(app, today);
      uow.registerNew(account, Loan_Account__c.Loan_Application__c, app);
    }
    uow.commitWork();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /**
   * @description Fetches Loan_Application__c records by Id using the selector.
   * @param applicationIds Set of Ids to fetch.
   * @return List of Loan_Application__c records.
   */
  private static List<Loan_Application__c> fetchApplications(
    Set<Id> applicationIds
  ) {
    ILoanApplicationSelector selector = new LoanApplicationSelector();
    return selector.selectById(applicationIds);
  }

  /**
   * @description Builds a new Loan_Account__c record derived from the
   *              provided Loan_Application__c and disbursement date.
   * @param app The approved Loan_Application__c to disburse.
   * @param today The disbursement date.
   * @return Populated Loan_Account__c ready for insertion.
   */
  private static Loan_Account__c buildLoanAccount(
    Loan_Application__c app,
    Date today
  ) {
    Decimal principal = app.Approved_Amount__c != null
      ? app.Approved_Amount__c
      : 0;
    Integer tenureMonths = app.Tenure_Months__c != null
      ? Integer.valueOf(app.Tenure_Months__c)
      : 0;
    Decimal annualRate = app.Annual_Interest_Rate__c != null
      ? app.Annual_Interest_Rate__c
      : 0;
    Decimal emi = computeEmi(principal, annualRate, tenureMonths);
    Loan_Account__c loanAccount = new Loan_Account__c();
    loanAccount.Principal_Balance__c = principal;
    loanAccount.Outstanding_Balance__c = principal;
    loanAccount.EMI_Amount__c = emi;
    loanAccount.Account_Status__c = 'Active';
    loanAccount.Disbursement_Date__c = today;
    loanAccount.Maturity_Date__c = today.addMonths(tenureMonths);
    loanAccount.Next_Due_Date__c = today.addMonths(1);
    return loanAccount;
  }

  /**
   * @description Computes the Equated Monthly Instalment using the
   *              standard reducing-balance formula:
   *              EMI = P * r * (1+r)^n / ((1+r)^n - 1)
   *              where r = annualRate / 1200 and n = tenureMonths.
   *              When the interest rate is zero the EMI is P / n.
   * @param principal The loan principal amount.
   * @param annualRate The annual interest rate as a percentage (e.g. 12 for 12%).
   * @param tenureMonths The loan tenure in months.
   * @return Calculated EMI amount rounded to 2 decimal places.
   */
  private static Decimal computeEmi(
    Decimal principal,
    Decimal annualRate,
    Integer tenureMonths
  ) {
    if (principal == null || principal == 0) {
      return 0;
    }
    if (tenureMonths == null || tenureMonths == 0) {
      return principal;
    }
    if (annualRate == null || annualRate == 0) {
      return (principal / tenureMonths).setScale(2, RoundingMode.HALF_UP);
    }
    Decimal monthlyRate = annualRate / 1200;
    Decimal compoundFactor = computePower(1 + monthlyRate, tenureMonths);
    Decimal emi =
      principal *
      monthlyRate *
      compoundFactor /
      (compoundFactor - 1);
    return emi.setScale(2, RoundingMode.HALF_UP);
  }

  /**
   * @description Computes base raised to the power of exponent iteratively,
   *              avoiding the use of Math.pow which is unavailable in Apex.
   * @param base The base value.
   * @param exponent The non-negative integer exponent.
   * @return Decimal result of base^exponent.
   */
  private static Decimal computePower(Decimal base, Integer exponent) {
    Decimal result = 1;
    Integer remaining = exponent;
    while (remaining > 0) {
      result = result * base;
      remaining--;
    }
    return result;
  }
}
