#lang racket

(provide cache-manager%)

(define make-temporary-file-orig make-temporary-file)
(define cache-manager%
  (class object%
    
    (init-field root             #| root of the cache location |#
                retention-days   #| number of days before items expire |#)
    
    (super-new)

    (define/public (make-temporary-file)
      ((curryr make-temporary-file-orig) root))

    (define/public (remove-old)
      (let* ([all-items       (directory-list root)]
             [cutoff          (- current-seconds (* retention-days 24 3600))]
             [expired-items   (filter-map (λ (f) (if (cutoff . < . (file-or-directory-modify-seconds f))
                                                     f #f))
                                          all-items)])
        (for-each delete-file expired-items)))

    ))