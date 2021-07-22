# Copyright 2017 Chad Vernon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Copyright 2021 Bantukul Olarn

#.rst:
# FindMaya
# --------
#
# Find Maya headers and libraries.
#
# Imported targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the following :prop_tgt:`IMPORTED` target:
#
# ``Maya::Maya``
#   The Maya libraries, if found.
#
# Result variables
# ^^^^^^^^^^^^^^^^
#
# This module will set the following variables in your project:
#
# ``Maya_FOUND``
#   Defined if a Maya installation has been detected
# ``MAYA_INCLUDE_DIR``
#   Where to find the headers (maya/MFn.h)
# ``MAYA_APP_DIR``
#   Base maya program location
# ``MAYA_LIBRARIES``
#   All the Maya libraries.
# ``MAYA_PYTHON_EXECUTABLE``
#   Path to mayapy/mayapy2
#   To be used with cmake's FindPython/2/3
#

include(CMakeParseArguments)

# Raise an error, halt if Maya version if not specified
# Default value will be "NOT_SET"
set(MAYA_VERSION "NOT_SET" CACHE STRING "Target Maya version")
set(MAYA_MAYAPY_AS_PYTHON_INTERPRETER OFF CACHE BOOL "Use mayapy/mayapy2 as PYTHON_EXECUTABLE")
set(MAYA_USE_LEGACY_PYTHON OFF CACHE BOOL "Prefer python2")

# Must specify MAYA_VERSION
if(MAYA_VERSION STREQUAL "NOT_SET")
    message(FATAL_ERROR "FindMaya: MAYA_VERSION is not specified")
endif()

# Maya version check

# OS Specific environment setup
set(MAYA_COMPILE_DEFINITIONS "REQUIRE_IOSTREAM;_BOOL")
set(MAYA_INSTALL_BASE_SUFFIX "")
set(MAYA_TARGET_TYPE LIBRARY)
if(WIN32)
    # Windows
    set(MAYA_INSTALL_BASE_DEFAULT "C:/Program Files/Autodesk")
    set(MAYA_COMPILE_DEFINITIONS "${MAYA_COMPILE_DEFINITIONS};NT_PLUGIN")
    set(MAYA_PLUGIN_EXTENSION ".mll")
    set(MAYA_TARGET_TYPE RUNTIME)
elseif(APPLE)
    # Apple
    set(MAYA_INSTALL_BASE_DEFAULT /Applications/Autodesk)
    set(MAYA_COMPILE_DEFINITIONS "${MAYA_COMPILE_DEFINITIONS};OSMac_")
    set(MAYA_PLUGIN_EXTENSION ".bundle")
else()
    # Linux
    set(MAYA_COMPILE_DEFINITIONS "${MAYA_COMPILE_DEFINITIONS};LINUX")
    set(MAYA_INSTALL_BASE_DEFAULT /usr/autodesk)
    if(MAYA_VERSION LESS 2016)
        # Pre Maya 2016 on Linux
        set(MAYA_INSTALL_BASE_SUFFIX -x64)
    endif()
    set(MAYA_PLUGIN_EXTENSION ".so")
endif()

set(MAYA_INSTALL_BASE_PATH ${MAYA_INSTALL_BASE_DEFAULT} CACHE STRING
    "Root path containing your maya installations, e.g. /usr/autodesk or /Applications/Autodesk/")

set(MAYA_LOCATION ${MAYA_INSTALL_BASE_PATH}/maya${MAYA_VERSION}${MAYA_INSTALL_BASE_SUFFIX})

set(MAYA_APP_DIR ${MAYA_LOCATION} CACHE STRING
    "Root path of Maya application")

# Detect and setup MayaPython
# Note: windows only for now
if(MAYA_VERSION LESS 2022)
    set(MAYA_PYTHON_EXECUTABLE "${MAYA_LOCATION}/bin/mayapy.exe")
else()
    if(MAYA_USE_LEGACY_PYTHON)
        set(MAYA_PYTHON_EXECUTABLE "${MAYA_LOCATION}/bin/mayapy2.exe")
    else()
        # Mayapy3k is simply mayapy.exe
        set(MAYA_PYTHON_EXECUTABLE "${MAYA_LOCATION}/bin/mayapy.exe")
    endif()
endif()

set(MAYA_PYTHON_EXECUTABLE ${MAYA_PYTHON_EXECUTABLE} CACHE STRING "" FORCE)

if(MAYA_MAYAPY_AS_PYTHON_INTERPRETER)
    if(NOT WIN32)
        message(FATAL_ERROR "MAYA_MAYAPY_AS_PYTHON_INTERPRETER")
    # else()
    endif()
    set(PYTHON_EXECUTABLE ${MAYA_PYTHON_EXECUTABLE} CACHE STRING "" FORCE)
endif()

# Maya include directory
find_path(MAYA_INCLUDE_DIR maya/MFn.h
    PATHS
        ${MAYA_LOCATION}
        $ENV{MAYA_LOCATION}
    PATH_SUFFIXES
        "include/"
        "devkit/include/"
)

find_library(MAYA_LIBRARY
    NAMES 
        OpenMaya
    PATHS
        ${MAYA_LOCATION}
        $ENV{MAYA_LOCATION}
    PATH_SUFFIXES
        "lib/"
        "Maya.app/Contents/MacOS/"
    NO_DEFAULT_PATH
)
set(MAYA_LIBRARIES "${MAYA_LIBRARY}")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Maya
    REQUIRED_VARS MAYA_INCLUDE_DIR MAYA_LIBRARY)
mark_as_advanced(MAYA_INCLUDE_DIR MAYA_LIBRARY)

if (NOT TARGET Maya::Maya)
    add_library(Maya::Maya UNKNOWN IMPORTED)
    set_target_properties(Maya::Maya PROPERTIES
        INTERFACE_COMPILE_DEFINITIONS "${MAYA_COMPILE_DEFINITIONS}"
        INTERFACE_INCLUDE_DIRECTORIES "${MAYA_INCLUDE_DIR}"
        IMPORTED_LOCATION "${MAYA_LIBRARY}")
    
    if (APPLE AND ${CMAKE_CXX_COMPILER_ID} MATCHES "Clang" AND MAYA_VERSION LESS 2017)
        # Clang and Maya 2016 and older needs to use libstdc++
        set_target_properties(Maya::Maya PROPERTIES
            INTERFACE_COMPILE_OPTIONS "-std=c++0x;-stdlib=libstdc++")
    endif ()
endif()

# Add the other Maya libraries into the main Maya::Maya library
set(_MAYA_LIBRARIES OpenMayaAnim OpenMayaFX OpenMayaRender OpenMayaUI Foundation clew)
foreach(MAYA_LIB ${_MAYA_LIBRARIES})
    find_library(MAYA_${MAYA_LIB}_LIBRARY
        NAMES 
            ${MAYA_LIB}
        PATHS
            ${MAYA_LOCATION}
            $ENV{MAYA_LOCATION}
        PATH_SUFFIXES
            "lib/"
            "Maya.app/Contents/MacOS/"
        NO_DEFAULT_PATH)
    mark_as_advanced(MAYA_${MAYA_LIB}_LIBRARY)
    if (MAYA_${MAYA_LIB}_LIBRARY)
        add_library(Maya::${MAYA_LIB} UNKNOWN IMPORTED)
        set_target_properties(Maya::${MAYA_LIB} PROPERTIES
            IMPORTED_LOCATION "${MAYA_${MAYA_LIB}_LIBRARY}")
        set_property(TARGET Maya::Maya APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES Maya::${MAYA_LIB})
        set(MAYA_LIBRARIES ${MAYA_LIBRARIES} "${MAYA_${MAYA_LIB}_LIBRARY}")
    endif()
endforeach()

function(MAYA_PLUGIN _target)
    if (WIN32)
        set_target_properties(${_target} PROPERTIES
            LINK_FLAGS "/export:initializePlugin /export:uninitializePlugin")
    endif()
    set_target_properties(${_target} PROPERTIES
        PREFIX ""
        SUFFIX ${MAYA_PLUGIN_EXTENSION})
endfunction()

# Declare, format and link target as maya plugin in one command
# Drop-in replacement for add_library
function(ADD_MAYA_PLUGIN _TARGET)
    cmake_parse_arguments(
        _PARSED
        "EXCLUDE_FROM_ALL"
        ""
        ""
        ${ARGN}
    )
    set(_SOURCES ${_PARSED_UNPARSED_ARGUMENTS})

    if(_PARSED_EXCLUDE_FROM_ALL)
        add_library(${_TARGET} SHARED EXCLUDE_FROM_ALL ${_SOURCES})
    else()
        add_library(${_TARGET} SHARED ${_SOURCES})
    endif()

    target_link_libraries(
        ${_TARGET} PRIVATE Maya::Maya
    )
    MAYA_PLUGIN(${_TARGET})
endfunction()
