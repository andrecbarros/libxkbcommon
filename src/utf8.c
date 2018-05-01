/*
 * Copyright © 2012 Intel Corporation
 * Copyright © 2014 Ran Benita <ran234@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * Author(s): Rob Bradford <rob@linux.intel.com>
 *            Andre Barros <andre.cbarros@yahoo.com>
 */

#include <stddef.h>
#include <stdbool.h>
#include <inttypes.h>

#include "utf8.h"

int
utf32_to_utf8(uint32_t unichar, char *buffer)
{
  if (UTF32_INVALID(unichar)) {
    *buffer = '\0';
    return 1;
  }
  if (unichar >= 0x80) {
    register short int b, n;

    /* we know precisely how the bits will be distributed, i.e., except for the 1st byte in buffer, the
     * remaining will be composed of extracted groups of 6 bits + 0x80
     */
    buffer[n = b = 2 + (unichar >= 0x800) + (unichar >= 0x10000) + (unichar >= 0x200000) + (unichar >= 0x4000000)] = '\0';
    for ( ; n > 1 ; buffer[--n] = (unichar & 0x3f) + 0x80, unichar >>= 6) ;
    *buffer = ((0xfe << (7 - b)) & 0xff) | unichar;
    return b + 1;
  }
  else {
    buffer[1] = '\0';
    *buffer = unichar;
    return 2;
  }
}

int utf8_to_utf32(unsigned char *ss, uint32_t *i)
{
  /* Positive returns -> number of valid used bytes on an encoded, '\0' terminated, string
   * Negative returns -> negative of it is the number of valid encoded chars, the next one is invalid
   * (this facilitate string iteration)
   */
  uint32_t j;
  unsigned char *u;

  if (*ss >= 0x80) {  // UTF encoded and need more than 2 byte? (counting the '\0' ending)
    register short int n, b;  // number of encoded bytes (not including the '\0')

    /* decoding - we know how the bits are distributed, i.e., except for the 1st byte in ss,
     * all the remaining bytes must be 10xxxxxx, where each x can be 0 or 1
     */
    n = b = 2 + (*ss >= 0xe0) + (*ss >= 0xf0) + (*ss >= 0xf8) + (*ss >= 0xfc);
    if ((j = (*ss << b) & 0xff) < 0x80)
      for (ss++, j >>= b-- ; b > 0 && (*ss & 0xc0) == 0x80 ; b--, j = (j<<6) + (*ss++ & 0x3f)) ;
    if (b || UTF_INVALID(j))
      return b - n;
    if (i)
      *i = j;
    return n + 1;
  }
  else
    return 2; /* it means that 0 should be "\0" string */
}

inline
bool
is_valid_utf8(const char *ss, size_t len)
{
  return utf8_to_utf32((unsigned char *)ss, NULL) == len;
}

#ifdef UTF8_DEBUG
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <memory.h>

typedef unsigned char utf8buf_t[7];     /* old max number of multi-byte encoded utf8 bytes for chars (6) + '\0'
                                           (by current standard it is lower, 4 + '\0'; lets play safe) */

int
utf32_to_utf8_orig(uint32_t unichar, char *buffer)
{
  int count, shift, length;
  uint8_t head;

  if (unichar <= 0x007f) {
    buffer[0] = unichar;
    buffer[1] = '\0';
    return 2;
  }
  else if (unichar <= 0x07FF) {
    length = 2;
    head = 0xc0;
  }
  else if (unichar <= 0xffff) {
    length = 3;
    head = 0xe0;
  }
  else if (unichar <= 0x1fffff) {
    length = 4;
    head = 0xf0;
  }
  else if (unichar <= 0x3ffffff) {
    length = 5;
    head = 0xf8;
  }
  else {
    length = 6;
    head = 0xfc;
  }

  for (count = length - 1, shift = 0; count > 0; count--, shift += 6)
    buffer[count] = 0x80 | ((unichar >> shift) & 0x3f);

  buffer[0] = head | ((unichar >> shift) & 0x3f);
  buffer[length] = '\0';

  return length + 1;
}

bool
is_valid_utf8_orig(const char *ss, size_t len)
{
    size_t i = 0;
    size_t tail_bytes = 0;
    const uint8_t *s = (const uint8_t *) ss;

    /* This beauty is from:
     *  The Unicode Standard Version 6.2 - Core Specification, Table 3.7
     *  https://www.unicode.org/versions/Unicode6.2.0/ch03.pdf#G7404
     * We can optimize if needed. */
    while (i < len)
    {
        if (s[i] <= 0x7F) {
            tail_bytes = 0;
        }
        else if (s[i] >= 0xC2 && s[i] <= 0xDF) {
            tail_bytes = 1;
        }
        else if (s[i] == 0xE0) {
            i++;
            if (i >= len || !(s[i] >= 0xA0 && s[i] <= 0xBF))
                return false;
            tail_bytes = 1;
        }
        else if (s[i] >= 0xE1 && s[i] <= 0xEC) {
            tail_bytes = 2;
        }
        else if (s[i] == 0xED) {
            i++;
            if (i >= len || !(s[i] >= 0x80 && s[i] <= 0x9F))
                return false;
            tail_bytes = 1;
        }
        else if (s[i] >= 0xEE && s[i] <= 0xEF) {
            tail_bytes = 2;
        }
        else if (s[i] == 0xF0) {
            i++;
            if (i >= len || !(s[i] >= 0x90 && s[i] <= 0xBF))
                return false;
            tail_bytes = 2;
        }
        else if (s[i] >= 0xF1 && s[i] <= 0xF3) {
            tail_bytes = 3;
        }
        else if (s[i] == 0xF4) {
            i++;
            if (i >= len || !(s[i] >= 0x80 && s[i] <= 0x8F))
                return false;
            tail_bytes = 2;
        }
        else {
            return false;
        }

        i++;

        while (i < len && tail_bytes > 0 && s[i] >= 0x80 && s[i] <= 0xBF) {
            i++;
            tail_bytes--;
        }

        if (tail_bytes != 0)
            return false;
    }

    return true;
}

void benchmarks()
{
  int32_t i, j, k, m, n1, n2, r1, r2;
  utf8buf_t utf1, utf2;
  struct timespec t0, t1;
  double e1, e2;

  /* 1st case, current implementation
   */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t0);
  for (m = 0 ; m < 200 ; m++)
    for (i = 0, j = 0x010FFFF ; i <= j ; i++) {
      if (UTF32_INVALID(i))
        continue;
      k = utf32_to_utf8_orig(i, utf1);
    }
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
  fprintf(stderr, "* 1st case - current implementation: %le (secs)\n", e1 = difftime(t1.tv_sec, t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) * 1e-9);

  /* 2nd case, test implementation
   */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t0);
  for (m = 0 ; m < 200 ; m++)
    for (i = 0, j = 0x010FFFF ; i <= j ; i++) {
      if (UTF32_INVALID(i))
        continue;
      k = utf32_to_utf8(i, utf2);
    }
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
  fprintf(stderr, "* 2st case - test implementation: %le (secs)\n", e2 = difftime(t1.tv_sec, t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) * 1e-9);

  fprintf(stderr, "Ellapsed time variation (%%) on (1st - 2nd)/1st: %5.2lf %%\n\n", (e1 - e2)/e1 * 100);

  /* 3rd case, testing original is_valid_utf8
   */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t0);
  for (r1 = n1 = 0, m = 0 ; m < 100 ; m++)
    for (i = 0, j = 0x010FFFF ; i <= j ; i++) {
      if (UTF32_INVALID(i))
        continue;
      k = utf32_to_utf8_orig(i, utf1);
      if (! is_valid_utf8_orig(utf1, k)) {
        n1++;
        if (r1 != i >> 8) {
          // fprintf(stderr, "* 3rd case - validation error on: 0x%06lx\n", i);
          r1 = i >> 8;
        }
      }
    }
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
  fprintf(stderr, "* 3rd case - current utf8 validation: %le (secs),\n  %ld encoding errors\n", e1 = difftime(t1.tv_sec, t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) * 1e-9, n1);

  /* 4th case, testing proposed is_valid_utf8
   */
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t0);
  for (r2 = n2 = 0, m = 0 ; m < 100 ; m++)
    for (i = 0, j = 0x010FFFF ; i <= j ; i++) {
      if (UTF32_INVALID(i))
        continue;
      k = utf32_to_utf8(i, utf1);
      if (! is_valid_utf8(utf1, k)) {
        n2++;
        if (r2 != i >> 8) {
          // fprintf(stderr, "* 4th case - validation error on: 0x%06lx\n", i);
          r2 = i >> 8;
        }
      }
    }
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
  fprintf(stderr, "* 4th case - current utf8 validation: %le (secs),\n  %ld encoding errors\n", e2 = difftime(t1.tv_sec, t0.tv_sec) + (double)(t1.tv_nsec - t0.tv_nsec) * 1e-9, n2);

  fprintf(stderr, "Ellapsed time variation (%%) on (3rd - 4th)/3rd: %5.2lf %%\n\n", (e1 - e2)/e1 * 100);
}

void check_regressions()
{
  int32_t i, j, m, n, errs;
  utf8buf_t utf1, utf2;

  /* Literally, check all valid unicode code points
   */
  for (errs = 0, i = 0, j = 0x010FFFF ; i <= j ; i++) {
    if (UTF32_INVALID(i))
      continue;
    m = utf32_to_utf8_orig(i, utf1);
    n = utf32_to_utf8(i, utf2);
    if (strcmp(utf1, utf2) != 0 || m != n) {
      errs++;
      fprintf(stderr, "Mismatch for code point: 0x%07lx\n", i);
    }
  }
  fprintf(stderr, "Number of mismatched cases on 0..0x010FFFF range: %d\n\n", errs);
}

int main(int ac, char *av[])
{
  int32_t i, j, k;
  char *end;
  utf8buf_t ucs;

  for (i = 1 ; i < ac ; i++) {
    k = strtol(av[i], &end, 0);
    if (*av[i] == '\0' || *end != '\0') {
      fprintf(stderr, "Skipping malformed integer '%s'.\n", av[i]);
      continue;
    }
    //j = utf32(k);
    fprintf(stderr, "str '%s': keysym (%05lx) -> ucs (%05lx).\n", av[i], k, j);
  }
  fprintf(stderr, "\n");

  benchmarks();

  check_regressions();

  return 0;
}
#endif /* UTF8_DEBUG */
