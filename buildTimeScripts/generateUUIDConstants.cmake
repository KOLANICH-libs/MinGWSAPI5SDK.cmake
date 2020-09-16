message(STATUS "sapiautFileName  ${inputFile}")
message(STATUS "guidsFile  ${outputFile}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")
include(workarounds)

generateUUIDConstants("${inputFile}" "${outputFile}")
