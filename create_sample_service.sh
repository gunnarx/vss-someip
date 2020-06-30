#!/bin/bash

cd "$(dirname "$0")"
MYDIR="$PWD"

CSVFILE="$MYDIR/vehicle_signal_specification/vss_rel_2.0.0-alpha+006.csv"
VSPEC2FRANCA="$MYDIR/vss-tools/vspeccsv2franca.py"

# Definitions for our conversion
PACKAGE='org.genivi.vss_someip'
PROVIDER='VSSService'
SRC_BASE_NAME='VehicleIdentification' # It will be same as the base interfacename
INTERFACE="Vehicle.VehicleIdentification"
STRIP="Vehicle"
SIGNAL_PATTERN='Vehicle.VehicleIdentification.*'
VSS_VERSION="1.99-create_sample_service"
IF_VERSION="1,99"

# Base name to use for FIDL files, service name, etc.
SERVICE_NAME=VehicleIDService
PROJECT_DIR="$MYDIR/src"
FIDL_FILE="$SERVICE_NAME.fidl"
FDEPL_FILE="$SERVICE_NAME.fdepl"

file_exists() { [ -f "$1" ] ; }

fail() {
  echo "Something went wrong.  Message:"
  echo "$1"
  exit 2
}

ensure_file_exists() {
  file_exists "$1" || fail "Expected file missing: $1"
}

# Show command that is being run to the user
# (More control than just setting -x flag in shell)
xcmd() {
  echo "+ $@"
  eval $@
}
header() {
  echo "==================================================================="
  echo -e "$1"
  echo "==================================================================="
}

# Make sure CSV file is created from VSS database
header "PREPARE VSS FILES IN VEHICLE_SIGNAL_SPECIFICATION"

xcmd cd vehicle_signal_specification
xcmd make
ensure_file_exists "$CSVFILE"
cd "$MYDIR/vss-tools"

header "GENERATE FRANCA IDL FROM VSS for $INTERFACE"
xcmd $VSPEC2FRANCA -v "$VSS_VERSION" -V $IF_VERSION -p $PACKAGE -n $INTERFACE -t $STRIP -s "$SIGNAL_PATTERN" -P $PROVIDER "$CSVFILE" "$PROJECT_DIR/$FIDL_FILE"
ensure_file_exists "$PROJECT_DIR/$FIDL_FILE"
ensure_file_exists "$PROJECT_DIR/$FDEPL_FILE"

# Generate code with wrapper that calls into container
cd "$PROJECT_DIR"
header "GENERATE COMMONAPI C++ CODE FROM FRANCA IDL\nfor core..."
xcmd ../build-common-api-cpp-native/docker/generate core $FIDL_FILE
header "...for D-Bus"
xcmd ../build-common-api-cpp-native/docker/generate dbus $FIDL_FILE
header "...for SOME/IP"
xcmd ../build-common-api-cpp-native/docker/generate someip $FDEPL_FILE $FIDL_FILE

# Check if OK (Only a handful of the expected generated source files...)
ensure_file_exists "$PROJECT_DIR/src-gen/v1/org/genivi/vss_someip/VehicleIdentificationDBusDeployment.cpp"
ensure_file_exists "$PROJECT_DIR/src-gen/v1/org/genivi/vss_someip/VehicleIdentification.hpp"
ensure_file_exists "$PROJECT_DIR/src-gen/v1/org/genivi/vss_someip/VehicleIdentificationSomeIPProxy.cpp"

header "COMPILE SOME/IP PROJECT"
echo "Generating cmake file (CMakeLists.txt)"
rm -f someip_test
../build-common-api-cpp-native/generate-someip-cmakelists.sh someip_test main.cpp src-gen/v1/org/genivi/vss_someip/$SRC_BASE_NAME*SomeIP*.cpp >CMakeLists.txt

xcmd mkdir build
xcmd cd build
xcmd cmake ..
xcmd make -j$(nproc)

ensure_file_exists "$PROJECT_DIR/build/someip_test"

header "RUN PROGRAM"
$PROJECT_DIR/build/someip_test
