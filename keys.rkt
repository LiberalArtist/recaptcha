#lang racket/base

(require racket/contract
         )

(provide recaptcha-testing-site-key
         recaptcha-testing-secret-key
         use-recaptcha?
         (contract-out
          [current-recaptcha-site-key
           (parameter/c (or/c #f string?))]
          [current-recaptcha-secret-key
           (parameter/c (or/c #f string?))]
          ))

(define recaptcha-testing-site-key
  "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI")

(define recaptcha-testing-secret-key
  "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe")

(define current-recaptcha-site-key
  (make-parameter recaptcha-testing-site-key)) 

(define current-recaptcha-secret-key
  (make-parameter recaptcha-testing-secret-key))

(define (use-recaptcha?)
  (and (current-recaptcha-site-key)
       (current-recaptcha-secret-key)))