(module bsd-random
(randomize random-integer random-fixnum
           fprand
           ;; fxrand
           )

(import scheme chicken foreign)

(foreign-declare "#include \"random.h\"")

(define _srandomdev
  (foreign-lambda void "freebsd_srandomdev"))
(define _srandom
  (foreign-lambda void "freebsd_srandom" long))

(define (randomize #!optional seed)
  (if seed
      (_srandom seed)
      (_srandomdev)))

(define fprand
  (foreign-lambda* double ()
    "return(freebsd_random() / (RAND_MAX + 1.0));"))

;; % might be ok too
(foreign-declare "#define fxrandom(n) C_fix((C_unfix(n) * (freebsd_random() / (RAND_MAX + 1.0))))")

;; Only allow exact input, like core random; however, full fixnum
;; range is permitted here on 64 bit platforms (still with 31-bit precision).
;; Note that as 2^30 is invalid on 32-bit, the range is 0..2^30-2 there.
;; This might hint that fxrand should return 0..2^30-1.
(define (random-fixnum n)
  (##sys#check-exact n 'fxrandom)
  (##core#inline "fxrandom" n))

;; Allow use of full 31-bit precision on 32-bit systems with up to a 52-bit range,
;; as this accepts and returns flonums.  On 64-bit this is worse than fxrandom so
;; that could theoretically be called directly (might need feature-test egg).
(define random-integer
  (foreign-lambda* number ((number n))  ;; NB: we can't avoid unnecessary modf() in number return conversion
    "return(trunc(n * (freebsd_random() / (RAND_MAX + 1.0))));"))

;; fxrand disabled.  On 64-bit system we can use entire 31-bit
;; precision, but on 32-bit system we get undefined behavior
;; due to SHL on signed int (in practice, will just become negative).
;; Possible solution is to unequivocally SHR 1 first, reducing precision
;; to 30 bits on all platforms; or use two code paths; or retain 31 bits by
;; subtracting 2^30 so it fits in fixnum but can be negative.
;;
;; (define fxrand
;;   (foreign-lambda int "freebsd_random"))

(randomize)
)
