/* Unos podataka */
libname PODACI base "/folders/myfolders/Podaci";                            * pravljenje biblioteke pod imenom PODACI;
run;


options validvarname=v7;   
proc import datafile="/folders/myfolders/Podaci/MiljanaTasic.xlsx"          * unosenje excel tabele sa podacima na sheet-u 'podaci';
			dbms=xlsx
			out=PODACI.MiljanaTasic  replace;                                     * u sas tabelu 'MiljanaTasic' iz biblioteke PODACI ;
			sheet=podaci;
run;


/* Deskriptivna statistika izmerenih obelezja */                            * prikaz apsolutne i relativne frekvencije kategorijalnih obelezja;
proc freq data=PODACI.MiljanaTasic;
	table pol redosled roditelji / nocum ;                                    * varijabli: pol, redosled rodjenja brace i sestara, status izmedju roditelja;
run;


proc means data=PODACI.MiljanaTasic N mean stddev median p25 p75 skewness kurtosis;    
	var uzrast st_funkc emoc ponasanje hiper vrsnjaci prosoc ukupno;          * opis numerickih obelezja metodima deskriptivne statistike, provera normalnosti raspodele;
run;                                                                        * ujedno i ispitivanje prve hipoteze;


/* Autori upitnika dali su sledeću kategorizaciju bodova: 1. niska verovatnoća postojanja klinički signifikantnih problema ovog tipa 
                                                          2. srednji rizik postojanja klinički signifikantninh probelma
                                                          3. označava visok rizik postojanja klinički signifikantnih problema ovog tipa.
  Potrebno je napraviti nove, kategorijalne varijable koje ce pokazati koliko dece je u kojoj rizik grupi. */

/* Pravljenje novih kolona u sas tabeli */     
%let novaKolona=ukupno1;  *st_funkc1 emoc1 ponasanje1 hiper1 vrsnjaci1 prosoc1 ukupno1;
proc sql;
   alter table PODACI.MiljanaTasic
      add &novaKolona num format=1.;
quit;	

/* Pravljenje kategorijalnih varijabli */                                    * granice kategorija odredili su autori upitnika;

data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if st_funkc <4 then do; st_funkc1 = 1; end;
	else if st_funkc >= 4 and st_funkc <=6 then do; st_funkc1 = 2;end;
	else do st_funkc1 =3;end;
run;
	
data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if emoc <=3 then do; emoc1 = 1; end;
	else if emoc=4 then do; emoc1 = 2; end;
	else do emoc1 =3;end;
run;

%let StaraKolona = ponasanje; * vrsnjaci;
%let NovaKolona = ponasanje1; * vrsnjaci1;
data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if &StaraKolona <=2 then do; &NovaKolona = 1; end;
	else if &StaraKolona=3 then do; &NovaKolona = 2; end;
	else do &NovaKolona =3;end;
run;

data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if hiper <=5 then do; hiper1 = 1; end;
	else if hiper=6 then do; hiper1 = 2; end;
	else do hiper1 =3; end;
run;

data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if prosoc >=6 then do; prosoc1 = 1; end;
	else if prosoc=5 then do; prosoc1 = 2; end;
	else do prosoc1 =3; end;
run;

data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
	if ukupno <=13 then do; ukupno1 = 1; end;
	else if ukupno>=14 and ukupno <17 then do; ukupno1 = 2; end;
	else do ukupno1 =3; end;
run;


/* Apsolutna i relativna frekvencija kategorijalnih varijabli */ 
proc freq data=PODACI.MiljanaTasic;                                                   * dobijamo uvid u broj dece u rizik grupama;
	table st_funkc1 emoc1 ponasanje1 hiper1 vrsnjaci1 prosoc1 ukupno1 / nocum;          * 1. hipoteza je ovim kompletno ispitana;
run;


/* 2. Hipoteza: ispitivanje uticaja porodicne klime na izmerena obelezja */           * vracamo se na numericka obelezja, i ispitujemo postojanje razlika u prosecnim vrednostima po grupama;

%let ZavisnaProm=st_funkc;  *st_funkc emoc ponasanje hiper vrsnjaci prosoc ukupno;
%let NezavisnaProm=roditelji; * redosled;
ods graphics / imagemap=on;

proc glm data=PODACI.MiljanaTasic;                                                    * kako varijable: roditelji i redosled imaju po 4 kategorije primenjuje se analiza varijanse;
	class &NezavisnaProm;                                                               * ispunjeni su uslovi za primenu ovog testa;
	model &ZavisnaProm=roditelji;
	means &NezavisnaProm / hovtest=levene welch plots=none;                                      
	lsmeans &NezavisnaProm / adjust=tukey pdiff alpha=.05;                              * koristi se Takijev naknadni test;
	run;
quit;

proc means data=PODACI.MiljanaTasic mean std min max n vardef=df;                     * prikaz deskriptivne statistike zavisne promenljive po grupama;
	var &ZavisnaProm;
	class &NezavisnaProm;
run;

/* Kako 80% uzorka čine porodice sa oba roditelja, a svega po 10% porodice sa razvedenim roditeljima ili samohranom majkom, izvršeno 
   je još jedno poređenje i to po grupama: porodice sa oba roditelja u odnosu na porodice sa jednim ili razvedenim roditeljima.  */

/* pravljenje nove varijable */                                                         
proc sql;
   alter table PODACI.MiljanaTasic
      add roditelji2 num format=1.;
quit;

data PODACI.MiljanaTasic replace;
	set PODACI.MiljanaTasic;
	keep _ALL_;
		if roditelji ="oba" then roditelji2 = 1;
		else do roditelji2 =2;
		end;
run;

/* Poredjenje izmedju dve grupe */
 ods graphics / imagemap=on;

/* Ispitivanje normalnosti raspodele */
proc univariate data=PODACI.MiljanaTasic normal mu0=0;
	ods select TestsForNormality;
	class roditelji2;
	var emoc;
run;

/* t test */
proc ttest data=PODACI.MiljanaTasic sides=2 h0=0 plots(showh0);
	class roditelji2;
	var emoc;
run;

/* Sledi ispitivanje postojanja znacajnih razlika u proporcijama kategorijalnih obelezja */

/* hi kvadrat test */
%let Varijabla1=st_funkc1;  *st_funkc1 emoc1 ponasanje1 hiper1 vrsnjaci1 prosoc1 ukupno1;
%let Varijabla2=roditelji;  * redosled;
proc freq data=PODACI.MiljanaTasic;
	tables &Varijabla1*&Varijabla2 / chisq nopercent norow ;
run;



/* 3. hipoteza: ispitivanje uticaja pola na smetnje u funkcionisanju */

/* Poredjenje izmedju dve grupe */
 ods graphics / imagemap=on;
 
%let ZavisnaVar=st_funkc; *st_funkc emoc ponasanje hiper vrsnjaci prosoc ukupno;
%let NezavisnaVar=pol;
/* Ispitivanje normalnosti */
proc univariate data=PODACI.MiljanaTasic normal mu0=0;
	ods select TestsForNormality;
	class &NezavisnaVar;
	var &ZavisnaVar;
run;

/* t test */
proc ttest data=PODACI.MiljanaTasic sides=2 h0=0 plots(showh0);
	class &NezavisnaVar;
	var &ZavisnaVar;
run;

/* hi kvadrat test */
proc freq data=PODACI.MiljanaTasic;
	tables &ZavisnaVar*&NezavisnaVar / chisq nopercent norow ;
run;


/* Hipoteze 4. i 5. : Korelaciona analiza*/                                     * uzimaju se u obzir samo numericka obelezja;
proc corr data=PODACI.MiljanaTasic pearson nosimple;
	var uzrast;
	with emoc ponasanje hiper vrsnjaci prosoc ukupno;
run;

proc corr data=PODACI.MiljanaTasic pearson nosimple;
	var st_funkc;
	with emoc ponasanje hiper vrsnjaci prosoc ukupno;
run;
