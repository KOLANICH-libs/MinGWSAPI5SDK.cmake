message(STATUS "inputFile  ${inputFile}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")
include(workarounds)

workaroundHiddenInEnum("${inputFile}" "${outputFile}")
