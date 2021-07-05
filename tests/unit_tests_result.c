/** \file tests/unit_tests.c
 *
 * Generated file: .build/unit_tests.c
 */

#include <assert.h>

int main(void)
{
    /* cos */
    assert(fabs(cos(-3.141593) - -1.000000) < 1e-6);
    assert(fabs(cos(-2.748894) - -0.923880) < 1e-6);
    assert(fabs(cos(-2.356194) - -0.707107) < 1e-6);
    assert(fabs(cos(-1.963495) - -0.382683) < 1e-6);
    assert(fabs(cos(-1.570796) - 0.000000) < 1e-6);
    assert(fabs(cos(-1.178097) - 0.382683) < 1e-6);
    assert(fabs(cos(-0.785398) - 0.707107) < 1e-6);
    assert(fabs(cos(-0.392699) - 0.923880) < 1e-6);
    assert(fabs(cos(0.000000) - 1.000000) < 1e-6);
    assert(fabs(cos(0.392699) - 0.923880) < 1e-6);
    assert(fabs(cos(0.785398) - 0.707107) < 1e-6);
    assert(fabs(cos(1.178097) - 0.382683) < 1e-6);
    assert(fabs(cos(1.570796) - 0.000000) < 1e-6);
    assert(fabs(cos(1.963495) - -0.382683) < 1e-6);
    assert(fabs(cos(2.356194) - -0.707107) < 1e-6);
    assert(fabs(cos(2.748894) - -0.923880) < 1e-6);
    assert(fabs(cos(3.141593) - -1.000000) < 1e-6);

    /* sin */
    assert(fabs(sin(-3.141593) - -0.000000) < 1e-6);
    assert(fabs(sin(-2.748894) - -0.382683) < 1e-6);
    assert(fabs(sin(-2.356194) - -0.707107) < 1e-6);
    assert(fabs(sin(-1.963495) - -0.923880) < 1e-6);
    assert(fabs(sin(-1.570796) - -1.000000) < 1e-6);
    assert(fabs(sin(-1.178097) - -0.923880) < 1e-6);
    assert(fabs(sin(-0.785398) - -0.707107) < 1e-6);
    assert(fabs(sin(-0.392699) - -0.382683) < 1e-6);
    assert(fabs(sin(0.000000) - 0.000000) < 1e-6);
    assert(fabs(sin(0.392699) - 0.382683) < 1e-6);
    assert(fabs(sin(0.785398) - 0.707107) < 1e-6);
    assert(fabs(sin(1.178097) - 0.923880) < 1e-6);
    assert(fabs(sin(1.570796) - 1.000000) < 1e-6);
    assert(fabs(sin(1.963495) - 0.923880) < 1e-6);
    assert(fabs(sin(2.356194) - 0.707107) < 1e-6);
    assert(fabs(sin(2.748894) - 0.382683) < 1e-6);
    assert(fabs(sin(3.141593) - 0.000000) < 1e-6);

    /* tan */
    assert(fabs(tan(-3.141593) - 0.000000) < 1e-6);
    assert(fabs(tan(-2.748894) - 0.414214) < 1e-6);
    assert(fabs(tan(-2.356194) - 1.000000) < 1e-6);
    assert(fabs(tan(-1.963495) - 2.414214) < 1e-6);
    assert(fabs(tan(-1.178097) - -2.414214) < 1e-6);
    assert(fabs(tan(-0.785398) - -1.000000) < 1e-6);
    assert(fabs(tan(-0.392699) - -0.414214) < 1e-6);
    assert(fabs(tan(0.000000) - 0.000000) < 1e-6);
    assert(fabs(tan(0.392699) - 0.414214) < 1e-6);
    assert(fabs(tan(0.785398) - 1.000000) < 1e-6);
    assert(fabs(tan(1.178097) - 2.414214) < 1e-6);
    assert(fabs(tan(1.963495) - -2.414214) < 1e-6);
    assert(fabs(tan(2.356194) - -1.000000) < 1e-6);
    assert(fabs(tan(2.748894) - -0.414214) < 1e-6);
    assert(fabs(tan(3.141593) - -0.000000) < 1e-6);

    return EXIT_SUCCESS;
}
