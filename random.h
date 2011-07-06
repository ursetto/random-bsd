void freebsd_srandom(unsigned long x);
void freebsd_srandomdev(void);
long freebsd_random(void);
char *freebsd_initstate(unsigned long seed, char *arg_state, long n);
char *freebsd_setstate(char *arg_state);
