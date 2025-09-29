#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8   #to ensure the accents are being dealt with properly
file="${1:-/path/to/your/file}"

awk -F" - " '
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }

{
  c1 = trim($1)
  c2 = (NF >= 2 ? trim($2) : "")
  if (NF >= 3) {
    c3 = trim($3)
    for (i = 4; i <= NF; i++) c3 = c3 " - " trim($i)
  } else c3 = ""

  a1[NR] = c1; a2[NR] = c2; a3[NR] = c3
  if (length(c1) > m1) m1 = length(c1)
  if (length(c2) > m2) m2 = length(c2)
  if (length(c3) > m3) m3 = length(c3)
}
END {
  if (NR == 0) exit

  fmt = "%-" m1 "s | %-" m2 "s | %-" m3 "s\n"
  sample = sprintf(fmt, "", "", "")
  total = length(sample)

  title = " CALENDARIO "
  tlen = length(title)
  left = int((total - tlen) / 2)
  right = total - tlen - left
  padL = ""; padR = ""
  for (i = 0; i < left; i++) padL = padL "="
  for (i = 0; i < right; i++) padR = padR "="
  print padL title padR

  for (i = 1; i <= NR; i++) printf fmt, a1[i], a2[i], a3[i]
}
' "$file"
