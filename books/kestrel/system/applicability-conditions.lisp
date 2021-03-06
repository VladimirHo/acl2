; Applicability Conditions
;
; Copyright (C) 2015-2016 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file provides utilities to manage logical formulas
; that must hold for certain processes to apply
; (e.g. for transforming a function into a new function).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "kestrel/system/event-forms" :dir :system)
(include-book "kestrel/system/fresh-names" :dir :system)
(include-book "kestrel/system/prove-interface" :dir :system)
(include-book "std/util/defaggregate" :dir :system)

(local (set-default-parents applicability-conditions))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection applicability-conditions
  :parents (kestrel-system-utilities system-utilities)
  :short
  "Utilities to manage logical formulas
  that must hold for certain processes to apply."
  :long
  "<p>
  For instance, transforming a function into a new function
  according to some criteria may be subject to conditions
  that must hold (i.e. must be proved as theorems)
  for the transformation to successfully take place.
  </p>")

(std::defaggregate applicability-condition
  :short
  "Records to describe and manipulate applicability conditions."
  ((name "Name of the applicability condition." symbolp)
   (formula  "The statement of the applicability condition (a term).")
   (hints "Hints to prove the applicability condition (possibly @('nil')).")))

(std::deflist applicability-condition-listp (x)
  (applicability-condition-p x)
  :short "Lists of applicability conditions."
  :true-listp t
  :elementp-of-nil nil)

(defsection applicability-condition-fail
  :short
  "Stop with an error message,
  due to a failure related to applicability conditions."
  :long "@(def applicability-condition-fail)"
  (defmacro applicability-condition-fail (message &rest arguments)
    (declare (xargs :guard (and (true-listp arguments)
                                (<= (len arguments) 10))))
    `(er hard? 'applicability-condition ,message ,@arguments)))

(define prove-applicability-condition ((app-cond applicability-condition-p)
                                       (verbose booleanp)
                                       state)
  :returns (mv (yes/no booleanp)
               state)
  :prepwork ((program))
  :short
  "Try to prove the applicability condition."
  :long
  "<p>
  If successful, return @('t').
  If unsuccessful or if an error occurs during the proof attempt,
  stop with an error message.
  </p>
  <p>
  If the @('verbose') argument is @('t'),
  also print a progress message to indicate that
  the proof of the applicability condition is being attempted,
  and then that it has been proved.
  </p>
  <p>
  Parentheses are printed around the progress message
  to ease navigation in an Emacs buffer.
  </p>"
  (b* ((name (applicability-condition->name app-cond))
       (formula (applicability-condition->formula app-cond))
       (hints (applicability-condition->hints app-cond))
       ((run-when verbose)
        (cw "(Proving applicability condition ~x0:~%~x1~|" name formula))
       ((mv erp yes/no state) (prove$ formula :hints hints))
       ((when erp)
        (applicability-condition-fail
         "Error ~x0 when attempting to prove ~
         applicability condition ~x1:~%~x2~|."
         erp name formula)
        (mv nil state))
       ((unless yes/no)
        (applicability-condition-fail
         "The applicability condition ~x0 fails:~%~x1~|"
         name formula)
        (mv nil state))
       ((run-when verbose)
        (cw "Done.)~%~%")))
    (mv t state)))

(define prove-applicability-conditions
  ((app-conds applicability-condition-listp)
   (verbose booleanp)
   state)
  :returns (mv (yes/no booleanp)
               state)
  :prepwork ((program))
  :short "Try to prove a list of applicability conditions, one after the other."
  :long
  "<p>
  If successful, return @('t').
  If unsuccessful or if an error occurs during a proof attempt,
  stop with an error message.
  </p>
  <p>
  If the @('verbose') argument is @('t'),
  also print progress messages for the applicability conditions.
  </p>"
  (cond ((endp app-conds) (mv t state))
        (t (b* ((app-cond (car app-conds))
                ((mv & state)
                 (prove-applicability-condition app-cond verbose state)))
             (prove-applicability-conditions (cdr app-conds) verbose state)))))

(define applicability-condition-event
  ((app-cond applicability-condition-p)
   (local booleanp "Make the theorem local or not.")
   (enabled booleanp "Leave the theorem enabled or not.")
   (rule-classes true-listp "Rule classes for the theorem.")
   (names-to-avoid symbol-listp "Avoid these as theorem name.")
   (w plist-worldp))
  :guard (or rule-classes enabled)
  :returns (mv (thm-name symbolp)
               (thm-event-form pseudo-event-formp))
  :prepwork ((program))
  :short "Generate theorem event form for applicability condition."
  :long
  "<p>
  The name of the theorem is made fresh in the world,
  and not among the names to avoid,
  by adding @('$') signs to the applicabiilty condition's name, if needed.
  Besides the theorem event form,
  return the name of the theorem
  (which may be the same as the name of the applicability condition).
  </p>
  <p>
  The generated theorem must be enabled if it has no rule classes,
  as required by the guard of this function.
  </p>"
  (b* ((defthm/defthmd (if enabled 'defthm 'defthmd))
       (name (applicability-condition->name app-cond))
       (formula (applicability-condition->formula app-cond))
       (hints (applicability-condition->hints app-cond))
       (thm-name (fresh-name-in-world-with-$s name names-to-avoid w))
       (thm-event-form `(,defthm/defthmd ,thm-name
                          ,formula
                          :hints ,hints
                          :rule-classes ,rule-classes))
       (thm-event-form (if local
                           `(local ,thm-event-form)
                         thm-event-form)))
    (mv thm-name thm-event-form)))

(define applicability-condition-events
  ((app-conds applicability-condition-listp)
   (locals boolean-listp "Make theorems local or not.")
   (enableds boolean-listp "Leave the theorems enabled or not.")
   (rule-classess "Rule classes for the theorems.")
   (names-to-avoid "Avoid these as theorem names.")
   (w plist-worldp))
  :guard (and (eql (len locals) (len app-conds))
              (eql (len enableds) (len app-conds))
              (eql (len rule-classess) (len app-conds)))
  :returns (mv (names-to-thm-names
                (and (symbol-symbol-alistp names-to-thm-names)
                     (eql (len names-to-thm-names) (len app-conds))))
               (thm-event-forms
                (and (true-list-listp thm-event-forms)
                     (eql (len thm-event-forms) (len app-conds)))))
  :prepwork ((program))
  :short "Generate theorem event forms for applicability conditions."
  :long
  "<p>
  Repeatedly call @(tsee applicability-condition-event)
  on each applicability condition
  and corresponding @('local'), @('enabled'), and @('rule-classes') elements
  from the argument lists.
  Besides the list of theorem event forms,
  return an alist from the names of the applicability conditions
  to the corresponding theorem names
  (some of which may be the same as the names of the applicability conditions).
  </p>
  <p>
  As new theorem event forms are generated,
  their names are added to the names to avoid,
  because the theorem events are not in the ACL2 world yet.
  </p>"
  (cond ((endp app-conds) (mv nil nil))
        (t (b* (((mv thm-name thm-event-form)
                 (applicability-condition-event (car app-conds)
                                                (car locals)
                                                (car enableds)
                                                (car rule-classess)
                                                names-to-avoid
                                                w))
                (new-names-to-avoid (cons thm-name names-to-avoid))
                ((mv names-to-thm-names thm-event-forms)
                 (applicability-condition-events (cdr app-conds)
                                                 (cdr locals)
                                                 (cdr enableds)
                                                 (cdr rule-classess)
                                                 new-names-to-avoid
                                                 w)))
             (mv (acons (applicability-condition->name (car app-conds))
                        thm-name
                        names-to-thm-names)
                 (cons thm-event-form thm-event-forms))))))
