list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_LIST_DIR}/thirdParty/FindIDL/cmake")

include(utils)
include(workarounds)

set(SpeechSDK_INCLUDE_DIRS "C:/Program Files/Windows Kits/10/Include/10.0.17134.0/um")

set("WINE_SOURCES" "WINE_SOURCES-NOTFOUND" CACHE PATH "Sources dir of Wine")
if(WINE_SOURCES)
	set(WINE_DLLS_SOURCES "${WINE_SOURCES}/dlls")
	set(WINE_INCLUDES "${WINE_SOURCES}/include")
endif()

#target_compile_definitions(RHVoice_sapi PRIVATE "-D_SAPI_VER=0x054")
#message(STATUS "MinGW is used, have to recompile missing IDLs from Windows SDK")
message(STATUS "COM_IDL_COMPILER_PATH ${COM_IDL_COMPILER_PATH}")
message(STATUS "COM_TLB_COMPILER_PATH ${COM_TLB_COMPILER_PATH}")

set(SAPI_MINGW_SDK_ARTIFACTS "")

function(createMinGWSAPI5SDK targetName)
	add_custom_target("${targetName}")
	set("WDK_IDLS_COMPILED" "${CMAKE_CURRENT_BINARY_DIR}/${targetName}_WDK_IDLS")
	file(MAKE_DIRECTORY "${WDK_IDLS_COMPILED}")

	# We build a clean dir to which we place IDLs we need and compile IDLs we need. It is needed because we mix SDKs.

	# compiling some core TLB libs. In fact they are PE, not TLB, and the TLB is in a resource. WIDL doesn't understand such ".tlb"s, so we recompile them into pure tlbs

	add_custom_target("${targetName}_headers")
	# compiling stdole32.tlb
	searchAndImportFile("${targetName}_headers" "std_ole_v1.idl" "${WDK_IDLS_COMPILED}" "stdole32.idl" "${WINE_DLLS_SOURCES}/stdole32.tlb" "You need Wine/ReactOS sources. https://github.com/wine-mirror/wine. Set WINE_SOURCES to the dir of the root of the sources, or WINE_DLLS_SOURCES to the dir of dlls dirs")

	compile_widl("${targetName}" "${WDK_IDLS_COMPILED}/stdole32.idl")
	add_dependencies("${targetName}_widl_stdole32" "${targetName}_headers_copy_stdole32_idl")

	# compiling stdole2.tlb
	importSystemFile("${targetName}_headers" "stdole2.idl")
	compile_widl("${targetName}" "${WDK_IDLS_COMPILED}/stdole2.idl")
	add_dependencies("${targetName}_widl_stdole2" "${targetName}_headers_copy_stdole2_idl")

	importSystemFile("${targetName}_headers" "basetsd.h")
	#importWSDKFile("${targetName}_headers" "basetsd.idl")  # DON'T COMPILE IT!
	importWSDKFile("${targetName}_headers" "wtypesbase.idl")
	importSystemFile("${targetName}_headers" "wtypes.idl")
	importSystemFile("${targetName}_headers" "unknwn.idl")
	importSystemFile("${targetName}_headers" "objidl.idl")
	importSystemFile("${targetName}_headers" "oaidl.idl")
	importSystemFile("${targetName}_headers" "oleidl.idl")
	importSystemFile("${targetName}_headers" "servprov.idl")

	importSystemFile("${targetName}_headers" "xmldom.idl")
	importSystemFile("${targetName}_headers" "xmldso.idl")
	importSystemFile("${targetName}_headers" "msxml.idl")
	importSystemFile("${targetName}_headers" "urlmon.idl")
	importSystemFile("${targetName}_headers" "ocidl.idl")

	importWSDKFile("${targetName}_headers" "sperror.h")
	importWSDKFileFull("${targetName}_headers" "sapiaut.idl" "${WDK_IDLS_COMPILED}" "sapiaut.idl.raw")

	callBuildTimeWorkaround(workaroundSapiAutDefaultValueFloat "${targetName}_headers_workaroundSapiAutDefaultValueFloat_sapiaut_idl" "${WDK_IDLS_COMPILED}/sapiaut.idl.raw" "${WDK_IDLS_COMPILED}/sapiaut.idl.floatWorkarounded")
	add_dependencies("${targetName}_headers_workaroundSapiAutDefaultValueFloat_sapiaut_idl" "${targetName}_headers_copy_sapiaut_idl_raw")
	callBuildTimeWorkaround(workaroundHiddenInEnum "${targetName}_headers_workaroundHiddenInEnum_sapiaut_idl" "${WDK_IDLS_COMPILED}/sapiaut.idl.floatWorkarounded" "${WDK_IDLS_COMPILED}/sapiaut.idl")
	add_dependencies("${targetName}_headers_workaroundHiddenInEnum_sapiaut_idl" "${targetName}_headers_workaroundSapiAutDefaultValueFloat_sapiaut_idl")

	add_dependencies("${targetName}_headers" "${targetName}_headers_workaroundHiddenInEnum_sapiaut_idl")

	importWSDKFile("${targetName}" "sapi.idl")
	compile_widl("${targetName}" "${WDK_IDLS_COMPILED}/sapi.idl" "${SAPI_MINGW_SDK_ARTIFACTS}" "-DSAPI_AUTOMATION")
	add_dependencies("${targetName}_widl_sapi" "${targetName}_headers_workaroundHiddenInEnum_sapiaut_idl" "${targetName}_copy_sapi_idl" "${targetName}_widl_stdole32" "${targetName}_widl_stdole2")
	importWSDKFileFull("${targetName}" "sapiddk.idl" "${WDK_IDLS_COMPILED}" "sapiddk.idl.raw")


	callBuildTimeWorkaround(workaroundSapiDDKAnonymousStruct "${targetName}_workaroundSapiDDKAnonymousStruct_sapiddk_idl" "${WDK_IDLS_COMPILED}/sapiddk.idl.raw" "${WDK_IDLS_COMPILED}/sapiddk.idl")
	add_dependencies("${targetName}_workaroundSapiDDKAnonymousStruct_sapiddk_idl" "${targetName}_copy_sapiddk_idl_raw")
	compile_widl("${targetName}" "${WDK_IDLS_COMPILED}/sapiddk.idl")
	add_dependencies("${targetName}_widl_sapiddk" "${targetName}_workaroundSapiDDKAnonymousStruct_sapiddk_idl" "${targetName}_widl_sapi" "${targetName}_headers")

	callBuildTimeWorkaround(generateUUIDConstants "${targetName}_uuids_source_gen" "${WDK_IDLS_COMPILED}/sapiaut.idl" "${WDK_IDLS_COMPILED}/missingGuids.c")
	add_library("${targetName}_uuids" OBJECT "${WDK_IDLS_COMPILED}/missingGuids.c")
	add_dependencies("${targetName}_uuids" "${targetName}_uuids_source_gen")
	
	add_dependencies("${targetName}" "${targetName}_headers" "${targetName}_uuids" "${targetName}_widl_sapi" "${targetName}_widl_sapiddk")
	
	set("${targetName}_include" "${WDK_IDLS_COMPILED}" PARENT_SCOPE)
endfunction()
