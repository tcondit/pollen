#lang racket/base
(require racket/list racket/string sugar/define sugar/test txexpr/base racket/match sugar/unstable/container sugar/coerce sugar/unstable/len  "../private/whitespace.rkt")

(provide whitespace? whitespace/nbsp?)

(define (make-replacer query+replacement)
  (let ([queries (map car query+replacement)]
        [replacements (map second query+replacement)])
    ;; reverse because first in list should be first applied to str (and compose1 works right-to-left)
    (apply compose1 (reverse (map (λ (query replacement) (λ (str) (regexp-replace* query str replacement))) queries replacements)))))

(define+provide/contract (smart-dashes str)
  (string? . -> . string?)
  (define dashes 
    ;; fix em dashes first, else they'll be mistaken for en dashes
    ;; \\s is whitespace + #\u00A0 is nonbreaking space
    '((#px"[\\s#\u00A0]*(---|—)[\\s#\u00A0]*" "—") ; em dash
      (#px"[\\s#\u00A0]*(--|–)[\\s#\u00A0]*" "–"))) ; en dash
  ((make-replacer dashes) str))

(module-test-external
 (check-equal? (smart-dashes "I had --- maybe 13 -- 20 --- hob-nobs.") "I had—maybe 13–20—hob-nobs.")
 (define tricky-string "\"Why,\" she could've asked, \"are we in O‘ahu watching 'Mame'?\"")
 (check-equal? (smart-quotes tricky-string) 
               "“Why,” she could’ve asked, “are we in O‘ahu watching ‘Mame’?”")
 (check-equal? (smart-quotes tricky-string
                             #:apostrophe "zing"
                             #:double-open "«" #:double-close "»"
                             #:single-open "‹" #:single-close "›")
               "«Why,» she couldzingve asked, «are we in O‘ahu watching ‹Mame›?»")
 (check-equal? (smart-quotes "\"\'Impossible.\' Yes.\"") "“‘Impossible.’ Yes.”")
 (check-equal? (smart-quotes '(div "don'" (em "t"))) '(div "don’" (em "t")))
 (check-equal? (smart-quotes '(div "do '" (em "not'"))) '(div "do ‘" (em "not’"))))


(define+provide/contract (smart-quotes x
                                       #:apostrophe [apostrophe-str "’"]
                                       #:single-open [single-open-str "‘"]
                                       #:single-close [single-close-str "’"]
                                       #:double-open [double-open-str "“"]
                                       #:double-close [double-close-str "”"])
  (((or/c string? txexpr?))
   (#:apostrophe string?
    #:single-open string?
    #:single-close string?
    #:double-open string?
    #:double-close string?) . ->* . (or/c string? txexpr?))

  (define quotes
    `((#px"(?<=\\w)'(?=\\w)" ,apostrophe-str) ; apostrophe
      (#px"(?<!\\w)'(?=\\S)" ,single-open-str) ; single_at_beginning
      (#px"(?<=\\S)'(?!\\w)" ,single-close-str) ; single_at_end
      (#px"(?<!\\w)\"(?=\\S)" ,double-open-str) ; double_at_beginning
      (#px"(?<=\\S)\"(?!\\w)" ,double-close-str))) ; double_at_end

  (cond
    [(string? x) ((make-replacer quotes) x)]
    [(txexpr? x)
     ;; convert the quotes as if the txexpr were a flat string, to get proximity right
     ;; then replace the actual strings with substrings from this converted result
     ;; todo: handle entities & chars correctly, for now they are ignored
     (define flat-str (string-append* (filter string? (flatten (remove-attrs x)))))
     (define char-vec (for/vector #:length (string-length flat-str)
                        ([c (in-string (smart-quotes flat-str))])
                        c))
     (define offset 0)
     (let loop ([x x])
       (cond
         [(txexpr? x) (txexpr (get-tag x) (get-attrs x) (map loop (get-elements x)))]
         [(string? x)
          (define prev-offset offset)
          (set! offset (+ prev-offset (string-length x)))
          (list->string
           (for/list ([c (in-vector char-vec prev-offset offset)])
             c))]
         [else x]))]
    [else x]))

; wrap initial quotes for hanging punctuation
; todo: improve this
; does not handle <p>“<em>thing</em> properly
(define+provide/contract (wrap-hanging-quotes nx 
                                              #:single-prepend [single-pp '(squo)]
                                              #:double-prepend  [double-pp '(dquo)])
  ((txexpr?) (#:single-prepend list? #:double-prepend list?) . ->* . txexpr?)
  
  (define two-or-more-char-string? (λ (i) (and (string? i) (>= (string-length i) 2))))
  (define-values (tag attr elements) (txexpr->values nx))
  (make-txexpr tag attr
               (if (and (list? elements) (not (empty? elements)))
                   (let ([new-car-elements  (match (car elements)
                                              [(? two-or-more-char-string? tcs)
                                               (define str-first (get tcs 0))
                                               (define str-rest (get tcs 1 (string-length tcs)))
                                               (cond
                                                 [(str-first . in? . '("\"" "“"))
                                                  ;; can wrap with any inline tag
                                                  ;; so that linebreak detection etc still works
                                                  `(,@double-pp ,(->string #\“) ,str-rest)]
                                                 [(str-first . in? . '("\'" "‘")) 
                                                  `(,@single-pp ,(->string #\‘) ,str-rest)]
                                                 [else tcs])]
                                              [(? txexpr? nx) (wrap-hanging-quotes nx)]
                                              [else (car elements)])])
                     (cons new-car-elements (cdr elements)))
                   elements)))

(module-test-external
 (check-equal? (wrap-hanging-quotes '(p "\"Hi\" there")) '(p (dquo "“" "Hi\" there")))
 (check-equal? (wrap-hanging-quotes '(p "'Hi' there")) '(p (squo "‘" "Hi' there")))
 (check-equal? (wrap-hanging-quotes '(p "'Hi' there") #:single-prepend '(foo ((bar "ino")))) 
               '(p (foo ((bar "ino")) "‘" "Hi' there")))
 
 ;; make sure txexpr without elements passes through unscathed
 (check-equal? (wrap-hanging-quotes '(div ((style "height:2em")))) '(div ((style "height:2em")))))

;; insert nbsp between last two words
(define+provide/contract (nonbreaking-last-space x #:nbsp [nbsp (->string #\u00A0)] 
                                                 #:minimum-word-length [minimum-word-length 6]
                                                 #:last-word-proc [last-word-proc (λ (x) x)])
  ((txexpr?) (#:nbsp string? #:minimum-word-length integer? #:last-word-proc procedure?) . ->* . txexpr?)
  
  ;; todo: parameterize this, as it will be different for each project
  (define tags-to-pay-attention-to '(p aside)) ; only apply to paragraphs
  
  (define (replace-last-space str)
    (if (#\space . in? . str)
        (let ([reversed-str-list (reverse (string->list str))]
              [reversed-nbsp (reverse (string->list (->string nbsp)))])
          (define-values (last-word-chars other-chars) 
            (splitf-at reversed-str-list (λ (i) (not (eq? i #\space)))))
          
          (define front-chars (if (< (len last-word-chars) minimum-word-length) ; OK for long words to be on their own line
                                  ; first char of other-chars will be the space, so use cdr
                                  (string-append (list->string (reverse (cdr other-chars))) (->string nbsp))
                                  (list->string (reverse other-chars))))
          (define last-word (list->string (reverse last-word-chars)))
          `(,front-chars ,(last-word-proc last-word))) ; don't concatenate last word bc last-word-proc might be a txexpr wrapper
        (list str)))
  
  (define (find-last-word-space x) ; recursively traverse xexpr
    (cond
      [(string? x) (replace-last-space x)] ; todo: this assumes a paragraph only has one string in it.
      [(txexpr? x)
       (let-values([(tag attr elements) (txexpr->values x)])
         (if (> (length elements) 0) ; elements is list of xexprs
             (let-values ([(all-but-last last) (split-at elements (sub1 (length elements)))]) 
               (define result (find-last-word-space (car last)))
               (define result-items (if (txexpr? result) (list result) result)) ; might be txexpr, or list of new elements
               (make-txexpr tag attr `(,@all-but-last ,@result-items)))
             x))]
      [else x]))
  
  (if ((car x) . in? . tags-to-pay-attention-to)
      (find-last-word-space x)
      x))

(module-test-internal
 ;; todo: make some tougher tests, it gets flaky with edge cases
 (check-equal? (nonbreaking-last-space '(p "Hi there")) '(p "Hi " "there")) ; nbsp in between last two words
 (check-equal? (nonbreaking-last-space '(p "Hi there") #:nbsp "Ø") '(p "HiØ" "there")) ; but let's make it visible
 (check-equal? (nonbreaking-last-space '(p "Hi there") #:nbsp "_up_") '(p "Hi_up_" "there")) 
 (check-equal? (nonbreaking-last-space '(p "Hi there") #:nbsp "_up_" #:minimum-word-length 3) 
               '(p "Hi " "there")) 
 (check-equal? (nonbreaking-last-space '(p "Hi here" (em "ho there")) #:nbsp "Ø") '(p "Hi here" (em "hoØ" "there"))))
