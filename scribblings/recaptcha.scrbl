#lang scribble/manual

@title{reCAPTCHA}
@author[(author+email @elem{Philip M@superscript{c}Grath}
                      "philip@philipmcgrath.com"
                      #:obfuscate? #t)]
@defmodule[recaptcha]

@(require (for-label racket
                     web-server/formlets
                     web-server/formlets/lib
                     recaptcha
                     racket/serialize
                     ))

This library provides utilities for using 
@hyperlink["https://www.google.com/recaptcha"]{reCAPTCHA}
with the @racketmodname[web-server/formlets] API.
It currently supports reCAPTCHA v2 (the ``no CAPTCHA reCAPTCHA'').

To actually use reCAPTCHA, you will need to
@hyperlink["https://developers.google.com/recaptcha/docs/start"]{
 register} to obtain a @deftech{site key} and a @deftech{secret key}
for your domain. This library supports testing use without registration
and behaves gracefully if reCAPTCHA is disabled.

@defproc[(recaptcha-formlet [#:theme theme (or/c #f "light" "dark") #f]
                            [#:type type (or/c #f "image" "audio") #f]
                            [#:size size (or/c #f "normal" "compact") #f]
                            [#:tabindex tabindex (or/c #f exact-integer?) #f]
                            [#:network-error-result network-error-result
                             (or/c #t #f 'disabled 'network-error) #f])
         (and/c (formlet/c (or/c #t #f 'disabled 'network-error))
                serializable?)]{
 Creates a @tech[#:doc '(lib "web-server/scribblings/web-server.scrbl")]{
  formlet} that embeds a reCAPTCHA widget. The resulting formlet will use
 the credentials specified by @racket[current-recaptcha-site-key] and
 @racket[current-recaptcha-secret-key] for validation. When
 @racket[(use-recaptcha?)] returns @racket[#f], the formlet will not render
 anything.

 The formlet's processing stage will return @racket[#t] if the response is
 validated successfully, @racket[#f] if validation fails, @racket['disabled]
 when @racket[(use-recaptcha?)] returns @racket[#f], and @racket[network-error-result]
 if an @racket[exn:fail:network] is raised while trying to validate the response.

 The @racket[theme], @racket[type], @racket[size], and @racket[tabindex] arguments
 attach optional attributes to the widget, the meaning of which is specified in
 the @hyperlink["https://developers.google.com/recaptcha/docs/display#render_param"]{
  reCAPTCHA documentation}. If an argument is @racket[#f], the corresponding
 attribute is not included.

 Formlets created by @racket[recaptcha-formlet] are @racket[serializable?],
 facilitating use with stateless @(hash-lang) @racketmodname[web-server]
 servlets.

 @history[
 #:changed "0.1" @elem{
   Added serialization support in coordination with changes to
   @racketmodname[web-server/formlets] in the Racket 6.11 release.
   }]
}


@section{Credentials}
@defmodule[recaptcha/keys #:no-declare]
@declare-exporting[recaptcha recaptcha/keys]

The bindings documented in this section are re-exported by
@racketmodname[recaptcha], but @racketmodname[recaptcha/keys] may be required
directly for fewer dependencies.

@deftogether[(@defparam[current-recaptcha-site-key maybe-site-key
                        (or/c #f string?)
                        #:value recaptcha-testing-site-key]
               @defparam[current-recaptcha-secret-key maybe-secret-key
                         (or/c #f string?)
                         #:value recaptcha-testing-secret-key])]{
 These parameters specify the (public) @tech{site key} and
 @tech{secret key} to be used for validation. Both must be non-false 
 for recaptcha to be enabled. Furthermore, unless they are valid, registered
 keys used on an appropriate domain, validation should fail.
}

@defproc[(use-recaptcha?) any/c]{
 Equivalent to
 @(racketblock
   (and (recaptcha-testing-site-key)
        (recaptcha-testing-secret-key)))
}

@deftogether[(@defthing[recaptcha-testing-site-key string?]
               @defthing[recaptcha-testing-secret-key string?])]{
 A key pair for testing use, which does not require registration.

 Per the
 @hyperlink[(string-append "https://developers.google.com/recaptcha/docs/"
                           "faq#id-like-to-run-automated-tests-with-recaptcha-v2-"
                           "what-should-i-do")]{
  reCAPTCHA documentation}, with these keys,
 @nested[#:style 'inset]{
  you will always get No CAPTCHA and all verification requests will pass …
  The reCAPTCHA widget will show a warning message to claim that it's only
  for testing purpose[s]. Please do not use these keys for your production traffic.
 }
}