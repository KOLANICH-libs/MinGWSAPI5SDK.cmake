set("SAPI5_SDK_WORKAROUNDS_BUILD_TIME_SCRIPTS" "${CMAKE_CURRENT_LIST_DIR}/buildTimeScripts")

function(callBuildTimeWorkaround workaroundName targetName inputFile outputFile)
	add_custom_command(
		OUTPUT "${outputFile}"
		PRE_BUILD COMMAND ${CMAKE_COMMAND} "-DinputFile=\"${inputFile}\"" "-DoutputFile=\"${outputFile}\"" "-P" "${SAPI5_SDK_WORKAROUNDS_BUILD_TIME_SCRIPTS}/${workaroundName}.cmake"
		MAIN_DEPENDENCY "${inputFile}"
		DEPENDS "${inputFile}"
		COMMENT "${workaroundName}: ${inputFile} -> ${outputFile}"
	)
	add_custom_target("${targetName}"
		DEPENDS "${outputFile}"
	)
endfunction()


# It is very redundant to use 2 files, but CMake tracks deps this way
function(workaroundSapiAutDefaultValueFloat inputFile outputFile)
	#https://bugs.winehq.org/show_bug.cgi?id=49807
	set(WS "[\n\r\t ]")
	file(READ "${inputFile}" f)
	string(REGEX REPLACE "(defaultvalue\\()([0-9]+)\\.0+(\\))" "\\1\\2\\3" "f" "${f}")
	file(WRITE "${outputFile}" "${f}")
endfunction()

function(wsdk_idl_restricted_workaround inputFile outputFile)
	# fixed https://bugs.winehq.org/show_bug.cgi?id=49795
	file(READ "${inputFile}" f)
	set(WS "[\n\r\t ]")
	
	# workaroundRemoveRestricted
	string(REGEX REPLACE "${WS}*,${WS}*restricted${WS}*,${WS}*" "," "f" "${f}")
	string(REGEX REPLACE "${WS}*,${WS}*restricted${WS}*\\]" "]" "f" "${f}")
	string(REGEX REPLACE "${WS}*\\[${WS}*restricted${WS}*\\]" "" "f" "${f}")
	string(REGEX REPLACE "${WS}*\\[${WS}*restricted${WS}*,${WS}*" "[" "f" "${f}")

	file(WRITE "${outputFile}" "${f}")
endfunction()

function(workaroundHiddenInEnum inputFile outputFile)
	# https://bugs.winehq.org/show_bug.cgi?id=49806
	file(READ "${inputFile}" f)
	string(REPLACE "[hidden]" "" "f" "${f}")
	file(WRITE "${outputFile}" "${f}")
endfunction()

# SAPI headers in Windows SDK don't contain some essential GUIDs in their GUID form. But contain in string form!
function(generateUUIDConstants sapiautFileName guidsFile)
	set(WS "[\n\r\t ]")
	set(HEXD "[0-9A-Fa-f]")
	set(HEXB "${HEXD}${HEXD}")
	set(HEXSH "${HEXB}${HEXB}")
	set(HEXD8 "${HEXSH}${HEXSH}")
	set(HEXD12 "${HEXD8}${HEXSH}")
	file(READ "${sapiautFileName}" f)
	set(RX "SpeechAudioFormatGUID([a-zA-Z0-9_]+)${WS}*=${WS}*L?\"\\{(${HEXD8}-${HEXSH}-${HEXSH})-(${HEXSH}-${HEXD12})\\}\"${WS}*")
	#message(STATUS "RX ${RX}")
	string(REGEX MATCHALL "${RX}" matches "${f}")
	#message(STATUS "matches ${matches}")
	set(amendment "#define INITGUID\n#include <guiddef.h>")
	foreach(m ${matches})
		string(REGEX MATCH "${RX}" groups "${m}")
		set(nm "${CMAKE_MATCH_1}")
		set(guidP1 "${CMAKE_MATCH_2}")
		set(guidP2 "${CMAKE_MATCH_3}")
		#message(STATUS "m ${m} nm ${nm} guidV ${guidV}")
		string(REPLACE "-" ", 0x" guidP1 "${guidP1}")
		set(guidP1 "0x${guidP1}")
		
		string(REPLACE "-" "" guidP2 "${guidP2}")
		message(STATUS "guidP2 ${guidP2}")
		string(REGEX REPLACE "${HEXB}" ", 0x\\0" guidP2 "${guidP2}")
		
		if("${nm}" STREQUAL "Wave")
			set(nm "${nm}FormatEx")
		endif()
		set(amendment "${amendment}\nDEFINE_GUID(SPDFID_${nm}, ${guidP1} ${guidP2});")
	endforeach()

	file(WRITE "${guidsFile}" "${amendment}")
endfunction()

function(workaroundSapiDDKAnonymousStruct inputFile outputFile)
	# https://bugs.winehq.org/show_bug.cgi?id=49797
	set(WS "[\n\r\t ]")
	file(READ "${inputFile}" f)
	string(REGEX REPLACE "struct${WS}*\\{${WS}*DWORD${WS}+fHasProperty${WS}*;${WS}*(//${WS}*[a-zA-Z\n\r\t ]+)?\\};" "DWORD fHasProperty;" "f" "${f}")
	file(WRITE "${outputFile}" "${f}")
endfunction()
