/*****************************************************************************

FORMULA NAME: _FLAT_AMOUNT_EARN

FORMULA TYPE: Payroll

DESCRIPTION:  Formula for Flat Amount for Earning Template for Mexico.
              Returns pay value (Amount);

*******************************************************************************

FORMULA TEXT

Formula Results :

 flat_amount           Direct Result for Earnings Amount.

 mesg                  Warning message will be issued for this assignment.

*******************************************************************************/

/* ALIAS section */

ALIAS SCL_ASG_MX_WORK_SCHEDULE AS Work_Schedule

/* Database Item Defaults */

DEFAULT FOR flat_amount                    is 0
DEFAULT FOR Amount                         is 0
DEFAULT FOR mesg                           is 'NOT ENTERED'
DEFAULT FOR P047_ISPT_ANUAL_A_FAVOR_ASG_GRE_YTD        is 0
DEFAULT FOR ASG_SALARY_BASIS IS 'NOT ENTERED'
DEFAULT FOR ASG_SALARY IS 0
DEFAULT FOR ASG_HOURS IS 40
DEFAULT FOR PAY_PROC_PERIOD_START_DATE IS '0001/01/01 00:00:00' (DATE)
DEFAULT FOR PAY_PROC_PERIOD_END_DATE IS '0001/01/02 00:00:00' (DATE)
DEFAULT FOR ASG_FREQ_CODE IS 'W'
/* Assume that an employee works for 8 hours per day, 5 days a week.*/
DEFAULT FOR Work_Schedule IS '1 Schedule: 8-8-8-8-8-0-0'
DEFAULT FOR Saldo_Pendiente                is 0

/* Inputs  */

INPUTS ARE        Amount,
                  Saldo_Pendiente

/* =====Local variables =====  */
local_tax_type = 'ISR'
local_dummy_class_name = 'NONE'
isr_subject = 0
isr_exempt = 0
local_daily_salary = 0
local_gross_earnings = GROSS_EARNINGS_ASG_RUN
local_ytd_gross_earnings = GROSS_EARNINGS_ASG_YTD
saldoPendiente = 0

IF Amount <= TOPE_PERCEPCIONES_ASG_GRE_RUN THEN
  (
   flat_amount = Amount
  )
   ELSE
    (
    flat_amount = TOPE_PERCEPCIONES_ASG_GRE_RUN
	)

/* Compute daily salary */
IF ASG_SALARY WAS DEFAULTED THEN
(
  local_daily_salary = FIXED_EARNINGS_ASG_GRE_RUN / Days_in_Pay_Period()
)
ELSE IF ASG_SALARY_BASIS = 'DAILY' THEN
(
  local_daily_salary = ASG_SALARY
)
ELSE
(
  local_daily_salary = Convert_Period_Type(
                       Work_Schedule,
                       ASG_HOURS,
                       ASG_SALARY,
                       ASG_SALARY_BASIS,
                       'DAILY',
                       PAY_PROC_PERIOD_START_DATE,
                       PAY_PROC_PERIOD_END_DATE,
                       ASG_FREQ_CODE)
)

/***************Codigo realizado para el Saldo Pendiente***************/

IF (Saldo_Pendiente = 0) THEN (
  Saldo_Pendiente = BALANCE()
) ELSE (
  Saldo_Pendiente = Saldo_Pendiente + BALANCE()
)

IF (flat_amount > Saldo_Pendiente) THEN(
  flat_amount = Saldo_Pendiente
)

saldoPendiente = Saldo_Pendiente - flat_amount
/***************Codigo realizado para el Saldo Pendiente***************/

/* ======ISR Subject calculation begins ======= */
    isr_subject = get_subject_earnings_ann
                    (local_tax_type,
                    flat_amount,
                    P047_ISPT_ANUAL_A_FAVOR_ASG_YTD +
                    flat_amount,
                    local_gross_earnings +
                    flat_amount,
                    local_ytd_gross_earnings +
                    flat_amount,
                    local_daily_salary,
                    local_dummy_class_name)
    isr_exempt = flat_amount - isr_subject
/* ======ISR Subject calculation ends ======= */

soe_ytd = P047_ISPT_ANUAL_A_FAVOR_ASG_GRE_YTD

RETURN flat_amount,
       mesg,
       isr_subject,
       isr_exempt,
       saldoPendiente

/* End Formula Text */