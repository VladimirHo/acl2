; Milawa - A Reflective Theorem Prover
; Copyright (C) 2005-2009 Kookamara LLC
;
; Contact:
;
;   Kookamara LLC
;   11410 Windermere Meadows
;   Austin, TX 78759, USA
;   http://www.kookamara.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Jared Davis <jared@kookamara.com>

(in-package "MILAWA")
(include-book "eqtrace-okp")
(include-book "transitivity-eqtraces")
(include-book "../../clauses/basic-bldrs")
(set-verify-guards-eagerness 2)
(set-case-split-limitations nil)
(set-well-founded-relation ord<)
(set-measure-function rank)

(defund rw.trans1-eqtrace-bldr (x box proofs)
  (declare (xargs :guard (and (rw.eqtracep x)
                              (rw.hypboxp box)
                              (rw.trans1-eqtrace-okp x)
                              (rw.eqtrace-okp x box)
                              (logic.appeal-listp proofs)
                              (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list (rw.eqtrace->subtraces x) box)))
                  :verify-guards nil)
           (ignore box))
  (if (rw.eqtrace->iffp x)
      (let ((proof1 (if (rw.eqtrace->iffp (first (rw.eqtrace->subtraces x)))
                        (first proofs)
                      (build.disjoined-iff-from-equal (first proofs))))
            (proof2 (if (rw.eqtrace->iffp (second (rw.eqtrace->subtraces x)))
                        (second proofs)
                      (build.disjoined-iff-from-equal (second proofs)))))
        (build.disjoined-transitivity-of-iff proof1 proof2))
    (build.disjoined-transitivity-of-equal (first proofs) (second proofs))))

(defobligations rw.trans1-eqtrace-bldr
  (build.disjoined-iff-from-equal
   build.disjoined-transitivity-of-equal
   build.disjoined-transitivity-of-iff))

(defthmd lemma-1-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
  (implies (and (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list x box))
                (force (consp x)))
           (equal (logic.conclusion (car proofs))
                  (rw.eqtrace-formula (car x) box))))

(defthmd lemma-2-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
  (implies (and (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list x box))
                (force (consp (cdr x))))
           (equal (logic.conclusion (second proofs))
                  (rw.eqtrace-formula (second x) box))))

(defthmd lemma-3-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
  (implies (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list x box))
           (equal (consp proofs)
                  (consp x))))

(defthmd lemma-4-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
  (implies (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list x box))
           (equal (consp (cdr proofs))
                  (consp (cdr x)))))


(encapsulate
 ()
 (local (in-theory (enable rw.eqtrace-formula
                           rw.trans1-eqtrace-bldr
                           rw.trans1-eqtrace-okp
                           lemma-1-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
                           lemma-2-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
                           lemma-3-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
                           lemma-4-for-forcing-logic.appealp-of-rw.trans1-eqtrace-bldr)))

 (defthm forcing-rw.trans1-eqtrace-bldr-under-iff
   (iff (rw.trans1-eqtrace-bldr x box proofs)
        t))

 (defthm forcing-logic.appealp-of-rw.trans1-eqtrace-bldr
   (implies (force (and (rw.eqtracep x)
                        (rw.hypboxp box)
                        (rw.trans1-eqtrace-okp x)
                        (rw.eqtrace-okp x box)
                        (logic.appeal-listp proofs)
                        (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list (rw.eqtrace->subtraces x) box))))
            (equal (logic.appealp (rw.trans1-eqtrace-bldr x box proofs))
                   t)))

 (defthm forcing-logic.conclusion-of-rw.trans1-eqtrace-bldr
   (implies (force (and (rw.eqtracep x)
                        (rw.hypboxp box)
                        (rw.trans1-eqtrace-okp x)
                        (rw.eqtrace-okp x box)
                        (logic.appeal-listp proofs)
                        (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list (rw.eqtrace->subtraces x) box))))
            (equal (logic.conclusion (rw.trans1-eqtrace-bldr x box proofs))
                   (rw.eqtrace-formula x box)))
   :rule-classes ((:rewrite :backchain-limit-lst 0)))

 (defthm@ forcing-logic.proofp-of-rw.trans1-eqtrace-bldr
   (implies (force (and (rw.eqtracep x)
                        (rw.hypboxp box)
                        (rw.trans1-eqtrace-okp x)
                        (rw.eqtrace-okp x box)
                        (logic.appeal-listp proofs)
                        (equal (logic.strip-conclusions proofs) (rw.eqtrace-formula-list (rw.eqtrace->subtraces x) box))
                        ;; ---
                        (logic.proof-listp proofs axioms thms atbl)
                        (equal (cdr (lookup 'iff atbl)) 2)
                        (@obligations rw.trans1-eqtrace-bldr)))
            (equal (logic.proofp (rw.trans1-eqtrace-bldr x box proofs) axioms thms atbl)
                   t)))

 (verify-guards rw.trans1-eqtrace-bldr))
