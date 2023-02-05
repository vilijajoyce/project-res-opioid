*************************************************************************
** This is a sample code for the manuscript:
** "Healthcare costs and utilization before and after
** opioid overdose in United States Veterans Health Administration
** patient with opioid use disorder"
** Author: Mark Bounthavong, PharmD, PhD
** Last updated: 20230202
*************************************************************************

clear all
cd "data path"
use XXXX.dta

// Recode time as month
gen month = .
	replace month = 1 if od_block_num == -12
	replace month = 2 if od_block_num == -11
	replace month = 3 if od_block_num == -10
	replace month = 4 if od_block_num == -9
	replace month = 5 if od_block_num == -8
	replace month = 6 if od_block_num == -7
	replace month = 7 if od_block_num == -6
	replace month = 8 if od_block_num == -5
	replace month = 9 if od_block_num == -4
	replace month = 10 if od_block_num == -3
	replace month = 11 if od_block_num == -2
	replace month = 12 if od_block_num == -1
	replace month = 13 if od_block_num == 0
	replace month = 14 if od_block_num == 1
	replace month = 15 if od_block_num == 2
	replace month = 16 if od_block_num == 3
	replace month = 17 if od_block_num == 4
	replace month = 18 if od_block_num == 5
	replace month = 19 if od_block_num == 6
	replace month = 20 if od_block_num == 7
	replace month = 21 if od_block_num == 8
	replace month = 22 if od_block_num == 9
	replace month = 23 if od_block_num == 10
	replace month = 24 if od_block_num == 11


**************************************************
** Panel data analysis
**************************************************
// IVs
global xlist female i.race1 i.ethnic age_od i.marital_status ind_service_connect_50 ind_elix_n_comorb med ind_nicotine i.rural2 ind_rx_antidepressant_90d ind_rx_benzodiazepine_90d ind_rx_musclerelaxant_90d ind_rx_stimulant_90d ind_elix_lung_chronic i.ckd i.hepatitis i.ind_elix_alcohol


/*
Note: At this point, we can limit the cohort to od_sub == 0.
Make sure to invoke the following code:
keep if od_sub == 0
*/

// WHOLE COHORT
**************************************************
** Total Costs (VA + cc)
**************************************************
// average costs per month
egen totcost_monthly = mean(all_total_bcost), by(month ind_tx)


// XSET
xtset patientid month

*** GEE model and marginal effects
xtgee all_total_bcost i.ind_tx i.month i.ind_tx#i.month $xlist, family(gaussian) link(identity) cor(ar1) vce(robust)

margins, dydx(ind_tx) at(month = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24))


// Plot with average and 95% CI for the Total costs (VA + cc)
preserve 

	gen hi = .
	gen lo = .

	forvalues j = 0/1 {
		forvalues i = 1/24{
			ci means all_total_bcost if month == `i' & ind_tx == `j'
			replace lo = r(lb) if month == `i' & ind_tx == `j'
			replace hi = r(ub) if month == `i' & ind_tx == `j'
		}
	}

	summ totcost_monthly lo hi 
	sort month


	graph twoway (connected totcost_monthly month if ind_tx == 1, msize(small) color(navy)) ///
				 (rcap lo hi month if ind_tx == 1, color(navy) saving(gtotal_va_cc, replace)) ///
				 (connected totcost_monthly month if ind_tx == 0, msize(small) color(cranberry)) ///
				 (rcap lo hi month if ind_tx == 0, color(cranberry) title("Total costs (VA + cc)") ytitle("Costs ($)") xtitle("Time (month)") ylabel(, labsize(small) nogrid) xlabel(, labsize(small)) graphregion(color(white)) bgcolor(white) legend(region(lcolor(white)) order(1 "OD group" 3 "Control")))

restore

