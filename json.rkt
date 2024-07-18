#! /usr/bin/env racket
#lang racket

(require json)
(require compatibility/defmacro)

;;(define :null ':null)

(define (to-json %x) (jsexpr->string %x #:null ':null))

(define (from-json %json) (string->jsexpr %json #:null ':null))

(define (json-api-safe-car %x)
  (cond
    ((list? %x)
     (if (zero? (length %x)) ':null (car %x)))
    (#t %x)))

(define-macro (define-json-api . $args)
  ;(print $args)
  `(begin
     (require ffi/unsafe
              ffi/unsafe/define)
     (define-ffi-definer
       ,(string->symbol (string-append "define-" (list-ref $args 0)))
       (ffi-lib ,(list-ref $args 1)))
     (,(string->symbol (string-append "define-" (list-ref $args 0)))
      Call (_fun _string _string -> _string))
     (define (,(string->symbol (string-append (list-ref $args 0) "-call" )) name args)
       (from-json (Call name (to-json args))))
     (define (,(string->symbol (string-append (list-ref $args 0) "-call-one")) name args)
       (let ((%result (from-json (Call name (to-json args)))))
         (if (null? %result)
             null
             (json-api-safe-car %result))))
     )
  )

(provide
 to-json
 from-json
 json-api-safe-car
 define-json-api
 )