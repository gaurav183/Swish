# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.7

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.7.2/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.7.2/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/akhome/Downloads/dlib-19.4/examples

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/akhome/Downloads/dlib-19.4/examples/build

# Include any dependencies generated for this target.
include CMakeFiles/file_to_code_ex.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/file_to_code_ex.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/file_to_code_ex.dir/flags.make

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o: CMakeFiles/file_to_code_ex.dir/flags.make
CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o: ../file_to_code_ex.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/akhome/Downloads/dlib-19.4/examples/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++   $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o -c /Users/akhome/Downloads/dlib-19.4/examples/file_to_code_ex.cpp

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/akhome/Downloads/dlib-19.4/examples/file_to_code_ex.cpp > CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.i

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/akhome/Downloads/dlib-19.4/examples/file_to_code_ex.cpp -o CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.s

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.requires:

.PHONY : CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.requires

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.provides: CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.requires
	$(MAKE) -f CMakeFiles/file_to_code_ex.dir/build.make CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.provides.build
.PHONY : CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.provides

CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.provides.build: CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o


# Object files for target file_to_code_ex
file_to_code_ex_OBJECTS = \
"CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o"

# External object files for target file_to_code_ex
file_to_code_ex_EXTERNAL_OBJECTS =

file_to_code_ex: CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o
file_to_code_ex: CMakeFiles/file_to_code_ex.dir/build.make
file_to_code_ex: dlib_build/libdlib.a
file_to_code_ex: /usr/X11R6/lib/libSM.dylib
file_to_code_ex: /usr/X11R6/lib/libICE.dylib
file_to_code_ex: /usr/X11R6/lib/libX11.dylib
file_to_code_ex: /usr/X11R6/lib/libXext.dylib
file_to_code_ex: /usr/local/lib/libpng.dylib
file_to_code_ex: /usr/lib/libcblas.dylib
file_to_code_ex: /usr/lib/liblapack.dylib
file_to_code_ex: /usr/lib/libsqlite3.dylib
file_to_code_ex: CMakeFiles/file_to_code_ex.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/akhome/Downloads/dlib-19.4/examples/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable file_to_code_ex"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/file_to_code_ex.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/file_to_code_ex.dir/build: file_to_code_ex

.PHONY : CMakeFiles/file_to_code_ex.dir/build

CMakeFiles/file_to_code_ex.dir/requires: CMakeFiles/file_to_code_ex.dir/file_to_code_ex.cpp.o.requires

.PHONY : CMakeFiles/file_to_code_ex.dir/requires

CMakeFiles/file_to_code_ex.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/file_to_code_ex.dir/cmake_clean.cmake
.PHONY : CMakeFiles/file_to_code_ex.dir/clean

CMakeFiles/file_to_code_ex.dir/depend:
	cd /Users/akhome/Downloads/dlib-19.4/examples/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/akhome/Downloads/dlib-19.4/examples /Users/akhome/Downloads/dlib-19.4/examples /Users/akhome/Downloads/dlib-19.4/examples/build /Users/akhome/Downloads/dlib-19.4/examples/build /Users/akhome/Downloads/dlib-19.4/examples/build/CMakeFiles/file_to_code_ex.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/file_to_code_ex.dir/depend

