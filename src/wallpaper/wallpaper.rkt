#lang racket

(module wallpaper-api-win racket/base
  ;; Changes windows desktop wallpaper [1]
  ;; [1]: https://stackoverflow.com/a/15052863/695964
  (provide set-wallpaper)
  
  (require ffi/unsafe
           ffi/unsafe/define)
  
  (define-ffi-definer define-user32 (ffi-lib "User32.dll"))
  
  (define SPIF_UPDATEINIFILE #x1)
  (define SPI_SETDESKWALLPAPER #x14)
  
  (define-user32 SystemParametersInfoW (_fun _uint32 _uint32 _string/utf-16 _uint32 -> _stdbool))

  (define (set-wallpaper path)
    (displayln (format "setting wallpaper: ~a" path))
    (unless (file-exists? (string->path path))
      (error (format "file not exist: ~a" path)))
    (unless (SystemParametersInfoW SPI_SETDESKWALLPAPER 0 path SPI_SETDESKWALLPAPER)
      (error (format "error setting wallpaper to ~a" path))))
  )

(module wallpaper-provider-apod racket
  ;; Get wallpaper from APOD. Use APOD API like this [2].
  ;; Calling REST API [1].
  ;; [1]: https://medium.com/chris-opperwall/practical-racket-using-a-json-rest-api-3d85eb11cc2d
  ;; [2]: https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=2016-12-03
  
  (require net/url json srfi/19)

  (provide get-random-image)
  
  (define (get-json url) (call/input-url url get-pure-port read-json))
  (define get-json/str (compose get-json string->url))

  (define (get-picurl json) (hash-ref json 'hdurl #f))

  (define (get-random-img-file-name) (path->string (build-path (find-system-path 'home-dir) ".wallpaper" ".wallpaper.jpg")))

  (define (imgurl->port url use-port)
    (displayln (format "Getting image: ~a" url))
    (call/input-url (string->url url)
                    get-pure-port
                    use-port))

  (define (port->file input file)
    (call-with-output-file file
      (λ (output) (copy-port input output))
      #:exists 'replace))

  (define (get-random-date-str range-in-days)
    (define rand (random range-in-days))
    (define res (- (current-seconds) (* rand 24 60 60)))
    (date->string (seconds->date res) "~Y-~m-~d"))

  (define (get-random-image-url)
    (let* ([img-id (get-random-date-str 300)]
           [img-url (format "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=~a" img-id)]
           [img-url (begin (displayln (format "APOD url: ~a" img-url))
                           img-url)]
           [img-json (get-json/str img-url)]
           [img-url (get-picurl img-json)])
      (or img-url (get-random-image-url))))
  
  ;; -> path
  (define (get-random-image)
    (let* ([img-url (get-random-image-url)]
           [img-path (get-random-img-file-name)])
      (unless (directory-exists? (path-only img-path)) (make-directory (path-only img-path)))
      (imgurl->port img-url (λ (port) (port->file port img-path)))
      img-path))

  ) ; module


(require 'wallpaper-provider-apod
         'wallpaper-api-win)
(define img-path (get-random-image))
(set-wallpaper img-path)
