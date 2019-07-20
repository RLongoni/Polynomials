%%%% 806853 Longoni Riccardo
%%%% 808314 Bertolo Alessandro

/* PREDICATI DI CONTROLLO:*/
/*Risponde true se una variabile e' scritta come v(P, V)*/
is_varpower(v(Power, VarSymbol)) :-
			integer(Power),
			Power >= 0,
			atom(VarSymbol).

/*Risponde true se il coefficiente del monomio e' un numero ed e'
"congruente"*/
is_coefficient(m(C, TD, VPs)) :-	%se C==0, allora anche TD == 0 e VPs == []
			number(C),
			C == 0,
			TD == 0,
			length(VPs, X),
			X == 0, !.
is_coefficient(m(C, TD, VPs)) :-	%altrimenti
			number(C),
			C \= 0,
			TD >= 0,
			length(VPs, X),
			X >= 0.

/*Risponde true se il monomio dato in input, scritto in notazione interna di
monomio, e' corretto; ovvero se ha un TD e un coefficiente corretti,
e' ordinato e semplificato*/
is_real_monomial(m(C, TD, VPs)) :-
			integer(TD),
			TD >= 0,
			is_list(VPs),
			foreach(member(VP, VPs), is_varpower(VP)),
			is_coefficient(m(C, TD, VPs)),
			sort(2, @=<, VPs, L),
			VPs == L,
			compressVar(L, V1),
			VPs == V1,
			totDeg(VPs, TD1),
			TD == TD1, !.

/*Risponde true se il polinomio dato in input, scritto in notazione interna di
polinomio, e' corretto; ovvero se ogni monomio che lo compone e' verificato dal
predicato is_real_monomial/1, e' ordinato e semplificato*/
is_real_polynomial(poly([])) :- !.
is_real_polynomial(poly([m(0, 0, [])])) :- !.
is_real_polynomial(poly(Monomials)) :-
			is_list(Monomials),
			foreach(member(M, Monomials), is_real_monomial(M)),
			sortPoly(Monomials, L1),
			compressPoly(L1, L2),
			Monomials == L2,
			remZero(L2, Mons),
			Monomials == Mons, !.

/*Risponde true se N e' un numero reale*/
real(N) :-
			( number(N);
		  	N =.. [+, A, B], real(A), real(B), Z is N, number(Z);
				N =.. [-, A, B], real(A), real(B), Z is N, number(Z);
				N =.. [^, A, B], real(A), real(B), Z is N, number(Z);
				N == pi;	%serve per riconoscere pi, come un numero prima di valutarlo
				N = A/B, real(A), real(B), Z is A/B, number(Z);
				N = sin(A), real(A), Z is sin(A), number(Z);
				N = cos(A), real(A), Z is cos(A), number(Z);
				N = tan(A), real(A), Z is tan(A), number(Z)
			), !.

/*Risponde true se N e' pari o approssimabile a zero*/
is_zero(N) :-
			( N == 0;
				N == 0.0;
				abs(N) =< 1e-10		%approssimiamo i numeri inferiori a 1e-10 a zero
			), !.


/* PREDICATI PER LA MANIPOLAZIONE DI POLINOMI MULTIVARIATI: */
/*Predicato as_monomial*/
%Prende il caso di un monomio moltiplicato per zero
as_monomial(Exp, Mon) :-
			Mon = m(C, 0, []),
			parse(Exp, _, C1),
			is_zero(C1),
			C is 0, !.

as_monomial(Exp, Mon) :-
			Mon = m(C, TD, VPs),
			parse(Exp, L, C),
			sort(2, @=<, L, L1),	%ordina le variabili in modo lessicografico
			compressVar(L1, VPs),
			totDeg(VPs, TD),
			TD >= 0, !.

/*Effettua il parsing di un monomio ritornando la lista delle variabili
e il coefficiente*/
%passi ricorsivi: riconoscono coefficienti reale (con o senza esponente reale)
parse(X * Y^N, L, E) :-
			real(Y), real(N), N1 is N, parse(X, L, E1), E is Y^N1 * E1, !.
parse(X * Y, L, E) :- real(Y), Y1 is Y, parse(X, L, E1), E is Y1 * E1, !.
%passi ricorsivi: riconoscono variabili (con o senz esponente intero)
parse(X * Y^N , L, E) :- atom(Y), integer(N), is_zero(N), parse(X, L, E), !.
parse(X * Y^N, [v(N, Y)|L], E) :- atom(Y), integer(N), parse(X, L, E), !.
parse(X * Y, [v(N, Y)|L], E) :- atom(Y), N is 1, parse(X, L, E), !.
parse(-(X * Y), L, E) :- parse(-X * Y, L, E), !.
%casi base: riconoscono coefficienti con esponente reale pari a zero
parse(X^N, [], C) :- real(X), real(N), N1 is N, is_zero(N1), C is 1, !.
parse(-(X)^N, [], C) :- real(X), real(N), N1 is N, is_zero(N1), C is 1, !.
parse(+(X)^N, [], C) :- real(X), real(N), N1 is N, is_zero(N1), C is 1, !.
%casi base: riconoscono coefficienti (con o senza esponente reale),
%nota: non viene gestito un numero negativo sotto radice quadrata
parse(X^N, [], C) :- real(X), real(N), N1 is N, C is X^N1, !.
parse(-(X)^N, [], C) :- real(X), real(N), N1 is N, C is (-X)^N1, !.
parse(+(X)^N, [], C) :- real(X), real(N), N1 is N, C is X^N1, !.
parse(-X, [], C) :- real(X), C is -X, !.
parse(X, [], C) :- real(X), C is X, !.
%casi base: riconoscono variabili (con o senza esponente intero),
parse(X^N, [], C) :- atom(X), integer(N), is_zero(N), C is 1, !.
parse(+X^N, [], C) :- atom(X), integer(N), is_zero(N), C is 1, !.
parse(-X^N, [], C) :- atom(X), integer(N), is_zero(N), C is -1, !.
parse(X^N, [v(N, X)], C) :- atom(X), integer(N), C is 1, !.
parse(+X^N, [v(N, X)], C) :- atom(X), integer(N), C is 1, !.
parse(-X^N, [v(N, X)], C) :- atom(X), integer(N), C is -1, !.
parse(X, [v(N, X)], C) :- atom(X), N is 1, C is 1, !.
parse(+X, [v(N, X)], C) :- atom(X), N is 1, C is 1, !.
parse(-X, [v(N, X)], C) :- atom(X), N is 1, C is -1, !.

/*Ritorna il grado totale di un monomio*/
totDeg([], 0).
totDeg([v(P, _)|L], T) :- totDeg(L, T1), T is T1 + P.

/*Ritorna il monomio dato in input correttamente semplificato*/
compressVar([], []) :- !.
compressVar([X], [X]) :- !.
compressVar([v(P, V), v(P1, V)|L], L2) :-
			V == V,
			NewP is P + P1,
			is_zero(NewP),
			compressVar([v(NewP, V)|L], L2), !.
compressVar([v(P, V), v(P1, V)|L], L2) :-
			V == V,
			NewP is P + P1,
			compressVar([v(NewP, V)|L], L2), !.
compressVar([v(P, V), v(P1, V1)|L], [v(P, V)|L2]) :-
			V \= V1,
			compressVar([v(P1, V1)|L], L2).


/*Predicato as_polynomial*/
as_polynomial(Exp, Poly) :-
			Poly = poly(Monomials),
			parsePoly(Exp, L),
			sortPoly(L, L1),
			compressPoly(L1, L2),
			remZero(L2, Monomials), !.

/*Effettua il parsing di un monomio ritornando la lista dei monomi*/
parsePoly(Exp1 + Exp2, [Mon|L]) :-
			as_monomial(Exp2, Mon),
			parsePoly(Exp1, L), !.
parsePoly(Exp1 - Exp2, [Mon|L]) :-
			as_monomial(-Exp2, Mon),
			parsePoly(Exp1, L), !.
parsePoly(Exp, [Mon]) :- as_monomial(Exp, Mon).

/*Ritorna la lista di monomi data in input correttamente ordinata*/
sortPoly(L, SL) :- predsort(comp, L, SL), !.
comp(<, X, Y) :- compare_monomials(X, Y), !.
comp(>, _, _) :- !.
%confronta i gradi totali dei monomi
compare_monomials(m(_, TD, _), m(_, TD1, _)) :- TD1 > TD, !.
%monomi con grado pari: confronta gli esponenti delle variabili
compare_monomials(m(_, TD, L1), m(_, TD, L2)) :-
			compare_exp_var(L1, L2), !.
%variabili con esponente pari: confronta lessicograficamente le variabili
compare_monomials(m(_, TD, L1), m(_, TD, L2)) :-
			compare_var(L1, L2), !.

/*Effettua il confronto tra gli esponenti delle variabili*/
compare_exp_var([v(P2, A)], [v(P1, A)]) :-
			P1 > P2, !.
compare_exp_var([v(P2, A)|_], [v(P1, A)|_]) :-
			P1 > P2, !.
compare_exp_var([v(P2, A)|X], [v(P1, A)|Y]) :-
			P1 == P2, compare_exp_var(X, Y).

/*Effettua il confronto (lessicografico) tra le variabili*/
compare_var([v(_, A)], [v(_, B)]) :-
			A @< B, !.
compare_var([v(_, A)|_], [v(_, B)|_]) :-
			A @< B, !.
compare_var([v(_, A)|X], [v(_, B)|Y]) :-
			A == B, compare_var(X, Y).

/*Ritorna il polinomio dato in input correttamente semplificato*/
compressPoly([], []).
compressPoly([X], [X]) :- !.
%monomi con uguali variabili: somma i loro coefficienti
compressPoly([m(C, TD, VPs), m(C1, TD, VPs)|L], F) :-
			NewC is C + C1,
			is_zero(NewC),	%controlla se il nuovo coefficiente e' zero
			compressPoly([m(NewC, 0, [])|L], F), !.
compressPoly([m(C, TD, VPs), m(C1, TD, VPs)|L], F) :-
			NewC is C + C1,
			compressPoly([m(NewC, TD, VPs)|L], F), !.
compressPoly([m(C, TD, La), m(C1, TD1, Lb)|L], [m(C, TD, La)|F]) :-
			La \= Lb,
			compressPoly([m(C1, TD1, Lb)|L], F).

/*Restituisce la lista di monomi data in input senza le rappresentazioni dello
zero nella forma m(0, 0, []).
Scorre la lista dei monomi inserendo nella lista di output solo quelli con
coefficiente diverso da zero (controllato tramite il predicato is_zero/1)*/
remZero([], []) :- !.
remZero([X|L], L1) :- X = m(C, 0, []), is_zero(C), remZero(L, L1), !.
remZero([X|L], [X|L1]) :- remZero(L, L1), !.


/*Predicato pprint_polynomial*/
pprint_polynomial(Poly) :-
			is_real_polynomial(Poly),
			Poly = poly(Monomials),
			printPoly(Monomials), !.

%Stampa il polinomio dato in input in forma non interna
pprint_polynomial(Exp) :-
			as_polynomial(Exp, Poly),
			Poly = poly(Monomials),
			printPoly(Monomials), !.

%stampa i coefficienti dei monomi dati in input
printPoly([]) :- write(0), !.
printPoly([m(C, _, [])]) :- write(C), !.
printPoly([m(C, _, []), m(C2, _, V)|L]) :-
			C2 < 0,
			!,
			write(C),
			printPoly([m(C2, _, V)|L]).
printPoly([m(C, _, []), m(C2, _, V)|L]) :-
			C2 > 0,
			!,
			write(C),
			write(+),
			printPoly([m(C2, _, V)|L]), !.
printPoly([m(C, _, L2)]) :-
			write(C),
			write(*),
			printVar(L2), !.
printPoly([m(C, _, L2), m(C2, _, V)|L]) :-
			C2 < 0,
			!,
			write(C),
			write(*),
			printVar(L2),
			printPoly([m(C2, _, V)|L]).
printPoly([m(C, _, L2), m(C2, _, V)|L]) :-
			C2 > 0,
			!,
			write(C),
			write(*),
			printVar(L2),
			write(+),
			printPoly([m(C2, _, V)|L]).

%stampa le singole variabili del monomio passate come lista
printVar([]) :- !.
printVar([v(P, V)]) :-
			P \= 1,
			write(V^P).
printVar([v(P, V)]) :-
			P == 1,
			write(V).
printVar([v(P, V)|L2]) :-
			P \= 1,
			write(V^P),
			write(*),
			printVar(L2).
printVar([v(P, V)|L2]) :-
			P == 1,
			write(V),
			write(*),
			printVar(L2).


/*Predicato coefficients*/
coefficients(Monomials, Coeff) :-			%INPUT: lista di monomi
			is_real_polynomial(poly(Monomials)),
			coefficients(poly(Monomials), Coeff), !.

coefficients(Poly, Coeff) :-					%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			take_coefficients(Poly, Coeff), !.

coefficients(Exp, Coeff) :-						%INPUT: espressione da convertire
			as_polynomial(Exp, Poly),
			take_coefficients(Poly, Coeff), !.

/*Ritorna la lista dei coefficienti estratta dal polinomio dato in input*/
take_coefficients(poly([]), [0]) :- !.
take_coefficients(poly([m(C, _, _)]), [C]) :- !.
take_coefficients(poly([m(C, _, _)|L]), [N|L1]) :-
			N = C,
			take_coefficients(poly(L), L1).


/*Predicato variables*/
variables(Monomials, Variables) :-		%INPUT: lista di monomi
			is_real_polynomial(poly(Monomials)),
			variables(poly(Monomials), Variables), !.

variables(Poly, Variables) :-					%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			take_variables(Poly, Var),
			sort(0, @<, Var, Variables), !. %ordina la lista delle variabili

variables(Exp, Variables) :-					%INPUT: espressione da convertire
			as_polynomial(Exp, Poly),
			take_variables(Poly, Var),
			sort(0, @<, Var, Variables). %ordina la lista delle variabili

/*Ritorna la lista delle variabili estratta dal polinomio dato in input senza
ripetizioni; scorrendo la lista dei monomi, le variabili vengono aggiunte solo
se non sono già presenti nella lista V*/
take_variables(poly([]), []) :- !.
take_variables(poly([m(_, _, [v(_, V)])]), [V]) :- !.
take_variables(poly([m(_, _, [])|L]), ListaVar) :-
			take_variables(poly(L), ListaVar), !.
take_variables(poly([m(_ ,_ , [v(_, V)|L1])|L]), [V|ListaVar]) :-
			take_variables(poly([m(_, _, L1)|L]), ListaVar),
			\+ member(V, ListaVar), !.
take_variables(poly([m(_, _, [v(_, V)|L1])|L]), ListaVar) :-
			take_variables(poly([m(_, _, L1)|L]), ListaVar),
			member(V, ListaVar), !.


/*Predicato monomial*/
monomials(L, Monomials) :-						%INPUT: lista di monomi
			is_real_polynomial(poly(L)),
			Monomials = L, !.

monomials(Poly, Monomials) :-					%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			Poly = poly(Monomials), !.

monomials(Exp, Monomials) :-					%INPUT: espressione da convertire
			as_polynomial(Exp, Poly),
			Poly = poly(Monomials), !.


/*Predicato maxdegree*/
maxdegree(Monomials, Degree) :-				%INPUT: lista di monomi
			is_real_polynomial(poly(Monomials)),
			maxdegree(poly(Monomials), Degree), !.

maxdegree(Poly, Degree) :-						%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			take_degree_list(Poly, DegreeList),
			max_list(DegreeList, Degree), !.

maxdegree(Exp, Degree) :-							%INPUT: espressione da convertire
			as_polynomial(Exp, Poly),
			take_degree_list(Poly, DegreeList),
			max_list(DegreeList, Degree).

/*Ritorna la lista dei gradi dei monomi estratta dal polinomio dato in input*/
take_degree_list(poly([]), [0]) :- !.
take_degree_list(poly([m(_, TD, _)]), [TD]) :- !.
take_degree_list(poly([m(_, TD, _)|L]), [TD|L1]) :-
			take_degree_list(poly(L), L1), !.


/*Predicato mindegree*/
mindegree(Monomials, Degree) :-				%INPUT: lista di monomi
			is_real_polynomial(poly(Monomials)),
			mindegree(poly(Monomials), Degree), !.

mindegree(Poly, Degree) :-						%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			take_degree_list(Poly, DegreeList),
			min_list(DegreeList, Degree), !.

mindegree(Exp, Degree) :-							%INPUT: espressione da convertire
			as_polynomial(Exp, Poly),
			take_degree_list(Poly, DegreeList),
			min_list(DegreeList, Degree).


/*Predicato polyplus*/
%INPUT: polinomi in forma interna
polyplus(poly(L1), poly(L2), poly(Monomials)) :-
			is_real_polynomial(poly(L1)),
			is_real_polynomial(poly(L2)),
			append(L1, L2, L),
			sortPoly(L, Ls),
			compressPoly(Ls, Lsc),
			remZero(Lsc, Monomials), !.

%INPUT: espressioni da convertire
polyplus(Exp1, Exp2, Result) :-
			as_polynomial(Exp1, Poly1),
			as_polynomial(Exp2, Poly2),
			polyplus(Poly1, Poly2, Result), !.

%INPUT: espressione da convertire e polinomio in forma interna (e viceversa)
polyplus(Exp, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polyplus(Poly, poly(Monomials), Result), !.
polyplus(poly(Monomials), Exp, Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polyplus(Poly, poly(Monomials), Result), !.

%INPUT: monomio in forma interna e polinomio in forma interna (e viceversa)
polyplus(Mon, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polyplus(Poly, poly(Monomials), Result), !.
polyplus(poly(Monomials), Mon, Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polyplus(Poly, poly(Monomials), Result), !.


/*Predicato polyminus*/
%INPUT: polinomi in forma interna
polyminus(poly(L1), poly(L2), poly(Monomials)) :-
			is_real_polynomial(poly(L1)),
			is_real_polynomial(poly(L2)),
			change_sign(L2, NewL),
			polyplus(poly(L1), poly(NewL), poly(Monomials)), !.

%INPUT: espressioni da convertire
polyminus(Exp1, Exp2, Result) :-
			as_polynomial(Exp1, Poly1),
			as_polynomial(Exp2, Poly2),
			polyminus(Poly1, Poly2, Result), !.

%INPUT: espressione da convertire e polinomio in forma interna (e viceversa)
polyminus(Exp, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polyminus(Poly, poly(Monomials), Result), !.
polyminus(poly(Monomials), Exp, Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polyminus(Poly, poly(Monomials), Result), !.

%INPUT: monomio in forma interna e polinomio in forma interna (e viceversa)
polyminus(Mon, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polyminus(Poly, poly(Monomials), Result), !.
polyminus(poly(Monomials), Mon, Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polyminus(Poly, poly(Monomials), Result), !.

/*Ritorna la lista di monomi data in input con segno cambiato (e' un espediente
per sfruttare la polyplus nella polyminus cambiando il segno del secondo
polinomio)*/
change_sign([], []).
change_sign([m(C, TD, VPs)|L], [m(NewC , TD, VPs)|L1]) :-
			NewC is (C) * -1,
			change_sign(L, L1), !.


/*Predicato polytimes*/
%INPUT: polinomi in forma interna
polytimes(poly(L1), poly(L2), poly(Monomials)) :-
			is_real_polynomial(poly(L1)),
			is_real_polynomial(poly(L2)),
			times_new_r(L1, L2, Rl),
			sortPoly(Rl, Rl1),
			compressPoly(Rl1, Rl2),
			remZero(Rl2, Monomials), !.

%INPUT: espressioni da convertire
polytimes(Exp1, Exp2, Result) :-
			as_polynomial(Exp1, Poly1),
			as_polynomial(Exp2, Poly2),
			polytimes(Poly1, Poly2, Result), !.

%INPUT: espressione da convertire e polinomio in forma interna (e viceversa)
polytimes(Exp, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polytimes(Poly, poly(Monomials), Result), !.
polytimes(poly(Monomials), Exp, Result) :-
			is_real_polynomial(poly(Monomials)),
			as_polynomial(Exp, Poly),
			polytimes(Poly, poly(Monomials), Result), !.

%INPUT: monomio in forma interna e polinomio in forma interna (e viceversa)
polytimes(Mon, poly(Monomials), Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polytimes(Poly, poly(Monomials), Result), !.
polytimes(poly(Monomials), Mon, Result) :-
			is_real_polynomial(poly(Monomials)),
			is_real_monomial(Mon),
			Poly = poly([Mon]),
			polytimes(Poly, poly(Monomials), Result), !.

/*Ritorna il prodotto dei due polinomi dati in input*/
times_new_r([], _, []) :- !.
times_new_r([m(0, 0, [])], _, []) :- !.
times_new_r(_, [m(0, 0, [])], []) :- !.
times_new_r([m(C, TD, VPs)|La], Lb, Lc) :-
			times_new_m(m(C, TD, VPs), Lb, NewL),
			times_new_r(La, Lb, NewL1),
			append(NewL, NewL1, Lc), !.

%predicati di supporto per la moltiplicazione tra i monomi
times_new_m(m(_, _, _), [], []) :- !.
times_new_m(m(C1, TD1, L1), [m(C2, TD2, L2)|Lb], [m(NewC, NewTD, NewL)|Lc]) :-
			NewC is C1 * C2,
			NewTD is TD1 + TD2,
			times_new_v(L1, L2, L3),
			sort(2, @=<, L3, NewL),
			times_new_m(m(C1, TD1, L1), Lb, Lc).
%si occupa delle variabili
times_new_v([], [], []) :- !.
times_new_v(La, [], La) :- !.
times_new_v([], Lb, Lb) :- !.
times_new_v([v(P1, V)|La], [v(P2, V)|Lb], Vl) :-
			NewP is P1 + P2,
			times_new_v([v(NewP, V)|La], Lb, Vl), !.
times_new_v([v(P1, V1)|La], [v(P2, V2)|Lb], [v(P2, V2)|Vl]) :-
			V1 \= V2,
			length(La, Len1),
			length(Lb, Len2),
			Len1 =< Len2,
			times_new_v([v(P1, V1)|La], Lb, Vl), !.
times_new_v([v(P1, V1)|La], [v(P2, V2)|Lb], [v(P1, V1)|Vl]) :-
			V1 \= V2,
			times_new_v(La, [v(P2, V2)|Lb], Vl).


/*Predicato polyval*/
polyval(Poly, VariableValues, Value) :-			%INPUT: polinomio in forma interna
			is_real_polynomial(Poly),
			variables(Poly, Var),
			foreach(member(A, VariableValues), number(A)),
			pairL(Var, VariableValues, List),
			replace(Poly, List, Value), !.

polyval(Exp, VariableValues, Value) :-			%INPUT: espressione da convertire
			as_polynomial(Exp, C),
			polyval(C, VariableValues, Value), !.

/*Restituisce una lista contenente le coppie (variabile, valore), ottenute
combinando gli elementi delle liste passate in input; si comporta in modo
simile alla pairlis di common lisp*/
pairL([], [], []) :- !.
pairL([], _, []) :- !.
pairL(_, [], []) :- !.
pairL([X], [Y], [(X, Y)]) :- !.
pairL([X|L], [Y|L1], [(X, Y)|L2]) :- pairL(L, L1, L2).

/*Restituisce il valore numerico ottenuto sostituendo alle variabili
del polinomio la lista dei valori forniti in input.
I valori sono passati nella lista fornita dalla pairL in modo da essere
univocamente connessi alla rispettiva variabile*/
replace(poly([]), _, 0) :- !.
replace(poly(Monomials), List, Value) :-
			Monomials = [m(C, _, VPs)|L],
			replaceVar(m(C, _, VPs), List, Val),
			replace(poly(L), List, Val1),
			Value is Val + Val1, !.

/*Sostituisce nel monomio, le variabili con i corrispondenti valori,
restituendo il risultato numerico*/
replaceVar(m(C, _, []), _, C).
replaceVar(m(C, _, [v(P, V)|La]), [(V, N)|Lb], NewValue) :-
			replaceVar(m(C, _, La), Lb, Val),
			NewValue is N^P * Val, !.
replaceVar(m(C, _, [v(P, V)|La]), [(V1, _)|Lb], NewValue) :-
			V \= V1,
			replaceVar(m(C, _, [v(P, V)|La]), Lb, NewValue), !.
