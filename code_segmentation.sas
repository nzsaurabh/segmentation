/* SAS Code for Customer Segmentation

Based on Factor Analysis, and K-means Clustering of 
Customer Satisfaction Survey for a cafe

*/

** set working directory;

libname hold 'H:\clustering';

** import csat data;

PROC IMPORT OUT= work.csat 
            DATAFILE= "BinaryData.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

** check data and distribution;

** import into work;

 data csat;
 set hold.csat;
 run;

proc contents data = csat;
run;

** check data;
proc freq data = csat;
	table 
Q32: q77 q84 q37: ;
run;

** assign labels **;

data csat;
  set csat;
  label
  	q32a1 = "MostSatisfied"
	q37a1 = "PickUpSpeed"
	q37a2 = "Ease"
	q37a3 =  "Listen"
	q37a4 =  "Resolution"
	q37a11 =  "FollowUp"
	q37a12 =  "Friendly"
	q37a13 =  "Clarity"
	q37a14 =  "Knowledge"
	q37a15 =  "Importance"
	q37a16 =  "Professional"
	q37a17 =  "Response Speed"

	q77 = "Education"
	q84 = "Income"
 ;
 run;


** check correlation;

ods graphics on;
 PROC CORR data= csat outp= csatcorr NOPROB;
 var q32a1 q37: ;
  run;
ods graphics off;


*** Factor Analysis because clustering wasn't discriminating well between the data;

proc factor data = csat out = csat nfact = 2
rotate = varimax fuzz = 0.5;
var q32a1 q37: ;
run;


******* Segment based on Factor Scores;

data csat;
 set csat;
	maxfct=max(of factor1-factor2);
	seg=1;
	if factor2=maxfct then seg=2;
RUN;

***** Check Segment sizes;

proc freq data = csat;
	table seg ;
run;

********** data for spider chart;

proc tabulate data = hold.Csat;
class seg;
var q32a1 q37a1--q37a17 ;

table q32a1 q37a1--q37a17, mean * seg;

run;



******** check variation in education by segment;

proc freq data = csat;
tables seg * q77;
run;

******** check variation in income by segment;

proc freq data = csat;
tables seg * q84;
run;

******* check how education varies by income;

proc freq data = csat;
tables q77 * q84;
run;

**** check correlation between education and income;

ods graphics on;
 PROC CORR data= csat outp= incedu NOPROB;
 var q77 q84;
  run;
ods graphics off;


******* discrimanate - default priors 0.5, 0.5 ;

proc discrim data = csat outstat=outdisc method = normal pool=yes list crossvalidate;

class seg;

var q77 q84;

run;

******* discrimanate - proportional priors ;

proc discrim data = csat outstat=outdisc method = normal pool=yes crossvalidate;

class seg;

var q77 q84; priors prop;

run;

******* discrimanate - quadratic and proportional priors ;

proc discrim data = csat outstat=outdisc method = normal pool=no crossvalidate;

class seg;

var q77 q84 ; priors prop;

run;


************ code not used for final result because clustering wasn't useful;



** k means cluster - do this many times and find the most most
useful solution - change random seed (below it's 456);

 ** 3 clusters - Most Satisfied, Neutral and Least Satisfied; ** maxiter=10;

proc fastclus data=csat maxc=3 replace=random random=747 out=clusters maxiter=10;
   var q37: ;
run;

** check how good the classification is;

proc freq data = clusters;
tables cluster*q32a1;
run;


** 2 clusters - Most Satisfied and Least Satisfied; ** maxiter=10;

proc fastclus data=csat maxc=2 replace=random random=747 out=clusters3 maxiter=10;
   var q37:;
run;

** check how good the classification is;

proc freq data = clusters3;
tables cluster*q32a1;
run;

** results are not encouraging because 9.5% of those who gave an overall score of 8 were wrongly classified in Cluster 1;



* try ward's min var ;

proc cluster data=csat method=wards standard outtree=treedat pseudo;
      var q37:; 
  run;

** build the tree ;

  proc tree  data=treedat;
run;

proc tree data = treedat nclusters=2 out=outclus;
run;

** sort the data by cluster;

proc sort data =outclus;
	by cluster;


proc means data =outclus mean;
	by cluster;
	var q37a1 ; 
run;

proc freq data = csat;
	table q37a1 ;
run;


