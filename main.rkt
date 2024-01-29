#! /usr/bin/env racket
#lang racket

(require ffi/unsafe
         ffi/unsafe/define)
(require json)
(require compatibility/defmacro)

(define :null ':null)

(define (to-json %x) (jsexpr->string %x #:null :null))

(define (from-json %json) (string->jsexpr %json #:null :null))

(define-macro (define-json-api . $args)
  ;(print $args)
  `(begin
    (define-ffi-definer
      ,(string->symbol (string-append "define-" (list-ref $args 0)))
      (ffi-lib ,(list-ref $args 1)))
    (,(string->symbol (string-append "define-" (list-ref $args 0)))
     Call (_fun _string _string -> _string))
    (define (,(string->symbol (string-append "call-" (list-ref $args 0))) name args)
      (from-json (Call name (to-json args))))
    )
  )

(provide
 to-json
 from-json
 define-json-api
 )
