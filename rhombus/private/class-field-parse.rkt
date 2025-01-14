#lang racket/base
(require syntax/parse/pre
         "tag.rkt"
         (for-template
          (submod "annotation.rkt" for-class)
          "parens.rkt"
          "assign.rkt"
          (submod "equal.rkt" for-parse)
          "parse.rkt"
          (only-in "class-clause-primitive.rkt" private)
          (submod "class-clause.rkt" for-class)
          "binding.rkt"))

(provide :constructor-field
         parse-field-annotations)

(define-syntax-class :private
  (pattern id:identifier
           #:when (free-identifier=? (in-class-clause-space #'id)
                                     (class-clause-quote private))))
(define-syntax-class :mutable
  (pattern id:identifier
           #:when (free-identifier=? (in-binding-space #'id)
                                     (bind-quote mutable))))

(define-syntax-class :id-field
  #:attributes (name private mutable ann-seq default)
  #:datum-literals (group op)
  (pattern (group (~optional private::private
                             #:defaults ([private #'#f]))
                  (~optional mutable::mutable
                             #:defaults ([mutable #'#f]))
                  name:identifier
                  ann::not-equal ...
                  _::equal
                  default-form ...+)
           #:with ((~optional c::unparsed-inline-annotation)) #'(ann ...)
           #:attr ann-seq (if (attribute c)
                              #'c.seq
                              #'#f)
           #:attr default #`((rhombus-expression (#,group-tag default-form ...))))
  (pattern (group (~optional private::private
                             #:defaults ([private #'#f]))
                  (~optional mutable::mutable
                             #:defaults ([mutable #'#f]))
                  name:identifier
                  ann ...
                  (block-tag::block default-form ...))
           #:with ((~optional c::unparsed-inline-annotation)) #'(ann ...)
           #:attr ann-seq (if (attribute c)
                              #'c.seq
                              #'#f)
           #:attr default #`((rhombus-body-at block-tag default-form ...)))
  (pattern (group (~optional private::private
                             #:defaults ([private #'#f]))
                  (~optional mutable::mutable
                             #:defaults ([mutable #'#f]))
                  name:identifier
                  (~optional c::unparsed-inline-annotation))
           #:attr ann-seq (if (attribute c)
                              #'c.seq
                              #'#f)
           #:attr default #'#f))

(define-syntax-class :constructor-field
  #:datum-literals (group op)
  (pattern idf::id-field
           #:attr ann-seq #'idf.ann-seq
           #:attr name #'idf.name
           #:attr keyword #'#f
           #:attr default #'idf.default
           #:attr mutable #'idf.mutable
           #:attr private #'idf.private)
  (pattern (group kw:keyword (::block idf::id-field))
           #:attr ann-seq #'idf.ann-seq
           #:attr name #'idf.name
           #:attr keyword #'kw
           #:attr default #'idf.default
           #:attr mutable #'idf.mutable
           #:attr private #'idf.private)
  (pattern (group kw:keyword)
           #:attr ann-seq #'#f
           #:attr name (datum->syntax #'kw (string->symbol (keyword->string (syntax-e #'kw))) #'kw #'kw)
           #:attr keyword #'kw
           #:attr default #'#f
           #:attr mutable #'#f
           #:attr private #'#f)
  (pattern (group kw:keyword _::equal default-form ...+)
           #:attr ann-seq #'#f
           #:attr name (datum->syntax #'kw (string->symbol (keyword->string (syntax-e #'kw))) #'kw #'kw)
           #:attr keyword #'kw
           #:attr default #`((rhombus-expression (#,group-tag default-form ...)))
           #:attr mutable #'#f
           #:attr private #'#f))


(define (parse-field-annotations ann-seqs-stx)
  (for/list ([seq (in-list (syntax->list ann-seqs-stx))])
    (syntax-parse seq
      [#f (list #'#f #'#f #'())]
      [(c::inline-annotation) (list #'c.converter #'c.annotation-str #'c.static-infos)])))
