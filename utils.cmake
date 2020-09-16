find_package(IDL REQUIRED)

function(fileName2TargetName fn outVar)
	string(REGEX REPLACE "[^A-Za-z0-9_]" "_" "${outVar}" "${fn}")
	set(${outVar} "${${outVar}}" PARENT_SCOPE)
endfunction()

function(compile_widl target_name_prefix file2compile)
	set(ourIncludes "${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}")
	list(FILTER ourIncludes INCLUDE REGEX ".*mingw.*")

	compile_widl_target_lowlevel("${file2compile}" "" ".;${ourIncludes}" OFF "${ARGN}" artifacts fileBaseName "")
	fileName2TargetName("${fileBaseName}" target_name)
	set(target_name "${target_name_prefix}_widl_${target_name}")
	message(STATUS "compiling widl -> ${target_name}")
	add_custom_target("${target_name}"
		DEPENDS ${artifacts}
	)
endfunction()

function(searchFile idlFullName varName paths msg)
	message(STATUS "varName ${varName}")
	find_file (
		${varName}
		NAMES "${idlFullName}"
		PATHS ${paths}
		NO_DEFAULT_PATH
	)
	message(STATUS "${varName} ${${varName}}")
	if("${${varName}}" STREQUAL "${varName}-NOTFOUND")
		message(FATAL_ERROR "${msg}")
	else()
		get_filename_component(fileExt "${${varName}}" LAST_EXT)
		message(STATUS "${idlName} found: ${${varName}}")
	endif()
	set(${varName} "${${varName}}" PARENT_SCOPE)
endfunction()

function(searchAndImportFile target_prefix idlFullName targetDir targetFileName paths msg)
	message(STATUS "target_prefix=${target_prefix} idlFullName=${idlFullName} targetDir=${targetDir} targetFileName=${targetFileName} paths=${paths} msg=${msg}")
	fileName2TargetName("${targetFileName}" idlFullSafeName)
	set(varName "IDL_SYSTEM_PATH_${idlFullSafeName}")
	searchFile("${idlFullName}" "${varName}" "${paths}" "${msg}")

	set(file2compile "${${varName}}")
	set(resultPath "${targetDir}/${targetFileName}")

	set(targetName "${target_prefix}_copy_${idlFullSafeName}")
	message(STATUS "Importing ${idlFullName} -> ${resultPath} (${targetName})")
	copyFileBuildTime("${targetName}" "${file2compile}" "${targetDir}" "${resultPath}")
	add_dependencies("${target_prefix}" "${targetName}")
endfunction()

function(copyFileBuildTime targetName sourcePath targetDir resultPath)
	add_custom_command(
		OUTPUT "${resultPath}"
		PRE_BUILD COMMAND ${CMAKE_COMMAND} "-E" "copy" "${sourcePath}" "${resultPath}"
		MAIN_DEPENDENCY "${sourcePath}"
		DEPENDS "${sourcePath}"
		WORKING_DIRECTORY "${targetDir}"
		COMMENT "Copying ${idlFullName}"
	)
	add_custom_target("${targetName}"
		DEPENDS "${resultPath}"
	)
endfunction()

function(importSystemFile target_prefix idlFullName)
	importSystemFileFull("${target_prefix}" "${idlFullName}" "${WDK_IDLS_COMPILED}" "${idlFullName}")
endfunction()

function(importSystemFileFull target_prefix idlFullName targetDir targetFileName)
	searchAndImportFile("${target_prefix}" "${idlFullName}" "${targetDir}" "${targetFileName}" "${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES};${WINE_INCLUDES}" "Your MinGW doesn't have ${idlFullName} . You may need Wine/ReactOS sources. https://github.com/wine-mirror/wine. Set WINE_INCLUDES to the dir of the includes of the sources")
endfunction()

function(importWSDKFile target_prefix idlFullName)
	importWSDKFileFull("${target_prefix}" "${idlFullName}" "${WDK_IDLS_COMPILED}" "${idlFullName}")
endfunction()

function(importWSDKFileFull target_prefix idlFullName targetDir targetFileName)
	searchAndImportFile("${target_prefix}" "${idlFullName}" "${targetDir}" "${targetFileName}" "${SpeechSDK_INCLUDE_DIRS}" "Your Speech/Windows SDK doesn't have ${idlFullName}. You need Speech/Windows SDK https://developer.microsoft.com/ru-ru/windows/downloads/windows-10-sdk/ . Set SpeechSDK_INCLUDE_DIRS to its root")
	
	fileName2TargetName("${targetFileName}" idlFullSafeName)
	add_dependencies("${target_prefix}" "${target_prefix}_copy_${idlFullSafeName}")
endfunction()


function(importWineBinFile target_prefix idlFullName)
	searchAndImportFile("${target_prefix}" "${idlFullName}" "${WDK_IDLS_COMPILED}" "${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES};${WINE_BIN_DLLS}" "Your MinGW doesn't have ${idlFullName}. You need wine prebuilt binaries (wine-staging-<arch>_<version>~<distro_version>_<arch>.deb). https://dl.winehq.org/wine-builds/debian/dists/bullseye/main/binary-i386/")
endfunction()

function(importWineFileFromDLLsDir target_prefix dllSubdir idlFullName)
	searchAndImportFile("${target_prefix}" "${idlFullName}" "${WDK_IDLS_COMPILED}" "" "${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES};${WINE_DLLS_SOURCES}/${dllSubdir}" "Your MinGW doesn't have ${idlFullName}. You need Wine sources (https://github.com/wine-mirror/wine)! Set WINE_DLLS_SOURCES to lib subdir of sources root.")
endfunction()

