// CrispCompat.m — the NSGlassEffectView compatibility stub, compiled by clang
// and linked into the binary. swiftc only imports the bridging header for type
// information and does not emit @implementations from it, so a class declared
// there alone leaves dyld with an undefined `_OBJC_CLASS_$` symbol at launch.
// The interface stays in Crisp-Bridging-Header.h (Swift sees the type); this
// file carries the implementation. Every use site is gated by
// #available(macOS 26.0, *) or a runtime responder check, so the stub is
// never instantiated on systems older than macOS 26.

#import "Crisp-Bridging-Header.h"

#if __MAC_OS_X_VERSION_MAX_ALLOWED < 260000
@implementation NSGlassEffectView
@end
#endif
