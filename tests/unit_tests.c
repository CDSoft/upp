/** \file $(input_files())
 *
 * Generated file: $(output_file())
 */

#include <assert.h>

:(  local n = 8
    angles = F.map(function(i) return i*pi/n end, F.range(-n, n))
)

int main(void)
{
    /* cos */
    $(test_f1 "cos" (angles))

    /* sin */
    $(test_f1 "sin" (angles))

    /* tan */
    $(test_f1 "tan" (F.filter(function(a) return abs(abs(a)-pi/2) > 1e-4 end, angles)))

    return EXIT_SUCCESS;
}
