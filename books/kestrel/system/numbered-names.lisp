; Numbered Names
;
; Copyright (C) 2016 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file provides utilities for numbered names,
; i.e. names accompanied by numeric indices at their end,
; e.g. NAME{1}, MAME{2}, ...,
; or NAME$1, NAME$2, ...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "std/strings/decimal" :dir :system)
(include-book "std/util/defval" :dir :system)
(include-book "system/kestrel" :dir :system)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc numbered-names
  :parents (kestrel-system-utilities system-utilities)
  :short "Utilities for numbered names."
  :long
  "<p>
  A <i>numbered name</i> is a symbol consisting of four parts, in this order:
  </p>
  <ol>
    <li>
    A non-empty <i>base</i> symbol.
    </li>
    <li>
    A non-empty sequence of non-numeric characters
    that marks the start of the numeric index,
    separating it from the base name.
    This character sequence is global but customizable.
    </li>
    <li>
    One of the following:
    <ul>
      <li>
      A non-empty sequence of numeric decimal digits not starting with 0,
      that forms the <i>numeric index</i>,
      which is a positive integer.
      </li>
      <li>
      A non-empty sequence of non-numeric characters
      that forms a <i>wildcard</i> for the numeric index.
      This character sequence is global but customizable.
      </li>
    </ul>
    </li>
    <li>
    A possibly empty sequence of non-numeric characters
    that marks the end of the numeric index
    and that, together with the character sequence in part 2 above,
    surrounds the numeric index or the wildcard.
    This character sequence is global but customizable.
    </li>
  </ol>
  <p>
  Examples of numbered names are:
  </p>
  <ul>
    <li>
    @('MUL2{14}'), where
    @('MUL2') is the base name,
    @('{') marks the start of the numeric index,
    @('14') is the numeric index, and
    @('}') marks the end of the numeric index.
    </li>
    <li>
    @('SORT{*}'), where
    @('SORT') is the base name,
    @('{') marks the start of the numeric index (wildcard),
    @('*') is the wildcard, and
    @('}') marks the end of the numeric index (wildcard).
    </li>
    <li>
    @('FIND$3'), where
    @('FIND') is the base name,
    @('$') marks the start of the numeric index,
    @('3') is the numeric index,
    and nothing marks the end of the numeric index.
    </li>
  </ul>
  <p>
  Numbered names are useful, for instance,
  to denote subsequent versions of functions
  produced by sequences of transformations,
  e.g. @('foo{1}'), @('foo{2}'), ...
  </p>")

(define non-numeric-character-listp (x)
  :returns (yes/no booleanp)
  :parents (numbered-name-index-start-p
            numbered-name-index-end-p
            numbered-name-index-wildcard-p)
  :short
  "True iff @('x') is a @('nil')-terminated list of non-numeric characters."
  (cond ((atom x) (eq x nil))
        (t (and (characterp (car x))
                (not (digit-char-p (car x)))
                (non-numeric-character-listp (cdr x))))))

(defxdoc numbered-name-index-start
  :parents (numbered-names)
  :short "Starting marker of the numeric index of numbered names."
  :long
  "<p>
  This is stored in a singleton @(tsee table).
  </p>")

(define numbered-name-index-start-p (x)
  :returns (yes/no booleanp)
  :parents (numbered-name-index-start)
  :short
  "True iff @('x') is an admissible starting marker
  of the numeric index of numbered names."
  :long
  "<p>
  Check whether @('x') consists of one or more non-numeric characters.
  </p>"
  (and (stringp x)
       (non-numeric-character-listp (explode x))
       (not (equal x ""))))

(table numbered-name-index-start nil nil
  :guard (and (equal key 'start) ; one key => singleton table
              (numbered-name-index-start-p val)))

(defval *default-numbered-name-index-start*
  :parents (numbered-name-index-start)
  :short "Default starting marker of the numeric index of numbered names."
  "{")

(define get-numbered-name-index-start ((w plist-worldp))
  ;; :returns (start numbered-name-index-start-p)
  :verify-guards nil
  :parents (numbered-name-index-start)
  :short
  "Retrieve the current starting marker
  of the numeric index of numbered names."
  :long
  "<p>
  If the starting marker is not set yet, the default is returned.
  </p>"
  (let ((pair (assoc-eq 'start (table-alist 'numbered-name-index-start w))))
    (if pair (cdr pair) *default-numbered-name-index-start*)))

;; set to default the first time this form is evaluated,
;; then set to current (i.e. no change) when this form is evaluated again
;; (e.g. when this file is redundantly loaded):
(table numbered-name-index-start
  'start (get-numbered-name-index-start world))

(defsection set-numbered-name-index-start
  :parents (numbered-name-index-start)
  :short "Set the starting marker of the numeric index of numbered names."
  :long
  "<p>
  This macro generates an event to override
  the default, or the previously set value.
  </p>
  @(def set-numbered-name-index-start)"
  (defmacro set-numbered-name-index-start (start)
    `(table numbered-name-index-start 'start ,start)))

(defxdoc numbered-name-index-end
  :parents (numbered-names)
  :short "Ending marker of the numeric index of numbered names."
  :long
  "<p>
  This is stored in a singleton @(tsee table).
  </p>")

(define numbered-name-index-end-p (x)
  :returns (yes/no booleanp)
  :parents (numbered-name-index-end)
  :short
  "True iff @('x') is an admissible ending marker
  of the numeric index of numbered names."
  :long
  "<p>
  Check whether @('x') consists of zero or more non-numeric characters.
  </p>"
  (and (stringp x)
       (non-numeric-character-listp (explode x))))

(table numbered-name-index-end nil nil
  :guard (and (equal key 'end) ; one key => singleton table
              (numbered-name-index-end-p val)))

(defval *default-numbered-name-index-end*
  :parents (numbered-name-index-end)
  :short "Default ending marker of the numeric index of numbered names."
  "}")

(define get-numbered-name-index-end ((w plist-worldp))
  ;; :returns (end numbered-name-index-end-p)
  :verify-guards nil
  :parents (numbered-name-index-end)
  :short
  "Retrieve the current ending marker
  of the numeric index of numbered names."
  :long
  "<p>
  If the ending marker is not set yet, the default is returned.
  </p>"
  (let ((pair (assoc-eq 'end (table-alist 'numbered-name-index-end w))))
    (if pair (cdr pair) *default-numbered-name-index-end*)))

;; set to default the first time this form is evaluated,
;; then set to current (i.e. no change) when this form is evaluated again
;; (e.g. when this file is redundantly loaded):
(table numbered-name-index-end
  'end (get-numbered-name-index-end world))

(defsection set-numbered-name-index-end
  :parents (numbered-name-index-end)
  :short "Set the ending marker of the numeric index of numbered names."
  :long
  "<p>
  This macro generates an event to override
  the default, or the previously set value.
  </p>
  @(def set-numbered-name-index-end)"
  (defmacro set-numbered-name-index-end (end)
    `(table numbered-name-index-end 'end ,end)))

(defxdoc numbered-name-index-wildcard
  :parents (numbered-names)
  :short "Wildcard for the numeric index of numbered names."
  :long
  "<p>
  This is stored in a singleton @(tsee table).
  </p>")

(define numbered-name-index-wildcard-p (x)
  :returns (yes/no booleanp)
  :parents (numbered-name-index-wildcard)
  :short
  "True iff @('x') is an admissible wildcard
  for the numeric index of numbered names."
  :long
  "<p>
  Check whether @('x') consists of one or more non-numeric characters.
  </p>"
  (and (stringp x)
       (non-numeric-character-listp (explode x))
       (not (equal x ""))))

(table numbered-name-index-wildcard nil nil
  :guard (and (equal key 'wildcard) ; one key => singleton table
              (numbered-name-index-wildcard-p val)))

(defval *default-numbered-name-index-wildcard*
  :parents (numbered-name-index-wildcard)
  :short "Default wildcard for the numeric index of numbered names."
  "*")

(define get-numbered-name-index-wildcard ((w plist-worldp))
  ;; :returns (wildcard numbered-name-index-wildcard-p)
  :verify-guards nil
  :parents (numbered-name-index-wildcard)
  :short
  "Retrieve the current wildcard
  for the numeric index of numbered names."
  :long
  "<p>
  If the wildcard is not set yet, the default is returned.
  </p>"
  (let ((pair
         (assoc-eq 'wildcard (table-alist 'numbered-name-index-wildcard w))))
    (if pair (cdr pair) *default-numbered-name-index-wildcard*)))

;; set to default the first time this form is evaluated,
;; then set to current (i.e. no change) when this form is evaluated again
;; (e.g. when this file is redundantly loaded):
(table numbered-name-index-wildcard
  'wildcard (get-numbered-name-index-wildcard world))

(defsection set-numbered-name-index-wildcard
  :parents (numbered-name-index-wildcard)
  :short "Set the wildcard for the numeric index of numbered names."
  :long
  "<p>
  This macro generates an event to override
  the default, or the previously set value.
  </p>
  @(def set-numbered-name-index-wildcard)"
  (defmacro set-numbered-name-index-wildcard (wildcard)
    `(table numbered-name-index-wildcard 'wildcard ,wildcard)))

(define check-numbered-name ((name symbolp) (w plist-worldp))
  :returns (mv (yes/no booleanp "@('t') iff @('name') is a numbered name.")
               (base symbolp "Base symbol of @('name'),
                             or @('nil') if @('yes/no') is @('nil').")
               (index maybe-natp "Numeric index of @('name'),
                                 or 0 if it is the wildcard,
                                 or @('nil') if @('yes/no') is @('nil')."))
  :verify-guards nil
  :parents (numbered-names)
  :short "Check whether a symbol is a numbered name."
  :long
  "<p>
  If successful, return its base symbol and index (or wildcard).
  </p>"
  (b* ((name-chars (explode (symbol-name name)))
       (index-start-chars (explode (get-numbered-name-index-start w)))
       (index-end-chars (explode (get-numbered-name-index-end w)))
       (wildcard-chars (explode (get-numbered-name-index-wildcard w)))
       (len-of-name-without-end-marker (- (len name-chars)
                                          (len index-end-chars)))
       ((unless (and (> len-of-name-without-end-marker 0)
                     (equal (subseq name-chars
                                    len-of-name-without-end-marker
                                    (len name-chars))
                            index-end-chars)))
        (mv nil nil nil))
       (name-chars-without-end-marker
        (take len-of-name-without-end-marker name-chars))
       (digits-of-index
        (reverse (str::take-leading-digits (reverse
                                            name-chars-without-end-marker)))))
    (if digits-of-index
        (b* (((when (eql (car digits-of-index) #\0))
              (mv nil nil nil))
             (index (str::digit-list-value digits-of-index))
             (name-chars-without-index-and-end-marker
              (take (- (len name-chars-without-end-marker)
                       (len digits-of-index))
                    name-chars-without-end-marker))
             (len-of-base-of-name
              (- (len name-chars-without-index-and-end-marker)
                 (len index-start-chars)))
             ((unless (and
                       (> len-of-base-of-name 0)
                       (equal (subseq
                               name-chars-without-index-and-end-marker
                               len-of-base-of-name
                               (len name-chars-without-index-and-end-marker))
                              index-start-chars)))
              (mv nil nil nil))
             (base-chars (take len-of-base-of-name
                               name-chars-without-index-and-end-marker))
             ((unless base-chars) (mv nil nil nil)))
          (mv t (intern-in-package-of-symbol (implode base-chars) name) index))
      (b* ((len-of-name-without-wildcard-and-end-marker
            (- (len name-chars-without-end-marker)
               (len wildcard-chars)))
           ((unless (and (> len-of-name-without-wildcard-and-end-marker 0)
                         (equal
                          (subseq name-chars-without-end-marker
                                  len-of-name-without-wildcard-and-end-marker
                                  (len name-chars-without-end-marker))
                          wildcard-chars)))
            (mv nil nil nil))
           (name-chars-without-wildcard-and-end-marker
            (take len-of-name-without-wildcard-and-end-marker
                  name-chars-without-end-marker))
           (len-of-base-of-name
            (- (len name-chars-without-wildcard-and-end-marker)
               (len index-start-chars)))
           ((unless (and (> len-of-base-of-name 0)
                         (equal
                          (subseq
                           name-chars-without-wildcard-and-end-marker
                           len-of-base-of-name
                           (len name-chars-without-wildcard-and-end-marker))
                          index-start-chars)))
            (mv nil nil nil))
           (base-chars (take len-of-base-of-name
                             name-chars-without-wildcard-and-end-marker))
           ((unless base-chars) (mv nil nil nil)))
        (mv t (intern-in-package-of-symbol (implode base-chars) name) 0)))))

(define make-numbered-name
  ((base symbolp)
   (index-or-wildcard natp "Positive index, or 0 for the wildcard.")
   (w plist-worldp))
  :returns (name symbolp)
  :verify-guards nil
  :parents (numbered-names)
  :short "Construct a numbered name from a base and an index (or wildcard)."
  (b* ((base-chars (explode (symbol-name base)))
       (index-start-chars (explode (get-numbered-name-index-start w)))
       (index-end-chars (explode (get-numbered-name-index-end w)))
       (index-or-wildcard-chars
        (if (zp index-or-wildcard)
            (explode (get-numbered-name-index-wildcard w))
          (str::natchars index-or-wildcard)))
       (name-chars (append base-chars
                           index-start-chars
                           index-or-wildcard-chars
                           index-end-chars)))
    (intern-in-package-of-symbol (implode name-chars) base)))

(define set-numbered-name-index ((name symbolp) (index posp) (w plist-worldp))
  :returns (new-name symbolp)
  :verify-guards nil
  :parents (numbered-names)
  :short "Sets the index of a numbered name."
  :long
  "<p>
  If @('name') is a numbered name with base @('base'),
  return the numbered name with base @('base') and index @('index')
  (i.e. replace the index).
  Otherwise, return the numbered name with base @('name') and index @('index')
  (i.e. add the index).
  </p>"
  (mv-let (is-numbered-name base index1)
    (check-numbered-name name w)
    (declare (ignore index1))
    (if is-numbered-name
        (make-numbered-name base index w)
      (make-numbered-name name index w))))

(defxdoc numbered-names-in-use
  :parents (numbered-names)
  :short "Numbered names in use."
  :long
  "<p>
  A @(tsee table) keeps track of the numbered names &ldquo;in use&rdquo;.
  The table must be updated explicitly
  every time a new numbered name is used
  (e.g. introduced into the ACL2 @(see world)).
  </p>
  <p>
  The table maps bases of numbered names
  to non-empty sets (encoded as lists) of positive integers.
  If @('base') is mapped to @('(index1 ... indexN)'),
  it means that the numbered names with base @('base')
  and indices @('index1'), ..., @('indexN') are in use.
  </p>")

(table numbered-names-in-use nil nil
  :guard (and (symbolp key)
              (pos-listp val)
              (no-duplicatesp val)))

(defsection add-numbered-name-in-use
  :parents (numbered-names-in-use)
  :short "Record that a numbered name is in use."
  :long
  "<p>
  This macro generates an event to add a numbered name
  to the table of numbered names in use.
  </p>
  @(def add-numbered-name-in-use)"

  (define add-numbered-name-in-use-aux
    ((base symbolp) (index posp) (w plist-worldp))
    ;; :returns (indices (and (pos-listp indices)
    ;;                        (no-duplicatesp indices)))
    :verify-guards nil
    :parents (add-numbered-name-in-use)
    :short "Auxiliary function for @(tsee add-numbered-name-in-use) macro."
    :long
    "<p>
    Return the result of adding @('index')
    to the set of indices that the table associates to @('base').
    </p>"
    (let* ((tab (table-alist 'numbered-names-in-use w))
           (current-indices (cdr (assoc-eq base tab))))
      (add-to-set-eql index current-indices)))

  (defmacro add-numbered-name-in-use (base index)
    `(table numbered-names-in-use
       ,base (add-numbered-name-in-use-aux ,base ,index world))))

(define max-numbered-name-index-in-use-aux
  ((indices pos-listp) (current-max-index natp))
  ;; :returns (final-max-index natp)
  :parents (max-numbered-name-index-in-use)
  :short "Auxiliary function for @(tsee max-numbered-name-index-in-use)."
  :long
  "<p>
     Return the maximum of @('(cons current-max-index indices)').
     </p>"
  (cond ((atom indices) current-max-index)
        (t (max-numbered-name-index-in-use-aux
            (cdr indices)
            (max (car indices) current-max-index)))))

(define max-numbered-name-index-in-use ((base symbolp) (w plist-worldp))
  ;; :returns (max-index natp)
  :verify-guards nil
  :parents (numbered-names-in-use)
  :short "Largest index of numbered name in use with given base."
  :long
  "<p>
  Return the largest positive integer @('i')
  such that the numbered name with base @('base') and index @('i') is in use
  (i.e. it is stored in the table).
  If no numbered name with base @('base') is in use,
  return 0.
  </p>"
  (let* ((tab (table-alist 'numbered-names-in-use w))
         (current-indices (cdr (assoc-eq base tab))))
    (max-numbered-name-index-in-use-aux current-indices 0)))

(define resolve-numbered-name-wildcard ((name symbolp) (w plist-worldp))
  ;; :returns (resolved-name symbolp)
  :verify-guards nil
  :parents (numbered-names)
  :short
  "Resolve the wildcard in a numbered name (if any)
  to the largest index in use for the name's base."
  :long
  "<p>
  If @('name') is a numbered name with base @('base') and the wildcard as index,
  return the numbered name with base @('base') and index @('i'),
  where @('i') is the result of @(tsee max-numbered-name-index-in-use).
  Otherwise, return @('name').
  </p>"
  (mv-let (is-numbered-name base index)
    (check-numbered-name name w)
    (if (and is-numbered-name
             (eql index 0))
        (make-numbered-name base (max-numbered-name-index-in-use base w) w)
      name)))

(define next-numbered-name-aux
  ((base symbolp) (current-index posp) (w plist-worldp))
  :returns (final-index posp)
  :prepwork ((program))
  :parents (next-numbered-name)
  :short "Auxiliary function for @(tsee next-numbered-name)."
  :long
  "<p>
  Returns the smallest positive integer @('final-index')
  that is greater than or equal to @('current-index')
  and such that the numbered name with base @('base') and index @('final-index')
  is not in the ACL2 @(see world).
  </p>"
  (let ((name (make-numbered-name base current-index w)))
    (if (logical-namep name w)
        (next-numbered-name-aux base (1+ current-index) w)
      current-index)))

(define next-numbered-name ((name symbolp) (w plist-worldp))
  :returns (next-index posp)
  :prepwork ((program))
  :parents (numbered-names)
  :short "Next numbered name with the same base."
  :long
  "<p>
  If @('name') is a numbered name with base @('base') and index @('i'),
  return the numbered name with base @('base') and index @('j'),
  where @('j') is the smallest integer larger than @('i')
  such that the numbered name with base @('base') and index @('j')
  is not in the ACL2 @(see world).
  If @('name') is a numbered name with base @('base') and the wildcard as index,
  the behavior is the same as if this function were called
  on the result of @(tsee resolve-numbered-name-wildcard) on @('name').
  If @('name') is not a numbered name, return 1
  (as if @('name') had numeric index 0).
  </p>
  <p>
  This function is independent from the
  <see topic='@(url global-numbered-name-index)'>global index
  for numbered names</see>.
  </p>"
  (mv-let (is-numbered-name base index)
    (check-numbered-name name w)
    (if is-numbered-name
        (let ((next-index (if (eql index 0)
                              (next-numbered-name-aux
                               base
                               (1+ (max-numbered-name-index-in-use base w))
                               w)
                            (next-numbered-name-aux base (1+ index) w))))
          (make-numbered-name base next-index w))
      (make-numbered-name name 1 w))))

(defxdoc global-numbered-name-index
  :parents (numbered-names)
  :short "Global index for numbered names."
  :long
  "<p>
  We maintain a global index for numbered names,
  which is initially 1 and can be incremented by 1 or reset to 1.
  This global index is stored in a @(tsee table).
  </p>
  <p>
  This global index can be used, for instance,
  to support the generation of successive sets of numbered names
  such that the names in each set have the same index
  and the index is incremented from one set to the next set.
  </p>
  <p>
  This global index is not used by @(tsee next-numbered-name),
  which increments the index in a more &ldquo;local&rdquo; way.
  </p>")

(table global-numbered-name-index nil nil
  :guard (and (eq key 'index) ; one key => singleton table
              (posp val)))

(define get-global-numbered-name-index ((w plist-worldp))
  ;; :returns (global-index posp)
  :verify-guards nil
  :parents (global-numbered-name-index)
  :short "Retrieve the global index for numbered names."
  :long
  "<p>
  If the global index is not set yet, 1 is returned.
  </p>"
  (let ((pair (assoc-eq 'index (table-alist 'global-numbered-name-index w))))
    (if pair (cdr pair) 1)))

;; set to 1 the first time this form is evaluated,
;; then set to current (i.e. no change) when this form is evaluated again
;; (e.g. when this file is redundantly loaded):
(table global-numbered-name-index
  'index (get-global-numbered-name-index world))

(defsection increment-global-numbered-name-index
  :parents (global-numbered-name-index)
  :short "Increment by 1 the global index for numbered names."
  :long
  "<p>
  This macro generates an event to increment the index by 1.
  </p>
  @(def increment-global-numbered-name-index)"
  (defmacro increment-global-numbered-name-index ()
    '(table global-numbered-name-index
       'index
       (1+ (get-global-numbered-name-index world)))))

(defsection reset-global-numbered-name-index
  :parents (global-numbered-name-index)
  :short "Reset to 1 the global index for numbered names."
  :long
  "<p>
  This macro generates an event to reset the index to 1.
  </p>
  @(def reset-global-numbered-name-index)"
  (defmacro reset-global-numbered-name-index ()
    '(table global-numbered-name-index 'index 1)))

(define set-numbered-name-index-to-global ((name symbolp) (w plist-worldp))
  :returns (new-name symbolp)
  :verify-guards nil
  :parents (numbered-names)
  :short
  "Sets the index of a numbered name to the global index for numbered names."
  :long
  "<p>
  Specialize @(tsee set-numbered-name-index)
  to use the global index for numbered names.
  </p>"
  (set-numbered-name-index name (get-global-numbered-name-index w) w))
