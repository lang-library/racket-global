#lang racket
(require compatibility/defmacro) ;; compatibility-lib
(require dyoo-while-loop) ;; while-loop

(define-macro (until cond . rest)
  `(while (not ,cond) ,@rest)
  )

(provide while until break continue)
