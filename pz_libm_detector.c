// Compile with: gcc pz_libm_detector.c -lm -o pz_libm_detector && ./pz_libm_detector
// Source: https://homepages.loria.fr/PZimmermann/libm-detector/




/* libm detector for x86_64 processors

$ gcc libm-detector.c -lm
$ ./a.out

Copyright 2020 Paul Zimmermann, INRIA

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

See https://www.gnu.org/licenses/lgpl-3.0.en.html for details of the license.
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifdef GLIBC
#include <gnu/libc-version.h>
#endif

int
test0 ()
{
  volatile float x = 0x1.02a10ep+0;
  float y = sinf (x);

  if (y == 0xd.8d361p-4) /* correctly rounded result */
    return 0;
  else
    return 1;
}

int
test1 ()
{
  volatile float x = 0x1.c66874p+0;
  float y = sinf (x);

  if (y == 0xf.aadedp-4) /* correctly rounded result */
    return 0;
  else
    return 2;
}

/* RedHat's libm claims:
   undefined reference to `__errno' in j1f/y1f */
int __errno;

int
test2 ()
{
  volatile float x = 8;
  float y = j1f (x);

  if (y == 0x1.e089060p-3) /* correctly rounded */
    return 0;
  else
    return 4;
}

int
test3 ()
{
  volatile float x = 571;
  float y = sinf (x);

  if (y == -0xb.22f78p-4) /* correctly rounded */
    return 0;
  else
    return 8;
}

int
test4 ()
{
  volatile float x = 1;
  float y = sinf (x);

  if (y == 0xd.76aa4p-4) /* correctly rounded */
    return 0;
  else
    return 16;
}

/* returns 0x1.0ee3ee0p-1 for glibc 2.17 */
int
test5 ()
{
  volatile float x = 34;
  float y = sinf (x);

  if (y == 0x1.0ee3ee0p-1f) /* correctly rounded */
    return 0;
  else
    return 32;
}

int
test6 ()
{
  volatile float x = 2;
  float y = erfcf (x);

  if (y == 0x1.328f5e0p-8f) /* correctly rounded */
    return 0;
  else
    return 64;
}

#if !defined(__x86_64__) && !defined(__x86_64)
int
main ()
{
  fprintf (stderr, "Error, this does not seem to be an x86_64 processor\n");
  exit (1);
}
#else
int
main ()
{
  int res;

  printf ("Mathematical Library Detector, version 1.0\n");

#ifdef GLIBC
  printf("GNU libc version: %s\n", gnu_get_libc_version ());
  printf("GNU libc release: %s\n", gnu_get_libc_release ());
#endif

  /* https://en.wikipedia.org/wiki/C_mathematical_functions#libm */

  res = test0 () | test1 () | test2 () | test3 () | test4 () | test5 ()
    | test6 ();

  if (res == 0)
    printf ("Congratulations, your libm seems to be correctly rounded!\n");
  else if (res == 2)
    printf ("Probably libm shipped with GNU libc, 2.17 <= version <= 2.28\n");
  else if (res == 34)
    printf ("Probably libm shipped with GNU libc, version >= 2.29\n");
  else if (res == 50)
    printf ("Probably libm shipped with GNU libc, version <= 2.16\n");
  else if (res == 9)
    printf ("Probably Intel Math Library\n");
  else if (res == 6)
    printf ("Probably musl (https://musl.libc.org/)\n");
  else if (res == 8)
    printf ("Probably AMD's libm\n");
  else if (res == 114)
    printf ("Probably RedHat's libm (https://sourceware.org/newlib/)\n");
  else if (res == 66)
    printf ("Probably OpenLibm (https://openlibm.org/)\n");
  else
    printf ("Unknown value: %d\n", res);

  return 0;
}
#endif