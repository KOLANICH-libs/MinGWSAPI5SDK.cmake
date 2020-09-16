Set of scripts to use vanilla SAPI 5 SDK with FOSS toolchains
=============================================================

Set of CMake scripts to use vanilla [SAPI 5]() SDK with FOSS toolchains Such as [MinGW-w64](https://sourceforge.net/projects/mingw-w64/files/) with [GCC](https://gcc.gnu.org/) and [Clang](https://clang.llvm.org/docs/ReleaseNotes.html) as compilers.

Headers provided with the compilers mentioned often lack some classes and interfaces. The solution is to use vanilla SDK provided by Microsoft. The problem is that that the headers in the SDK were generated with MIDL, that generates the code that is meant to be compiled using Visual Studio - Microsoft proprietary compiler and IDE, and mainly cannot be compiled with GCC.

Fortunately, Component Object Model was designed for interoperability, and Microsoft also ship IDL files as a part of this SDK, so the needed headers can be regenerated using `widl` - an IDL compiler, that generates code to be used with [FOSS](https://en.wikipedia.org/wiki/FOSS) [toolchain](https://en.wikipedia.org/wiki/Toolchain)s.

So, this project is a CMake module, allowing you to automatically recompile needed IDL files into headers, that can be used with FOSS toolchains.

Prerequirements
---------------


You will need:

* Sources of Wine and idl files from MinGW-w64. Some core IDL files have to be taken from there.
* A bleeding edge version of widl. MinGW-w64 has widl, but not all the critical bugs are fixed there. Currently can be built only by compiling Wine (it is OK to stop right after it has built widl), but [I have moved it into a separate repo](https://github.com/KOLANICH/widl). You will need its dependencies too.
* Windows 10 SDK. It doesn't matter uf you gonna compile to Windows XP - Component Object Model was designed for compatibility, XP will just ignore the stuff for 7. Earlier versions of the SDK are also available.
* GCC or Clang compiler. Our widl crash workaround app uses inline assembly with AT&T syntax. Also, cross-compilation is not yet supported. We should fix the bugs causing crashes in widl to get rid of the workaround.

Using the module
----------------
1. Add a git submodule pointing to this repo.
2. Use the code below after you have created a target for your module. Because some of CMake commands would require you to already have a target.
3. Add the code like that:

```cmake
if(MINGW)
	include(MinGWSAPI5SDK)  # Include our module. Should be in CMAKE_MODULE_PATH
	createMinGWSAPI5SDK(yourNameForTargetsForSAPI5Headers)  # Transpiles the needed IDLs into the headers
	add_dependencies(your_sapi5_module_target SAPI_SDK_FOR_MinGW)
	target_include_directories(your_sapi5_module_target PRIVATE "${yourNameForTargetsForSAPI5Headers_include}")
	target_link_libraries(your_sapi5_module_target PRIVATE "yourNameForTargetsForSAPI5Headers_uuids")  # some required symbols in the original SDK are neither in the headers, nor in the shared lib. Instead they are in MSVC-specific static lib. Fortunately, the IDL files contain some info, that is enough to recreate them. So we extract the info with a regex and create a C file with it, and compile it. You have to link it, if you have to use the symbols.
elseif(MSVC)
	# do something else
endif()
```

CMake configuration
-------------------
* `WINE_SOURCES` - The path, pointing to the root of unpacked Wine sources. You can either [fetch them from the official website using git (takes longer)](https://source.winehq.org/git/wine.git/), or [fetch a zip with snapsho from Wine GitHub mirror](https://github.com/wine-mirror/wine/archive/master.zip).
* `SpeechSDK_INCLUDE_DIRS` - The path, pointing to `um` dir of [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/). It may also point to root of [Speech SDK](https://www.microsoft.com/en-us/download/confirmation.aspx?id=10121). It may also be possible to do something to use it with [Speech Platform SDK](https://www.microsoft.com/en-us/download/confirmation.aspx?id=27226), since SAPI and Speech Platform are very similar, but I have not tried this use case.
