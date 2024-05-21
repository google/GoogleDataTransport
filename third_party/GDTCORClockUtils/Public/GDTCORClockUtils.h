#include <stdint.h>

/** Returns the kernel boottime property from sysctl.
 *
 * Inspired by https://stackoverflow.com/a/40497811
 *
 * @return The KERN_BOOTTIME property from sysctl, in nanoseconds.
 */
int64_t GDTCORKernelBootTimeInNanoseconds(void);

/** Returns value of gettimeofday, in nanoseconds.
 *
 * Inspired by https://stackoverflow.com/a/40497811
 *
 * @return The value of gettimeofday, in nanoseconds.
 */
int64_t GDTCORUptimeInNanoseconds(void);
