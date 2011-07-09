;; random-bsd extension for Chicken
;; Copyright (c) 2011 Ursetto Consulting, Inc.  See LICENSE for details.

(module random-bsd
(randomize randomize/device
 random-integer random-fixnum random-real
 random    ;; mapped to random-fixnum
 ;; fxrand
 )

(import scheme chicken foreign)

(foreign-declare "#include \"random.h\"")
(foreign-declare "#define BSD_RAND_MAX 2147483647")
(foreign-declare "#include <sys/time.h>")

(define _srandomdev
  (foreign-lambda void "freebsd_srandomdev"))
(define _srandom
  (foreign-lambda void "freebsd_srandom" long))  ;; warning: arg type is unsigned long, then cast to uint32

;; Seed with pid and current time w/o reading from /dev/random like srandomdev().
;; It may however be ok to read from /dev/urandom; whether to use this data as the
;; seed or the full state (as in srandomdev) is unknown.
(define _spseudorandom
  (foreign-lambda* void () #<<EOF
    struct timeval tv;
    unsigned long junk;
    C_gettimeofday(&tv, NULL);
    freebsd_srandom((C_getpid() << 16) ^ tv.tv_sec ^ tv.tv_usec ^ junk);
EOF
))

(define (randomize #!optional seed)
  (if seed
      (_srandom seed)
      (_spseudorandom)))

(define (randomize/device)
  (_srandomdev))

(define fprand
  (foreign-lambda* double ()
    "return(freebsd_random() / (BSD_RAND_MAX + 1.0));"))
(define random-real fprand)

;; % might be ok too
;;(foreign-declare "#define fxrandom(n) C_fix((C_unfix(n) * (freebsd_random() / (BSD_RAND_MAX + 1.0))))")
(foreign-declare #<<EOF
C_inline C_word fxrandom(C_word n) {
#ifdef C_SIXTY_FOUR
  C_word i = C_unfix(n);
  if (i >= (1L<<31)) {
    long L = (freebsd_random() << 31) | freebsd_random();
    L &= 0x1fffffffffffffL;               /* 53 bits */
    double d = L / 9007199254740992.0;    /* 2^53 */
/*
    printf("%016lx %20ld\n", L, L);
    printf("%016lx %20ld\n", *(unsigned long *)(&d), (long)(d*9007199254740992.0));
*/
    return C_fix(i * d);
  } else
#endif
  return C_fix((C_unfix(n) * (freebsd_random() / (BSD_RAND_MAX + 1.0))));
}
EOF
)

;; Only allow exact input, like core random; however, full 62-bit fixnum
;; range is permitted here on 64 bit platforms (with 53-bit precision).
;; Note that as 2^30 is invalid on 32-bit, the range is 0..2^30-2 there.
;; This might hint that fxrand should return 0..2^30-1.
(define (random-fixnum n)
  (##sys#check-exact n 'random-fixnum)
  (##core#inline "fxrandom" n))
(define random random-fixnum)

;; Generate an integer in range [0..N-1] where N is an inexact integer (flonum),
;; and returns a flonum.  This is used when N is outside of fixnum range.
(define (random-inexact-integer n)
  (fptruncate (fp* n (fprand))))

;; Generate random integer in range [0..N-1].  N may be a fixnum or flonum;
;; when a flonum, an integer flonum with 31-bit precision is returned.
;; Does not attempt to coerce flonums to fixnums even when they fit.
(define random-integer
  (lambda (n)
    (if (exact? n)
        (random-fixnum n)
        (if (integer? n)        ;; nb: anything over 2^47 is always an integer
            (random-inexact-integer n)
            (error 'random-integer "argument must be an integer" n)))))

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
