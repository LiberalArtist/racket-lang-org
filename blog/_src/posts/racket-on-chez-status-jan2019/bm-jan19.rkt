#lang racket/base
(require racket/runtime-path
         pict
         "color.rkt"
         "plot.rkt"
         "build-desc.rkt")

(provide traditional-benchmarks
         shootout-benchmarks)

(define-runtime-path log-cs-orig-txt "bmtimes-jan19/log-cs-orig.txt")
(define-runtime-path log-cs-txt "bmtimes-jan19/log-cs.txt")
(define-runtime-path log-rcs-txt "bmtimes-jan19/log-rcs.txt")
(define-runtime-path log-r-txt "bmtimes-jan19/log-r.txt")
(define-runtime-path sho-rcs-txt "bmtimes-jan19/sho-rcs.txt")
(define-runtime-path sho-r-txt "bmtimes-jan19/sho-r.txt")
(define-runtime-path build-rcs-png "bmtimes-jan19/build-rcs.png")

(define traditional-cs-orig (get-times log-cs-orig-txt))
(define traditional-cs (get-times log-cs-txt))
(define traditional-r/cs (get-times log-rcs-txt))
(define traditional-r (get-times log-r-txt))
(define shootout-r/cs (get-times sho-rcs-txt))
(define shootout-r (get-times sho-r-txt))

(define (r/cs-def t)
  (hbl-append (colorize (t "R/CS") racket-color) (t " = ") (colorize (t "Racket CS") racket-color)))
(define (r-def t)
  (hbl-append (colorize (t "Racket") c-color) (t " = ") (colorize (t "Racket") c-color)))

(define (machine t)
  (vl-append
   (t "x86_64 Linux")
   (t "Core i7-2600 3.4GHz")))

(define (traditional-benchmarks #:t t #:tt tt #:gap-size gap-size #:bar-sep [bar-sep 0])
  (define p
    (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
          #:columns 6
          #:sort-ratio '(1 . 2)
          #:suffix " msec"
          (list (t "CS") (t "R/CS") (t "R"))
          (list scheme-color racket-color c-color)
          (list traditional-cs traditional-r/cs traditional-r)))
  
  (rb-superimpose
   p
   (vl-append
    (hbl-append (colorize (filled-rectangle 20 20) r5rs-color) (t " = mutable pairs"))
    (hbl-append (colorize (t "CS") scheme-color) (t " = ") (colorize (t "Chez Scheme") scheme-color))
    (r/cs-def t)
    (r-def t))
   (vl-append
    (machine t)
    (blank 0 (* (pict-height p) 0.33)))))

(define (shootout-benchmarks #:t t #:tt tt #:gap-size gap-size #:bar-sep [bar-sep 0])
  (rb-superimpose
   (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
         #:columns 6
         #:sort-ratio '(0 . 1)
         #:suffix " msec"
         (list (t "R/CS") (t "R"))
         (list "blue" "red")
         (list shootout-r/cs shootout-r))
   (hc-append
    (* 3 gap-size)
    (machine t)
    (vl-append
     (r/cs-def t)
     (r-def t)))))

(module+ pict
  (provide traditional-benchmarks*
           shootout-benchmarks*
           one-plot
           general-plot
           build-desc
           compile-time-plot
           compile-time-detail-plot
           recompile-time-plot)
  (define (t s) (text s 'swiss 32))
  (define (it s) (text s '(italic . swiss) 32))
  (define (tt s) (text s '(bold . modern) 32))
  (define gap-size 24)
  (define bar-sep 5)
  (define scale-amt 0.3)
  (define plot-width 700)
  (define plot-height 300)
  (define (traditional-benchmarks*)
    (scale (traditional-benchmarks #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep) scale-amt))
  (define (shootout-benchmarks*)
    (scale (shootout-benchmarks #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep) scale-amt))

  (define (add-desc desc p)
    (rt-superimpose
     (hbl-append (scale (it desc) 0.75) (t ""))
     p))
  
  (define (one-plot label-str
                    #:cs cs
                    #:r r
                    #:r-cify [r-cify #f]
                    #:r6 [r6 #f]
                    #:r-all [r-all #f]
                    #:r-jit [r-jit #f]
                    #:max max
                    #:display-scale [display-scale 1]
                    #:suffix [suffix ""]
                    #:vertical-bars? [vertical-bars? #f]
                    #:desc [desc ""])
    (define label (string->symbol label-str))
    (define (mk n) (if n (list (hash label n)) null))
    (scale
     (add-desc
      desc
      (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
            #:normalize-max? #t
            #:max max
            #:columns 1
            #:width (if vertical-bars? plot-height plot-width)
            #:display-scale display-scale
            #:suffix suffix
            #:vertical-bars? vertical-bars?
            (append
             (list (t "R/CS") (t "R"))
             (if r-cify (list (t "R/cify")) null)
             (if r6 (list (t "Rv6")) null)
             (if r-all (list (t "R/all")) null)
             (if r-jit (list (t "R/jit!")) null))
            (append
             (list "blue" "red")
             (if r-cify (list "darkred") null)
             (if r6 (list "brown") null)
             (if r-all (list r-jit-color) null)
             (if r-jit (list r-jit-color) null))
            (append
             (list (hash label cs)
                   (hash label r))
             (mk r-cify)
             (mk r6)
             (mk r-all)
             (mk r-jit))))
     (* 2 scale-amt)))

  (define (general-plot labels
                        colors
                        tables
                        #:vertical-bars? [vertical-bars? #f]
                        #:desc [desc ""]
                        #:suffix [suffix ""])
    (scale
     (add-desc
      desc
      (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
            #:columns 1
            #:width (* 1/2 plot-width)
            #:vertical-bars? vertical-bars?
            #:suffix suffix
            (map t labels) colors tables))
     (* 2 scale-amt)))

  (define (build-desc)
    (scale (inset (describe-build-plot (bitmap build-rcs-png)
                                       #:t t
                                       #:gap-size gap-size
                                       #:max-time "2h32m")
                  (* gap-size 4) (* gap-size 2) (* gap-size 6) (* gap-size 4))
           0.5))

  (define (add-diff ht)
    (hash-set ht 'compile-linklet-minus-regalloc
              (- (hash-ref ht 'compile-linklet)
                 (hash-ref ht 'regalloc))))

  (define r/cs-compile
    (hash '|racket -cl racket|
          (+ 56786 476) ; user + sys
          '|racket -cl racket/base|
          (+ 5226 72)))
  (define r/cs-compile-detail
    (hash '|racket -cl racket|
          (add-diff
           (hash 'expand 23737
                 'compile 26883
                 'schemify 2571
                 'compile-linklet 20143
                 'regalloc 7870
                 'read 1430))
          '|racket -cl racket/base|
          (add-diff
           (hash 'expand 2063
                 'compile 3138 ; includes 'schemify and 'compile-linklet
                 'schemify 300
                 'compile-linklet 2449
                 'regalloc 880 ; part of 'compile-linklet
                 'read 226))))
  (define r/cs-recompile
    (hash '|racket -Ml racket|
          (+ 19398 304)
          '|racket -Ml racket/base|
          (+ 2555 80)))
  (define r-compile
    (hash '|racket -cl racket|
          (+ 30825 784)
          '|racket -cl racket/base|
          (+ 2785 72)))
  (define r-compile-detail
    (hash '|racket -cl racket|
          (add-diff
           (hash 'expand 21743
                 'compile 3697
                 'compile-linklet 2917
                 'regalloc 0
                 'read 1378
                 'jit 325))
          '|racket -cl racket/base|
          (add-diff
           (hash 'expand 2034
                 'compile 409
                 'compile-linklet 294
                 'regalloc 0
                 'read 229
                 'jit 100))))
  (define r-recompile
    (hash '|racket -Ml racket|
          (+ 1829 88)
          '|racket -Ml racket/base|
          (+ 296 32)))
  (define r-jit-compile
    (hash '|racket -cl racket|
          (+ 35685 704)
          '|racket -cl racket/base|
          (+ 3191 88)))
  (define r-jit-compile-detail
    (hash '|racket -cl racket|
          (add-diff
           (hash 'expand 24956
                 'compile 3593
                 'compile-linklet 2667
                 'regalloc 0
                 'read 1468
                 'jit 905))
          '|racket -cl racket/base|
          (add-diff
           (hash 'expand 2288
                 'compile 410
                 'compile-linklet 297
                 'regalloc 0
                 'read 229
                 'jit 170))))
  (define r-jit-recompile
    (hash '|racket -Ml racket|
          (+ 2393 100)
          '|racket -Ml racket/base|
          (+ 457 40)))

  (define ghost-label (t "R/CS JIT"))

  (define expand-color "darkgray")
  (define compile-color "brown")
  (define regalloc-color "chocolate")
  (define jit-color "gold")
  (define schemify-color "slateblue")

  (define compile-key
    (scale
     (let ([sq (let ([s (* 0.8 gap-size)])
                 (filled-rectangle s s))])
       (vl-append
        3
        (hbl-append (colorize sq expand-color) (t " = expand"))
        (hbl-append (colorize sq schemify-color) (t " = schemify"))
        (hbl-append (colorize sq compile-color) (t " = compile"))
        (hbl-append (colorize sq regalloc-color) (t " = register allocate"))
        (hbl-append (colorize sq jit-color) (t " = JIT"))))
     1/2))

  (define key-sep 20)

  (define (compile-time-plot)
    (hc-append
     key-sep
     (scale
      (add-desc
       "load-from-source time"
       (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
             #:normalize-max? #t
             #:max (hash-ref r/cs-compile '|racket -cl racket|)
             #:reverse? #t
             #:columns 1
             #:width plot-width
             #:ghost-label ghost-label
             #:suffix " msec"
             (list (t "R/CS") (t "R") (t "R/jit!"))
             (list racket-color c-color r-jit-color)
             (list r/cs-compile
                   r-compile
                   r-jit-compile)))
      (* 2 scale-amt))
     (ghost compile-key)))

  (define (compile-time-detail-plot)
    (hc-append
     key-sep
     (scale
      (add-desc
       "load-from-source time"
       (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
             #:normalize-max? #t
             #:max (hash-ref r/cs-compile '|racket -cl racket|)
             #:reverse? #t
             #:columns 1
             #:width plot-width
             #:ghost-label ghost-label
             #:suffix " msec"
             (list (t "R/CS") (t "R") (t "R/jit!"))
             (list racket-color c-color r-jit-color)
             (list r/cs-compile
                   r-compile
                   r-jit-compile)
             #:details (list r/cs-compile-detail
                             r-compile-detail
                             r-jit-compile-detail)
             #:detail-spec (list (cons 'jit jit-color)
                                 (cons 'regalloc regalloc-color)
                                 (cons 'compile-linklet-minus-regalloc compile-color)
                                 (cons 'schemify schemify-color)
                                 (cons 'expand expand-color))))
      (* 2 scale-amt))
     compile-key))

  (define (recompile-time-plot)
    (hc-append
     key-sep
     (scale
      (add-desc
       "load-from-expanded time"
       (plot #:t t #:tt tt #:gap-size gap-size #:bar-sep bar-sep
             #:normalize-max? #t
             #:max (hash-ref r/cs-compile '|racket -cl racket|)
             #:reverse? #t
             #:columns 1
             #:width plot-width
             #:ghost-label ghost-label
             #:suffix " msec"
             (list (t "R/CS") (t "R") (t "R/jit!"))
             (list racket-color c-color r-jit-color)
             (list r/cs-recompile
                   r-recompile
                   r-jit-recompile)))
      (* 2 scale-amt))
     (ghost compile-key))))
