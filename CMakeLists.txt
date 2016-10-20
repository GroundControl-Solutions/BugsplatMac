cmake_minimum_required(VERSION 3.2)
project(BugSplat)

include(ExternalProject)

add_custom_target(BugSplatCommand
        COMMAND xcodebuild -project ${CMAKE_CURRENT_SOURCE_DIR}/BugsplatMac.xcodeproj -target BugsplatMac
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )

add_library(BugSplat INTERFACE)
add_dependencies(BugSplat BugSplatCommand)
target_link_libraries(BugSplat INTERFACE "-framework BugsplatMac" "-F${CMAKE_CURRENT_SOURCE_DIR}/build/Release")
