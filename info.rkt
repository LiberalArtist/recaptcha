#lang info

(define pkg-name "recaptcha")
(define collection "recaptcha")

(define deps
  '(["base" #:version "6.1"]
    "web-server-lib"))

(define build-deps
  '("scribble-lib"
    "racket-doc"
    "web-server-doc"))

(define scribblings
  '(("scribblings/recaptcha.scrbl"
     ()
     (net-library)
     "reCAPTCHA")))

(define pkg-desc
  "Utilities for using reCAPTCHA with web-server/formlets")

(define version "0.1.1")

(define pkg-authors '(philip))

(define license
  'MPL-2.0)
