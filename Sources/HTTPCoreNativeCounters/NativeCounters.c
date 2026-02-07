//
//  NativeCounters.c
//  HTTPCore
//

#include "NativeCounters.h"

#if defined(__APPLE__)

// Apple platforms (macOS, iOS, tvOS, watchOS, visionOS)

#include <stdatomic.h>

static _Atomic uint64_t requestID = 0;

uint64_t nextRequestID(void) {
	// relaxed is sufficient for uniqueness/monotonicity of the returned value
	return atomic_fetch_add_explicit(&requestID, 1, memory_order_relaxed) + 1;
}

#elif defined(__linux__)

// Linux

#include <stdatomic.h>

static _Atomic uint64_t requestID = 0;

uint64_t nextRequestID(void) {
	return atomic_fetch_add_explicit(&requestID, 1, memory_order_relaxed) + 1;
}

#elif defined(_WIN32)
// Windows (MSVC)

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static LONG64 requestID = 0;

uint64_t nextRequestID(void) {
	// Returns incremented value.
	return (uint64_t)InterlockedIncrement64(&requestID);
}

#else

#error "HTTPCoreNativeCounters is not supported on this platform."

#endif
