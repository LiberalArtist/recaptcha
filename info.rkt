#lang info

(define collection "recaptcha")

(define deps '("base"
               "web-server-lib"
               ))

(define build-deps '("scribble-lib"
                     "racket-doc"
                     "web-server-doc"
                     ))

(define scribblings
  '(("scribblings/recaptcha.scrbl"
     ()
     (net-library)
     "reCAPTCHA"
     )))

(define pkg-desc
  "Utilities for using reCAPTCHA with web-server/formlets")

(define version "0.1")

(define pkg-authors '(philip))
