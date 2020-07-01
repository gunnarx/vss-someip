VSS - SOME/IP Service
=====================

This README is a work in progress

This programs uses a number of existing tools together to produce
a full `VSS-to-SOME/IP service` **example**, it can serve as an (automated)
test for the involved programs, and is a possible basis for developing a more
complete program using VSS signals over SOME/IP, in either client or server
role.

Program parts
-------------

`build-common-api-cpp-native` is the major part, and it provides a tested
and reusable local (native) build of the runtime libraries for CommonAPI,
as well as copies of the code generators in a tested working
environment with the right Java version.  This project can be run locally
but it also uses containers to produce a more guaranteed repeatable setup.

All container parts use Docker as the frontend and runtime environment.

`vss-tools` has the VSS-to-Franca-IDL converter program

`vehicle_signal_specification` is the main VSS repository, where we take
the VSS signal definitions used in the example.

(All of the above are brought into this project by use of Git Submodules).

`src` is a project directory where we put the generated Franca IDL (.fidl,
.fdepl) files, and generated C++ source code.

`create_sample_service.sh` is the main script that uses a combination of
all the submodule project to produce a final, compiled, SOME/IP program.

The script does the following in sequence:

- Generates Franca IDL from VSS (using a _specified part_ of the tree which
is defined in the script as of now)
- Generates CommonAPI binding code from the Franca IDL (D-Bus and SOME/IP
but in the later stages only SOME/IP is considered).  This uses generators
from a _running container_ provided by `build-common-api-cpp-native`
- Creates a small CMake project file for the SOME/IP variant of generation,
and compiles it into an executable - in the process linking to the
vSomeip and CommonAPI runtime libraries.
- Compiles the program from this CMake project and runs it

To transform this to a full program, you would modify the part of the VSS tree
that shall be converted to Franca, modify main.cpp and add any other
required source files to create the actual program or SOME/IP based
service.  A full program would refer to (inherit classes etc.) from the
auto-generated proxies and stubs.

Usage
-----

Warning!  This is not really ready for end-user usage yet.  All the
information is here, but it is not an easy out-of-the-box experience.

Improvements are likely to follow!

What you must know, if you dare to try it:

1. Code-generation steps are run inside the container, which specifically means
that the container from `build-common-api-cpp-native` must exist and be
running, with the name of `buildcapicxx` in the Docker environment.

Since the container image is not yet published on an external site, this
requires building and then running the container image.  It is for the moment
recommended to do this by the `run-in-docker.sh` script, instead of the
`docker/Dockerfile`, although the latter would also work, as long as you then
start a container from the image with the container name set to `buildcapicxx`

2. Compilation steps refer to the source code (include files) and the built
libraries in the `build-common-api-cpp-native` directory.  These two parts are
currently _not_ fetched from within the container, and therefore it is
required that the `build-common-api-cpp-native` project is **also** built
natively at least once (by running `build-commonapi.sh`), so that the required
headers and libraries then exist under the
`build-common-api-cpp-native/install` directory.

Note that building the `build-common-api-cpp-native` project takes significant
time, for both the container and non-container environments.

These two usages of the build-common-api-cpp-native project should benefit
from being combined at a later time for a more convenient use.
