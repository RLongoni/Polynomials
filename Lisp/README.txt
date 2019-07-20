README mvpoli.lisp
Riccardo Longoni 806853
Alessandro Bertolo 808314

DISCLAIMER:
Assumiamo che l'input fornito ai predicati in forma interna sia stato ottenuto
tramite i predicati as_monomial/2 ed as_polynomial/2.
I predicati di controllo che abbiamo definito, oltre a controllare la struttura,
controllano anche: la congruenza del grado totale e del coefficiente,
l'ordinamento, e la semplificazione dei termini.

Qui sono elencate le funzioni principali richieste nel progetto
e anche delle funzioni di rilevante importanza che permettono l'uso
della libreria.
Le restanti funzioni sono commentate nel file mvpoli.lisp 


funzioni:

---- as-monomial^1 :
funzione che prende come argomento una espressione ed una volta "parsata"
genera un monomio nella forma richiesta.

In particolare si controlla che l'espressione sia della forma:
a) lista vuota
b) un monomio nella forma richiesta
c) un valore
d-e) una variabile nella forma <variabile> -oppure- (expt <var> <num>)
f) una espressione da riportare nella forma richiesta

Se l'espressione non viene accettata dai casi precedentemente
elencati (tranne f) ) viene lanciato un errore, altrimenti si passa al punto f.

As-monomial e' stata impostata in modo tale da poter accettare come input:
- '<numero>
- '<variabile>
- '(expt <variabile> <num>)
- '(* <coeff> <variabili>)

dove <coeff>/<numero> puo' essere nella forma:
1) '(sin <num>)
2) '(cos <num>)
3) '(log <num>)
4) '(+ <numeri>)
5) '(- <numeri>)
6) '(expt <num> <num>)
7) '(/ <num> <num>)
8) '(* <num>)
9) un numero appartenente ai numeri Reali.

NB nella forma '(* ... ) si possono "mischiare" fra loro i coeff e le variaibili,
as-monomial tornera' comunque un monomio nella forma (m Coeff TotDegree VarList)
dove: 
- Coeff : prodotto di tutti i <coeff> 
- TotDegree : il grado totale 
- Varlist : lista delle variabili nella forma (v <potenza> <variabile>)
Esempio1: 

CL-USER 1 > (as-monomial '(* x 42 (expt x 2) (expt 1 2) 2 y))
(M 84 4 ((V 3 X) (V 1 Y)))

-oppure- 

CL-USER 2 > (as-monomial '(* (+ (log 9) 2 4) x a (* 21 2) (expt a 2)))
(M 344.28345 4 ((V 3 A) (V 1 X)))

E' stato implementata una funzione evaluate-monomial^1 che nel caso 
di (sin pi),(sin (* 2 pi)),(cos (/ pi 2)),(cos (* 3 (/ pi 2))) ritorna 0.0 e 
quindi (m 0 0 nil).
Questo perche' in lisp il calcolo del sin/cos in radianti genera un numero 
che si puo' approssimare a zero.

Esempio2:

CL-USER 1 > (sin pi)
1.2246063538223773D-16

-quindi- 

CL-USER 2 > (as-monomial '(sin pi))
(M 0 0 NIL) 

-anche nella forma 'standard'-

CL-USER 3 > (as-monomial '(* (cos (/ pi 2))))
(M 0 0 NIL)

Dovessero essere presenti più variabili uguali fra loro,
verrà fatta un'opportuna compress tramite la funzione order-compress^1.
Lo stesso vale per tutti i valori numerici inseriti (valori Reali), tramite
coeff^1 e total-degree^1.

PS : per il caso b) verra' fatto un ordinamento in quanto non si sa se
il monomio '(m <coeff> <num> <variabili>) abbia le variabili gia' ordinate

------------ as-polynomial^1 
Funzione che accetta come input una espressione nella seguente forma:
a) (+ (* ...) ....) ['forma standard']
b) '<numeri>  
c) '<variabili>
d) '(expt <variabile> <numero>)
e) '(expt <polinomio> <numero>) 
f) '(m <coeff> <totDegree> <varList>)
g) '(poly (<monomi>)

Riguardo al punto b),c) e d) sono gestiti in maniera simile a as-monomial.

Il punto a) e' quello richiesto per il progetto.

Piu' interessante invece e' il caso e), implementato dopo aver sviluppato la 
funzione polytimes^2. 
Permette infatti il calcolo della potenza di polinomi.
Esempio3 

; calcolo di (x + 1)^2 
CL-USER 1 > (as-polynomial '(expt (+ x 1) 2))
(POLY ((M 1 0 NIL) (M 2 1 ((V 1 X))) (M 1 2 ((V 2 X)))))
; 1 + 2*x + x^2

-oppure- 

;calcolo di (x - y + 2)^2 
CL-USER 2 > (as-polynomial '(expt (+ x (* -1 y) 2) 2))
(POLY ((M 4 0 NIL) (M 4 1 ((V 1 X))) 
		(M -4 1 ((V 1 Y))) (M -2 2 ((V 1 X) (V 1 Y))) 
		(M 1 2 ((V 2 X))) (M 1 2 ((V 2 Y)))))
; 4 + 4*x - 4*y - 2*x*y + x^2 + y^2 

-oppure -

;calcolo di (a*b + c)^3
CL-USER 3 > (as-polynomial '(expt (+ (* a b) c) 3))
(POLY ((M 1 3 ((V 3 C))) (M 3 4 ((V 1 A) (V 1 B) (V 2 C))) 
		(M 3 5 ((V 2 A) (V 2 B) (V 1 C))) 
		(M 1 6 ((V 3 A) (V 3 B))))) 
; 3*c^3 + 3*a*b*c^2 + 3*a^2*b^2*c + a^3*b^3

Per motivi di spazio ho indentato il secondo e terzo risultato.

il caso f), come in as-monomial viene comunque ordianta la lista
delle variabili in quanto magari passata disordinata

il caso g) copre il caso in cui venga passato un polinomio nella forma
'(poly (<monomi>) .
Viene controllato tramite il predicato is-real-polynomial che sia
effettivamente un polinomio, ordinato secondo gli ordinamenti
stabiliti nella consegna del progetto:
Esempio4

CL-USER 1 > (as-polynomial '(POLY ((M 2 1 ((V 1 X))) (M 1 0 NIL) (M 1 2 ((V 2 X))))))
(POLY ((M 1 0 NIL) (M 2 1 ((V 1 X))) (M 1 2 ((V 2 X)))))


CL-USER 2 > (as-polynomial '(POLY ((M 1 1 ((V 1 X)))  (M 1 4 ((V 1 c) (V 2 a) (V 1 b))))))
(POLY ((M 1 1 ((V 1 X))) (M 1 4 ((V 2 A) (V 1 B) (V 1 C)))))

Se dovesse essere passato un polinomio che contiene un monomio
che ha un totalDegree diverso dalla somma dei gradi delle sue varibili
verra' lanciato un errore.

-----monomial< ------
Viene usato per l'ordinamento dei polinomi, prende spunto dalla
funzione <^2.
Controlla prima se il totDegree del primo monomio e' piu' piccolo
del tot Degree del secondo.
Nel caso in cui fossero uguali va a confrontare le variabili dei due
monomi.


----varpowers-----
Ritorna la lista delle variabili con le potenze di un monomio preso nella forma
ottenuta da as-monomial^1 oppure da una espressione da "parsare"

----vars-of-----
ritorna la lista dele variabili di un monomio, passando da as-monomial
le variabili vengono semplificate fra loro quindi si avra' un output
del tipo ( a b c d e).

----monomial-degree----
dato un monomio ritorna il suo total degree.

---monomial-cefficient-----
dato un monomio ritorna il suo coefficiente.

Le seguenti funzioni ammettono come input Espressioni ancora da "parsare" o
strutture della forma '(Poly (<monomi>)), anche quelle non generate da
as-polynomial, in questo caso la lista dei monomi viene controllata da is-real-polynomial
e nel caso ordinata.

----coefficients-----
Ritorna la lista dei coefficienti, prendendo come input un polinomio.
NB ritorna la lista ordinata secondo l'ordine stabilito da
as-polynomial.

----monomials-----
Ritorna la lista dei monomi di un polinomio, l'ordine di tali monomi
e' dato da as-polynomial.

----maxdegree----
Preso un polinomio ritorna il totDegree più alto fra i monomi che
compongono il polinomio.

----mindegree----
Preso un monomio ritorna il totDegree più piccolo fra i monomi che
compongono il polinomio.

----polyplus----
Effettua la somma fra polinomi, si controlla anche il caso in cui
vengano passati monomi, polinomi gia' nella forma "parsata".
Ritorna un polinomio risultante la somma fra due polinomi, monomi o
espressioni da trasmormare.

---polyminus----
Effettua la differenza fra polinomi, prima si cambia il segno al
secondo polinomio e poi si effettua una polyplus fra i due polinomi.
Come in polyplus vengono tenuti in consideranzione casi, in cui
vengano passati monomi / polinomi nella forma gia' "parsata" oppure
espressioni ancora da parsare.
Ritorna il polinomio risultante la differenza fra i due polinomi.

----polytimes----
Effettua il prodotto fra due polinomi, come in polimunis e politymes
vengono effettuati gli opportuni controlli per le varie espressioni
passate in input.
Ritorna il polinomio risultante il prodotto fra i due polinomi passati
come argomenti.

--- polyval ---
Prende come parametro un polinomio e una lista di valori.
Viene controllato che la lista di valori non sia vuota, nel caso viene
generato un errore.
Viene fatto un controllo sulla lunghezza della lista di valori e la
lunghezza della lista delle variabili del polinomio, nel caso in ci la
prima fosse più picolla della seconda allora verrebbe generato un
errore.
Inoltre viene anche controllato che la lista di valori contenga solo
numeri, anche in questo viene generato un opportuno errore nel caso
venga trovata una variabiles.
La funzione dopo questi opportuni controlli, sostituisce i valori
all'interno delle variabili del polinomio, calcolandone il valore.
Una volta calcolato la funzione ritorna quel valore.

---pprint-polynomial----
Funzione che preso un polinomio nella forma "parsata" lo stampa a
video e ritorna NIL .


----is-real-polynomial----
funzione che serve per controllare se un polinomio e' nella forma che
viene accettata da is-polynomial. Inoltre si controlla se il grado
totale di ogni monomio è uguale alla somma dei gradi delle sue
variabili. Nel caso viene generato un errore.
Per finire viene controllato l'ordinamento delle variabili e dei
monomi.
Se un polinomio rispetta tutte queste condizioni allora la funzione
ritorna T, nil altrimenti, o un errore nel caso di esponente negativo.
