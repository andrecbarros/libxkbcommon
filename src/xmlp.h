/* Almost nothing to see here as I am still testing what I think may be
 * a useful interface
 *
 * Author: Andre C. Barros (andre.cbarros@yahoo.com)
 */

#ifndef XMLP_H
#define XMLP_H

#include <inttypes.h>

#ifndef XKB_XMLP_UTF_PREENCODED
#define XKB_XMLP_UTF_PREENCODED 1
#endif

enum xmlp_entity_tags_e { /* XML+ entities set, i.e. XML with additions - list of current tags */
  LLATIN =                1<<4, /*         16 - Latin letter */

  ISOBOX =                1<<5, /*         32 - Box and Line Drawing */

  LCYRILLIC =             1<<6, /*         64 - Cyrillic letter */
  ISOCYR1 =                 65, /*              Russian Cyrillic */
  ISOCYR2 =                 66, /*              Non-Russian Cyrillic */
  ISODIA  =               1<<7, /*        128 - Diacritical Marks */

  LATINSYMB =             1<<8, /*        256 - Latin symbols and letters */
  ISOLAT1 =                257, /*              Added Latin 1 */
  ISOLAT2 =                258, /*              Added Latin 2 */
  ISONUM =                1<<9, /*        512 - Numeric and Special Graphic */
  ISOPUB =               1<<10, /*       1024 - Publishing */

  MATHSYMB =             1<<11, /*       2048 - Math symbol */
  ISOAMSA =               2049, /*              Added Math Symbols: Arrow Relations */
  ISOAMSB =               2050, /*              Added Math Symbols: Binary Operators */
  ISOAMSC =               2051, /*              Added Math Symbols: Delimiters */
  ISOAMSN =               2052, /*              Added Math Symbols: Negated Relations */
  ISOAMSO =               2053, /*              Added Math Symbols: Ordinary */
  ISOAMSR =               2054, /*              Added Math Symbols: Relations */
  ISOMFRK =      (1<<4) + 2055, /*       2071 - Math Alphabets: Fraktur */
  ISOMOPF =               2072, /*              Math Alphabets: Open Face */
  ISOMSCR =               2073, /*              Math Alphabets: Script */
  MMLEXTRA = (1<<11) + (1<<12), /*       6144 - Additional MathML Symbols */
  MMLALIAS = (1<<11) + (1<<13), /*      10240 - MathML Aliases */
  ISOTECH =  (1<<11) + (1<<14), /*      18432 - General Technical */

  LGREEK =               1<<15, /*      32768 - Greek letter */
  ISOGRK1 =              32769, /*              Greek Letters  (not in MathML3 / HTML5) */
  ISOGRK2 =              32770, /*              Monotoniko Greek  (not in MathML3 / HTML5) */
  ISOGRK3 =              32771, /*              Greek Symbols */
  ISOGRK4 =              32772, /*              Alternative Greek Symbols  (not in MathML3 / HTML5) */

  XMLSYMB =              1<<16, /*      65536 - XML/HTML predefined */
  PREDEFINED =           65537, /*              Predefined XML */
  HTML5_UPPERCASE =      65538, /*              Uppercase aliases for HTML */

  XHTMLSYMB =                            1<<17, /*  131072 - XHTML symbols */
  XHTML1_LAT1 =              (1<<17) + (1<<18), /*           Latin for HTML */
  XHTML1_SPECIAL =           (1<<17) + (1<<19), /*           Special for HTML */
  XHTML1_SYMBOL  = (1<<17) + (1<<18) + (1<<19), /*           Symbol for HTML */

  UPCASE =     1<<20, /* Upper case letter */
  LOCASE =     1<<21, /* Lower case letter */
  COMPDIACS =  1<<22, /* composed letter with diacritics */
  COMPLIGAT =  1<<23, /* composed letter with letter (ligature) */
  COMBGRAPH =  1<<24, /* combined grapheme (grapheme cluster) */
  BIGCODEPT =  1<<25, /* graphme with code point > 0xFFFF */

  XMLPLUS =    1<<30, /* Not in default xml standard */
};

typedef union ucsm {
  uint32_t   u4;     /* utf32 code point */
  uint16_t   u2[2];  /* cluster with up to 2 code points <= 0xffff, the constants we deal with don't use big code points for clustered graphemes */
} ucsm_t;

typedef struct xmlp_map {
  const char * name; /* entity name */
  ucsm_t       codept;
#if XKB_XMLP_UTF_PREENCODED
  const char * utf;
#endif
  uint32_t     tag;    /* a combination of tags present on xmlp_entity_tags_e */
} xmlp_map_t;


#endif /* XMLP_H */
