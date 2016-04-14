;; AUTHOR:
;; Shilpi Goel <shigoel@cs.utexas.edu>

(in-package "X86ISA")
(include-book "gather-paging-structures" :ttags :all)

(local (include-book "centaur/bitops/ihs-extensions" :dir :system))
(local (include-book "centaur/bitops/signed-byte-p" :dir :system))

(local (in-theory (e/d () (unsigned-byte-p signed-byte-p))))

;; ======================================================================

(defthm member-p-remove-duplicates-equal-iff-member-p
  ;; See MEMBER-P-OF-REMOVE-DUPLICATES-EQUAL in
  ;; gather-paging-structures.lisp.
  (iff (member-p index (remove-duplicates-equal a))
       (member-p index a))
  :hints (("Goal"
           :in-theory (e/d* (member-p-iff-member-equal)
                            (member-p)))))

(defthm member-p-and-gather-qword-addresses-corresponding-to-1-entry
  (implies (and (equal (page-present (rm-low-64 superior-structure-paddr x86)) 1)
                (equal (page-size (rm-low-64 superior-structure-paddr x86)) 0)
                (<=
                 (ash (loghead
                       40
                       (logtail 12 (rm-low-64 superior-structure-paddr x86)))
                      12)
                 e)
                (< e
                   (+
                    4096
                    (ash (loghead
                          40
                          (logtail 12 (rm-low-64 superior-structure-paddr x86)))
                         12)))
                (physical-address-p e)
                (equal (loghead 3 e) 0))
           (member-p e (gather-qword-addresses-corresponding-to-1-entry
                        superior-structure-paddr x86)))
  :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-1-entry
                                    member-p)
                                   ()))))

(defthm member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
  (implies (and (member-p e
                          (gather-qword-addresses-corresponding-to-1-entry
                           superior-structure-paddr x86))
                (member-p superior-structure-paddr superior-structure-paddrs))
           (member-p e
                     (gather-qword-addresses-corresponding-to-entries-aux
                      superior-structure-paddrs x86)))
  :hints (("Goal" :in-theory (e/d* (member-p
                                    gather-qword-addresses-corresponding-to-entries-aux)
                                   ()))))

(defthm gather-qword-addresses-corresponding-to-entries-aux-and-entries
  (implies (member-p e
                     (gather-qword-addresses-corresponding-to-entries-aux
                      superior-structure-paddrs x86))
           (member-p e
                     (gather-qword-addresses-corresponding-to-entries
                      superior-structure-paddrs x86)))
  :hints (("Goal" :in-theory (e/d* (member-p
                                    gather-qword-addresses-corresponding-to-entries)
                                   ()))))

(encapsulate
  ()
  (local
   (defthm member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux-1
     (implies (member-p e (gather-qword-addresses-corresponding-to-entries-aux (remove-duplicates-equal superior-structure-paddrs) x86))
              (member-p e (gather-qword-addresses-corresponding-to-entries-aux superior-structure-paddrs x86)))
     :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux member-p) ())))))

  (local
   (defthm member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux-2
     (implies (member-p e (gather-qword-addresses-corresponding-to-entries-aux superior-structure-paddrs x86))
              (member-p e (gather-qword-addresses-corresponding-to-entries-aux (remove-duplicates-equal superior-structure-paddrs) x86)))
     :hints (("Goal"
              :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux member-p)
                               (member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux)))
             ("Subgoal *1/2"
              ;; Ugh.
              :use ((:instance member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                               (e e)
                               (superior-structure-paddr (car superior-structure-paddrs))
                               (superior-structure-paddrs (cdr superior-structure-paddrs))))
              :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux member-p)
                               (member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux))))))

  (defthm member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux
    (iff (member-p e (gather-qword-addresses-corresponding-to-entries-aux (remove-duplicates-equal superior-structure-paddrs) x86))
         (member-p e (gather-qword-addresses-corresponding-to-entries-aux superior-structure-paddrs x86)))))

;; ======================================================================

(defthm pml4-table-entry-addr-is-at-the-first-level
  (implies (and (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
                (canonical-address-p lin-addr))
           (member-p (pml4-table-entry-addr lin-addr base-addr)
                     (gather-pml4-table-qword-addresses x86)))
  :hints (("Goal"
           :in-theory (e/d* (pml4-table-entry-addr
                             gather-pml4-table-qword-addresses
                             member-p)
                            ()))))

(defthm pml4-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
  (implies (and (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
                (canonical-address-p lin-addr))
           (member-p (pml4-table-entry-addr lin-addr base-addr)
                     (gather-all-paging-structure-qword-addresses x86)))
  :hints (("Goal"
           :in-theory (e/d* (gather-all-paging-structure-qword-addresses)
                            (gather-pml4-table-qword-addresses)))))

;; ======================================================================

(defthm page-dir-ptr-table-entry-addr-is-at-the-second-level
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0))
   (member-p (page-dir-ptr-table-entry-addr
              lin-addr
              (ash (loghead 40
                            (logtail 12
                                     (rm-low-64
                                      (pml4-table-entry-addr lin-addr base-addr)
                                      x86)))
                   12))
             (gather-qword-addresses-corresponding-to-entries-aux
              (gather-pml4-table-qword-addresses x86)
              x86)))
  :hints (("Goal"
           :use ((:instance pml4-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
                            (base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12)))
                 (:instance member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                            (e (page-dir-ptr-table-entry-addr
                                lin-addr
                                (ash (loghead 40 (logtail
                                                  12
                                                  (rm-low-64
                                                   (pml4-table-entry-addr lin-addr base-addr)
                                                   x86)))
                                     12)))
                            (superior-structure-paddr
                             (pml4-table-entry-addr lin-addr base-addr))
                            (superior-structure-paddrs (gather-pml4-table-qword-addresses x86))))
           :in-theory (e/d* (page-dir-ptr-table-entry-addr
                             gather-all-paging-structure-qword-addresses
                             gather-qword-addresses-corresponding-to-entries
                             gather-qword-addresses-corresponding-to-entries-aux
                             member-p)
                            (pml4-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
                             member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux)))))

(defthm page-dir-ptr-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0))
   (member-p (page-dir-ptr-table-entry-addr
              lin-addr
              (ash (loghead 40
                            (logtail 12
                                     (rm-low-64
                                      (pml4-table-entry-addr lin-addr base-addr)
                                      x86)))
                   12))
             (gather-all-paging-structure-qword-addresses x86)))
  :hints (("Goal" :in-theory (e/d* (gather-all-paging-structure-qword-addresses) ()))))

;; ======================================================================

(defthm page-directory-entry-addr-is-at-the-third-level
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0)
        (equal
         (page-present
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         0))
   (member-p
    (page-directory-entry-addr
     lin-addr
     (ash
      (loghead
       40
       (logtail
        12
        (rm-low-64
         (page-dir-ptr-table-entry-addr
          lin-addr
          (ash (loghead 40
                        (logtail 12
                                 (rm-low-64
                                  (pml4-table-entry-addr lin-addr base-addr)
                                  x86)))
               12))
         x86)))
      12))
    (gather-qword-addresses-corresponding-to-entries-aux
     (gather-qword-addresses-corresponding-to-entries-aux
      (gather-pml4-table-qword-addresses x86)
      x86)
     x86)))
  :hints (("Goal"
           :use ((:instance page-dir-ptr-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
                            (base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12)))
                 (:instance member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                            (e (page-directory-entry-addr
                                lin-addr
                                (ash
                                 (loghead
                                  40
                                  (logtail
                                   12
                                   (rm-low-64
                                    (page-dir-ptr-table-entry-addr
                                     lin-addr
                                     (ash (loghead 40
                                                   (logtail 12
                                                            (rm-low-64
                                                             (pml4-table-entry-addr lin-addr base-addr)
                                                             x86)))
                                          12))
                                    x86)))
                                 12)))
                            (superior-structure-paddr
                             (page-dir-ptr-table-entry-addr
                              lin-addr
                              (ash (loghead 40
                                            (logtail 12
                                                     (rm-low-64
                                                      (pml4-table-entry-addr lin-addr base-addr)
                                                      x86)))
                                   12)))
                            (superior-structure-paddrs
                             (gather-qword-addresses-corresponding-to-entries-aux
                              (gather-pml4-table-qword-addresses x86)
                              x86))))
           :in-theory (e/d* (page-directory-entry-addr
                             gather-qword-addresses-corresponding-to-entries
                             gather-qword-addresses-corresponding-to-entries-aux
                             gather-all-paging-structure-qword-addresses
                             member-p)
                            (member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                             page-dir-ptr-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses)))))

(defthm page-directory-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0)
        (equal
         (page-present
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         0))
   (member-p
    (page-directory-entry-addr
     lin-addr
     (ash
      (loghead
       40
       (logtail
        12
        (rm-low-64
         (page-dir-ptr-table-entry-addr
          lin-addr
          (ash (loghead 40
                        (logtail 12
                                 (rm-low-64
                                  (pml4-table-entry-addr lin-addr base-addr)
                                  x86)))
               12))
         x86)))
      12))
    (gather-all-paging-structure-qword-addresses x86)))
  :hints (("Goal"
           :use ((:instance page-directory-entry-addr-is-at-the-third-level
                            (base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))))
           :in-theory (e/d* (gather-all-paging-structure-qword-addresses
                             gather-qword-addresses-corresponding-to-entries)
                            (page-directory-entry-addr-is-at-the-third-level)))))

;; ======================================================================

(defthm page-table-entry-addr-is-at-the-fourth-level
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0)
        (equal
         (page-present
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         0)
        (equal
         (page-present
          (rm-low-64
           (page-directory-entry-addr
            lin-addr
            (ash
             (loghead
              40
              (logtail
               12
               (rm-low-64
                (page-dir-ptr-table-entry-addr
                 lin-addr
                 (ash
                  (loghead
                   40
                   (logtail
                    12
                    (rm-low-64
                     (pml4-table-entry-addr
                      lin-addr
                      base-addr)
                     x86)))
                  12))
                x86)))
             12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-directory-entry-addr
            lin-addr
            (ash
             (loghead
              40
              (logtail
               12
               (rm-low-64
                (page-dir-ptr-table-entry-addr
                 lin-addr
                 (ash
                  (loghead
                   40
                   (logtail
                    12
                    (rm-low-64
                     (pml4-table-entry-addr
                      lin-addr
                      base-addr)
                     x86)))
                  12))
                x86)))
             12))
           x86))
         0))
   (member-p
    (page-table-entry-addr
     lin-addr
     (ash
      (loghead
       40
       (logtail
        12
        (rm-low-64
         (page-directory-entry-addr
          lin-addr
          (ash
           (loghead
            40
            (logtail
             12
             (rm-low-64
              (page-dir-ptr-table-entry-addr
               lin-addr
               (ash (loghead 40
                             (logtail 12
                                      (rm-low-64
                                       (pml4-table-entry-addr lin-addr base-addr)
                                       x86)))
                    12))
              x86)))
           12))
         x86)))
      12))
    (gather-qword-addresses-corresponding-to-entries-aux
     (gather-qword-addresses-corresponding-to-entries-aux
      (gather-qword-addresses-corresponding-to-entries-aux
       (gather-pml4-table-qword-addresses x86)
       x86)
      x86)
     x86)))
  :hints (("Goal"
           :use ((:instance page-directory-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
                            (base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12)))
                 (:instance member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                            (e (page-table-entry-addr
                                lin-addr
                                (ash
                                 (loghead
                                  40
                                  (logtail
                                   12
                                   (rm-low-64
                                    (page-directory-entry-addr
                                     lin-addr
                                     (ash
                                      (loghead
                                       40
                                       (logtail
                                        12
                                        (rm-low-64
                                         (page-dir-ptr-table-entry-addr
                                          lin-addr
                                          (ash (loghead 40
                                                        (logtail 12
                                                                 (rm-low-64
                                                                  (pml4-table-entry-addr lin-addr base-addr)
                                                                  x86)))
                                               12))
                                         x86)))
                                      12))
                                    x86)))
                                 12)))
                            (superior-structure-paddr
                             (page-directory-entry-addr
                              lin-addr
                              (ash
                               (loghead
                                40
                                (logtail
                                 12
                                 (rm-low-64
                                  (page-dir-ptr-table-entry-addr
                                   lin-addr
                                   (ash (loghead 40
                                                 (logtail 12
                                                          (rm-low-64
                                                           (pml4-table-entry-addr lin-addr base-addr)
                                                           x86)))
                                        12))
                                  x86)))
                               12)))
                            (superior-structure-paddrs
                             (gather-qword-addresses-corresponding-to-entries-aux
                              (gather-qword-addresses-corresponding-to-entries-aux
                               (gather-pml4-table-qword-addresses x86)
                               x86)
                              x86))))
           :in-theory (e/d* (page-table-entry-addr
                             gather-qword-addresses-corresponding-to-entries
                             gather-qword-addresses-corresponding-to-entries-aux
                             gather-all-paging-structure-qword-addresses
                             member-p)
                            (member-p-when-gather-qword-addresses-corresponding-to-1-entry-then-member-p-entries-aux
                             page-dir-ptr-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses)))))

(defthm gather-qword-addresses-corresponding-to-1-entry-subsetp-equal-entries-aux
  (implies (member-equal a b)
           (subsetp-equal (gather-qword-addresses-corresponding-to-1-entry a x86)
                          (gather-qword-addresses-corresponding-to-entries-aux b x86)))
  :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux) ()))))

(defthmd subsetp-equal-and-gather-qword-addresses-corresponding-to-entries-aux-1
  (implies (subsetp-equal (cons e a) b)
           (subsetp-equal
            (append (gather-qword-addresses-corresponding-to-1-entry e x86)
                    (gather-qword-addresses-corresponding-to-entries-aux a x86))
            (gather-qword-addresses-corresponding-to-entries-aux b x86)))
  :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux append subsetp-equal std::set-equiv) ()))))

(defthmd subsetp-equal-and-gather-qword-addresses-corresponding-to-entries-aux-2
  (implies (subsetp-equal b (cons e a))
           (subsetp-equal
            (gather-qword-addresses-corresponding-to-entries-aux b x86)
            (append (gather-qword-addresses-corresponding-to-1-entry e x86)
                    (gather-qword-addresses-corresponding-to-entries-aux a x86))))
  :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux append subsetp-equal std::set-equiv) ()))))

(defthm set-equiv-and-gather-qword-addresses-corresponding-to-entries-aux-helper
  (implies (std::set-equiv (cons e a) b)
           (std::set-equiv
            (gather-qword-addresses-corresponding-to-entries-aux b x86)
            (append (gather-qword-addresses-corresponding-to-1-entry e x86)
                    (gather-qword-addresses-corresponding-to-entries-aux a x86))))
  :hints (("Goal" :in-theory (e/d* (std::set-equiv) ())
           :use ((:instance subsetp-equal-and-gather-qword-addresses-corresponding-to-entries-aux-1)
                 (:instance subsetp-equal-and-gather-qword-addresses-corresponding-to-entries-aux-2)))))

(defthm set-equiv-and-gather-qword-addresses-corresponding-to-entries-aux
  (implies (std::set-equiv a b)
           (std::set-equiv (gather-qword-addresses-corresponding-to-entries-aux a x86)
                           (gather-qword-addresses-corresponding-to-entries-aux b x86)))
  :hints (("Goal" :in-theory (e/d* (gather-qword-addresses-corresponding-to-entries-aux)
                                   ())))
  :rule-classes :congruence)

(defthm set-equiv-implies-iff-member-p-2
  (implies (acl2::set-equiv x y)
           (iff (member-p a x) (member-p a y)))
  :hints (("Goal" :in-theory (e/d* (member-p-iff-member-equal) ())))
  :rule-classes :congruence)

(defthm member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux-new
  (iff
   (member-p e (gather-qword-addresses-corresponding-to-entries-aux
                (gather-qword-addresses-corresponding-to-entries-aux
                 superior-structure-paddrs
                 x86)
                x86))
   (member-p e (gather-qword-addresses-corresponding-to-entries-aux
                (gather-qword-addresses-corresponding-to-entries-aux
                 (remove-duplicates-equal superior-structure-paddrs)
                 x86)
                x86))))

(defthm page-table-entry-addr-is-a-member-of-gather-all-paging-structure-qword-addresses
  (implies
   (and (canonical-address-p lin-addr)
        (equal base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12))
        (equal (page-present (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 1)
        (equal (page-size (rm-low-64 (pml4-table-entry-addr lin-addr base-addr) x86)) 0)
        (equal
         (page-present
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-dir-ptr-table-entry-addr
            lin-addr
            (ash (loghead 40
                          (logtail 12
                                   (rm-low-64
                                    (pml4-table-entry-addr lin-addr base-addr)
                                    x86)))
                 12))
           x86))
         0)
        (equal
         (page-present
          (rm-low-64
           (page-directory-entry-addr
            lin-addr
            (ash
             (loghead
              40
              (logtail
               12
               (rm-low-64
                (page-dir-ptr-table-entry-addr
                 lin-addr
                 (ash
                  (loghead
                   40
                   (logtail
                    12
                    (rm-low-64
                     (pml4-table-entry-addr
                      lin-addr
                      base-addr)
                     x86)))
                  12))
                x86)))
             12))
           x86))
         1)
        (equal
         (page-size
          (rm-low-64
           (page-directory-entry-addr
            lin-addr
            (ash
             (loghead
              40
              (logtail
               12
               (rm-low-64
                (page-dir-ptr-table-entry-addr
                 lin-addr
                 (ash
                  (loghead
                   40
                   (logtail
                    12
                    (rm-low-64
                     (pml4-table-entry-addr
                      lin-addr
                      base-addr)
                     x86)))
                  12))
                x86)))
             12))
           x86))
         0))
   (member-p
    (page-table-entry-addr
     lin-addr
     (ash
      (loghead
       40
       (logtail
        12
        (rm-low-64
         (page-directory-entry-addr
          lin-addr
          (ash
           (loghead
            40
            (logtail
             12
             (rm-low-64
              (page-dir-ptr-table-entry-addr
               lin-addr
               (ash (loghead 40
                             (logtail 12
                                      (rm-low-64
                                       (pml4-table-entry-addr lin-addr base-addr)
                                       x86)))
                    12))
              x86)))
           12))
         x86)))
      12))
    (gather-all-paging-structure-qword-addresses x86)))
  :hints (("Goal"
           :do-not '(preprocess)
           :use ((:instance page-table-entry-addr-is-at-the-fourth-level
                            (base-addr (ash (cr3-slice :cr3-pdb (ctri *cr3* x86)) 12)))
                 (:instance member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux-new
                            (e (page-table-entry-addr
                                lin-addr
                                (ash
                                 (loghead
                                  40
                                  (logtail
                                   12
                                   (rm-low-64
                                    (page-directory-entry-addr
                                     lin-addr
                                     (ash
                                      (loghead
                                       40
                                       (logtail
                                        12
                                        (rm-low-64
                                         (page-dir-ptr-table-entry-addr
                                          lin-addr
                                          (ash (loghead 40
                                                        (logtail 12
                                                                 (rm-low-64
                                                                  (pml4-table-entry-addr lin-addr base-addr)
                                                                  x86)))
                                               12))
                                         x86)))
                                      12))
                                    x86)))
                                 12)))
                            (superior-structure-paddrs
                             (gather-qword-addresses-corresponding-to-entries-aux
                              (gather-pml4-table-qword-addresses x86)
                              x86))))
           :in-theory (e/d* (gather-all-paging-structure-qword-addresses
                             gather-qword-addresses-corresponding-to-entries)
                            (page-table-entry-addr-is-at-the-fourth-level
                             member-p-after-remove-duplicates-equal-of-superior-paddrs-in-gather-qword-addresses-corresponding-to-entries-aux-new)))))

;; ======================================================================
