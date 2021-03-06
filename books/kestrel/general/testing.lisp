; Testing Facilities
;
; Copyright (C) 2015-2016 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Authors:
;   Alessandro Coglio (coglio@kestrel.edu)
;   Eric Smith (eric.smith@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains macros for building tests,
; related to MUST-SUCCEED and MUST-FAIL.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "make-event/eval-check" :dir :system)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection must-succeed*

  :parents (kestrel-general-utilities errors)

  :short "A variant of @(tsee must-succeed) that takes multiple forms."

  :long
  "@({
  (must-succeed* form1
                 ...
                 formN
                 :with-output-off ...
                 :check-expansion ...)
  })
  <p>
  The @('N') forms must be
  <see topic='@(url embedded-event-form)'>embedded event forms</see>,
  because they are put into a @(tsee progn)
  so that earlier forms are evaluated
  before considering later forms in the sequence.
  This is a difference with @(tsee must-succeed),
  whose form is required to return
  an <see topic='@(url error-triple)'>error triple</see>
  without necessarily being an embedded event form;
  since @(tsee must-succeed) takes only one form,
  there is no issue of earlier forms being evaluated
  before considering later forms
  as in @(tsee must-succeed*).
  </p>
  <p>
  The forms may be followed by
  @(':with-output-off') and/or @(':check-expansion'),
  as in @(tsee must-succeed).
  </p>
  @(def must-succeed*)"

  (defmacro must-succeed* (&rest args)
    (mv-let (erp forms options)
      (partition-rest-and-keyword-args args
                                       '(:with-output-off :check-expansion))
      (if erp
          '(er hard?
               'must-succeed*
               "The arguments of MUST-SUCCEED* must be zero or more forms ~
               followed by the options :WITH-OUTPUT-OFF and :CHECK-EXPANSION.")
        (let ((with-output-off-pair (assoc :with-output-off options))
              (check-expansion-pair (assoc :check-expansion options)))
          `(must-succeed (progn ,@forms)
                         ,@(if with-output-off-pair
                               `(:with-output-off ,(cdr with-output-off-pair))
                             nil)
                         ,@(if check-expansion-pair
                               `(:check-expansion ,(cdr check-expansion-pair))
                             nil)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection must-be-redundant

  :parents (kestrel-general-utilities errors)

  :short
  "A top-level @(tsee assert$)-like command
  to ensure that given forms are redundant."

  :long
  "<p>
  The forms are put into an @(tsee encapsulate),
  along with a @(tsee set-enforce-redundancy) command that precedes them.
  </p>
  @(def must-be-redundant)"

  (defmacro must-be-redundant (&rest forms)
    `(encapsulate
       ()
       (set-enforce-redundancy t)
       ,@forms)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection must-fail-local

  :parents (kestrel-general-utilities errors)

  :short "A @(see local) variant of @(tsee must-fail)."

  :long
  "<p>
  This is useful to overcome the problem discussed in the caveat
  in the documentation of @(tsee must-fail).
  </p>
  @(def must-fail-local)"

  (defmacro must-fail-local (&rest args)
    `(local (must-fail ,@args))))
