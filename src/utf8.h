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
 * Author: Rob Bradford <rob@linux.intel.com>
 */

#ifndef XKBCOMMON_UTF8_H
#define XKBCOMMON_UTF8_H

/* It is recommended that XKBCOMMON_UNICODE_COMPAT be defined as 0 so that new code
 * is future proof about valid Unicode code points; on newer versions of libxkbcommon
 * it may be flipped to 0 as default
 */

#ifndef XKBCOMMON_UNICODE_COMPAT
#define XKBCOMMON_UNICODE_COMPAT 1
#endif

#if XKBCOMMON_UNICODE_COMPAT == 1
#define UTF32_STRICT 0
#else
#define UTF32_STRICT 1
#endif

#define UTF_INVALID(ch)   ((ch) >= 0x00110000 || ((ch) >= 0xd800 && (ch) <= 0xdfff))
#if UTF32_STRICT
#define UTF32_FRONTIER    0x00110000
/* surrogates are not allowed in strict utf8 or utf32 encoding */
#define UTF32_INVALID(ch) UTF_INVALID(ch)
#else
#define UTF32_FRONTIER    0x80000000
#define UTF32_INVALID(ch) ((ch) >= UTF32_FRONTIER)
#endif
#define UTF32_MAX         (UTF32_FRONTIER - 1)

int
utf32_to_utf8(uint32_t unichar, char *buffer);

bool
is_valid_utf8(const char *ss, size_t len);

#endif
