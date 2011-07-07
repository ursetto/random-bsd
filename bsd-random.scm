(module bsd-random
(randomize random fxrandom fxrand fprand)

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

(define fxrand
  (foreign-lambda int "freebsd_random"))   ;; Maybe subtract 2^30 so it fits in fixnum?
(define fprand
  (foreign-lambda* double ()
    "return(freebsd_random() / (RAND_MAX + 1.0));"))

(define random
  (foreign-lambda* number ((number n))  ;; NB: we can't avoid unnecessary modf() in number return conversion
    "return(trunc(n * (freebsd_random() / (RAND_MAX + 1.0))));"))

;; % might be ok too
(foreign-declare "#define fxrandom(n) C_fix((int)(C_unfix(n) * (freebsd_random() / (RAND_MAX + 1.0))))")

;; behave like core random: only allow exact input; return garbage for exact input > 2^31 (??)
(define (fxrandom n)
  (##sys#check-exact n 'fxrandom)
  (##core#inline "fxrandom" n))

(randomize)
)
