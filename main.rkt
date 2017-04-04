#lang racket/base

(require racket/match
         racket/contract
         web-server/formlets/lib
         web-server/http
         net/url
         (only-in json
                  read-json)
         (only-in net/uri-codec
                  uri-encode)
         "keys.rkt"
         )

(provide (all-from-out "keys.rkt")
         (contract-out
          [recaptcha-formlet
           (->* {}
                {#:theme (or/c #f "light" "dark")
                 #:type (or/c #f "image" "audio")
                 #:size (or/c #f "normal" "compact")
                 #:tabindex (or/c #f exact-integer?)
                 #:network-error-result (or/c #t #f 'disabled 'network-error)}
                (formlet/c (or/c #t #f 'disabled 'network-error)))]
          ))



(define (recaptcha-formlet #:theme [theme #f]
                           #:type [type #f]
                           #:size [size #f]
                           #:tabindex [tabindex #f]
                           #:network-error-result [network-error-result #f])
  (cross (pure (make-verify-recaptcha #:network-error-result
                                      network-error-result))
         (make-recaptcha-formlet/raw #:theme theme
                                     #:type type
                                     #:size size
                                     #:tabindex tabindex)))

(define-syntax-rule (list-when test body)
  (if test body null))

(define ((make-recaptcha-formlet/raw #:theme [theme #f]
                                     #:type [type #f]
                                     #:size [size #f]
                                     #:tabindex [tabindex #f])
         int)
  (cond
    [(use-recaptcha?)
     (values
      `((script ([src "https://www.google.com/recaptcha/api.js"]
                 [async "async"]
                 [defer "defer"]))
        (div ,(append `([class "g-recaptcha"]
                        [data-sitekey ,(current-recaptcha-site-key)])
                      (list-when theme
                        `([data-theme ,theme]))
                      (list-when type
                        `([data-type ,type]))
                      (list-when size
                        `([data-size ,size]))
                      (list-when tabindex
                        `([data-tabindex ,(number->string tabindex)])))))
      (λ (l-bindings)
        (match (bindings-assq #"g-recaptcha-response"
                              l-bindings)
          [(binding:form #"g-recaptcha-response" value)
           value]
          [_
           #f]))
      int)]
    [else
     (values null (λ (_) 'disabled) int)]))

(define ((make-verify-recaptcha #:network-error-result [network-error-result #f])
         g-recaptcha-response)
  (if (use-recaptcha?)
      (case g-recaptcha-response
        [(disabled) g-recaptcha-response]
        [else
         (with-handlers ([exn:fail:network? (λ (_) network-error-result)])
           (define-values {status-line l-headers data-port}
             (http-sendrecv/url
              (struct-copy
               url
               (string->url
                "https://www.google.com/recaptcha/api/siteverify")
               [query
                `([secret . ,(uri-encode (current-recaptcha-secret-key))]
                  [response . ,(uri-encode
                                (if (bytes? g-recaptcha-response)
                                    (bytes->string/utf-8
                                     g-recaptcha-response)
                                    g-recaptcha-response))])])
              #:method #"POST"))
           (hash-ref (read-json data-port) 'success #f))])
      'disabled))