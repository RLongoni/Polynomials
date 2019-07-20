;;;; 806853 Riccardo Longoni
;;;; 808314 Bertolo Alessandro
;;;;

;;; FUNZIONI DI CONTROLLO
(defun is-monomial (m)
  (and (listp m)
       (eq 'm (first m))
       (let ((mtd (monomial-total-degree m))
             (vps (monomial-vars-and-powers m))
             )
         (and (integerp mtd)
     (>= mtd 0)
     (listp vps)
     (every #'is-varpower vps)))))

(defun monomial-total-degree (m)
  (if (null m) nil (third m)))

(defun monomial-vars-and-powers (m)
  (if (null m) nil (fourth m)))

(defun is-varpower(vp)
  (and (listp vp)
     (eq 'v (first vp))
     (let ((p (varpower-power vp))
           (v (varpower-symbol vp))
           )
       (and (integerp p)
            (>= p 0)
            (symbolp v)))))

(defun varpower-power (vp)
  (if (null vp) nil (second vp)))

(defun varpower-symbol (vp)
  (if (null vp) nil (third vp)))

(defun is-polynomial (p)
  (and (listp p)
       (eq 'poly (first p))
       (let ((ms (poly-monomials p)))
         (and (listp ms)
              (every #'is-monomial ms)))))

(defun poly-monomials (p)
  (if (null p) nil (second p)))

;;; is-real-polynomial:
;controlla se una espressione e' un polinomio
;gia' "parsato" e ordinato, inoltre
;controlla che il grado totale dei monomi
;coincide con la somma dei gradi delle
;variabili
(defun is-real-polynomial (x)
  (cond
   ((and (is-polynomial x)
         (is-degree (second x))
         (is-ordered (second x)))
    t)
   ((and (is-polynomial x)
         (is-degree (second x))
         (not (is-ordered (second x))))
    nil)
   ((and (is-polynomial x)
         (not (is-degree (second x))))
    (error "Polynomial with wrong degree"))
   (t nil)))

;;; is-ordered
;controlla se una lista di monomi
;e' ordinata secondo l'ordinamento
;richiesto nel progetto
(defun is-ordered (x)
  (cond
   ((null x) t)
   ((and (null (cdr x)) ;quando ho un solo elem
         (is-sorted
          (varpowers (car x))))
    t)
   ((and (null (cdr x))
         (not (is-sorted
               (varpowers (car x)))))
    nil)
   ((or (not (is-sorted
         (varpowers (car x))))
        (not (is-sorted
         (varpowers (second x)))))
    nil)
   ((not (monomial< (car x)
                    (second x)))
    nil)
   (t
    (is-ordered (cdr x)))))

;;; is-sorted:
;verifica che una lista di variabili sia ordinata
(defun is-sorted (x)
  (cond
   ((null x) t)
   ((and (null (cdr x))
         (is-varpower (car x)))
    t)
   ((not (string-lessp (third (first x))
                       (third (second x))))
    nil)
   (t (is-sorted (cdr x)))))

;;; is-degree
;data una lista di monomi controlla
;che ognuno abbia totDegree
;uguale alla somma delle potenze
;delle sue variaibli
(defun is-degree (x)
  (cond
   ((null x) t)
   ((not (= (third (car x))
            (sum-power (varpowers (car x)))))
    nil)
   (t (is-degree (cdr x)))))
(defun sum-power (x)
  (cond
   ((null x) 0)
   (t (+ (second (car x))
         (sum-power (cdr x))))))

;;; funzione as-monomial Expression -> Monomial :
;commentata su README
(defun as-monomial (E)
  (cond
   ((null E) nil)
    ((is-monomial E)
    (list 'm
          (second E)
          (third E)
          (order-compress
           (fourth E))))
   ((is-number E)
    (evaluate-monomial
     (list 'm (eval E) 0 nil)))
   ((atom E)
    (list 'm
          1
          1
          (list (list 'v 1 E))))
   ((eql 'expt (car E))
    (list 'm 1 (third E)
          (list
           (list 'v
                 (third E)
                 (second E)))))
   ((not (eql (car E) '*))
    (error "That is not a Monomial"))
   (t (evaluate-monomial
       (list 'm
             (coeff (cdr E))
             (total-degree (cdr E))
             (order-compress
              (var-list (cdr E))))))))

;;; funzione evaluate-monomial Monomial -> Monomial :
;Restituisce (m 0 0 ()) se il coeff del monomio passato e' zero.
;Restituisce un errore se il totalDegree del monomio e' Negativo (questo
;controllo viene fatto sulla base di is-monomial che controlla
;che il totDegree sia >=0).
;Restituisce il monomio se e' nella forma normale.
; Viene usata in as-monomial per controllare che l'effettivo input sia
;corretto secondo i criteri di as-monomial
(defun evaluate-monomial (m)
  (cond
   ((null m) nil)
   ((or (zerop (second m))
         (<= (abs (second m))  1.0D-10))
    (list 'm 0 0 nil))
   ((> 0 (third m)) (error "Negative TotalDegree"))
   (t m)))

;;; funzione coeff Expression -> Coefficient :
;Data una espressione che rappresenta un monomio, ne ritorna il coeff
;vengono considerati anche i casi: sin-cos-log-expt-somma-diff-prodotto...
; Viene usata in as-monomial per ritornare il coeff.
(defun coeff (E)
  (cond
   ((null E) 1)
   ((is-number (car E))
    (* (eval (car E))
       (coeff (cdr E))))
   (t (coeff (cdr E)))))

;;; funzione total-degree Expression -> totalDegree :
;Calcola il totalDegree del monomio, prendendo come input
;una espressione nella forma stabilita nella consegna del progetto.
; Viene usata in as-monomial.
(defun total-degree (E)
  (cond
   ((null E) 0)
   ((is-number (car E))
    (+ 0 (total-degree (cdr E))))
   ((atom (car E))
    (+ 1 (total-degree (cdr E))))
   ((and (eql 'expt (first (car E)))
        (not (integerp (second (car E)))))
    (+ (third (car E))
       (total-degree (cdr E))))))

;;; is-number :
; Predicato che controlla se l'argomento e' un numero Reale nelle forme:
;sin-cos-log-expt-(+ <numeri>)-(- <numeri>)-(* <numeri>)-(/ <num1> <num2>).
; Viene usato nel progetto per controllare tutti questi casi
(defun is-number (x)
  (cond
   ((numberp x) t)
   ((atom x) nil) ;se x e' una variabile false
   ((and (eql 'expt (first x)) ;se x = (expt var num) false
         (atom (second x))
         (not (is-number (second x))))
    nil)
   ((and (eql 'expt (first x))
         (not (numberp (second x)))
         (not (number-list (second x))))
    nil) ;caso per gestire (as-polynomial '(expt <polynomial> <integer>)
   ((and (eql 'expt (first x)) ;se x = (expt num num) true
         (integerp (eval (second x))))
    t)
   ((and (eql 'sin (first x)) ;se x= sin
          (numberp (eval (second x))))
     t)
   ((and (eql 'cos (first x)) ;se x= cos
         (numberp (eval (second x))))
    t)
   ((and (eql 'tan (first x)) ;se x = tan
         (numberp (eval (second x))))
    t)
   ((and (eql 'log (first x)) ;se x = log
         (numberp (eval (second x))))
    t)
   ((and (listp x) ;se e' nella forma (- <numeri>)
         (eql (car x) '-)
         (number-list (cdr x)))
    t)
   ((and (listp x) ;se e' nella forma (+ <numeri>)
         (eql (car x) '+)
         (number-list (cdr x)))
    t)
   ((and (eql '/ (first x)) ;se x = (/ <num1> <num2>)
         (number-list (cdr x)))
    t)
  ((and (eql '* (first x))  ;se x = (* <numeri>)
         (number-list (cdr x)))
    t)
  (t nil)))

;;; number-list :
;predicato che controlla se una lista e' composta
;da soli numeri accettati da is-number
; Viene richiamata in is-number
(defun number-list (l)
  (cond
   ((and (is-number (car l))
         (null (cdr l)))
    t)
   ((null (cdr l)) nil)
   ((is-number (car l))
    (number-list (cdr l)))
   (t nil)))

;;; funzione var-list Expression -> varList :
;Crea una lista delle variabili nella forma (v <potenza> <variabile>)
; Viene usata in as-monomial
(defun var-list (E)
  (cond
   ((null E) nil)
   ((is-number (car E))
    (var-list (cdr E)))
   ((atom (car E))
    (cons (list 'v 1 (car E))
          (var-list (cdr E))))
   ((and (eql 'expt (first (car E)))
         (= 0 (third (car E))))
    (var-list (cdr E)))
   ((and (not (integerp (second (car E))))
         (eql 'expt (first (car E))))
    (cons (list 'v
                (third (car E))
                (second (car E)))
          (var-list (cdr E))))
   (t (var-list (cdr E)))))

;;; funzione order-compress ListaVar -> Ordered-ListaVar :
; tramite una sort ordina le variabili del monomio poi richiama
; la funzione compress-vars per comprimere la lista.
;L'ordinamento delle variabili avviene in maniera lessicografica
(defun order-compress (l)
  (cond
   ((null l) nil) ;se la lista e' vuota torna nil
   (t (compress-vars
       (sort
        (copy-seq l) ;per evitare la distruzione della lista
        'string<     ;data come input a sort
        :key
        'third)))))

;;; funzione compress-vars VarList -> VarList :
; prende una lista di variabili (v <potenza> <variabile>), la comprime
; sommando le potenze dove le variabili sono uguali e rimuovendole
;nelca caso in cui la potenza si annulli.
(defun compress-vars (l)
  (cond
   ((null l) nil)
   ((zerop (second (car l))) ;caso in cui (v 0 <variabile>) -> 1
    (cons (compress-vars (cdr l))
          nil))
   ((eql (third (first l))
         (third (second l)))
    (compress-vars
     (cons
      (list 'v
            (+ (second (first l))
               (second (second l)))
            (third (first l)))
      (cdr (cdr l)))))
   (t (cons (car l) (compress-vars (cdr l))))))

;;;funzione as-polynomial Expression -> Polynomial
; per l'uso vedere README.
; Funzione che data una espressione ritorna una struttura dati che
; rappresenta un polynomio.
; Per l'ordinamento dei monomi e' stata usata la funzione sort, usando il
; predicato monomial<^2 che confronta due polinomi.
(defun as-polynomial (E)
  (cond
   ((null E) (list 'poly nil))
   ((and (is-number E)     ;caso in cui E sia un numero
         (zerop (eval E))) ;accettato da is-number e sia zero
    (list 'Poly nil))
   ((is-number E)
       (list 'poly (list (as-monomial E))))
   ((atom E)      ;caso in cui E sia una variabile
    (list 'poly
          (list (as-monomial E))))
   ((is-monomial E)
    (list 'poly
          (list (list 'm
                      (second E)
                      (third E)
                      (order-compress
                       (fourth E))))))
   ((is-real-polynomial E) E)
   ((and (eql 'poly
              (first E))
         (not (is-real-polynomial E)))
    (list 'poly
          (sort
           (copy-seq
            (order-varlist (second E)))
           #'monomial<)))
   ((and (eql 'expt (first E))        ;caso particolare per calcolare
         (eql '+ (first (second E)))) ;la potenza di un polinomio
    (is-nil
     (polytime-list
      (power-poly
       (as-polynomial (second E))
       (third E)))))
   ((eql 'expt (first E))
    (list 'poly
          (list (as-monomial E))))
   ((not (eql '+ (car E)))
    (error "That is not a Polynomial"))
   (t (list 'poly
            (remove-zero
             (compress-monomials
              (order-monomials
               (list-monomials (cdr E )))))))))

;;; funzione power-poly List Number -> MonomialList:
;[usata per (as-polynomial '(expt <polinomio-da-parsare> <power>)].
;Crea una lista di polinomi uguali fra loro. Una volta creata si
;va a moltiplicare tutti i polinomi fra loro.
(defun power-poly (l n)
  (cond
   ((>  0 n) (error "...Coming Soon..."))
   ((zerop n) nil)
   (t (cons l (power-poly l (+ -1 n) )))))

;;; predicato is-nil:
;[usato per il caso '(expt <polinomio-da-parsare> <power>)].
; Se l'argomento che e' stato precendentemente valutato in polytime-list
; (in as-polynomial) fosse una lista vuota, ritorna il polinomio nullo.
(defun is-nil (x)
  (if (null x) (as-polynomial nil) x))

;;; funzione polytime-list MonomialList -> :
;[usata per (as-polynomial '(expt <polinomio-da-parsare> <power>)].
; presa una lista, creata da power-poly ne fa la compress, richiamando
; polytimes^2 definita piu' avanti nel progetto
(defun polytime-list (l)
  (cond
   ((null (cdr l)) (car l))
   ((null l) (as-polynomial 1))
   (t (polytimes (first l)
                 (polytime-list (cdr l))))))

;;;funzione order-varlist
;usata in as-polynomial nel caso gli venga
;passato un polinomio gia' nella forma
; (poly (<monomi>))
;serve per ordinare le variabili dei
;monomi che compongono il polinomio
(defun order-varlist (l)
  (cond
   ((null l) nil)
   ((cons (list 'm
                (second (car l))
                (third (car l))
                (order-compress (fourth (car l))))
          (order-varlist (cdr l))))))

;;; funzione list-monomials Expression -> Monomials:
;data una espressione, la funzione genera una lista di monomi
;da ordinare
(defun list-monomials (E)
  (cond
   ((null E) nil)
   (t (cons (as-monomial (car E)) (list-monomials (cdr E))))))

;;; funzione order-monomials Monomials -> Monomials:
; ordina la lista di monomi generata da list-monomials,
; viene usata la funzione sort per ordinare e
; sapendo che questa e' distruttiva, la lista viene
; prima passata alla funzione (copy-seq lista)
(defun order-monomials (E)
  (cond
   ((null E) nil)
   (t (sort (copy-seq E) #'monomial<))))

;;; predicato monomial< :
;monomial<^2 fa esattamente quello che fa la funzione
;<^2 solo che al posto dei numeri confronta monomi.
; quindi x<y , con x,y monomi vale se :
; totaldegree di x < totaldegree di y - oppure - se i totd
; sono uguali allora x<y vale se la prima var di x e' < della prima
; var di y in ordine lessicografico - oppure - se totd uguale e prima
; var uguale allora si va a vedere la potenza
; della variabile---> se sono uguali allora passare alla variabile successi
(defun monomial< (x y)
  (cond
  ; ((null (first (fourth x))) t)
  ; ((null (first (fourth y))) nil)
   ((null (fourth x)) t)
   ((null (fourth y)) nil)
   ((< (third x)
       (third y)) t) ; se il totdegree di x < y allora torna true
   ((> (third x)
       (third y)) nil)
   ((string-lessp
     (third
      (first
       (fourth x)))
     (third
      (first
       (fourth y)))) t) ;torna true se la prima var di x < di quella di y
   ((string-greaterp
     (third (first (fourth x)))
     (third (first (fourth y)))) nil)
   ((< (second (first (fourth x)))
       (second (first (fourth y)))) t)
   ((> (second (first (fourth x)))
       (second (first (fourth y)))) nil)
   ((= (second (first (fourth x)))
       (second (first (fourth y))))
    (monomial<
     (list (first x)
           (second x)
           (third x)
           (cdr (fourth x)))
     (list (first y)
           (second y)
           (third y)
           (cdr (fourth y)))))
   (t nil)))

;;; funzione compress-monomials Monomials -> Monomials :
;comprime la lista dei monomi ordinata da order-monomials.
;NB un monomio si puo' sommare ad un altro se hanno le
; stesse variabili con lo stesso grado.
(defun compress-monomials (E)
  (cond
   ((null E) nil)
   ((null (cdr E))
    (list (car E))) ;caso in cui ho un solo elemento
 ;  ((= 0 (second (first E))) (comprimi (cdr E)))
   ((equal (fourth (first E))
           (fourth (second E)))
    (compress-monomials (cons (list 'm
                          (+ (second (first E))
                             (second (second E)))
                          (third (first E))
                          (fourth (first E)))
                    (cdr (cdr E)))))
   (t (cons (car E)
            (compress-monomials (cdr E))))))

;;; funzione remove zero Monomials -> Monomials:
;rimuove dalla lista ordinata e compressa tutti
;i monomi nulli
(defun remove-zero (l)
  (cond
   ((null l) nil)
   ((zerop (second (car l)))
    (remove-zero (cdr l)))
   (t (cons (car l)
            (remove-zero (cdr l))))))

;;; funzione varpowers Monomial -> VP-list:
;data una struttura Monomial, ritorna la lista
;delle variabili nella forma (v <potenza> <var>)
(defun varpowers (m)
  (cond
   ((null m) nil)
   ((is-monomial m) (fourth m))
   (t (varpowers (as-monomial m)))))

;;; funzione vars-of Monomial -> Variables:
;dato un monomio ritorna la lista delle
;variabili.
(defun vars-of (m)
  (cond
   ((null m) nil)
   ((is-monomial m) (vars (fourth m)))
   (t (vars-of (as-monomial m)))))

;;; funzione vars Monomial -> Variables:
;ritorna la lista delle variabili
;controllando che ogni singolo elemento
;della lista sia effettivamente
;(v <potenza> <variabile>)
(defun vars (l)
  (cond
   ((null l) nil)
   ((is-varpower (car l))
    (cons (third (car l))
          (vars (cdr l))))))

;;; funzione monomial-degree Monomial -> TotalDegree:
;restituisce il totalDegree del monomio.
(defun monomial-degree (m)
  (cond
   ((null m) nil)
   ((is-monomial m) (third m))
   (t (monomial-degree
       (as-monomial m)))))

;;; funzione monomial-coefficient Monomial -> Coefficient:
;restiuisce il coefficiente del monomio.
(defun monomial-coefficient (m)
  (cond
   ((null m) nil)
   ((is-monomial m) (second m))
   (t (monomial-coefficient
       (as-monomial m)))))

;;; funzione coefficients Poly -> Coefficients:
;dato un polinomio, ritorna la lista dei
;suoi coefficienti.
;E' possibile anche passare un monomio
;in questo caso viene restituita una lista
;con un solo elemento.
(defun coefficients (Poly)
  (cond
   ((null (second Poly)) (list 0))
   ((is-monomial Poly) (monomial-coefficient Poly))
   ((is-real-polynomial Poly)
    (remove-null-coeff
     (cons (monomial-coefficient
            (first (second Poly)))
           (coefficients
            (list 'POLY
                  (cdr (second Poly)))))))
   (t (coefficients (as-polynomial Poly)))))

;;; funzione remove-null-coeff
;usata in coefficients che rimuove
;lo zero messo in ultima posizione dal caso
;base di coefficients.
(defun remove-null-coeff (l)
  (cond
   ((null l) nil)
   ((zerop (car l))
    (remove-null-coeff (cdr l)))
   (t (cons (car l)
            (remove-null-coeff (cdr l))))))

;funzione variables Poly -> Variables :
;dato un polinomio, ritorna la lista
;delle sue variabili. Come in
; coefficients^1 si puo' passare una
;espressione da "parsare" nella forma
;richiesta.
(defun variables (Poly)
  (cond
   ((and (is-real-polynomial Poly)
         (null (second Poly)))
    nil)
   ((is-monomial Poly) (vars-of Poly))
   ((is-real-polynomial Poly)
    (vars-list (second Poly)))
   (t (variables
       (as-polynomial Poly)))))


;;; funzione vars-list Monomials -> Variables :
;NB diversa da var-list...
;Sfruttando var-of estrae da ogni singolo
;monomio le variabili e tramite la union genera
;una lista senza variabili doppie, poi la ordina
;tramite una sort.
;NB2 siccome sort e' distruttiva viene usata la
;funzione copy-seq^1.
(defun vars-list (l)
  (cond
   ((null l) nil)
   ((listp l)
    (sort
     (copy-seq
      (union (vars-of (car l))
             (vars-list (cdr l))))
     #'string-lessp))))

;;; funzione monomials Poly -> Monomials:
;Dato un polinomio restituisce la lista
;dei monomi, ordinata e compressa.
;Come in coefficients^1 e variables^1
;si puo' passare un'espressione sulla
;quale si effettueranno controlli.
(defun monomials (Poly)
  (cond
   ((null Poly) nil)
   ((null (second Poly)) nil)
   ((is-monomial Poly) (list Poly))
   ((is-real-polynomial Poly)
    (second Poly))
   (t (monomials
       (as-polynomial Poly)))))

;;; funzione maxdegree Poly -> Degree:
;Preso come input un polinomio, viene
;restituito il massimo grado dei monomi
;che appaiono in Poly.
;E' anche stato considerato, oltre al caso che
;venga passata un'espressione da valutare,
;anche la possibilita' di passare un monomio
;singolo e una lista di monomi.
(defun maxdegree (Poly)
  (cond
   ((is-monomial Poly) (monomial-degree Poly))
   ((is-real-polynomial Poly)
    (maximus (list-degrees (monomials Poly))))
   ((is-real-polynomial (list 'poly (list Poly)))
    (maximus (list-degrees Poly)))
   (t (maxdegree
       (as-polynomial Poly)))))

;;; funzione mindegree Poly -> Degree:
;come in maxdegree^1, vengono accettati
;diversi input e la funzione ritornera'
;sempre il minimo grado dei monomi che
;appaiono in Poly
(defun mindegree (Poly)
  (cond
   ((is-monomial Poly) (monomial-degree Poly))
   ((is-real-polynomial Poly)
    (minimus (list-degrees (monomials Poly))))
   ((is-real-polynomial
     (list 'poly (list Poly)))
    (minimus (list-degrees Poly)))
   (t (mindegree
       (as-polynomial Poly)))))

;;; funzione list-degrees Monomials -> DegreesList:
;data una lista di monomi ritorna una lista
;dei totalDegree.
;Questa funzione viene usata per trovare comunque
;il massimo-minimo anche se viene passato
;un polinomio disordinato
(defun list-degrees (l)
  (cond
   ((null l) nil)
   (t (cons (third (car l))
            (list-degrees (cdr l))))))

;;; funzione maximus Degree -> MaxDegree:
;trova il massimo elemento in una lista
;di numeri
(defun maximus (l)
  (cond
   ((null l) 0)
   ((null (cdr l)) (car l))
   (t (max (car l)
           (maximus (cdr l))))))

;;; funzione minimus Degree -> MinDegree:
;trova il minimo elemento di una lista
;di numeri
(defun minimus (l)
  (cond
   ((null l) 0)
   ((null (cdr l)) (car l))
   (t (min (car l)
           (minimus (cdr l))))))

;;; funzione polyplus Poly1 Poly2 -> Result
;vengono fatti tutti i controlli opportuni sugli argomenti
;se sono un monomio polinomio, polinomio monomio ecc ecc.
;restituisce un polynomio che e' il risultato della somma
;dei due polinomi passati come argomenti.
;Il nuovo polinomio viene anche ordinato e "compresso".
(defun polyplus (Poly1 Poly2)
  (cond
   ((and (is-monomial Poly1)
         (is-monomial Poly2))
    (polyplus (list 'poly (list Poly1))
              (list 'poly (list Poly2))))
   ((and (is-monomial Poly1)
         (is-real-polynomial Poly2))
    (polyplus (list 'poly (list Poly1)) Poly2))
   ((and (is-monomial Poly2)
         (is-real-polynomial Poly1))
    (polyplus Poly1 (list 'poly (list Poly2))))
   ((not (and  (is-real-polynomial Poly1)
               (is-real-polynomial Poly2)))
    (polyplus (as-polynomial Poly1) (as-polynomial Poly2)))
   ((and (null (second Poly1))
         (is-real-polynomial Poly2)) Poly2)
   ((and (null (second Poly2))
         (is-real-polynomial Poly1)) Poly1)
   (t
    (list 'Poly (remove-zero
                 (compress-monomials
                  (sort
                   (copy-seq
                    (append (second Poly1)
                            (second Poly2)))
                   #'monomial<)))))))

;;; funzione polyminus Poly1 Poly2 -> Result
;vengono fatti gli stessi controlli di polyplus sugli argomenti
;e una volta fatta la differenza, il
;polinomio risultante viene ordinato.
;viene usata la funzione compress-monomials, implementata
;precedentemente per as-polynomial.
(defun polyminus (Poly1 Poly2)
  (cond
   ((and (is-monomial Poly1)
         (is-monomial Poly2))
    (polyminus (list 'poly (list Poly1))
              (list 'poly (list Poly2))))
   ((and (is-monomial Poly1)
         (is-real-polynomial Poly2))
    (polyminus (list 'poly (list Poly1)) Poly2))
   ((and (is-monomial Poly2)
         (is-real-polynomial Poly1))
    (polyminus Poly1 (list 'poly (list Poly2))))
   ((not (and (is-real-polynomial Poly1)
              (is-real-polynomial Poly2)))
    (polyminus (as-polynomial Poly1) (as-polynomial Poly2)))
   ((and (null (second Poly1))
         (is-real-polynomial Poly2))
    (list 'poly (change-sign (second Poly2))))
   ((and (null (second Poly2))
         (is-real-polynomial Poly1)) Poly1)
   (t
    (list 'poly
          (remove-zero
           (compress-monomials
            (sort
             (copy-seq
              (append (second Poly1)
                      (change-sign (second Poly2))))
             #'monomial<)))))))

;;; funzione change-sign:
;cambia il segno a tutti i coefficienti di un polinomio.
;Usata in polyminus^2.
(defun change-sign (l)
  (cond
   ((null l) nil)
   (t (cons
       (list 'm
             (* -1 (second (first l)))
             (third (first l))
             (fourth (first l)))
       (change-sign (cdr l))))))

;;; funzione polytimes Poly1 Poly2 -> Result
;come per le polyplus^2 e polyminus^2,
;vengono fatti tutti i controlli sui due argomenti
;anche se si passano polinomi 'disordinati' dal
;punto di vista delle variabili, la funzione
;e' implementata per farne comunque il
;prodotto e ritornarne un polinomio ordinato e
;semplificato.
(defun polytimes (Poly1 Poly2)
  (cond
   ((and (is-monomial Poly1)
         (is-monomial Poly2))
    (polytimes (list 'poly (list Poly1))
              (list 'poly (list Poly2))))
   ((and (is-real-polynomial Poly1)
         (is-monomial Poly2))
    (polytimes Poly1 (list 'poly (list Poly2))))
   ((and (is-real-polynomial Poly2)
         (is-monomial Poly1))
    (polytimes (list 'poly (list Poly1)) Poly2))
   ((and (not (atom Poly1))
         (null (second Poly1)))
    (list 'Poly nil))
   ((and (not (atom Poly2))
         (null (second Poly2)))
    (list 'Poly nil))
   ((and (is-real-polynomial Poly1)
         (is-real-polynomial Poly2))
    (list 'Poly
          (remove-zero
           (compress-monomials
            (sort
             (copy-seq
              (multiply-monomials
               (second Poly1)
               (second Poly2)))
             #'monomial<)))))
   (t (polytimes (as-polynomial Poly1)
                 (as-polynomial Poly2)))))

;;; funzione multiply-monomials Monomials Monomials -> Monomials:
;date due liste di monomi ne fa il prodotto.
;prende il primo monomio della prima lista e lo
;moltiplica per tutti i monomi della seconda, poi ricorsivamente
;moltiplica il resto della prima lista per la seconda
(defun multiply-monomials (x y)
  (cond
   ((null x) nil)
   ((null y) nil)
   (t (append
       (times-monomial (car x) y)
       (multiply-monomials (cdr x) y)))))

;;; funzione times-monomiall Monomial Monomials -> Monomials:
;Moltiplica un monomio per una lista di monomi
;sfrutta la order-compress^1 per ordinare e
;semplificare la lista di variabili.
(defun times-monomial (x l)
  (cond
   ((null l) nil)
   ((and (is-monomial x)
         (is-monomial (car l)))
    (cons
     (list 'm
           (* (second x) (second (car l)))
           (+ (third x) (third (first l)))
           (order-compress
            (append (fourth x)
                    (fourth (first l)))))
     (times-monomial x (cdr l))))))

;;; funzione polyval Polynomial VariablesValue --> Value:
; funzione che dato un polinomio/monomio ed una
;lista di valori, restituisce il valore ottenuto
;tramite la sostituzione dei valori nelle variabili
;del polinomio/monomio.
;Vengono gestiti i casi in cui a) non vengano inseriti
;valori come secondo argomento,b) la lista dei
;valori e' piu' corta della lista delle variabili
;c) viene passata una lista che contiene uno o piu'
;elementi che non sono numerici [accettati da is-number].
;In questi casi viene generato un errore altrimenti si
;passa alla sostituzione.
(defun polyval (poly varVal)
  (cond
   ((null varVal)
    (error "No values in the second argument"))
   ((and (is-real-polynomial poly)
         (< (length varVal) (length (variables poly))))
    (error "variables-list greater than values-list"))
   ((not (is-number-list varVal))
    (error "Value-List holds a not number element"))
   ((is-monomial poly)
    (polyval (list 'poly (list poly))
             varVal))
   ((is-real-polynomial poly)
    (replace-vars (monomials poly)
                 (variables poly)
                 varVal))
   (t (polyval (as-polynomial poly) varVal))))

;;; predicato is-number-list:
;controlla che la lista sia composta da soli
;numeri accettati da is-number^1
(defun is-number-list (l)
  (cond
   ((and (null (cdr l))
         (is-number (car l)))
    t)
   ((null (cdr l)) nil)
   ((not (is-number (car l))) nil)
   (t (is-number-list (cdr l)))))

;;; funzione replace-vars Monomials Variables Values -> Value:
; estrae un monomio dalla lista di monomi e lo
;passa assieme alla lista delle variabili e
;dei valori alla funzione list-monomials-var.
;questo una volta valutato il monomio, ritornera'
; un valore che andra' a sommarsi con il
;risultato delle chiamate ricorsive di replace-vars.
(defun replace-vars (mon var val)
  (cond
   ((null mon) 0)
   (t (+ (times-values
          (list-monomials-var
           (car mon) var val))
         (replace-vars
          (cdr mon) var val)))))

;;; funzione list-monomials-var Mon Vars Vals -> Value:
; Funzione che mette in una lista tutte le
; sostituzioni dei valori nelle variabili
;del monomio
(defun list-monomials-var (mon var val)
  (cond
   ((null (fourth mon)) nil) ;caso lista var vuota
   ((eql (third         ;se la variabile del mon = alla prima variabile
          (first        ;di var, allora sostituisce e la mette in una lista
           (fourth mon)))
         (car var))
    (cons (expt (eval (car val)) ;eval nel caso non sia solo
                (second          ; un numero ma anche cos sin ecc
                 (first (fourth mon))))
          (list-monomials-var
           (list 'm
                 (second mon)
                 (third mon)
                 (cdr (fourth mon)))
           (cdr var)
           (cdr val))))
   (t (list-monomials-var mon
                 (cdr var)
                 (cdr val)))))

;;; funzione times-values Values -> Value:
;Riceve una lista di interi accettati da is-number
; e li moltiplica fra loro
(defun times-values (l)
  (cond
   ((null l) 1)
   (t (* (car l)
         (times-values(cdr l))))))

;;;funzione pprint-polynomial Polynomial -> Nil
;funzione che stampa a video un polinomio e
;restituisce nil
(defun pprint-polynomial (Poly)
  (cond
   ((null (second Poly)) nil)
   ((is-real-polynomial Poly)
    (format t "~A" (string-poly (second Poly))))))

(defun string-poly (x)
  (cond
   ((null x) "")
   ((null (cdr x))
    (concatenate
     'string
     (if (= 1 (second (car x))) "+"
       (concatenate 'string
                    (if (< (second (car x)) 0) "" "+")
                    (write-to-string (second (car x)))))
     (if (null (fourth (car x))) "~T "
       (string-var (fourth (car x))))))
   (t (concatenate 'string
                   (if (= 1 (second (car x))) "+"
                     (concatenate 'string
                                  (if (< (second (car x)) 0) "" "+")
                                  (write-to-string (second (car x)))))
                   (if (null (fourth (car x))) " "
                     (string-var (fourth (car x))))
                   (string-poly (cdr x))
                   ))))

(defun string-var (y)
  (cond
   ((null y) " ")
   ((and (null (cdr y))
         (= 1 (second (car y))))
    (symbol-name (third (car y))))
   ((= 1 (second (car y)))
    (concatenate 'string
                 (symbol-name
                  (third (car y)))
                 "*"
                 (string-var (cdr y))))
   (t (concatenate 'string
                   (symbol-name (third (car y)))
                   "^"
                   (write-to-string
                    (second (car y)))
                   "*"
                   (string-var (cdr y))))))
