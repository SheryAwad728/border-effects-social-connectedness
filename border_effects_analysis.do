*****************************Enrollment Information****************************

cd "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project/productDownload_2026-04-05T192139"


****** use varnames(1) as row 1 contains the actual header names 
import delimited "ACSST5Y2024.S1401-Data.csv", varnames(1) clear

summarize

describe

describe, full

* keep only relevant variables - % of college_enrollment per county 
keep geo_id name s1401_c02_008e

* convert from string to numeric
destring s1401_c02_008e, replace force

* rename to something readable
rename s1401_c02_008e pct_undergrad_enrolled

* verify
summarize pct_undergrad_enrolled

** to extract the FIPS code 
gen fips = substr(geo_id, -5, 5)
destring fips, replace


keep fips pct_undergrad_enrolled

save "college_enrollment.dta", replace

************************************Merging*************************************

***to merge with my main dataset

* set globals
global enroll "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project/productDownload_2026-04-05T192139/college_enrollment.dta"
global enroll_friend "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project/productDownload_2026-04-05T192139/college_enrollment_friend.dta"



* create user version (fips = user_region)
use "$enroll", clear
rename fips user_region
save "$enroll", replace

use "$enroll", clear
destring user_region, replace force
save "$enroll", replace

* create friend version from user version
use "$enroll", clear
rename user_region friend_region
save "$enroll_friend", replace

use "$enroll_friend", clear
destring friend_region, replace force
save "$enroll_friend", replace


cd "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project"


import delimited "us_counties.csv", clear


***** merge for USER's county

merge m:1 user_region using "$enroll", keepusing(pct_undergrad_enrolled)
rename pct_undergrad_enrolled pct_enroll_user
drop _merge

 **10,243,188 matched — the vast majority of your data merged successfully
 **22,428 unmatched from master — these are rows main data where the county code didn't  find a match in the census data (Puerto Rico, or missing codes)
 **26 unmatched from using — 26 counties in the census data that don't appear in main dataset 

* save after first merge
save "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project/temp.dta", replace



**** merge for Friend's county 

merge m:1 friend_region using "$enroll_friend", keepusing(pct_undergrad_enrolled)
rename pct_undergrad_enrolled pct_enroll_friend
drop _merge

** same as user's county 
**10,243,188 matched — the vast majority of your data merged successfully
 **22,428 unmatched from master — these are rows main data where the county code didn't  find a match in the census data (Puerto Rico, or missing codes)
 **26 unmatched from using — 26 counties in the census data that don't appear in main dataset 

save "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project/temp.dta", replace
 

*** to create a difference variable between enrollment in User's county and 
** friend's county

** differencein the enrollment between each two counties
gen enroll_diff = abs(pct_enroll_user - pct_enroll_friend)

** average enrollment between each two counties
gen enroll_avg = (pct_enroll_user + pct_enroll_friend)/2


save "us_counties_final.dta", replace


****************************Dist Between Counties*******************************

*** https://simplemaps.com/data/us-counties

***** to get the distances between coutnties

cd "/Users/sheryawad/Desktop/Spring 26/International Trade and Development 670/Term Project"


import delimited "uscounties.csv", varnames(1) clear
keep county_fips lat lng
save "county_coords.dta", replace

* create user version of coords file
use "county_coords.dta", clear
rename county_fips user_region
save "county_coords_user.dta", replace

* create friend version of coords file
use "county_coords.dta", clear
rename county_fips friend_region
save "county_coords_friend.dta", replace

use "us_counties_final.dta", clear

* merge lat/lng for user county
merge m:1 user_region using "county_coords_user.dta", keepusing(lat lng)
rename lat lat_user
rename lng lng_user
drop _merge

*** Matched 9,993,301 
**unmatched   272,366

* merge lat/lng for friend county
merge m:1 friend_region using "county_coords_friend.dta", keepusing(lat lng)
rename lat lat_friend
rename lng lng_friend
drop _merge

*** Matched 9,993,301 
**unmatched   272,366



***Calculate Distance 

gen dist = 6371 * 2 * asin(sqrt(sin((lat_friend - lat_user) * _pi/180 / 2)^2 + cos(lat_user * _pi/180) * cos(lat_friend * _pi/180) * sin((lng_friend - lng_user) * _pi/180 / 2)^2))

gen ln_dist = ln(dist)

summarize dist ln_dist


save "us_counties_final.dta", replace


*********************************Contiguity************************************

****8 Census Bureau's Adjacency File for contiguity/border dummy variable


import delimited "county_adjacency2025.txt", delimiter("|") varnames(1) clear


keep countygeoid neighborgeoid length

* rename to match your main dataset
rename countygeoid user_region
rename neighborgeoid friend_region

* create contiguity dummy
gen contiguous = 1

* save
save "adjacency.dta", replace


use "us_counties_final.dta", clear
merge m:1 user_region friend_region using "adjacency.dta", keepusing(contiguous)
replace contiguous = 0 if _merge == 1
drop _merge

 *Not matched                    10,247,179
       *from master                10,246,939  (_merge==1)
        *from using                        240  (_merge==2)

   * Matched                            18,728  (_merge==3)


** 18,728 matched = county pairs that share a border → contiguous = 1
**10,246,939 unmatched from master = county pairs that don't share a border 
    * → contiguous = 0


* verify
tab contiguous
summarize contiguous



save "us_counties_final.dta", replace


**** cleaning the data 


summarize

count if user_region == friend_region

****** 3,119 that means we have same county data 

** Same County 

gen same_county = (user_region == friend_region)

sum same_county

*** county border dummy 

gen different_county = (user_region != friend_region)

sum different_county



* sum same_county
*   Variable |        Obs        Mean    Std. dev.       Min        Max
*-------------+---------------------------------------------------------
* same_county |  9,728,161    .0003206    .0179029          0          1. 

* sum different_county
*    Variable |        Obs        Mean    Std. dev.       Min        Max
*-------------+---------------------------------------------------------
*different_~y |  9,728,161    .9996794    .0179029          0          1

*** this means I am unable to do county border analysis as there are not enough 
* county to same county observations 



use "us_counties_final.dta", clear


drop if missing(dist)

save "us_counties_final.dta", replace


*********************************Cleaning***************************************


use "us_counties_final.dta", clear

drop if user_region == friend_region
** 3,119 observations deleted 

count if dist==0
* =0 

sum


drop if missing(scaled_sci)
* 0 observations deleted 

drop if missing(enroll_diff)
*0 observations dropped 

drop if missing(enroll_avg)
* 6,236 observations deleted 


gen user_state = floor(user_region/1000)
gen friend_state = floor(friend_region/1000)
gen different_state = (user_state != friend_state)



replace dist = 1 if dist == 0

summarize scaled_sci ln_dist contiguous enroll_avg

save "us_counties_final.dta", replace


**************************Major Public University*******************************

	
**** adding if there is a strong public university to see how that affects 
** borders


import delimited "Most-Recent-Cohorts-Institution.csv", varnames(1) clear
			 
			 
* keep only public institutions
keep if control == 1  
* 1 = public 
* 4,274 observations deleted

* keep relevant variables
keep unitid instnm city stabbr zip ugds
* ugds = undergraduate enrollment 

rename ugds enrollment

drop if missing(enrollment)
* 0 observations dropped 


destring enrollment, replace force
drop if missing(enrollment)
*156 observations deleted


gen major_public = (enrollment >= 15000)

* verify
tab major_public
summarize enrollment if major_public == 1
list unitid instnm enrollment if major_public == 1 in 1/10
			 
save "scorecard_public.dta", replace			 

			 
*******************************Zip-County***************************************			 
			 
import excel "ZIP_COUNTY_122025.xlsx", firstrow clear

describe			 
			 
* Keeping only the needed variables
keep ZIP COUNTY RES_RATIO

* save crosswalk
save "zip_county_crosswalk.dta", replace		


******

use "zip_county_crosswalk.dta", clear

* keep only the best county match per zip- as zip codes can span multiple 
*counties, so I only want to keep the ones with the largest overlap

bysort ZIP (RES_RATIO): keep if _n == _N

* rename to match scorecard data
rename ZIP zip5
rename COUNTY county_fips
destring county_fips, replace force

save "zip_county_crosswalk.dta", replace	 


*********************************Merging***************************************
			 
* merging with the "scorecard_public.dta" data set (Universities data set)

use "scorecard_public.dta", clear 

* clean zip to 5 digits
gen zip5 = substr(zip, 1, 5)

* merge with crosswalk
merge m:1 zip5 using "zip_county_crosswalk.dta", keepusing(county_fips)
drop if _merge == 2
* 37,732 observations deleted
drop _merge

* Result                      Number of obs
*    -----------------------------------------
*    Not matched                        37,744
*        from master                        12  (_merge==1)
*        from using                     37,732  (_merge==2)
*
*    Matched                             1,880  (_merge==3)
*    -----------------------------------------



* collapse to county level
collapse (max) major_public (sum) enrollment, by(county_fips)
drop if missing(county_fips)
* 1 observation deleted 

tab major_public
summarize



** 11.53% of counties have major public universities. 



save "county_university.dta", replace


********************************************************************************
			 
**Merge with original dataset:			 
		
* create user version
use "county_university.dta", clear
rename county_fips user_region
rename major_public major_public_user
rename enrollment univ_enroll_user
save "county_univ_user.dta", replace

* create friend version
use "county_university.dta", clear
rename county_fips friend_region
rename major_public major_public_friend
rename enrollment univ_enroll_friend
save "county_univ_friend.dta", replace

* merge with main dataset
use "us_counties_final.dta", clear

merge m:1 user_region using "county_univ_user.dta"
replace major_public_user = 0 if _merge == 1
replace univ_enroll_user = 0 if _merge == 1
drop _merge

merge m:1 friend_region using "county_univ_friend.dta"
replace major_public_friend = 0 if _merge == 1
replace univ_enroll_friend = 0 if _merge == 1
drop _merge


    *Result                      Number of obs
    *-----------------------------------------
    *Not matched                     6,240,274
        *from master                 6,240,254  (_merge==1)
        *from using                         20  (_merge==2)

    *Matched                         3,478,572  (_merge==3)
    *-----------------------------------------



tab major_public_user
tab major_public_friend

** 4.20 of the county pairs involve a county with a mjor public university
* 95.80% don't 


save "us_counties_final.dta", replace
			 
			 
**************************Cleaning Data*************************************** 			 

use "us_counties_final.dta", clear


* drop unused variables
drop univ_enroll_user    // never used in regressions
drop univ_enroll_friend  // never used in regressions
drop major_public_friend // never used in regressions
drop lat_user lng_user lat_friend lng_friend
drop pct_enroll_user pct_enroll_friend
drop if missing(scaled_sci)

describe
summarize



*    Variable |        Obs        Mean    Std. dev.       Min        Max
*-------------+---------------------------------------------------------
*user_country |          0
*friend_cou~y |          0
* user_region |  9,718,806    30364.24    15183.59       1001      56045
*friend_reg~n |  9,718,806    30364.24    15183.59       1001      56045
*  scaled_sci |  9,718,806    24262.96      499661          1   2.11e+08
*-------------+---------------------------------------------------------
* enroll_diff |  9,718,806    8.526992     8.95299          0       85.3
*  enroll_avg |  9,718,806    16.41972    6.179959          0       79.8
*        dist |  9,718,806    1428.811    941.6839   .9273676   8443.753
*     ln_dist |  9,718,806    7.041274    .7208354  -.0754053   9.041183
*  contiguous |  9,718,806    .0018864    .0433922          0          1
*-------------+---------------------------------------------------------
*  user_state |  9,718,806    30.26042    15.16595          1         56
*friend_state |  9,718,806    30.26042    15.16595          1         56
*different_~e |  9,718,806    .9696701    .1714933          0          1
*major_publ~r |  9,718,806    .0420141    .2619107          0          1

 



save "us_counties_final.dta", replace

************************ Re_identifiing Flagship *******************************


import delimited "Most-Recent-Cohorts-Institution.csv", varnames(1) clear
describe


* keep only public institutions
keep if control == 1

* keep relevant variables including coordinates
keep unitid instnm stabbr zip ugds latitude longitude

rename ugds enrollment

destring enrollment, replace force
drop if missing(enrollment)

* convert coordinates to numeric
destring latitude, replace force
destring longitude, replace force
drop if missing(latitude) | missing(longitude)

* keep only flagships (15,000+ undergrads)
keep if enrollment >= 15000

* keep only the LARGEST institution per state as the state flagship
bysort stabbr (enrollment): keep if _n == _N

* verify - should have one row per state
tab stabbr

* get state_fips from zip via the crosswalk you already built
gen zip5 = substr(zip, 1, 5)
merge m:1 zip5 using "zip_county_crosswalk.dta", keepusing(county_fips) nogen keep(match master)
gen state_fips = floor(county_fips / 1000)

* keep only what's needed for the distance calculation
keep state_fips latitude longitude instnm
save "flagship_coords.dta", replace


* compute distance from each county centroid to its in-state flagship

use "county_coords.dta", clear
* has: county_fips, lat, lng

gen state_fips = floor(county_fips / 1000)

merge m:1 state_fips using "flagship_coords.dta", nogen keep(match master)

* haversine distance to flagship (same formula as your county-to-county distance)
gen dist_to_flagship = 6371 * 2 * asin(sqrt( ///
    sin((latitude - lat) * _pi/180 / 2)^2 + ///
    cos(lat * _pi/180) * cos(latitude * _pi/180) * ///
    sin((longitude - lng) * _pi/180 / 2)^2))

summarize dist_to_flagship

* catchment dummies at three thresholds
gen in_catchment_100 = (dist_to_flagship <= 100)
gen in_catchment_150 = (dist_to_flagship <= 150)
gen in_catchment_200 = (dist_to_flagship <= 200)

tab in_catchment_100
tab in_catchment_150
tab in_catchment_200

keep county_fips state_fips in_catchment_100 in_catchment_150 in_catchment_200
save "county_flagship_catchment.dta", replace


* build SharedFlagship_ij at the pair level

* user version
use "county_flagship_catchment.dta", clear
rename county_fips user_region
rename state_fips flagship_state_user
rename in_catchment_100 catchment100_user
rename in_catchment_150 catchment150_user
rename in_catchment_200 catchment200_user
save "catchment_user.dta", replace

* friend version
use "county_flagship_catchment.dta", clear
rename county_fips friend_region
rename state_fips flagship_state_friend
rename in_catchment_100 catchment100_friend
rename in_catchment_150 catchment150_friend
rename in_catchment_200 catchment200_friend
save "catchment_friend.dta", replace

* merge into main dataset
use "us_counties_final.dta", clear

merge m:1 user_region using "catchment_user.dta", nogen keep(match master)
merge m:1 friend_region using "catchment_friend.dta", nogen keep(match master)

* SharedFlagship_ij = 1 if both counties are within catchment of the SAME state flagship
gen shared_flagship_100 = (catchment100_user == 1 & catchment100_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)
gen shared_flagship_150 = (catchment150_user == 1 & catchment150_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)
gen shared_flagship_200 = (catchment200_user == 1 & catchment200_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)

tab shared_flagship_100 
* 0.12
tab shared_flagship_150
* 0.42
tab shared_flagship_200
* 0.80
save "us_counties_final.dta", replace



use "us_counties_final.dta", clear
tab shared_flagship_100 different_state
tab shared_flagship_150 different_state
tab shared_flagship_200 different_state





describe





***************************Running Regressions*********************************			 
			 
**************************** OLS ****************************

use "us_counties_final.dta", clear
cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)

eststo clear

*** Column 1 - Base OLS
eststo ols1: reghdfe ln_scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Education Similarity OLS
eststo ols2: reghdfe ln_scaled_sci ln_dist contiguous different_state enroll_diff, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 3 - Similarity Interaction OLS
*** enroll_diff varies at pair level so different_state=1 has a coefficient
eststo ols3: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state enroll_diff ///
    c.enroll_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Avg Enrollment Interaction OLS
*** enroll_avg is county level so only same state (different_state=0) survives fixed effects
eststo ols4: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - University Mechanism OLS
*** major_public_user is county level so only same state (different_state=0) survives fixed effects
eststo ols5: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - All mechanisms together OLS
eststo ols6: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    enroll_diff ///
    c.enroll_diff#i.different_state ///
    c.enroll_avg#i.different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab ols1 ols2 ols3 ols4 ols5 ols6 using "results_table_ols.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Effect of State Borders on County-Level Social Connectedness - OLS") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
    scalars("r2 R-squared" "r2_a Adjusted R-squared") ///
    nonumbers booktabs noconstant ///
    keep(ln_dist contiguous different_state enroll_diff ///
         "1.different_state#c.enroll_diff" ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.major_public_user") ///
    order(ln_dist contiguous different_state enroll_diff ///
          "1.different_state#c.enroll_diff" ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.major_public_user") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              enroll_diff "Undergraduate Enrollment Difference" ///
              "1.different_state#c.enroll_diff" "Cross-State $\times$ Undergrad. Enrollment Diff." ///
              "0.different_state#c.enroll_avg" "Within-State $\times$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.major_public_user" "Within-State $\times$ Major Public University") ///
    addnotes("Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Dependent variable is log SCI." ///
             "Column (1): Base gravity model. Column (2): Adds enrollment similarity." ///
             "Column (3): Splits enrollment effect into within and cross-state components." ///
             "Column (4): Average enrollment interaction. Column (5): University presence mechanism." ///
             "Column (6): Includes all mechanisms simultaneously. Coefficient instability" ///
             "reflects multicollinearity between enrollment variables. Columns 3-5 preferred.")

**************************** PPML ****************************

*** Column 1 - Base PPML
eststo m1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Enrollment Similarity PPML
eststo m2: ppmlhdfe scaled_sci ln_dist contiguous different_state enroll_diff, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 3 - Similarity Interaction PPML
*** enroll_diff varies at pair level so different_state=1 has a coefficient
eststo m3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state enroll_diff ///
    c.enroll_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Avg Enrollment Interaction PPML
*** enroll_avg is county level so only same state (different_state=0) survives fixed effects
eststo m4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - University Mechanism PPML
*** major_public_user is county level so only same state (different_state=0) survives fixed effects
eststo m5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - All mechanisms together PPML
eststo m6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    enroll_diff ///
    c.enroll_diff#i.different_state ///
    c.enroll_avg#i.different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

** export PPML table
esttab m1 m2 m3 m4 m5 m6 using "results_table.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Effect of State Borders on County-Level Social Connectedness - PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state enroll_diff ///
         "1.different_state#c.enroll_diff" ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.major_public_user") ///
    order(ln_dist contiguous different_state enroll_diff ///
          "1.different_state#c.enroll_diff" ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.major_public_user") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              enroll_diff "Undergraduate Enrollment Difference" ///
              "1.different_state#c.enroll_diff" "Cross-State $\times$ Undergrad. Enrollment Diff." ///
              "0.different_state#c.enroll_avg" "Within-State $\times$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.major_public_user" "Within-State $\times$ Major Public University") ///
    addnotes("Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base gravity model. Column (2): Adds enrollment similarity." ///
             "Column (3): Splits enrollment effect into within and cross-state components." ///
             "Column (4): Average enrollment interaction. Column (5): University presence mechanism." ///
             "Column (6): Includes all mechanisms simultaneously. Coefficient instability" ///
             "reflects multicollinearity between enrollment variables. Columns 3-5 preferred.")

save "us_counties_final.dta", replace

use "us_counties_final.dta", replace 

sum

drop user_country friend_country 

ssc install logout

logout, save("summary_stats") tex replace: ///
    tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_diff enroll_avg major_public_user, ///
    statistics(obs mean sd min max n) ///
    columns(statistics)
	
estpost tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_diff enroll_avg major_public_user, ///
    statistics(mean sd min max n) ///
    columns(statistics)

esttab using "summary_stats.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    title("Summary Statistics - Full Sample") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs.") ///
    label ///
    nonumber ///
    booktabs ///
    noobs ///
    addnotes("All statistics computed at the county-pair level." ///
             "Sample consists of 9,718,806 county pairs." ///
             "Enrollment variables measured in percentage points.")

			 ********************************************************************************
		 			 
********************* Adding Political Similarities *****************************

* importing the data
import delimited "countypres_2000-2024.csv", varnames(1) clear

* keep only 2020 presidential election
keep if year == 2020
keep if party == "REPUBLICAN"

* keep only TOTAL mode to avoid duplicates
keep if mode == "TOTAL"

* convert to numeric
destring candidatevotes, replace force
destring county_fips, replace force

* calculate republican vote share
gen rep_share = candidatevotes / totalvotes

* check for remaining duplicates
duplicates report county_fips

* keep only what's needed
keep county_fips rep_share

* verify
summarize rep_share

* save base version
save "political.dta", replace

* create user version
rename county_fips user_region
rename rep_share rep_share_user
save "political_user.dta", replace

* create friend version
use "political.dta", clear
rename county_fips friend_region
rename rep_share rep_share_friend
save "political_friend.dta", replace

* merge with main dataset
use "us_counties_final.dta", clear

merge m:1 user_region using "political_user.dta"
drop _merge

merge m:1 friend_region using "political_friend.dta"
drop _merge

* Result                      Number of obs
*    -----------------------------------------
*    Not matched                     2,752,381
*        from master                 2,752,311  (_merge==1)
*        from using                         70  (_merge==2)
*
*    Matched                         6,966,566  (_merge==3)
*    -----------------------------------------



* create political difference variable
gen political_diff = abs(rep_share_user - rep_share_friend)

* verify
summarize rep_share_user rep_share_friend political_diff

count if missing(political_diff)
* 4,725,928

* which user regions have no political data
bysort user_region: gen tag = (_n == 1)
tab user_state if missing(rep_share_user) & tag == 1

* problem: almost half the dataset has missing political data
* some states report by district not by county
* state average fix attempted but 11 states have completely missing data:
* Arizona, Arkansas, Connecticut, Georgia, Iowa, Kentucky, Maryland,
* North Carolina, Oklahoma, South Carolina, Virginia
* solution: drop missing observations and save as restricted dataset
* note:
			 
drop if missing(political_diff)
* 4,725,886 observations deleted

* verify
count
* 4,993,061 observations

summarize political_diff

* save as separate restricted dataset
save "us_counties_final_with_political.dta", replace			 

********************************************************************************

			 
* load restricted dataset
use "us_counties_final_with_political.dta", clear

eststo clear

*** Column 1 - Base PPML (restricted sample - robustness check)
eststo p1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Education similarity (restricted sample)
eststo p2: ppmlhdfe scaled_sci ln_dist contiguous different_state enroll_diff, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 3 - University mechanism (restricted sample)
*** major_public_user is county level so only same state (different_state=0) survives
eststo p3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Political similarity (total effect)
eststo p4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state political_diff ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Political interaction
*** political_diff is pair level so different_state=1 has a coefficient
*** do NOT include standalone political_diff to avoid collinearity
eststo p5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - All mechanisms together
eststo p6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    enroll_diff ///
    c.major_public_user#i.different_state ///
    political_diff ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

* export PPML political table
esttab p1 p2 p3 p4 p5 p6 using "results_political.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Effect of State Borders on Social Connectedness - Restricted Sample PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state enroll_diff ///
         "0.different_state#c.major_public_user" ///
         political_diff ///
         "1.different_state#c.political_diff") ///
    order(ln_dist contiguous different_state enroll_diff ///
          "0.different_state#c.major_public_user" ///
          political_diff ///
          "1.different_state#c.political_diff") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              enroll_diff "Undergraduate Enrollment Difference" ///
              "0.different_state#c.major_public_user" "Within-State $\times$ Major Public University" ///
              political_diff "Political Difference" ///
              "1.different_state#c.political_diff" "Cross-State $\times$ Political Difference") ///
    addnotes("Sample restricted to counties with available 2020 presidential election data." ///
             "11 states excluded due to missing county-level election data." ///
             "Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base gravity model. Column (2): Adds enrollment similarity." ///
             "Column (3): University presence mechanism. Column (4): Political similarity." ///
             "Column (5): Cross-state political interaction. Column (6): All mechanisms.")
		 

estpost tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_diff enroll_avg ///
    major_public_user political_diff, ///
    statistics(mean sd min max n) ///
    columns(statistics)

esttab using "summary_stats_political.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    title("Summary Statistics - Restricted Sample") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs.") ///
    label ///
    nonumber ///
    booktabs ///
    noobs ///
    addnotes("Sample restricted to counties with available 2020 election data." ///
             "11 states excluded due to missing county-level election data.")		 
		 
		 
		 
		 
save "us_counties_final_with_political.dta", replace		

******************************************************************************
*** Visuals
	 
ssc install spmap
ssc install shp2dta
ssc install mif2dta

* convert shapefile to Stata format

* spshape2dta is the newer command that handles type 5
spshape2dta "tl_2020_us_county/tl_2020_us_county", replace

use "tl_2020_us_county.dta", clear
describe
list in 1/5

* Step 1 - convert GEOID to numeric for merging
use "tl_2020_us_county.dta", clear
destring GEOID, replace
rename GEOID friend_region
save "county_map.dta", replace

* Step 2 - prepare LA connections
use "us_counties_final.dta", clear

* filter to Los Angeles County (FIPS = 6037)
keep if user_region == 6037

* keep top 100 connections
gsort -scaled_sci
keep in 1/100

* keep only needed variables
keep user_region friend_region scaled_sci

* normalize SCI for color intensity
gen sci_norm = scaled_sci / scaled_sci[1]

save "la_connections.dta", replace

* Step 3 - merge with map data on friend_region
use "county_map.dta", clear
merge 1:1 friend_region using "la_connections.dta"

* create connection variable
gen connection = scaled_sci if _merge == 3
replace connection = 0 if _merge == 1
drop _merge

save "county_map_final.dta", replace


use "county_map_final.dta", clear

* drop Alaska and Hawaii for cleaner map
* Alaska FIPS starts with 02, Hawaii with 15
destring STATEFP, replace
drop if STATEFP == 2   // Alaska
drop if STATEFP == 15  // Hawaii
drop if STATEFP > 56   // territories

* draw the map
spmap connection using "tl_2020_us_county_shp.dta", ///
    id(_ID) ///
    fcolor(Blues) ///
    ocolor(white) ///
    osize(0.01) ///
    clmethod(custom) ///
    clbreaks(0 1000 10000 50000 100000 500000) ///
    title("Social Connections from Los Angeles County, CA" ///
          "Top 99 County Connections by SCI", size(medium)) ///
    legend(title("SCI Value", size(small)) ///
           label(1 "No connection") ///
           label(2 "Low (1k-10k)") ///
           label(3 "Medium (10k-50k)") ///
           label(4 "High (50k-100k)") ///
           label(5 "Very High (100k-500k)")) ///
    ndfcolor(gs14) ///
    ndocolor(white) ///
    ndsize(0.01)

graph export "connections_map.png", replace width(3000)


use "county_map_final.dta", clear

destring STATEFP, replace
drop if STATEFP == 2
drop if STATEFP == 15
drop if STATEFP > 56

spmap connection using "tl_2020_us_county_shp.dta", ///
    id(_ID) ///
    fcolor(white Blues) ///
    ocolor(gs8) ///
    osize(0.01) ///
    clmethod(custom) ///
    clbreaks(0 1 1000 10000 50000 100000 500000) ///
    title("Social Connections from Los Angeles County, CA" ///
          "Darker = Stronger Connection", size(medium)) ///
    legend(title("SCI Value", size(small)) ///
           label(1 "No connection (0)") ///
           label(2 "Very Low (1-1k)") ///
           label(3 "Low (1k-10k)") ///
           label(4 "Medium (10k-50k)") ///
           label(5 "High (50k-100k)") ///
           label(6 "Very High (100k+)")) ///
    ndfcolor(gs14) ///
    ndocolor(white) ///
    ndsize(0.01)

graph export "connections_map_improved.png", replace width(3000)

use "county_map_final.dta", clear

destring STATEFP, replace
drop if STATEFP == 2
drop if STATEFP == 15
drop if STATEFP > 56

spmap connection using "tl_2020_us_county_shp.dta", ///
    id(_ID) ///
    fcolor(white Blues) ///
    ocolor(gs8) ///
    osize(0.01) ///
    clmethod(custom) ///
    clbreaks(0 1 1000 10000 50000 100000 500000) ///
    legend(off) ///
    title("") ///
    ndfcolor(gs14) ///
    ndocolor(white) ///
    ndsize(0.01)

graph export "connections_map_bg.png", replace width(4000)


clear
input str20 group value
"Cross-State" 0.38
"Within-State" 1.00
end

* draw bar chart
graph bar value, ///
    over(group, relabel(1 "Cross-State" 2 "Within-State")) ///
    bar(1, color(188 143 143%70)) ///
    bar(2, color(188 143 143%70)) ///
    ytitle("Relative Social Connectedness") ///
    title("State Borders Reduce Social Connectedness by 62%") ///
    subtitle("Baseline PPML Estimate") ///
    ylabel(0 0.2 0.4 0.6 0.8 1.0) ///
    blabel(bar, format(%4.2f)) ///
    note("Based on coefficient of -0.968 from Column (1), Table 1" ///
         "Cross-State = exp(-0.968) = 0.38 relative to Within-State baseline")

graph export "border_effect_bar.png", replace width(3000)


use "us_counties_final.dta", clear

* first rerun your regressions to have estimates stored
cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)

eststo clear

eststo m1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

eststo m2: ppmlhdfe scaled_sci ln_dist contiguous different_state enroll_diff, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

eststo m3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state enroll_diff ///
    c.enroll_diff#i.different_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

eststo m4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

eststo m5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

* coefficient plot of border effect across specifications
coefplot m1 m2 m3 m4 m5, ///
    keep(different_state) ///
    title("Border Effect Across Specifications" ///
          "PPML Estimates with 95% Confidence Intervals") ///
    xline(0, lcolor(red) lpattern(dash)) ///
    xtitle("Coefficient on Cross-State Pair") ///
    mlabel format(%9.3f) mlabposition(12) ///
    legend(order(1 "Base" 3 "Enroll. Diff." ///
                 5 "Enroll. Interaction" ///
                 7 "Avg. Enrollment" ///
                 9 "Flagship University") ///
           rows(1) size(small)) ///
    ylabel(1 "Base" 2 "Enroll. Diff." ///
           3 "Enroll. Interaction" ///
           4 "Avg. Enrollment" ///
           5 "Flagship University") ///
    graphregion(color(white))

graph export "coefplot.png", replace width(3000)

save "new.dta"

*******************************************************************************
*****************************Commuting Zones***********************************


import delimited "commuting-zones-2020.csv", varnames(1) clear
describe
list in 1/10


* keep only what's needed
keep fipstxt cz2020
rename fipstxt county_fips

* create user version
rename county_fips user_region
rename cz2020 cz_user
save "cz_user.dta", replace

* create friend version
import delimited "commuting-zones-2020.csv", varnames(1) clear
keep fipstxt cz2020
rename fipstxt county_fips
rename county_fips friend_region
rename cz2020 cz_friend
save "cz_friend.dta", replace

* merge into main dataset
use "us_counties_final.dta", clear

merge m:1 user_region using "cz_user.dta", nogen keep(match master)
merge m:1 friend_region using "cz_friend.dta", nogen keep(match master)

* SharedCZ_ij = 1 if both counties are in the same commuting zone
gen shared_cz = (cz_user == cz_friend)

tab shared_cz
tab shared_cz different_state

save "us_counties_final.dta", replace


********************************************************************************


use "us_counties_final.dta", clear

describe


drop enroll_diff user_country friend_country 
drop flagship_state_user flagship_state_friend
drop catchment100_user catchment150_user catchment200_user
drop catchment100_friend catchment150_friend catchment200_friend

cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)

save "us_counties_final.dta", replace

*******************************************************************************
*new regressions to run 

eststo clear

*** Column 1 - Base OLS
eststo sf_ols1: reghdfe ln_scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment OLS
eststo sf_ols2: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Shared Flagship 100km OLS
eststo sf_ols3: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_100#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km OLS
eststo sf_ols4: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Flagship 200km OLS
eststo sf_ols5: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_200#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - Commuting Zone OLS
eststo sf_ols6: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 7 - All mechanisms OLS (avg enrollment + flagship 150km + commuting zone)
eststo sf_ols7: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab sf_ols1 sf_ols2 sf_ols3 sf_ols4 sf_ols5 sf_ols6 sf_ols7 using "results_shared_flagship_ols.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Mechanisms of the Border Effect - OLS") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)") ///
    scalars("r2 R-squared" "r2_a Adjusted R-squared") ///
    nonumbers booktabs noconstant ///
    keep(ln_dist contiguous different_state ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.shared_flagship_100" ///
         "1.different_state#c.shared_flagship_100" ///
         "0.different_state#c.shared_flagship_150" ///
         "1.different_state#c.shared_flagship_150" ///
         "0.different_state#c.shared_flagship_200" ///
         "1.different_state#c.shared_flagship_200" ///
         "0.different_state#c.shared_cz" ///
         "1.different_state#c.shared_cz") ///
    order(ln_dist contiguous different_state ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.shared_flagship_100" ///
          "1.different_state#c.shared_flagship_100" ///
          "0.different_state#c.shared_flagship_150" ///
          "1.different_state#c.shared_flagship_150" ///
          "0.different_state#c.shared_flagship_200" ///
          "1.different_state#c.shared_flagship_200" ///
          "0.different_state#c.shared_cz" ///
          "1.different_state#c.shared_cz") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.different_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.shared_flagship_100" "Within-State \$\times\$ Shared Flagship (100 km)" ///
              "1.different_state#c.shared_flagship_100" "Cross-State \$\times\$ Shared Flagship (100 km)" ///
              "0.different_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.different_state#c.shared_flagship_150" "Cross-State \$\times\$ Shared Flagship (150 km)" ///
              "0.different_state#c.shared_flagship_200" "Within-State \$\times\$ Shared Flagship (200 km)" ///
              "1.different_state#c.shared_flagship_200" "Cross-State \$\times\$ Shared Flagship (200 km)" ///
              "0.different_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.different_state#c.shared_cz" "Cross-State \$\times\$ Shared Commuting Zone") ///
    addnotes("Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Dependent variable is log SCI." ///
             "Column (1): Base gravity model. Column (2): Average enrollment." ///
             "Columns (3)-(5): Shared flagship catchment at 100, 150, and 200 km thresholds." ///
             "Column (6): Shared commuting zone. Column (7): All mechanisms (150 km threshold)." ///
             "Within-State coefficient: effect on same-state pairs." ///
             "Cross-State coefficient: whether mechanism attenuates the border penalty.")

**************************** PPML ****************************


*** Column 1 - Base PPML
eststo sf_m1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment PPML
eststo sf_m2: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Shared Flagship 100km PPML
eststo sf_m3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_100#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km PPML
eststo sf_m4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Flagship 200km PPML
eststo sf_m5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_200#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - Commuting Zone PPML
eststo sf_m6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 7 - All mechanisms PPML (avg enrollment + flagship 150km + commuting zone)
eststo sf_m7: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab sf_m1 sf_m2 sf_m3 sf_m4 sf_m5 sf_m6 sf_m7 using "results_shared_flagship.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Mechanisms of the Border Effect - PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.shared_flagship_100" ///
         "1.different_state#c.shared_flagship_100" ///
         "0.different_state#c.shared_flagship_150" ///
         "1.different_state#c.shared_flagship_150" ///
         "0.different_state#c.shared_flagship_200" ///
         "1.different_state#c.shared_flagship_200" ///
         "0.different_state#c.shared_cz" ///
         "1.different_state#c.shared_cz") ///
    order(ln_dist contiguous different_state ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.shared_flagship_100" ///
          "1.different_state#c.shared_flagship_100" ///
          "0.different_state#c.shared_flagship_150" ///
          "1.different_state#c.shared_flagship_150" ///
          "0.different_state#c.shared_flagship_200" ///
          "1.different_state#c.shared_flagship_200" ///
          "0.different_state#c.shared_cz" ///
          "1.different_state#c.shared_cz") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.different_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.shared_flagship_100" "Within-State \$\times\$ Shared Flagship (100 km)" ///
              "1.different_state#c.shared_flagship_100" "Cross-State \$\times\$ Shared Flagship (100 km)" ///
              "0.different_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.different_state#c.shared_flagship_150" "Cross-State \$\times\$ Shared Flagship (150 km)" ///
              "0.different_state#c.shared_flagship_200" "Within-State \$\times\$ Shared Flagship (200 km)" ///
              "1.different_state#c.shared_flagship_200" "Cross-State \$\times\$ Shared Flagship (200 km)" ///
              "0.different_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.different_state#c.shared_cz" "Cross-State \$\times\$ Shared Commuting Zone") ///
    addnotes("Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base gravity model. Column (2): Average enrollment." ///
             "Columns (3)-(5): Shared flagship catchment at 100, 150, and 200 km thresholds." ///
             "Column (6): Shared commuting zone. Column (7): All mechanisms (150 km threshold)." ///
             "Within-State coefficient: effect on same-state pairs." ///
             "Cross-State coefficient: whether mechanism attenuates the border penalty.")
			 
			 
			 
******************************New-Political*************************************

* merge shared flagship and commuting zone into political dataset
use "us_counties_final_with_political.dta", clear

merge m:1 user_region using "catchment_user.dta", nogen keep(match master)
merge m:1 friend_region using "catchment_friend.dta", nogen keep(match master)

gen shared_flagship_100 = (catchment100_user == 1 & catchment100_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)
gen shared_flagship_150 = (catchment150_user == 1 & catchment150_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)
gen shared_flagship_200 = (catchment200_user == 1 & catchment200_friend == 1 & ///
                           flagship_state_user == flagship_state_friend)

merge m:1 user_region using "cz_user.dta", nogen keep(match master)
merge m:1 friend_region using "cz_friend.dta", nogen keep(match master)

gen shared_cz = (cz_user == cz_friend)

save "us_counties_final_with_political.dta", replace

********************************************************************************
use "us_counties_final_with_political.dta", clear

cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)
eststo clear

*** Column 1 - Base OLS (restricted sample)
eststo pol_ols1: reghdfe ln_scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment OLS
eststo pol_ols2: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Major Public University OLS
eststo pol_ols3: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km OLS
eststo pol_ols4: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Commuting Zone OLS
eststo pol_ols5: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - Political Difference (total effect) OLS
eststo pol_ols6: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state political_diff ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 7 - Political Interaction OLS
eststo pol_ols7: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 8 - All mechanisms OLS
eststo pol_ols8: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.major_public_user#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    political_diff ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab pol_ols1 pol_ols2 pol_ols3 pol_ols4 pol_ols5 pol_ols6 pol_ols7 pol_ols8 ///
    using "results_political_ols.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Effect of State Borders on Social Connectedness - Restricted Sample OLS") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)") ///
    scalars("r2 R-squared" "r2_a Adjusted R-squared") ///
    n
	
********************************************************************************
eststo clear

*** Column 1 - Base PPML (restricted sample)
eststo p1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment
eststo p2: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Major Public University
eststo p3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km
eststo p4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Commuting Zone
eststo p5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - Political Difference (total effect)
eststo p6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state political_diff ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 7 - Political Interaction
eststo p7: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 8 - All mechanisms
eststo p8: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    political_diff ///
    c.political_diff#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab p1 p2 p3 p4 p5 p6 p7 p8 using "results_political.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Effect of State Borders on Social Connectedness - Restricted Sample PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.major_public_user" ///
         "0.different_state#c.shared_flagship_150" ///
         "1.different_state#c.shared_flagship_150" ///
         "0.different_state#c.shared_cz" ///
         "1.different_state#c.shared_cz" ///
         political_diff ///
         "1.different_state#c.political_diff") ///
    order(ln_dist contiguous different_state ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.major_public_user" ///
          "0.different_state#c.shared_flagship_150" ///
          "1.different_state#c.shared_flagship_150" ///
          "0.different_state#c.shared_cz" ///
          "1.different_state#c.shared_cz" ///
          political_diff ///
          "1.different_state#c.political_diff") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.different_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.major_public_user" "Within-State \$\times\$ Major Public University" ///
              "0.different_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.different_state#c.shared_flagship_150" "Cross-State \$\times\$ Shared Flagship (150 km)" ///
              "0.different_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.different_state#c.shared_cz" "Cross-State \$\times\$ Shared Commuting Zone" ///
              political_diff "Political Difference" ///
              "1.different_state#c.political_diff" "Cross-State \$\times\$ Political Difference") ///
    addnotes("Sample restricted to counties with available 2020 presidential election data." ///
             "11 states excluded due to missing county-level election data." ///
             "Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base. Column (2): Average enrollment. Column (3): Major public university." ///
             "Column (4): Shared flagship 150km. Column (5): Shared commuting zone." ///
             "Column (6): Political difference. Column (7): Political interaction." ///
             "Column (8): All mechanisms simultaneously.")

save "us_counties_final_with_political.dta", replace

********************************************************************************



*********************** Border County Robustness Check ***********************

* restrict to counties that are adjacent to a state border
* i.e. keep only pairs where both counties are adjacent to a county
* in a different state

* first identify which counties are border counties
use "adjacency.dta", clear

* generate state for each side
gen user_state_adj = floor(user_region/1000)
gen friend_state_adj = floor(friend_region/1000)

* keep only cross-state adjacencies
keep if user_state_adj != friend_state_adj

* get unique list of border counties
keep user_region
duplicates drop
rename user_region border_county
save "border_counties.dta", replace

* merge into main dataset to flag border counties
use "us_counties_final.dta", clear

* flag if user county is a border county
merge m:1 user_region using "border_counties.dta", ///
    keepusing(border_county) nogen keep(match master)
gen is_border_user = (border_county != .)
drop border_county

* flag if friend county is a border county
merge m:1 friend_region using "border_counties.dta", ///
    keepusing(border_county) nogen keep(match master)
gen is_border_friend = (border_county != .)
drop border_county

* keep only pairs where BOTH counties are border counties
keep if is_border_user == 1 & is_border_friend == 1

count
* check how many observations remain

cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)

save "us_counties_border.dta", replace


*********************** Border County Regressions - PPML *********************

use "us_counties_border.dta", clear

eststo clear

*** Column 1 - Base PPML
eststo bc_m1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment PPML
eststo bc_m2: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Major Public University PPML
eststo bc_m3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km PPML
eststo bc_m4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Commuting Zone PPML
eststo bc_m5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - All mechanisms PPML
eststo bc_m6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab bc_m1 bc_m2 bc_m3 bc_m4 bc_m5 bc_m6 ///
    using "results_border_counties.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Border Effect Robustness - Counties Adjacent to State Borders - PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.major_public_user" ///
         "0.different_state#c.shared_flagship_150" ///
         "1.different_state#c.shared_flagship_150" ///
         "0.different_state#c.shared_cz" ///
         "1.different_state#c.shared_cz") ///
    order(ln_dist contiguous different_state ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.major_public_user" ///
          "0.different_state#c.shared_flagship_150" ///
          "1.different_state#c.shared_flagship_150" ///
          "0.different_state#c.shared_cz" ///
          "1.different_state#c.shared_cz") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.different_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.major_public_user" "Within-State \$\times\$ Major Public University" ///
              "0.different_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.different_state#c.shared_flagship_150" "Cross-State \$\times\$ Shared Flagship (150 km)" ///
              "0.different_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.different_state#c.shared_cz" "Cross-State \$\times\$ Shared Commuting Zone") ///
    addnotes("Sample restricted to county pairs where both counties are adjacent to a state border." ///
             "Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base gravity model. Column (2): Average enrollment." ///
             "Column (3): Major public university. Column (4): Shared flagship 150km." ///
             "Column (5): Shared commuting zone. Column (6): All mechanisms.")


*********************** Border County Regressions - OLS **********************

eststo clear

*** Column 1 - Base OLS
eststo bc_ols1: reghdfe ln_scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment OLS
eststo bc_ols2: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 3 - Major Public University OLS
eststo bc_ols3: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 150km OLS
eststo bc_ols4: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 5 - Shared Commuting Zone OLS
eststo bc_ols5: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

*** Column 6 - All mechanisms OLS
eststo bc_ols6: reghdfe ln_scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.different_state ///
    c.shared_flagship_150#i.different_state ///
    c.shared_cz#i.different_state ///
    , absorb(user_region friend_region) ///
    vce(cluster user_region friend_region)

esttab bc_ols1 bc_ols2 bc_ols3 bc_ols4 bc_ols5 bc_ols6 ///
    using "results_border_counties_ols.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Border Effect Robustness - Counties Adjacent to State Borders - OLS") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
    scalars("r2 R-squared" "r2_a Adjusted R-squared") ///
    nonumbers booktabs noconstant ///
    keep(ln_dist contiguous different_state ///
         "0.different_state#c.enroll_avg" ///
         "0.different_state#c.major_public_user" ///
         "0.different_state#c.shared_flagship_150" ///
         "1.different_state#c.shared_flagship_150" ///
         "0.different_state#c.shared_cz" ///
         "1.different_state#c.shared_cz") ///
    order(ln_dist contiguous different_state ///
          "0.different_state#c.enroll_avg" ///
          "0.different_state#c.major_public_user" ///
          "0.different_state#c.shared_flagship_150" ///
          "1.different_state#c.shared_flagship_150" ///
          "0.different_state#c.shared_cz" ///
          "1.different_state#c.shared_cz") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.different_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.different_state#c.major_public_user" "Within-State \$\times\$ Major Public University" ///
              "0.different_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.different_state#c.shared_flagship_150" "Cross-State \$\times\$ Shared Flagship (150 km)" ///
              "0.different_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.different_state#c.shared_cz" "Cross-State \$\times\$ Shared Commuting Zone") ///
    addnotes("Sample restricted to county pairs where both counties are adjacent to a state border." ///
             "Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Dependent variable is log SCI." ///
             "Column (1): Base gravity model. Column (2): Average enrollment." ///
             "Column (3): Major public university. Column (4): Shared flagship 150km." ///
             "Column (5): Shared commuting zone. Column (6): All mechanisms.")

save "us_counties_border.dta", replace






****************************Own Catchment Area**********************************



use "us_counties_final.dta", clear

merge m:1 user_region using "catchment_user.dta", nogen keep(match master)
merge m:1 friend_region using "catchment_friend.dta", nogen keep(match master)

gen own_flagship_100 = (catchment100_user == 1 & catchment100_friend == 1 & ///
                        !missing(flagship_state_user) & !missing(flagship_state_friend))
gen own_flagship_150 = (catchment150_user == 1 & catchment150_friend == 1 & ///
                        !missing(flagship_state_user) & !missing(flagship_state_friend))
gen own_flagship_200 = (catchment200_user == 1 & catchment200_friend == 1 & ///
                        !missing(flagship_state_user) & !missing(flagship_state_friend))

tab own_flagship_100
tab own_flagship_150
tab own_flagship_200

drop flagship_state_user flagship_state_friend ///
     catchment100_user catchment150_user catchment200_user ///
     catchment100_friend catchment150_friend catchment200_friend




gen same_state = 1 - different_state




save "us_counties_final.dta", replace


cap drop ln_scaled_sci
gen ln_scaled_sci = ln(scaled_sci)

eststo clear

*** Column 1 - Base
eststo m1: ppmlhdfe scaled_sci ln_dist contiguous different_state, ///
    absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 2 - Avg Enrollment
eststo m2: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 3 - Major Public University
eststo m3: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.major_public_user#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 4 - Shared Flagship 100km
eststo m4: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_100#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 5 - Shared Flagship 150km
eststo m5: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_150#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 6 - Shared Flagship 200km
eststo m6: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_flagship_200#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 7 - Shared Commuting Zone (same_state only)
eststo m7: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.shared_cz#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 8 - Own Flagship 100km
eststo m8: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.own_flagship_100#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 9 - Own Flagship 150km
eststo m9: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.own_flagship_150#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 10 - Own Flagship 200km
eststo m10: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.own_flagship_200#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

*** Column 11 - All mechanisms
eststo m11: ppmlhdfe scaled_sci ///
    ln_dist contiguous different_state ///
    c.enroll_avg#i.same_state ///
    c.shared_flagship_150#i.same_state ///
    c.shared_cz#i.same_state ///
    , absorb(user_region friend_region) vce(cluster user_region friend_region)

esttab m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 using "results_main_ppml.tex", replace ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    title("Mechanisms of the Border Effect - PPML") ///
    mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)" "(10)" "(11)") ///
    scalars("ll Log-pseudolikelihood" "r2_p Pseudo R2") ///
    nonumbers booktabs alignment(c) ///
    keep(ln_dist contiguous different_state ///
         "0.same_state#c.enroll_avg" ///
         "0.same_state#c.major_public_user" ///
         "1.same_state#c.shared_flagship_100" ///
         "1.same_state#c.shared_flagship_150" ///
         "1.same_state#c.shared_flagship_200" ///
         "1.same_state#c.shared_cz" ///
         "1.same_state#c.own_flagship_100" ///
         "1.same_state#c.own_flagship_150" ///
         "1.same_state#c.own_flagship_200") ///
    order(ln_dist contiguous different_state ///
          "0.same_state#c.enroll_avg" ///
          "0.same_state#c.major_public_user" ///
          "1.same_state#c.shared_flagship_100" ///
          "1.same_state#c.shared_flagship_150" ///
          "1.same_state#c.shared_flagship_200" ///
          "1.same_state#c.shared_cz" ///
          "1.same_state#c.own_flagship_100" ///
          "1.same_state#c.own_flagship_150" ///
          "1.same_state#c.own_flagship_200") ///
    varlabels(ln_dist "Distance (log)" ///
              contiguous "Adjacent Counties (Shared Border)" ///
              different_state "Cross-State Pair" ///
              "0.same_state#c.enroll_avg" "Within-State \$\times\$ Avg. Undergrad. Enrollment" ///
              "0.same_state#c.major_public_user" "Within-State \$\times\$ Major Public University" ///
              "1.same_state#c.shared_flagship_100" "Within-State \$\times\$ Shared Flagship (100 km)" ///
              "1.same_state#c.shared_flagship_150" "Within-State \$\times\$ Shared Flagship (150 km)" ///
              "1.same_state#c.shared_flagship_200" "Within-State \$\times\$ Shared Flagship (200 km)" ///
              "1.same_state#c.shared_cz" "Within-State \$\times\$ Shared Commuting Zone" ///
              "1.same_state#c.own_flagship_100" "Within-State \$\times\$ Own Flagship (100 km)" ///
              "1.same_state#c.own_flagship_150" "Within-State \$\times\$ Own Flagship (150 km)" ///
              "1.same_state#c.own_flagship_200" "Within-State \$\times\$ Own Flagship (200 km)") ///
    addnotes("Robust standard errors clustered at the user and friend region levels." ///
             "All regressions include origin and destination county fixed effects." ///
             "Column (1): Base. Column (2): Avg enrollment. Column (3): Major public university." ///
             "Columns (4)-(6): Shared flagship at 100, 150, 200 km. Column (7): Shared commuting zone." ///
             "Columns (8)-(10): Own flagship at 100, 150, 200 km. Column (11): All mechanisms.")




tab same_state different_state






use "us_counties_final.dta", clear

label variable scaled_sci "Social Connectedness Index"
label variable dist "Distance (km)"
label variable ln_dist "Distance (log)"
label variable contiguous "Contiguous"
label variable different_state "Cross-State Pair"
label variable enroll_avg "Avg. Undergrad. Enrollment"
label variable major_public_user "Major Public University"
label variable shared_flagship_100 "Shared Flagship (100 km)"
label variable shared_flagship_150 "Shared Flagship (150 km)"
label variable shared_flagship_200 "Shared Flagship (200 km)"
label variable own_flagship_100 "Own Flagship (100 km)"
label variable own_flagship_150 "Own Flagship (150 km)"
label variable own_flagship_200 "Own Flagship (200 km)"
label variable shared_cz "Shared Commuting Zone"

estpost tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_avg major_public_user ///
    shared_flagship_100 shared_flagship_150 shared_flagship_200 ///
    own_flagship_100 own_flagship_150 own_flagship_200 ///
    shared_cz, ///
    statistics(mean sd min max n) ///
    columns(statistics)

esttab using "summary_stats_updated.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    title("Summary Statistics - Full Sample") ///
    collabels("Mean" "Std. Dev." "Min" "Max" "Obs.") ///
    nonumber booktabs noobs ///
    addnotes("All statistics computed at the county-pair level." ///
             "Sample consists of 9,718,806 county pairs." ///
             "Enrollment variables measured in percentage points." ///
             "Binary variables take values of 0 or 1.")
			 
			 
tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_avg major_public_user ///
    shared_flagship_100 shared_flagship_150 shared_flagship_200 ///
    own_flagship_100 own_flagship_150 own_flagship_200 ///
    shared_cz, ///
    statistics(mean sd min max n) ///
    columns(statistics)
	
	
	
logout, save("summary_stats_updated") tex replace: ///
    tabstat scaled_sci dist ln_dist contiguous ///
    different_state enroll_avg major_public_user ///
    shared_flagship_100 shared_flagship_150 shared_flagship_200 ///
    own_flagship_100 own_flagship_150 own_flagship_200 ///
    shared_cz, ///
    statistics(mean sd min max n) ///
    columns(statistics)
