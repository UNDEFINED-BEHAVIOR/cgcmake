New features:

* Added cmake variable
    * MAYA_APP_DIR Maya application base directory (for that particular version)
    * MAYA_PYTHON_EXECUTABLE MayaPy executable
* ADD_MAYA_PLUGIN function
    * Declare, format and link target as Maya plugin in one command
    * Drop-in replacement for add_library command
* MAYA_VERSION no longer defaults to any specific version
    * Unspecified Maya version will be marked as "NOT_SET", and treated as error
* Specifying Maya python intepreter as target python interpreter (Windows only)
    * Setting mayapy as PYTHON_EXECUTABLE by delcaring MAYA_MAYAPY_AS_PYTHON_INTERPRETER
    * Provide shim capability for 2022 and beyond
        * Force mayapy2 in Maya 2022 by declaring MAYA_USE_LEGACY_PYTHON

# Note
Using Maya Python as main interpreter:
Load maya module first to setup python executable and library or
alternatively, use MAYA_PYTHON_EXECUTABLE
variable to specify python interpreter before calling subsequent
python dependent projects.

# cgcmake
CMake modules for common applications related to computer graphics.

## Example
-------------------
```
Hierarchy:
    MayaPlugin-Top
    - HelloWorldCmd
    - PluginMain
    - SimpleHelloWorldCmd-Main
Target linkage:
    HelloWorldCmd <- PluginMain
    SimpleHelloWorldCmd-Main
```

Top level CMakeLists.txt
-------------------
    cmake_minimum_required(VERSION 3.14) # prefer newest version

    project(MayaPlugin-Top C CXX)

    # set this to whereever you placed FindMaya.cmake
    set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

    ## import Maya package
    find_package(Maya REQUIRED)

    add_subdirectory(HelloWorldCmd)
    add_subdirectory(PluginMain)
    add_subdirectory(SimpleHelloWorldCmd-Main)

HelloWorldCmd CMakeLists.txt
-------------------


    ## Sample hello world command

    project(HelloWorldCmd)

    add_library(${PROJECT_NAME} STATIC)

    target_include_directories(
        ${PROJECT_NAME} 
        PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    target_sources(
        ${PROJECT_NAME}
        PRIVATE
        src/MSimple.h
        include/HelloworldCmd.h
        src/HelloworldCmd.cpp
    )

    target_link_libraries(
        ${PROJECT_NAME} 
        PUBLIC 
        Maya::Maya
    )

PluginMain CMakeLists.txt
-------------------

    ## Maya plugin entry, using HelloWorldCmd target

    project(SamplePlugin)

    # Maya plugin specific drop-in replacement for add_library command
    ADD_MAYA_PLUGIN(${PROJECT_NAME})

    target_sources(
        ${PROJECT_NAME}
        PRIVATE
        src/main.cpp
    )

    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE 
        HelloWorldCmd
    )

    # Uncomment this to enable installing to CMAKE_INSTALL_PREFIX.
    # install(TARGETS ${PROJECT_NAME} ${MAYA_TARGET_TYPE} DESTINATION .)


SimpleHelloWorldCmd-Main CMakeLists.txt
-------------------

    ## Hello world plugin defined in a single target
    ## ADD_MAYA_PLUGIN can accept ADD_LIBRARY arguments
    ## *Library type is fixed to SHARED

    PROJECT(SimpleHelloWorldCmd-Main)

    ADD_MAYA_PLUGIN(
        ${PROJECT_NAME}
        # EXCLUDE_FROM_ALL
        include/HelloworldCmd.h
        src/main.cpp
    )

    TARGET_INCLUDE_DIRECTORIES(
        ${PROJECT_NAME}
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    INSTALL(TARGETS ${PROJECT_NAME} ${MAYA_TARGET_TYPE} DESTINATION .)

From Command Line
-----------------
    # CMake 3.x
    cmake -G "Visual Studio 14 2015 Win64" -DMAYA_VERSION=2018 ../
    cmake --build . --config Release

## note:
-----------------
https://stackoverflow.com/questions/1027247/is-it-better-to-specify-source-files-with-glob-or-each-file-individually-in-cmak/1060061
