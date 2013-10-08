#!/bin/sh

SCRIPT_PATH=`dirname $0`
source "${SCRIPT_PATH}/xcode_functions.sh"

function setup_build_environment ()
{
  pushd . > /dev/null
  cd "$SCRIPT_PATH/.."
  ROOT_PATH="$(pwd)"
  popd > /dev/null

  CLANG=`/usr/bin/xcrun --find clang`
  CC=${CLANG}
  CPP="${CLANG} -E"
  ARCHS=("i386" "armv7" "armv7s")
  DEVELOPER="/Applications/Xcode.app/Contents/Developer"
  MACOSX_DEPLOYMENT_TARGET=""
  
  XCODE_MAJOR_VERSION=$(xcode_major_version)

  if [ "${XCODE_MAJOR_VERSION}" -ge "5" ]; then
    SDKVERSION="7.0"
    if [ -z "${IPHONEOS_DEPLOYMENT_TARGET}" ]; then
      IPHONEOS_DEPLOYMENT_TARGET=${SDKVERSION}
    fi
    if [ `echo ${IPHONEOS_DEPLOYMENT_TARGET} '>=' 6.0 | bc -l` == "1" ]; then
      ARCHS=("x86_64" "${ARCHS[@]}" "arm64")
    fi
  else
    SDKVERSION="6.1"
    IPHONEOS_DEPLOYMENT_TARGET="5.0"
  fi
}

function build_all_archs 
{
  setup_build_environment
  
  # run the prepare function
  eval $1
  
  echo "Building for ${ARCHS[@]}"
  
  for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    if [ "${ARCH}" == "arm64" ]; then
        HOST="aarch64-apple-darwin"
    else
        HOST="${ARCH}-apple-darwin"
    fi

    echo "Building ${LIBRARY_NAME} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
    echo "Please stand by..."	
    DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

    # run the per arch build command
    eval $2
  done
  
  # run the finishing function (usually lipo)
  eval $3
}

