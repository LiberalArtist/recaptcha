#lang web-server/base

(require racket/match
         racket/contract
         racket/serialize
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
                (and/c serializable?
                       (formlet/c (or/c #t #f 'disabled 'network-error))))]
          [verify-recaptcha-response
           (->* {string?}
                {#:secret-key string?
                 #:network-error-result (or/c #t #f 'disabled 'network-error)}
                (or/c #t #f 'disabled 'network-error))]
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
         (verify-recaptcha-response g-recaptcha-response
                                    #:secret-key (current-recaptcha-secret-key)
                                    #:network-error-result network-error-result)])
      'disabled))

(define (verify-recaptcha-response g-recaptcha-response
                                   #:secret-key [secret-key (current-recaptcha-secret-key)]
                                   #:network-error-result [network-error-result #f])
  (define-values {status-line l-headers data-port}
    (let* ([u (string->url "https://www.google.com/recaptcha/api/siteverify")]
           [query `([secret . ,(uri-encode secret-key)]
                    [response . ,(uri-encode
                                  (if (bytes? g-recaptcha-response)
                                      (bytes->string/utf-8
                                       g-recaptcha-response)
                                      g-recaptcha-response))])]
           [u (struct-copy url u
                           [query query])])
      (with-handlers ([exn:fail:network? (λ (_) network-error-result)])
        (http-sendrecv/url u #:method #"POST"))))
  (hash-ref (read-json data-port) 'success #f))
  
                                   
