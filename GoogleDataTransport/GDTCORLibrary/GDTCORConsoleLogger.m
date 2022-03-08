/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"

#import <GoogleUtilities/GULLogger.h>

/** The console logger prefix. */
static NSString *kGDTCORConsoleLogger = @"[GoogleDataTransport]";

NSString *GDTCORMessageCodeEnumToString(GDTCORMessageCode code) {
  return [[NSString alloc] initWithFormat:@"I-GDT%06ld", (long)code];
}

void GDTCORLog(GDTCORMessageCode code, GDTCORLoggingLevel logLevel, NSString *format, ...) {
#if !NDEBUG
  GULLoggerLevel gulLevel = GULLoggerLevelDebug;
  switch (logLevel) {
    case GDTCORLoggingLevelDebug:
      gulLevel = GULLoggerLevelDebug;
      break;
    case GDTCORLoggingLevelVerbose:
      gulLevel = GULLoggerLevelInfo;
      break;
    case GDTCORLoggingLevelWarnings:
      gulLevel = GULLoggerLevelWarning;
      break;
    case GDTCORLoggingLevelErrors:
      gulLevel = GULLoggerLevelError;
      break;
    default:
      break;
  }

  va_list args;
  va_start(args, format);
  GULLogBasic(gulLevel, kGDTCORConsoleLogger, false, GDTCORMessageCodeEnumToString(code), format,
              args);
  va_end(args);
#endif  // !NDEBUG
}

void GDTCORLogAssert(
    BOOL wasFatal, NSString *_Nonnull file, NSInteger line, NSString *_Nullable format, ...) {
  GDTCORMessageCode code = wasFatal ? GDTCORMCEFatalAssertion : GDTCORMCEGeneralError;

  GDTCORLog(code, GDTCORLoggingLevelErrors, @"(%@:%ld) : %@", file, (long)line, format);
}
