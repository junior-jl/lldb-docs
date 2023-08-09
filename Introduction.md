- High performance debugger
- Support for C, Objective-C and C++ on desktop and iOS devices and simulator

## Compiler Integration Benefits

- LLDB converts debug information into Clang types
- It makes possible to use the Clang compiler infrastructure

### Major benefits

- Up to date language support for C, C++, Objective-C
- Multi-line expressions that can declare local variables and types
- Utilise the JIT for expressions when supported
- Evaluate expression Intermediate Representation (IR) when JIT can’t be used

## Reusability

- LLDB debugger APIs are exposed as a C++ OO interface in a shared library
	- For macOS -> `LLDB.framework`
	- For Unix -> `lldb.so`
- LLDB command line tool uses this public API
- The API is also exposed through Python script bindings

## Platform Support

- macOS debugging for i386, x86_64 and AArch64
- iOS, tvOS, and watchOS simulator debugging on i386, x86_64 and AArch64
- iOS, tvOS, and watchOS device debugging on ARM and AArch64
- Linux user-space debugging for i386, x86_64, ARM, AArch64, PPC64le, s390x
- FreeBSD user-space debugging for i386, x86_64, ARM, AArch64, MIPS64, PPC
- NetBSD user-space debugging for i386 and x86_64
- Windows user-space debugging for i386, x86_64, ARM and AArch64

[[Starting LLDB]]

