#import <sys/sysctl.h>

#include <dispatch/time.h>

// Using a monotonic clock is necessary because CFAbsoluteTimeGetCurrent(), NSDate, and related all
// are subject to drift. That it to say, multiple consecutive calls do not always result in a
// time that is in the future. Clocks may be adjusted by the user, NTP, or any number of external
// factors. This class attempts to determine the wall-clock time at the time of the event by
// capturing the kernel start and time since boot to determine a wallclock time in UTC.
//
// Timezone offsets at the time of a snapshot are also captured in order to provide local-time
// details. Other classes in this library depend on comparing times at some time in the future to
// a time captured in the past, and this class needs to provide a mechanism to do that.
//
// TL;DR: This class attempts to accomplish two things: 1. Provide accurate event times. 2. Provide
// a monotonic clock mechanism to accurately check if some clock snapshot was before or after
// by using a shared reference point (kernel boot time).
//
// Note: Much of the mach time stuff doesn't work properly in the simulator. So this class can be
// difficult to unit test.

/** Returns the kernel boottime property from sysctl.
 *
 * Inspired by https://stackoverflow.com/a/40497811
 *
 * @return The KERN_BOOTTIME property from sysctl, in nanoseconds.
 */
int64_t GDTCORKernelBootTimeInNanoseconds(void) {
  // Caching the result is not possible because clock drift would not be accounted for.
  struct timeval boottime;
  int mib[2] = {CTL_KERN, KERN_BOOTTIME};
  size_t size = sizeof(boottime);
  int rc = sysctl(mib, 2, &boottime, &size, NULL, 0);
  if (rc != 0) {
    return 0;
  }
  return (int64_t)boottime.tv_sec * NSEC_PER_SEC + (int64_t)boottime.tv_usec * NSEC_PER_USEC;
}

/** Returns value of gettimeofday, in nanoseconds.
 *
 * Inspired by https://stackoverflow.com/a/40497811
 *
 * @return The value of gettimeofday, in nanoseconds.
 */
int64_t GDTCORUptimeInNanoseconds(void) {
  int64_t before_now_nsec;
  int64_t after_now_nsec;
  struct timeval now;

  before_now_nsec = GDTCORKernelBootTimeInNanoseconds();
  // Addresses a race condition in which the system time has updated, but the boottime has not.
  do {
    gettimeofday(&now, NULL);
    after_now_nsec = GDTCORKernelBootTimeInNanoseconds();
  } while (after_now_nsec != before_now_nsec);
  return (int64_t)now.tv_sec * NSEC_PER_SEC + (int64_t)now.tv_usec * NSEC_PER_USEC -
         before_now_nsec;
}
