#! /usr/bin/env racket
#lang racket

(require ffi/unsafe
         ffi/unsafe/define)
(require json)

(define :null ':null)

(define (to-json %x) (jsexpr->string %x #:null :null))
(define (from-json %json) (string->jsexpr %json #:null :null))

(provide
 to-json
 from-json
 )
