//
//  NativeCounters.h
//  HTTPCore
//

#ifndef HTTPCORE_NATIVE_COUNTERS_H
#define HTTPCORE_NATIVE_COUNTERS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Returns a monotonically increasing request id (starting from 1).
/// Thread-safe on supported platforms/toolchains.
uint64_t nextRequestID(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // HTTPCORE_NATIVE_COUNTERS_H
