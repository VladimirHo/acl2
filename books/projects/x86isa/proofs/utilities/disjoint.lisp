;; AUTHOR:
;; Shilpi Goel <shigoel@cs.utexas.edu>

(in-package "X86ISA")
(include-book "std/util/define" :dir :system)
(include-book "std/lists/rev" :dir :system)
(include-book "std/lists/flatten" :dir :system)

;; ===================================================================

;; Member-p:

(define member-p
  (e
   (x (true-listp x)))

  :parents (proof-utilities)
  :enabled t

  (if (endp x)
      nil
    (if (equal e (car x))
	t
      (member-p e (cdr x))))

  ///

  (defthm member-p-of-not-a-consp
    (implies (not (consp x))
	     (equal (member-p e x) nil)))

  (defthm member-p-of-nil
    (equal (member-p e nil) nil))

  (defthm member-p-cons
    (equal (member-p e1 (cons e2 x))
	   (if (equal e1 e2)
	       t
	     (member-p e1 x))))

  (defthm member-p-append
    (equal (member-p e (append x y))
	   (or (member-p e x)
	       (member-p e y))))

  (defthm member-p-cdr
    (implies (member-p e (cdr x))
	     (member-p e x))
    ;; From the ACL2-DOC:
    ;; The relieving of hypotheses may be limited to the use of
    ;; contextual information (without backchaining, i.e., without
    ;; recursively rewriting hypotheses) by executing
    ;; :set-backchain-limit 0.
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthmd member-p-iff-member-equal
    (iff (member-p e x)
	 (member-equal e x))))

;; ======================================================================

;; Disjoint-p:

(define disjoint-p
  ((x (true-listp x))
   (y (true-listp y)))

  :parents (proof-utilities)
  :long "<p>@('disjoint-p') returns @('t') if @(see true-listp)-satisfying
  inputs @('x') and @('y') have no element in common. Otherwise, @('nil') is
  returned.</p>"
  :enabled t

  (if (endp x)
      t
    (if (member-p (car x) y)
	nil
      (disjoint-p (cdr x) y)))

  ///

  (defthm disjoint-p-x-x
    (implies (consp x)
	     (equal (disjoint-p x x) nil)))

  (defthm disjoint-p-nil-1
    (equal (disjoint-p nil y) t)
    :hints (("Goal" :in-theory (e/d (disjoint-p) ()))))

  (defthm disjoint-p-nil-2
    (equal (disjoint-p x nil) t)
    :hints (("Goal" :in-theory (e/d (disjoint-p) ()))))

  (defthmd disjoint-p-cdr-1
    (implies (disjoint-p x y)
	     (disjoint-p (cdr x) y))
    :hints (("Goal" :in-theory (e/d (disjoint-p member-p) ())))
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthmd disjoint-p-cdr-2
    (implies (disjoint-p x y)
	     (disjoint-p x (cdr y)))
    :hints (("Goal" :in-theory (e/d (disjoint-p member-p) ())))
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthmd disjoint-p-cons-1
    (equal (disjoint-p (cons e x) a)
	   (and (disjoint-p x a)
		(equal (member-p e a) nil)))
    :hints (("Goal" :in-theory (e/d* (disjoint-p) ()))))

  (defthm disjoint-p-cons-2
    (equal (disjoint-p a (cons e x))
	   (and (disjoint-p a x)
		(equal (member-p e a) nil))))

  (defthmd disjoint-p-commutative
    (equal (disjoint-p a b)
	   (disjoint-p b a))
    :rule-classes ((:rewrite :loop-stopper ((a b)))))

  (defthmd member-p-when-not-disjoint-p
    (implies (and (member-p e x)
		  (member-p e y))
	     (equal (disjoint-p x y) nil)))

  (defthm not-member-p-when-disjoint-p
    (implies (and (disjoint-p x y)
		  (member-p e x))
	     (equal (member-p e y) nil)))

  (defthm disjoint-p-append-1
    (implies (true-listp a)
	     (equal (disjoint-p (append a b) c)
		    (and (disjoint-p a c)
			 (disjoint-p b c)))))

  (defthm disjoint-p-append-2
    (implies (true-listp b)
	     (equal (disjoint-p a (append b c))
		    (and (disjoint-p a b)
			 (disjoint-p a c))))))

(define disjoint-p$ ((x (true-listp x))
		     (y (true-listp y)))
  (disjoint-p x y)
  ///
  (defthmd rewrite-disjoint-p$-to-disjoint-p
    (equal (disjoint-p$ x y) (disjoint-p x y))))

;; ======================================================================

;; Position:

(defun pos-1 (e x n)
  (declare (xargs :guard (and (true-listp x)
			      (natp n))))
  (if (endp x)
      nil
    (if (equal e (car x))
	n
      (pos-1 e (cdr x) (1+ n)))))

(defthm member-p-pos-1-non-nil
  (implies (and (member-p e x)
		(natp n))
	   (natp (pos-1 e x n)))
  :rule-classes :type-prescription)

(defthm member-p-pos-1-value
  (implies (and (member-p e x)
		(natp n))
	   (< (- (pos-1 e x n) n) (len x)))
  :rule-classes :linear)

(defthm not-member-p-pos-1-nil
  (implies (equal (member-p e x) nil)
	   (equal (pos-1 e x n) nil)))

(defthm pos-1-accumulator-thm
  (implies (member-p e x)
	   (equal (pos-1 e x (+ n1 n2))
		  (+ n1 (pos-1 e x n2)))))

(define pos
  (e
   (x (true-listp x)))

  :parents (proof-utilities)
  :short "Position of element @('e') in a list @('x')"

  :long "<p>We use this function to get the byte located at a memory
  address; thus, in our use case, @('e') is the address, @('x') is the
  region of memory represented as a true-list, and the return value is
  the byte at address @('e') \(if @('e') is a valid address in
  @('x')\).  We use this function exclusively on the output obtained
  from functions like @(see rb) and @(see program-at).</p>"

  :enabled t

  (pos-1 e x 0)

  ///

  (defthm member-p-pos-non-nil
    (implies (member-p e x)
	     (and (integerp (pos e x))
		  (<= 0 (pos e x))))
    :rule-classes :type-prescription)

  (defthm member-p-pos-value
    (implies (member-p e x)
	     (< (pos e x) (len x)))
    :rule-classes :linear)

  (defthm not-member-p-pos-nil
    (implies (equal (member-p e x) nil)
	     (equal (pos e x) nil)))

  (defthm nth-pos-of-list-first
    ;; See nth-pos-of-addr-range-first.
    (implies (and (syntaxp (not (and (consp xs)
				     (eq (car xs) 'addr-range))))
		  (equal index (car xs))
		  (consp xs))
	     (equal (pos index xs) 0))
    :hints (("Goal" :in-theory (e/d* (pos) ())))))

;; ======================================================================

;; Subset-p:

(define subset-p
  ((x (true-listp x))
   (y (true-listp y)))

  :parents (proof-utilities)
  :enabled t

  (if (consp x)
      (if (member-p (car x) y)
	  (subset-p (cdr x) y)
	nil)
    (if (equal x nil)
	t
      nil))

  ///

  (defthm subset-p-cdr-x
    (implies (subset-p x y)
	     (subset-p (cdr x) y))
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthm subset-p-cdr-y
    (implies (subset-p x (cdr y))
	     (subset-p x y))
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthm subset-p-cons
    (implies (subset-p x y)
	     (subset-p (cons e x) (cons e y)))
    :rule-classes ((:rewrite :backchain-limit-lst (0))))

  (defthm subset-p-reflexive
    (implies (true-listp x)
	     (equal (subset-p x x) t)))

  (defthmd subset-p-transitive
    (implies (and (subset-p x y)
		  (subset-p y z))
	     (subset-p x z)))

  ;; (defthm append-subset-p-1
  ;;   (implies (and (subset-p a x)
  ;;                 (subset-p b x))
  ;;            (subset-p (append a b) x)))

  (defthm subset-p-of-append-1
    (implies (true-listp a)
	     (equal (subset-p (append a b) x)
		    (and (subset-p a x)
			 (subset-p b x)))))

  (defthm subset-p-of-append-2
    (implies (or (subset-p a x)
		 (subset-p a y))
	     (subset-p a (append x y))))

  (defthm subset-p-and-append-both
    (implies (subset-p a b)
	     (subset-p (append e a) (append e b))))

  (defthm subset-p-of-nil
    (equal (subset-p x nil)
	   (equal x nil)))

  (defthm subset-p-cons-2
    (implies (subset-p x y)
	     (subset-p x (cons e y))))

  (defthm member-p-of-subset-is-member-p-of-superset
    (implies (and (subset-p x y)
		  (member-p e x))
	     (member-p e y)))

  (defthmd not-member-p-of-superset-is-not-member-p-of-subset
    (implies (and (equal (member-p e y) nil)
		  (subset-p x y))
	     (equal (member-p e x) nil))
    :hints (("Goal" :in-theory (e/d* (member-p) ()))))

  (defthmd subset-p-and-remove-duplicates-equal-1
    (implies (subset-p x y)
	     (subset-p (remove-duplicates-equal x) y))
    :hints (("Goal" :in-theory (e/d* (subset-p) ()))))

  (defthmd subset-p-and-remove-duplicates-equal-2
    (implies (subset-p x y)
	     (subset-p x (remove-duplicates-equal y)))
    :hints (("Goal" :in-theory (e/d* (subset-p) ()))))

  (defthmd subset-p-and-remove-duplicates-equal-both
    (implies (subset-p x y)
	     (subset-p (remove-duplicates-equal x) (remove-duplicates-equal y)))
    :hints (("Goal" :in-theory (e/d* (subset-p-and-remove-duplicates-equal-1
				      subset-p-and-remove-duplicates-equal-2)
				     ()))))

  (defthmd subset-p-remove-duplicates-equal-is-subset-p
    (implies (true-listp x)
	     (equal (subset-p (remove-duplicates-equal x) (remove-duplicates-equal y))
		    (subset-p x y)))
    :hints (("Goal" :in-theory (e/d* (subset-p
				      remove-duplicates-equal
				      subset-p-and-remove-duplicates-equal-both)
				     ())))))

;; ======================================================================

;; no-duplicates-p:

(define no-duplicates-p
  ((l (true-listp l)))

  :parents (proof-utilities)
  :enabled t

  (cond ((endp l) t)
	((member-p (car l) (cdr l)) nil)
	(t (no-duplicates-p (cdr l))))

  ///

  (defthm no-duplicates-p-and-append
    (implies (no-duplicates-p (append a b))
	     (and (no-duplicates-p a)
		  (no-duplicates-p b)))
    :rule-classes (:forward-chaining :rewrite)))

(defthmd no-duplicatesp-equal-to-no-duplicates-p
  (equal (no-duplicatesp-equal xs)
	 (no-duplicates-p xs)))

(defthmd no-duplicates-p-to-no-duplicatesp-equal
  (equal (no-duplicates-p xs)
	 (no-duplicatesp-equal xs)))

;; ======================================================================

;; Misc. theorems:

(defthm disjoint-p-forward-chain-to-member-p
  (implies (disjoint-p (list i) x)
	   (not (member-p i x)))
  :rule-classes :forward-chaining)

(defthm cdr-strip-cars-is-strip-cars-cdr
  (equal (cdr (strip-cars x))
	 (strip-cars (cdr x))))

(defthm strip-cars-append
  (equal (strip-cars (append x y))
	 (append (strip-cars x)
		 (strip-cars y))))

(defthm disjoint-p-subset-p
  ;; Ugh, free vars.
  (implies (and (disjoint-p x y)
		(subset-p a x)
		(subset-p b y))
	   (disjoint-p a b)))

(defthm subset-p-cons-member-p-lemma
  ;; Ugh, free vars.
  (implies (and (subset-p x (cons e y))
		(not (subset-p x y)))
	   (not (member-p e y))))

(local (include-book "std/lists/reverse" :dir :system))

(defthm assoc-of-append-when-member-p-1
  (implies (member-p a (strip-cars xs))
	   (equal (assoc-equal a (append xs ys))
		  (assoc-equal a xs))))

(defthm assoc-of-append-when-member-p-2
  (implies (not (member-p a (strip-cars xs)))
	   (equal (assoc-equal a (append xs ys))
		  (assoc-equal a ys))))

(defthm strip-cars-of-rev-is-rev-of-strip-cars
  (equal (strip-cars (acl2::rev x))
	 (acl2::rev (strip-cars x))))

;; (defthm member-p-of-rev
;;   (equal (member-p x (acl2::rev y))
;;          (member-p x y))
;;   :hints (("Goal" :in-theory (e/d (member-p) ()))))

(defthm member-p-of-rev
  (iff (member-p e (acl2::rev x))
       (member-p e x)))

(defthm subset-p-of-rev
  (equal (subset-p x (acl2::rev y))
	 (subset-p x y))
  :hints (("Goal" :in-theory (e/d (subset-p) ()))))

(defthm member-of-rev
  (implies (member-p a xs)
	   (member-p a (acl2::rev xs)))
  :hints (("Goal" :in-theory (e/d (member-p) ()))))

 (defthm member-strip-cars-assoc-and-rev
   (implies (member-p a (strip-cars xs))
	    (member-p a (acl2::rev (strip-cars xs)))))

(defthm assoc-of-append-when-member-p-with-rev
  (implies (member-p a (strip-cars xs))
	   (equal (assoc-equal a (append (acl2::rev xs) ys))
		  (assoc-equal a (acl2::rev xs)))))

(defthm not-member-assoc-equal-with-rev-and-strip-cars
  (implies (not (member-p a (strip-cars xs)))
	   (equal (cdr (assoc a (acl2::rev (acons a b xs))))
		  b))
  :hints (("Goal" :in-theory (e/d (member-p) ()))))

(defthm assoc-equal-append-list-cons-and-not-member-p
  (implies (and (not (member-p e (strip-cars x)))
		(alistp x))
	   (equal (assoc-equal e (append x (list (cons e y))))
		  (cons e y)))
  :hints (("Goal" :in-theory (e/d* (member-p) ()))))

;; ======================================================================

(in-theory (e/d () (member-p disjoint-p pos subset-p)))

;; ======================================================================
