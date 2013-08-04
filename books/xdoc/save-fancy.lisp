; XDOC Documentation System for ACL2
; Copyright (C) 2009-2013 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.
;
; Original author: Jared Davis <jared@centtech.com>

; save-fancy.lisp
;
; Writes out the XDOC database into JSON format for the new, fancy viewer.

(in-package "XDOC")
(include-book "save-classic")
(include-book "centaur/bridge/to-json" :dir :system)
(set-state-ok t)
(program)

(defun-inline json-encode-string (x acc)
  (declare (type string x))
  (cons #\" (bridge::json-encode-str x (cons #\" acc))))


(defun json-encode-filename (x acc)
  (declare (type symbol x))
  (json-encode-string
   (str::rchars-to-string (file-name-mangle x nil))
   acc))

(defun json-encode-filenames-aux (x acc)
  (declare (xargs :guard (symbol-listp x)))
  (b* (((when (atom x))
        acc)
       (acc (json-encode-filename (car x) acc))
       ((when (atom (cdr x)))
        acc)
       (acc (cons #\, acc)))
    (json-encode-filenames-aux (cdr x) acc)))

(defun json-encode-filenames (x acc)
  (declare (xargs :guard (symbol-listp x)))
  (b* ((acc (cons #\[ acc))
       (acc (json-encode-filenames-aux x acc)))
    (cons #\] acc)))

#||
(str::rchars-to-string (json-encode-filename 'xdoc::foo nil))
(str::rchars-to-string (json-encode-filenames '(xdoc::a acl2::b str::c) nil))
||#


(defun json-encode-topicname (x base-pkg acc)
  (declare (type symbol x)
           (type symbol base-pkg))
  (json-encode-string
   (str::rchars-to-string (sym-mangle-cap x base-pkg nil))
   acc))

(defun json-encode-topicnames-aux (x base-pkg acc)
  (declare (xargs :guard (symbol-listp x)))
  (b* (((when (atom x))
        acc)
       (acc (json-encode-topicname (car x) base-pkg acc))
       ((when (atom (cdr x)))
        acc)
       (acc (cons #\, acc)))
    (json-encode-topicnames-aux (cdr x) base-pkg acc)))

(defun json-encode-topicnames (x base-pkg acc)
  (declare (xargs :guard (symbol-listp x)))
  (b* ((acc (cons #\[ acc))
       (acc (json-encode-topicnames-aux x base-pkg acc)))
    (cons #\] acc)))


#||
(str::rchars-to-string (json-encode-topicname 'xdoc::foo 'acl2::foo nil))
(str::rchars-to-string (json-encode-topicname 'xdoc::foo 'xdoc::bar nil))
(str::rchars-to-string (json-encode-topicnames '(acl2::sock-monster xdoc::shoe-monster)
                                               'xdoc::bar nil))
||#


; The basic idea here is to split the database into two files:
;
;  - The INDEX will bind KEY -> {name,parents,short,...}
;     (and will also contain the long string for the "top" topic)
;
;  - The DATA will bind KEY -> long
;
; Where the KEYs are just the "file names" in the old scheme.  That is, they
; are nice, safe names that can be used in URLs or wherever.
;
; Why not just save it as one big table?  The hope is that this kind of split
; will let us (in a web interface) load in the index and give the user a
; working display, even before the data has been loaded.
;
; As of July 2013, the serialized version of the xdoc table (before
; preprocessing, mind you) is 7.1 MB.  The JSON-encoded, post-preprocessing
; (i.e., proper XML) version is over 22 MB.  This doesn't count the additional
; documentation internal to Centaur or other companies.  Even with fast
; internet connections, that can be a noticable delay, and the size will only
; grow.

(defun json-encode-index-entry (topic topics-fal state acc)
  (b* ((name     (cdr (assoc :name topic)))
       (base-pkg (cdr (assoc :base-pkg topic)))
       (short    (or (cdr (assoc :short topic)) ""))
       (long     (or (cdr (assoc :long topic)) ""))
       (parents  (cdr (assoc :parents topic)))
       ((unless (symbolp name))
        (mv (er hard? 'preprocess-topic "Name is not a string: ~x0.~%" topic)
            state))
       ((unless (symbolp base-pkg))
        (mv (er hard? 'preprocess-topic "Base-pkg is not a symbol: ~x0.~%" topic)
            state))
       ((unless (symbol-listp parents))
        (mv (er hard? 'preprocess-topic "Parents are not a symbol-listp: ~x0.~%" topic)
            state))
       ((unless (stringp short))
        (mv (er hard? 'preprocess-topic "Short is not a string: ~x0.~%" topic)
            state))
       ((unless (stringp long))
        (mv (er hard? 'preprocess-topic "Long is not a string: ~x0.~%" topic)
            state))

       ((mv short-rchars state) (preprocess-main short nil topics-fal base-pkg state nil))
       (short-str (str::rchars-to-string short-rchars))
       ((mv err &) (parse-xml short-str))
       (state
        (if err
            (pprogn
               (fms "~|~%WARNING: problem with :short in topic ~x0:~%"
                    (list (cons #\0 name))
                    *standard-co* state nil)
               (princ$ err *standard-co* state)
               (fms "~%~%" nil *standard-co* state nil))
          state))

       (acc (json-encode-filename name acc))

; I originally used a JSON object like {"name":"Append","rawname":"..."}  But
; then some back-of-the-napkin calculations said that these nice names were
; taking up about 400 KB of space in the index, so I figured I'd get rid of
; them and just use an array.

; IF YOU ADD/CHANGE THE ORDER THEN YOU MUST UPDATE XDOC.JS:

       ; name (xml encoded nice topic name)
       (acc (str::revappend-chars ":[" acc))
       (acc (json-encode-topicname name base-pkg acc))

       ; raw name (non-encoded symbol name, no package)
       (acc (cons #\, acc))
       (acc (json-encode-string (symbol-name name) acc))

       ; parent keys (array of keys for parents)
       (acc (cons #\, acc))
       (acc (json-encode-filenames parents acc))

       ; short: xml encoded short topic description
       (acc (cons #\, acc))
       (acc (json-encode-string short-str acc))

       (acc (cons #\] acc)))
    (mv acc state)))

#||
(b* ((topics (get-xdoc-table (w state)))
     (topics-fal (topics-fal topics))
     ((mv acc state)
      (json-encode-index-entry (car topics) topics-fal state nil))
     (state (princ$ (str::rchars-to-string acc) *standard-co* state)))
  state)
||#

(defun json-encode-index-aux (topics topics-fal state acc)
  (b* (((when (atom topics))
        (mv acc state))
       ((mv acc state) (json-encode-index-entry (car topics) topics-fal
                                                state acc))
       ((when (atom (cdr topics)))
        (mv acc state))
       (acc (list* #\Space #\Newline #\, acc)))
    (json-encode-index-aux (cdr topics) topics-fal state acc)))

(defun json-encode-index (topics topics-fal state acc)
  (b* ((acc (cons #\{ acc))
       ((mv acc state) (json-encode-index-aux topics topics-fal state acc))
       (acc (cons #\} acc)))
    (mv acc state)))

#||
(b* ((topics     (take 5 (get-xdoc-table (w state))))
     (topics-fal (topics-fal topics))
     ((mv acc state)
      (json-encode-index topics topics-fal state nil))
     (state (princ$ (str::rchars-to-string acc) *standard-co* state)))
  state)
||#


(defun json-encode-data-entry (topic topics-fal state acc)
  (b* ((name     (cdr (assoc :name topic)))
       (base-pkg (cdr (assoc :base-pkg topic)))
       (short    (or (cdr (assoc :short topic)) ""))
       (long     (or (cdr (assoc :long topic)) ""))
       (parents  (cdr (assoc :parents topic)))
       ((unless (symbolp name))
        (mv (er hard? 'preprocess-topic "Name is not a string: ~x0.~%" topic)
            state))
       ((unless (symbolp base-pkg))
        (mv (er hard? 'preprocess-topic "Base-pkg is not a symbol: ~x0.~%" topic)
            state))
       ((unless (symbol-listp parents))
        (mv (er hard? 'preprocess-topic "Parents are not a symbol-listp: ~x0.~%" topic)
            state))
       ((unless (stringp short))
        (mv (er hard? 'preprocess-topic "Short is not a string: ~x0.~%" topic)
            state))
       ((unless (stringp long))
        (mv (er hard? 'preprocess-topic "Long is not a string: ~x0.~%" topic)
            state))

       ((mv long-rchars state) (preprocess-main long nil topics-fal base-pkg state nil))
       (long-str (str::rchars-to-string long-rchars))
       ((mv err &) (parse-xml long-str))
       (state
        (if err
            (pprogn
               (fms "~|~%WARNING: problem with :long in topic ~x0:~%"
                    (list (cons #\0 name))
                    *standard-co* state nil)
               (princ$ err *standard-co* state)
               (fms "~%~%" nil *standard-co* state nil))
          state))

       (acc (json-encode-filename name acc))
       (acc (str::revappend-chars ":[" acc))

; IF YOU ADD/CHANGE THE ORDER THEN YOU MUST UPDATE XDOC.JS:

       ; parent names (xml encoded nice parent names)
       ; BOZO move to xdata, probably
       (acc (json-encode-topicnames parents base-pkg acc))
       (acc (cons #\, acc))

       (acc (json-encode-string long-str acc))
       (acc (cons #\] acc)))
    (mv acc state)))

#||
(b* ((topics (get-xdoc-table (w state)))
     (topics-fal (topics-fal topics))
     ((mv acc state)
      (json-encode-data-entry (car topics) topics-fal state nil))
     (state (princ$ (str::rchars-to-string acc) *standard-co* state)))
  state)
||#

(defun json-encode-data-aux (topics topics-fal state acc)
  (b* (((when (atom topics))
        (mv acc state))
       ((mv acc state) (json-encode-data-entry (car topics) topics-fal state acc))
       ((when (atom (cdr topics)))
        (mv acc state))
       (acc (list* #\Space #\Newline #\Newline #\, acc)))
    (json-encode-data-aux (cdr topics) topics-fal state acc)))

(defun json-encode-data (topics topics-fal state acc)
  (b* ((acc (cons #\{ acc))
       ((mv acc state) (json-encode-data-aux topics topics-fal state acc))
       (acc (cons #\} acc)))
    (mv acc state)))

#||
(b* ((topics (take 5 (get-xdoc-table (w state))))
     (topics-fal (topics-fal topics))
     (acc nil)
     ((mv acc state)
      (json-encode-data topics topics-fal state acc))
     (state (princ$ (str::rchars-to-string acc) *standard-co* state)))
  state)
||#

(defun save-json-files (dir state)
  (b* ((topics (get-xdoc-table (w state)))
       (topics (normalize-parents-list (clean-topics topics)))
       (- (cw "; Writing JSON for ~x0 topics.~%" (len topics)))
       (topics-fal (time$ (topics-fal topics)))

       (index nil)
       (index (str::revappend-chars "var xindex = " index));
       ((mv index state)
        (time$ (json-encode-index topics topics-fal state index)))
       (index (cons #\; index))
       (index (str::rchars-to-string index))
       (idxfile (oslib::catpath dir "xindex.js"))
       ((mv channel state) (open-output-channel idxfile :character state))
       (state (princ$ index channel state))
       (state (close-output-channel channel state))

       (data nil)
       (data (str::revappend-chars "var xdata = " data))
       ((mv data state)
        (time$ (json-encode-data topics topics-fal state data)))
       (data (cons #\; data))
       (data (str::rchars-to-string data))
       (datafile (oslib::catpath dir "xdata.js"))
       ((mv channel state) (open-output-channel datafile :character state))
       (state (princ$ data channel state))
       (state (close-output-channel channel state))

       (orphans (find-orphaned-topics topics topics-fal nil)))

    (or (not orphans)
        (cw "~|~%WARNING: found topics with non-existent parents:~%~x0~%These ~
             topics may only show up in the index pages.~%~%" orphans))
    state))


(defun prepare-fancy-dir (dir state)
  (b* (((unless (stringp dir))
        (prog2$ (er hard? 'prepare-fancy-dir
                    "Dir must be a string, but is: ~x0.~%" dir)
                state))
       (- (cw "; Preparing directory ~s0.~%" dir))

       (dir/lib        (oslib::catpath dir "lib"))
       (dir/images     (oslib::catpath dir "images"))
       (state          (mkdir dir state))
       (state          (mkdir dir/lib state))
       (state          (mkdir dir/images state))
       (xdoc/classic   (oslib::catpath *xdoc-dir* "classic"))
       (xdoc/fancy     (oslib::catpath *xdoc-dir* "fancy"))
       (xdoc/fancy/lib (oslib::catpath xdoc/fancy "lib"))

       (- (cw "Copying fancy viewer main files...~%"))
       (state          (stupid-copy-files xdoc/fancy
                                          (list "collapse_subtopics.png"
                                                "expand_subtopics.png"
                                                "favicon.png"
                                                "Icon_External_Link.png"
                                                "index.html"
                                                "kfm_home.png"
                                                "leaf.png"
                                                "LICENSE"
                                                "minus.png"
                                                "plus.png"
                                                "render.js"
                                                "style.css"
                                                "view_flat.png"
                                                "view_tree.png"
                                                "config.js"
                                                "xdoc.js"
                                                "xdataget.pl"
                                                "xdata2sql.pl"
                                                )
                                          dir state))

       (- (cw "Copying fancy viewer library files...~%"))
       (state          (stupid-copy-files xdoc/fancy/lib
                                          (list "hogan-2.0.0.js"
                                                "jquery-2.0.3.js"
                                                "jquery-2.0.3.min.js"
                                                "jquery.base64.js"
                                                "jquery.powertip.css"
                                                "jquery.powertip.js"
                                                "jquery.powertip.min.js"
                                                "lazyload.js"
                                                "typeahead.js"
                                                "typeahead.min.js")
                                          dir/lib state))

       (- (cw "Copying ACL2 tour graphics...~%"))
       (state          (stupid-copy-files xdoc/classic
                                          *acl2-graphics*
                                          dir/images state)))
    state))


(defun save-fancy (dir state)
  (b* ((state (prepare-fancy-dir dir state))
       (state (save-json-files dir state)))
    state))
