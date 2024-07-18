#lang info
(define collection "racket-globa")
(define blurb '("Miscellaneous Functions for Racket."))
(define categories '(devtools))
(define can-be-loaded-with 'all)
(define required-core-version "5.1.1")
(define version "1.0")
(define repositories '("4.x"))
(define primary-file "main.rkt")
(define release-notes '((p "First release")))
(define deps '(
               "reprovide-lang-lib"
               "while-loop"
               ))
(define build-deps '("racket-doc"
                     "scribble-lib"))
