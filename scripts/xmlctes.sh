#!/bin/bash
#
# Entities are extract from the following reference files (in https://www.w3.org/TR/xml-entity-names/): 
#    * All in Unicode order    - https://www.w3.org/TR/xml-entity-names/bycodes.html
#    * All in alphabetic order - https://www.w3.org/TR/xml-entity-names/byalpha.html
#
# Afer new specs are released, a rerun of this script will generate (hopefully) the updated "C" mappings
#
# awk would be a better tool for this job but now is too late.


init_consts () {
  NL='
'
  originals_dir=./

  # XML+ Entity sets
  #
  # llatin*             # Latin letter
  # lcyrillic*          # cyrillic letter
  # lgreek*             # greel letter
  # upcase*             # Upper case letter
  # locase*             # Lower case letter
  # compdiacs*          # composed letter with diacritics
  # compligat*          # composed letter with letter (ligature)
  # latinsymb*          # latin letters and symbols (punctuation, diacritics, ...)
  # mathsymb*           # math symbols
  # xmlplus*            # symbols that are not part of standard xml
  # combgrah*           # combined grapheme (like grapheme cluster)
  # bigcodep*           # big code point (>0xffff)
  # isobox              # Box and Line Drawing
  # isocyr1             # Russian Cyrillic
  # isocyr2             # Non-Russian Cyrillic
  # isodia              # Diacritical Marks
  # isolat1             # Added Latin 1
  # isolat2             # Added Latin 2
  # isonum              # Numeric and Special Graphic
  # isopub              # Publishing
  # isoamsa             # Added Math Symbols: Arrow Relations
  # isoamsb             # Added Math Symbols: Binary Operators
  # isoamsc             # Added Math Symbols: Delimiters
  # isoamsn             # Added Math Symbols: Negated Relations
  # isoamso             # Added Math Symbols: Ordinary
  # isoamsr             # Added Math Symbols: Relations
  # isogrk1             # Greek Letters  (not in MathML3 / HTML5)
  # isogrk2             # Monotoniko Greek  (not in MathML3 / HTML5)
  # isogrk3             # Greek Symbols
  # isogrk4             # Alternative Greek Symbols  (not in MathML3 / HTML5)
  # isomfrk             # Math Alphabets: Fraktur
  # isomopf             # Math Alphabets: Open Face
  # isomscr             # Math Alphabets: Script
  # isotech             # General Technical
  # mmlextra            # Additional MathML Symbols
  # mmlalias            # MathML Aliases
  # xhtml1_lat1         # Latin for HTML
  # xhtml1_special      # Special for HTML
  # xhtml1_symbol       # Symbol for HTML
  # html5_uppercase     # uppercase aliases for HTML
  # predefined          # Predefined XML
  # * : our internal use

  # constants used on hashing (not really a real hashing as we
  # specifically preserve the sort order and used only the 2
  # first bytes)
  #
  aa=$( LC_CTYPE=C printf '%d' "'a" )
  AA=$( LC_CTYPE=C printf '%d' "'A" )
  d0=$( LC_CTYPE=C printf '%d' "'0" )
  I0=1
  I1=3


  # instead of printing the code point, we print the offset of entities
  # on xmlp_entitties_map and, as so, have access to the complete tags
  # of them without further searching (but at cost of 1 more indirection)
  #
  print_code_points=
  if [ "${print_code_points,}" = y ]; then tt=ucsm_t ; else tt=int16_t ; fi

  # enlarge a bit the generated xmlp_entities_map table to reduce a lot of
  # time in processing
  #
  print_utf_encoded=y

  rval= # for functions that must return more than just an integer
}

gen_import () {
  #
  # Import the files used in this script
  #
  cat "${originals_dir}/byalpha.html" |\
  sed -n '    /<pre>/! b; s!.*<pre>!!;                      # wind through until reach the sart of data of interest
          :1; $ q;
              s!<a[^>]\+>\s*\(\([uU]+[[:xdigit:]]\{3,\}\s*\)\+\)</a>!\1!;  # links to images; not useful for us
              /\b[uU]+[[:xdigit:]]\{3,\}\b/! {N; b1};       # complete the thing 1 (i.e., should not process it with sed!)
              /\b[uU]+[[:xdigit:]]\{3,\}\s*,\?\s*$/ N;      # complete the thing 2 (i.e., should not process it with sed!)
              s!\s\+! !g;                                   # get ride of extra spaces
              /<\/pre>/ b2;                                 # marks the end of data of interest
              /^\s*$/ b1;                                   # print if not empty
              p; n; b1;                                     # next line
          :2; s!</pre>.*!!;
              /^\s*$/ q;
              p; q;                                         # the end' |\
  LC_COLLATE=C sort -- > xml-byalpha-raw.txt

  i=$( cat xml-byalpha-raw.txt | wc -l )

  # parse a bit the data and reord the files to <name>,<code point>,;<classes> \t <description> \a <Unicode descriptioin>
  # apart from what xml already give, we added 'upcase' (UPCASE - upper case letters), 'locase' (LOCASE - lower case letters),
  # 'llatin' (LLATIN - latin letter), compdiacs (COMPDIACS - letter with diacritics) and complig (COMPLIG - ligatures).
  # These are things we plan to use on another project and adds no cost to the current. We reserve compegc (COMPEGC - composed
  # extended grapheme cluster) for future use
  #
  cat xml-byalpha-raw.txt |\
  sed -n 's!^\([[:alpha:]][[:alnum:].]\+\),[^,]*,\s*\([[:alnum:] -]*[[:alnum:]]\)\s*,\s*\(\(.*\S\)\s*\|\),\s*\(\([uU]+\([[:xdigit:]]\+\)\s*\)\+\),!\1,\5,;\2\t\4 \a !; # parse: name,code,;classes\t description \a unicode description
          T;  # Try to detect errors

          # upper case letter?
          /\t.*\b\(capital\s\+letter\|\(script\|fraktur\|black-letter\|double-struck\|bold\|cyrillic\|greek\)\s\+capital\|capital\s\+ligature\)\b/I {s|\t| upcase&|};

          # lower case letter?
          /\t.*\b\(small\s\+letter\|\(script\|fraktur\|black-letter\|double-struck\|bold\|cyrillic\|greek\)\s\+small\|small\s\+ligature\)\b/I {s|\t| locase&|};

          # latin letter?
          /\t.*\b\(latin\b.*\bletter\|\(script\|fraktur\|black-letter\|double-struck\)\b.*\b\(capital\|small\)\)\b/I {s|\t| llatin&|};

          # greek letter?
          /\(\bisogrk[1-4]\|\t.*\bgreek\b.*\bletter\)\b/I {s|\t| lgreek&|};

          # cyrillic letter?
          /\(\bisocyr[1-2]\|\t.*\bcyrillic\b.*\bletter\)\b/I {s|\t| lcyrillic&|};

          # composed letter with diacritics?
          /\t.*\b\(letter\b.*\bwith\b.*\b\(acute\|breve\|caron\|cedilla\|circumflex\|diaeresis\|dialytika\|dot\|grave\|macron\|ogonek\|ring\|stroke\|tilde\|tonos\)\)\b/I {s|\t| compdiacs&|};

          # latin symbol? (letters, punctuations, ..)
          /\b\(isolat[12]\)\b/I {s|\t| latinsymb&|};

          # math symbol?
          /\b\(isoams[abcnor]\|isom\(frk\|opf\|scr\)\|isotech\|mml\(extra\|alias\)\)\b/I {s|\t| mathsymb&|};

          # XML predefined symbol?
          /\b\(predefined\|html5[_-]uppercase\)\b/I {s|\b\(html5\)[_-]\(uppercase\)\b|\1_\2|i; s|\t| xmlsymb&|};

          # XHTML symbol?
          /\bxhtml1[_-]\(lat1\|special\|symbol\)\b/I {s/\b\(xhtml1\)[_-]\(lat1\|special\|symbol\)\b/\1_\2/i; s|\t| xhtmlsymb&|};

          # ligature? for fjlig we may, perhaps, use dotless j instead of the default, i.e., fj -> fȷ (U+0237)
          /\t.*\b\(ligature\)\b/I {s|\t| compligat&|; /^fjlig,/ {s|\t| locase&|}};

          # grapheme cluster?
          /\([uU]+[[:xdigit:]]\+[[:space:],]\+\)\{2,\}/I {s|\(\([uU]+[[:xdigit:]]\+\)[[:space:],]\+\)|\2,|ig; s|\s*,;| ,;|; s|\t| combgraph&|};

          # big code point?
          /[uU]+[[:xdigit:]]\{5,\}\b/I {s|\t| bigcodept&|};

          # translate to hexadecimal constants in C
          s|[uU]+\([[:xdigit:]]\+\b\)|0x\1|ig; p' \
  > xml-byalpha.txt

  # inform if problems were found on parsing process
  #
  j=$( cat xml-byalpha-raw.txt | wc -l )
  [ $i -ne $j ] \
    && echo -e "($FUNCNAME:$LINENO) - Errro on number of lines of processed input 'byalpha.html' file." \
    && exit 0

  # inform if problems were found on classification
  #
  t1=$( cat xml-byalpha.txt | grep -iEe "upcase.*locase|iso(grk|cyr).*llatin" )
  [ ${#t1} -gt 0 ] \
    && echo -e "($FUNCNAME:$LINENO) - Errro on character classes of 'byalpha.html' file.\n'\n$t1\n'\n" \
    && exit 0
}

expand_grapheme () {
  # deal with combined graphemes
  #
  local ncg=${1//[!xX]/} fmt=$2 sub=$3 j

  ncg=${#ncg}
  if [ $ncg -ge 2 ]; then
    rval=$( echo "$1" | sed -n 's!\(\s*\(\b0[xX][[:xdigit:]]\+\b\)\([[:space:],]\+\|\)\)!.u2[#]=\2, !g; s|[[:space:],]\+$||; s|.*|{&}|; T; p' )
    for ((j=0 ; j < ncg ; j++)); do
      rval=${rval/[#]/$j}
    done
    rval="$rval${1##*[[:alnum:].]}"
  else
    fmt=$((fmt - sub))
    [ "$fmt" -le 0 ] && fmt=
    printf -v rval '%#'$fmt'X%s' ${1//[ ,]/} "${1##*[[:alnum:].]}"
    rval=${rval/X/x}
    rval=${rval/ 0x/0x0}
  fi
}

print_element () {
  local dif=$1 i=$2 cf=$3 div=$4 fmt=$5 cc ch j te aux

  te=
  [ $(((i + 1) % div)) = 0 ] && te=$NL

  cc=${cf#*[#_]}
  cc=${cc%%[#_]*}
  ch=${cf##*[#_]}
  cf="${cf%/*}/"
  cf=${cf//#/ }
  if [ "${print_code_points,}" = y ]; then
    expand_grapheme "$ch" "$fmt" "${#cf}"; ch=$rval
  else
    if [ "${ch:0:1}" != '-' ]; then
      j=$( cat xml-byalpha.txt | sed -n "/^$cc$dif,/ =;" )
      j=$((j - 1)) # offset inside the vector
      [ "$j" -lt 0 ] \
        && echo -e "Invalid offset for '$cc$dif,'" \
        && exit 0
    else
      j=${ch%,*}
    fi
    fmt=$((fmt - ${#cf}))
    [ "$fmt" -le 0 ] && fmt=
    printf -v ch '%'$fmt'd%s' $j "${ch##*[[:alnum:].]}"
  fi
  printf '  %s %s%s' "$cf" "$ch" "$te"
}

print_latin_diacs () {
  #
  # Latin with diacritics
  #
  echo -e "/*\n * Latin chars with diacritics\n */"
  for dif in acute: breve: caron: cedil:cedilla circ:circumflex dblac:dblacute dot: grave: macr:macron ogon:ogonek ring: strok:stroke tilde: uml:; do

    # collect all latin chars with specific diacritical mark
    #
    t1=$( cat xml-byalpha.txt | \
          sed -n '/^\([[:alpha:]]'${dif%:*}'\),/! b;
                  /^[ost]dot,/d;                          # remove what isnt latin char with diacritics
                  s|;.*||; p' )

    # 1st chars will be used as index
    #
    ch=$( echo "$t1" | sed -n 's|^\([[:alpha:]]\)'${dif%:*}',.*|\1|; T; p' )

    # save entities names for future name filtering (not in use right now)
    #
    dia=$( echo "$t1" | sed -n 's|^\([[:alpha:]]'${dif%:*}'\),.*|\1|; T; p' )
    ent="$ent${ent:+$NL}$dia"

    # unabbreviated diacritical name
    #
    dia=${dif#*:} && [ ${#dia} = 0 ] && dia=${dif%:*}

    # print C map vector name
    #
    j=$( echo "$t1" | wc -l )
    printf 'const char xmlp_latin_%s_ch[] = "%s"; /* %s chars */\n' $dia "${ch//[[:cntrl:][:space:]]/}" $j

    # now the translation table (we print the size of it to double check)
    #
    t1=$( echo "$t1" | sed -n 's|^\([[:alpha:]]\)'${dif%:*}',|/*#\1#*/#|; T; p' )
    t1=${t1//[[:cntrl:]]/ }
    t1=${t1// , /, }
    t1=${t1%,*}        # will leave all ',' except the last one

    printf '%s xmlp_latin_%s_map[sizeof(xmlp_latin_%s_ch)] = { /* %s integers */\n' $tt $dia $dia $j

    i=0
    for ch in $t1; do
      print_element "${dif%:*}" "$i" "$ch" 5 16
      i=$((i + 1))
    done
    if [ $((i % 5)) = 0 ]; then te= ; else te=$NL ; fi
    printf '%s};\n\n' "$te"
  done
}

print_styles_langs () {
  #
  # Styles / languages
  #
  echo -e "/*\n * Styles / languages\n */"
  for dif in cy:cyrillic fr:latin_fraktur gr:greek lig:latin_ligature opf:latin_openface scr:latin_script; do

    # collect all styles/languages with 1 ch leading
    #
    t1=$( cat xml-byalpha.txt | \
          sed -n '/^\([[:alpha:]]'${dif%:*}'\),/! b;
                  s|;.*||; p' )

    # collect all styles/languages with more than 1 ch leading
    #
    tn=$( cat xml-byalpha.txt | \
          sed -n '/^\([[:alpha:]][[:alnum:]]\+'${dif%:*}'\),/! b;
                  /^\(SZ\|sz\)lig,/d;                               # remove what isnt a ligature
                  s|;.*||; p' )

    # initial substrings will be used as index (1 ch leading will use direct map)
    #
    [ ${#tn} -gt 0 ] \
      && sn=$( echo "$tn" | sed -n 's|^\([[:alnum:]]\+\)'${dif%:*}',.*|\1,|; T; p' | xargs -r printf '%-5s' ) \
      && sn=${sn// /,}

    # save entities names for future name filtering
    #
    [ ${#t1} -gt 0 ] \
      && dia=$( echo "$t1" | sed -n 's|^\([[:alnum:]]\+'${dif%:*}'\),.*|\1|; T; p' ) \
      && ent="$ent${ent:+$NL}$dia"
    [ ${#tn} -gt 0 ] \
      && dia=$( echo "$tn" | sed -n 's|^\([[:alnum:]]\+'${dif%:*}'\),.*|\1|; T; p' ) \
      && ent="$ent${ent:+$NL}$dia"

    # unabbreviated names
    #
    dia=${dif#*:} && [ ${#dia} = 0 ] && dia=${dif%:*}
    j=$( echo "$tn" | wc -l )
    [ ${#tn} -gt 0 ] \
      && printf 'const char xmlp_%s_str[] = "%s"; /* %s tokens */\n' $dia "${sn//[[:cntrl:][:space:]]/}" $j

    ch=
    for s1 in {A..Z} {a..z}; do ch="$ch$s1"; done

    printf '%s xmlp_%s_map[%s%s] = { /* %s integers */\n' $tt $dia "${t1:+52}" "${tn:+${t1:+ + }sizeof(xmlp_${dia}_str)/5}" $((${t1:+ 52 +} ${tn:+ $j} + 0))

    # print first what will have direct map
    #
    if [ ${#t1} -gt 0 ]; then
      t1=$( echo "$t1" | sed -n 's|^\([[:alnum:]]\+\)'${dif%:*}',|/*#\1#*/#|; T; p' )
      t1=${t1//[[:cntrl:]]/ }
      t1=${t1// , /, }
      t1=${t1// ,/,}
      [ ${#tn} -eq 0 ] \
        && t1=${t1%,*}

      i=0
      for s1 in $t1; do
        # not mapped entities must be flagged
        #
        while [ "${s1:3:1}" != "${ch:i:1}" ]; do
          if [ "${print_code_points,}" = y ]; then inv=0 ; else inv=-1 ; fi
          print_element "${dif%:*}" "$i" "/*_${ch:$((i++)):1}_*/#$inv," 5 16
        done
        print_element "${dif%:*}" "$i" "$s1" 5 16
        i=$((i + 1))
      done
    fi

    # print what must be searched as tokens
    #
    if [ ${#tn} -gt 0 ]; then
      tn=$( echo "${tn#*,}" | sed -n 's|^\([[:alnum:]]\+\)'${dif%:*}',|/*#\1#*/#|; T; p' )
      tn=${tn//[[:cntrl:]]/ }
      tn=${tn// , /, }
      tn=${tn%,*}
      [ ${#t1} -gt 0 ] \
        && printf '\n'

      i=0
      for sn in $tn; do
        print_element "${dif%:*}" "$i" "$sn" 5 16
        i=$((i + 1))
        # te=
        # [ $((i++ % 5)) = 4 ] && te=$NL
        # printf '  %-18s%s' "${sn//#/ }" "$te"
      done
    fi
    if [ $((i % 5)) = 0 ]; then te= ; else te=$NL ; fi
    printf '%s};\n\n' "$te"
  done
}

hash_str () {
  #
  # Use the first 2 bytes of an ascii string to create hashes following C sorting order;
  # string must has first char as ascii alpha and the rest can only be [[:alnum:].]
  #
  i1=$( LC_CTYPE=C printf '%d' "'${1:1:1}" )
  if [ $i1 -ge $AA ]; then if [ $i1 -ge $aa ]; then i1=$((2 + ((i1 - aa + I1) >> 4))); else i1=$((1 + ((i1 - AA + I1) >> 4))); fi; else if [ $i1 -ge $d0 ]; then 1; else i1=0; fi; fi
  i0=$( LC_CTYPE=C printf '%d' "'${1:0:1}" )
  if [ $i0 -ge $aa ]; then i0=$((((i0 - aa + 26 + I0) << 2) + i1)) ; else i0=$((((i0 - AA + I0) << 2) + i1)) ; fi
  return $i0
}

print_entities () {
  #
  # Print all entities
  #
  local aux i j jj dh h0 h1

  echo -e "/*\n * Entities${1:+ filtered}\n */"

  # just in case we may want to reduce the table size; not in use right now
  #
  [ ${#ent} -eq 0 ] \
    && ent=ABCDEF  # of course, it is something that doesn't exist on our list

  # remove the descriptions as we don't use them; also convert the xml <classes>
  # to upper case
  #
  t1=$( cat xml-byalpha.txt |\
        sed -n 's|\t.*||; s|\s*,;\s*\(.*\)|:#\U\1\E|; p' ${1:+ | grep -vwhF "$ent"} )
  tn=$( echo "$t1" |\
        sed -n 's|^\([[:alnum:].]\+\),.*|\1|; p' )

  # print C map vector name
  #
  j=$( echo "$t1" | wc -l)
  printf 'xmlp_map_t xmlp_entities_map[] = { /* %s integers */\n' $j

  # now the translation table
  #
  t1=$( echo "$t1" | sed -n 's|^\([[:alnum:].]\+\),\(.*\)|"\1",#\2},|;
                             s=\b \b= | =g;
                             T;
                             s| \+$||;
                             s| \+}|}|g;
                             s| \+|#|g; p' )
  t1=${t1//[[:cntrl:]]/ }
  t1=${t1// , /, }
  t1=${t1%,*}

  aux=
  i=0
  for ch in $t1; do
    ch=${ch//#/ }
    rval=${ch#*,}
    rval=${rval%:*}
    expand_grapheme "$rval" 0 1
    if [ "${print_utf_encoded,}" = y ]; then
      aux=$( for aux in ${rval//[\{\},]/ }; do aux=${aux##*=}; echo -en "${aux/0x/\\U}"; done )
      if [ "$aux" = '"' ]; then
          aux='\\"'
      elif [ "$aux" = '\' ]; then
          aux='\\\\'
      fi
      aux=$( echo -en " \"$aux\",")
    fi
    te=
    [ $((i++ % 1)) = 0 ] && te=$NL
    printf '  {%s, %s,%s%s%s' "${ch%%,*}" "$rval" "$aux" "${ch#*:}" "$te"
  done
  if [ ${#te} = 1 ]; then te= ; else te=$NL ; fi
  printf '%s};\n\n' "$te"

  # print the range bounds
  #
  printf 'int16_t xmlp_map_bounds[] = {\n' $j

  # uncomment to test deviation
  #
  dh=
  jj=0

  h0=0
  h1=0
  i=0
  j=0
  for ch in $tn; do
    hash_str $ch ; h1=$?

    # check if new range bounds must be printed
    #
    if [ $h1 -ge $h0 ]; then

      # values inside this range compose empty sets
      # {'j' the master table index gets repeated and, as so,
      #  (<bounds>[k+1] - 1) - (<bounds>[k]) == -1 -> empty set}
      #
      for (( ; h0 < h1 ; h0++)); do
        te=
        [ $((i++ % 5)) = 4 ] && te=$NL
        printf '  /* %3d */  %4d,%s' $h0 $j "$te"

        # uncomment to test deviation
        #
        dh="$dh${dh:+ }$((j - jj))"
        jj=$j
      done
      h0=$((h1 + 1))
      te=
      [ $((i++ % 5)) = 4 ] && te=$NL
      printf '  /* %3d */  %4d,%s' $h1 $j "$te"

      # uncomment to test deviation
      #
      dh="$dh${dh:+ }$((j - jj))"
      jj=$j
    fi
    j=$((j+1))
  done

  # print the upper limit of our hash to full span
  # the possible values
  #
  hash_str "zz"; h1=$?
  for ((h1++ ; h0 < h1 ; h0++)); do
    te=
    [ $((i++ % 5)) = 4 ] && te=$NL
    printf '  /* %3d */  %4d,%s' $h0 $j "$te"

    # uncomment to test deviation
    #
    dh="$dh${dh:+ }$((j - jj))"
    jj=$j
  done
  te=
  [ $((i++ % 2)) = 1 ] && te=$NL
  printf '  /* %s */  %4d%s' END $j "$te"
  if [ ${#te} = 1 ]; then te= ; else te=$NL ; fi
  printf '%s};\n\n' "$te"

  # uncomment to test deviation
  printf '/* Entities names/interval\n'
  i=0
  for ch in $dh $((j - jj)); do
    te=
    [ $((i++ % 20)) = 19 ] && te=$NL
    printf '%4d%s' $ch "$te"
  done
  if [ ${#te} = 1 ]; then te= ; else te=$NL ; fi
  printf '%s*/\n\n' "$te"
}

# main :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

init_consts

# Generate the general import files from original files
#
gen_import

ent=
printf '%s\n%s\n%s\n *\n%s\n */\n\n' \
       '/* This file is automatically generated by scripts/xmlctes.sh.' \
       ' * Please, do not edit it directly because all hand customizations will be lost.' \
       ' * Any change must be done directly on cited script.' \
       ' * Author: Andre Barros (andre.cbarros@yahoo.com)'

printf '#ifndef XKB_XMLP_PRIV_H\n#define XKB_XMLP_PRIV_H\n\n'

printf '#include "xmlp.h"\n\n'

if [ "${print_code_points,}" = y ]; then 
  printf '/* Using code points on auxiliary tables\n */\n'
  printf '#define XKB_XMLP_USES_OFFSETS 0\n\n'
else
  printf '/* Using offsets to xmlp_entities_map on auxiliary tables gives access to all tags\n * associated to each entity at cost of 1 more indirection\n */\n'
  printf '#define XKB_XMLP_USES_OFFSETS 1\n\n'
fi
print_latin_diacs

print_styles_langs

print_entities

printf '#endif /* XKB_XMLP_PRIV_H */\n'

# echo "$ent" | wc -l
