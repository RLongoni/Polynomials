README mvpoli.pl
//806853 Longoni Riccardo
//808314 Bertolo Alessandro

DISCLAIMER:
Assumiamo che l'input fornito ai predicati in forma interna sia stato ottenuto
tramite i predicati as_monomial/2 ed as_polynomial/2.
I predicati di controllo che abbiamo definito, oltre a controllare la struttura,
controllano anche: la congruenza del grado totale e del coefficiente,
l'ordinamento, e la semplificazione dei termini.
Se uno di questi parametri non e' verificato, i predicati falliscono.

NOTAZIONI UTILIZZATE (all'interno del progetto):
VP   --> v(P,V)				(variabile in forma interna)
VPs  --> [v(P,V), ...]			(lista di variabili in forma interna)
Mon  --> m(C,TD,VPs)			(monomio in forma interna)
Monomials --> [m(...), ...]		(lista di monomi in forma interna)
Poly --> poly([m(...), ...])		(polinomio in forma interna)
Exp  --> 2*x^2*...			(espressione da convertire)

PREDICATI DI CONTROLLO:
--- is_varpower/1 ---
Argomenti: VP
Controlla se la variabile data in input nella forma interna v(P,V), e' corretta
ovvero se P e' un intero >= 0 e V e' un atomo.
Altrimenti fallisce.

--- is_coefficient/1 ---
Argomenti: Mon
Controlla se il coefficiente del monomio dato in input in forma interna e' un
numero ed e' "congruente". Per congruente si intende che se esso e' pari a zero
allora il monomio deve essere nullo, ovvero scritto come: m(0,0,[]); se invece
non e' pari a zero, allora il grado totale e la lunghezza della lista delle
variabili possono essere maggiori o pari a zero.
Altrimenti fallisce.

--- is_real_monomial/1 ---
Argomenti: Mon
Controlla se il monomio dato in input in forma interna e' un monomio avente
una struttura corretta, un TD e un coefficiente corretti; ed inoltre se e'
ordinato e semplificato.
Il coefficiente viene controllato tramite il predicato is_coefficient/1, mentre
il TD, l'ordine e la semplificazione vengono controllati ottenendo a partire
dall'input, un monomio ordinato e semplificato, confrontandolo con quello in
ingresso.
Se uno dei controlli fallisce, il predicato fallisce.

--- is_real_polynomial/1 ---
Argomenti: Poly
Controlla se il polinomio dato in input in forma interna e' un polinomio avente
una struttura corretta, ed inoltre se e' ordinato e semplificato.
I singoli monomi che lo compongono vengono controllati tramite il predicato
is_real_monomial/1, mentre per l'ordinamento e la semplificazione esso viene
confrontato con il polinomio correttamente ordinato e semplificato ottenuto
da quello in ingresso.
Se uno dei controlli fallisce, il predicato fallisce.

--- real/1 ---
Argomenti: N
Risponde true se l'input N e' un numero reale.
Lo fa controllando se N e' un numero tramite il predicato number/1, oppure
se e':
	- la costante pi-greco;
	- la somma di due numeri reali;
	- la differenza di due numeri reali;
	- un numero razionale con numeratore e denominatore reali;
	- un numero reale elevato ad un altro numero reale;
	- una funzione trigonometrica tra sin, cos, tan.
Se N non rientra in questi casi, allora il predicato fallisce.

--- is_zero/1 ---
Input: N
Risponde true se l'input N e' pari a zero.
Lo fa controllando se N e' pari a 0 (intero), 0.0 (float) oppure e' un numero
molto piccolo in modulo e quindi approssimabile a zero (=< 1e-10).
Quest'ultima approssimazione la abbiamo introdotta per gestire i risultati
delle funzioni trigonometriche, poiche' i predicati sin, cos e tan non
restituiscono lo zero ma dei numeri molto piccoli.
Se N non rientra in questi casi, allora il predicato fallisce.


PREDICATI PER LA MANIPOLAZIONE DI POLINOMI MULTIVARIATI:
---- as_monomial/2 ----
Argomenti: Exp, Mon
Effettua la conversione in forma interna del monomio Exp.
Puo' correttamente interpretare: variabili con esponenti interi >=0 e numeri
reali tra cui:
	- funzioni trigonometriche applicate a numeri reali;
	- numeri reali con esponenti reali (non frazionari) positivi e negativi;
	- radici di numeri reali positivi;
Exp puo' essere espresso come:
	a) <num> * <var> (singoli o combinati, il numero puo' anche trovarsi dopo var)
	b) (<num> +/- <num> +/- ...) * <var>.

Per la conversione esso sfrutta dei predicati ausiliari:
	- parse/3: per estrarre da Exp, la lista delle variabili e il coefficiente
 	- sort/4: per ordinare le variabili in modo lessicografico;
	- compressVar/2: per semplificare le variabili del monomio sommando gli
			gli esponenti delle variabili uguali;
	- totDeg/2: per calcolare la somma dei gradi della variabili del monomio,
			ottenendo cosi' il grado totale.
Fallisce se Exp non e' interpretabile secondo le definizioni elencate.

---- as_polynomial/2 ----
Argomenti: Exp, Poly
Effettua la conversione in forma interna del polinomio Exp.
Puo' correttamente interpretare somme e differenze di monomi riconosciuti da
as_monomial/2.
Exp puo' essere espresso come:
	a) <Mon>
	b) <Mon> +/- <Mon> +/- ...

Per la conversione esso sfrutta dei predicati ausiliari:
	- parsePoly/3: per estrarre da Exp la lista dei monomi, ottenuti a loro volta
			utilizzando il predicato as_monomial/2;
 	- sortPoly/2: per ordinare la lista dei monomi come da specifica;
	- compressPoly/2: per semplificare i monomi sommando tra loro quelli con pari
			variabili;
	- remZero/2: per rimuovere dalla lista dei monomi che formano il polinomio
			le rappresentazioni dello zero (in forma interna).
Nota: il polinomio 0 e' rappresentato poly([]).
Fallisce se Exp non e' interpretabile secondo le definizioni elencate.

---- pprint_polynomial/1 ----
Argomenti: Poly o Exp (comodo per la verifica)
Effettua la stampa a schermo del polinomio dato in input in forma interna (o
eventualmente del polinomio da convertire Exp).
Per la stampa utilizza due predicati di supporto atti a stampare le variabili
dei monomi e i coefficienti (rispettivamente printVar/1 e printPoly/1).
Risponde true alla fine della stampa, altrimenti risponde false se il polinomio
in input non ha superato il controllo di is_real_polynomial/2 oppure se
as_polynomial/2 ha fallito nella conversione di Exp.

---- coefficients/2 ----
Argomenti: (Monomials o Poly o Exp), Coeff
Ritorna in Coeff la lista dei coefficienti estratti dalla lista di monomi o dal
polinomio in forma interna o dall'espressione da convertire in input.
Per farlo utilizza un predicato ausiliario (take_coefficients/2), il quale
scorrendo la lista dei monomi del polinomio, ne estrae i coefficienti.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp.

---- variables/2 ----
Argomenti: (Monomials o Poly o Exp), Variables
Ritorna in Variables la lista delle variabili (in ordine lessicografico e senza
ripetizioni) estratte dalla lista di monomi o dal polinomio in forma interna o
dall'espressione da convertire in input.
Per farlo utilizza i predicato ausiliari:
	- take_variables/2: per estrarre dalla lista dei monomi tutte le variabili
			controllando che non siano gia' state estratte;
	- sort/4: per ordinare le variabili estratte in ordine lessicografico.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp.

---- monomials/2 ----
Argomenti: (Monomials o Poly o Exp), Monomials
Ritorna in Monomials la lista dei monomi estratti dalla lista di monomi o
dal polinomio in forma interna o dall'espressione da convertire in input.
Per farlo controlla se il polinomio e' corretto e utilizza l'unificazione.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp.

---- maxdegree/2 ----
Argomenti: (Monomials o Poly o Exp), Degree
Ritorna in Degree il massimo grado del polinomio dato in input come lista di
monomi, polinomio in forma interna o espressione da convertire.
Per farlo utilizza i predicato ausiliari:
	- take_degree_list/2: per estrarre la lista dei gradi totali dei monomi;
	- max_list/2: per trovare il valore massimo nella lista dei gradi totali.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp.

---- mindegree/2 ----
Argomenti: (Monomials o Poly o Exp), Degree
Ritorna in Degree il grado minimo del polinomio dato in input come lista di
monomi, polinomio in forma interna o espressione da convertire.
Per farlo utilizza i predicato ausiliari:
	- take_degree_list/2: per estrarre la lista dei gradi totali dei monomi;
	- min_list/2: per trovare il valore minimo nella lista dei gradi totali.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp.

---- polyplus/3 ----
Argomenti: (Poly o Exp o Mon), (Poly o Exp o Mon), Result
Ritorna in Result il risultato della somma tra monomi dati in input secondo le
seguenti combinazioni:
	a) Poly, Poly
	b) Exp, Exp
	c) Exp, Poly (e viceversa)
	d) Mon, Poly (e viceversa)
Nota: i monomi, se corretti, vengono convertiti in notazione poly([Mon]).
Per il calcolo utilizza i predicati ausiliari:
	- append/3: per unire in una sola le liste dei monomi in input;
	- sortPoly/2: per ordinare la lista unica ottenuta;
	- compressPoly/2: per semplificare i termini simili;
	- remZero/2: per rimuovere le rappresentazioni dello zero.
La lista ottenuta e' esattamente il risultato della somma tra i polinomi.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp, oppure se il monomio in input non ha superato il controllo di
is_real_monomial/2.

---- polyminus/3 ----
Argomenti: (Poly o Exp o Mon), (Poly o Exp o Mon), Result
Ritorna in Result il risultato della differenza tra monomi dati in input
secondo le seguenti combinazioni:
	a) Poly, Poly
	b) Exp, Exp
	c) Exp, Poly (e viceversa)
	d) Mon, Poly (e viceversa)
Nota: i monomi, se corretti, vengono convertiti in notazione poly([Mon]).
Per il calcolo utilizza il predicato polyplus/2 utilizzando un "espediente",
ovvero cambiando il segno del secondo polinomio tramite il predicato
change_sign/2.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp, oppure se il monomio in input non ha superato il controllo di
is_real_monomial/2.

---- polytimes/3 ----
Argomenti: (Poly o Exp o Mon), (Poly o Exp o Mon), Result
Ritorna in Result il risultato del prodotto tra monomi dati in input secondo le
seguenti combinazioni:
	a) Poly, Poly
	b) Exp, Exp
	c) Exp, Poly (e viceversa)
	d) Mon, Poly (e viceversa)
Nota: i monomi, se corretti, vengono convertiti in notazione poly([Mon]).
Per il calcolo utilizza i predicati ausiliari:
	- times_new_r/3: ritorna la lista contenente il prodotto delle liste di
			monomi prese in input; lo fa sfruttando times_new_m/3 e append/3;
	- times_new_m/3: ritorna la lista dei monomi dati in input moltiplicata per
			il primo monomio dato; sfrutta times_new_v/3 per la gestione delle
			variabili;
	- sortPoly/2: per ordinare la lista risultatante ottenuta;
	- compressPoly/2: per semplificare i termini simili;
	- remZero/2: per rimuovere le rappresentazioni dello zero.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp, oppure se il monomio in input non ha superato il controllo di
is_real_monomial/2.

---- polyval/3 ----
Argomenti: (Poly o Exp), VariableValues, Value
Ritorna in Value il risultato della applicazione della lista VariableValues alle
corrisponenti variabili presenti nel polinomio dato in input (in forma interna
o da convertire).
Per farlo utilizza i seguenti predicati ausiliari:
	- variables/2: per estrarre dal polinomio in input la lista delle variabili;
	- number/2: per controllare che la lista VariableValues contenga solo numberi;
	- pairL/2: per associare le variabili ai valori in una lista contenente le
			coppie (variabile, valore);
	- replace/3: per sostituire al polinomio i valori alle corrispondenti
			variabili, calcolando il risultato complessivo; per farlo utilizza
			replaceVar/2 e la lista ottenuta dal predicato pairL/2.
Il predicato fallisce se il polinomio in input non ha superato il controllo
di is_real_polynomial/2 oppure se as_polynomial/2 ha fallito nella conversione
di Exp, oppure se il monomio in input non ha superato il controllo di
is_real_monomial/2.
