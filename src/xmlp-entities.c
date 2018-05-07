/* Almost nothing to see here as I am still testing what I think may be
 * a useful interface
 *
 * Author: Andre C. Barros (andre.cbarros@yahoo.com)
 */
#include <stddef.h>
#include <stdlib.h>
#include <inttypes.h>
#include "xmlp.h"
#include "xmlp-priv.h"

int main(int ac, char *av[])
{
  const xmlp_map_t a[] = {{"a", {.u2[0] = 12, .u2[1] = 11}, "a", 0}, {"b", {.u4 = 14}, "b", 12}};

  exit(0);
}
