(module bsd-random
(randomize random fxrandom fprand
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

(define random
  (foreign-lambda* number ((number n))  ;; NB: we can't avoid unnecessary modf() in number return conversion
    "return(trunc(n * (freebsd_random() / (RAND_MAX + 1.0))));"))

;; % might be ok too
(foreign-declare "#define fxrandom(n) C_fix((C_unfix(n) * (freebsd_random() / (RAND_MAX + 1.0))))")

;; behave like core random: only allow exact input; return garbage for exact input > 2^31 (??)
(define (fxrandom n)
  (##sys#check-exact n 'fxrandom)
  (##core#inline "fxrandom" n))

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
