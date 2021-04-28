#!/bin/bash
# Cross-compile environment for Android on ARMv7 and x86
#
# Contents licensed under the terms of the OpenSSL license
# http://www.openssl.org/source/license.html
#
# See http://wiki.openssl.org/index.php/FIPS_Library_and_Android
#   and http://wiki.openssl.org/index.php/Android


EXIT_CODE_SUCCESS=1
EXIT_CODE_ERROR_PARAM=-1

PLATFORM_ARMEABI="armeabi-v7a"
PLATFORM_ARM64="arm64-v8a"
PLATFORM_86="x86"
PLATFORM_86_64="x86-64"

_ndk_root=$ANDROID_NDK_ROOT
_platform=$PLATFORM_ARM64
_toolchain=linux-x86_64
_api=26

LD_LIBRARY_PATH=$(pwd)
_out=${LD_LIBRARY_PATH}/out-$_platform

if [ $# -gt 0 ]; then
  if [ $1 = "--help" ] || [ $1 = "-h" ]; then
    echo """
  Options:

    --ndk-home  :   设置Android ndk的根目录

    --platform  :   设置编译的平台类型
                     $PLATFORM_ARMEABI
                     $PLATFORM_ARM64
                     $PLATFORM_86
                     $PLATFORM_86_64

    --toolchain :   交叉编译工具目录，根据平台不同得到的，在NDK中的toolchains目录下的llvm/prebuilt，比如:
                     darwin-x86_64
                     linux-x86_64

    --api       :   设置编译的目标API

    --out       :   设置编译之后安装的输出目录
    """
    exit $EXIT_CODE_SUCCESS
  fi
fi

# 解析参数
for i in "$@"; do
    if [[ $i == --ndk-home* ]]; then
      _ndk_root=${i#*=}
      _ndk_root=${_ndk_root}
    elif [[ $i == --platform* ]]; then
      _platform=${i#*=}
      _platform=${_platform}
    elif [[ $i == --api* ]]; then
      _api=${i#*=}
      _api=${_api}
    elif [[ $i == --toolchain* ]]; then
      _toolchain=${i#*=}
      _toolchain=${_toolchain}
    elif [[ $i == --out* ]]; then
      _out=${i#*=}
      _out=${_out}
    else
      echo "未知参数: $i, Ignore"
    fi
done

# 判断参数有效性
checking_ret=1
if [ -z $_ndk_root ] || [ ! -d $_ndk_root ]; then
  echo "NDK目录无效，查看帮组 -h"
  checking_ret=0
fi
if [ -z $_toolchain ] || [ ! -d "$_ndk_root/toolchains/llvm/prebuilt/$_toolchain" ]; then
  echo "交叉编译工具设置无效，查看帮组 -h"
  checking_ret=0
fi
if [ -z $_platform ] || ([ $_platform != $PLATFORM_ARMEABI ] \
    && [ $_platform != $PLATFORM_ARM64 ] \
    && [ $_platform != $PLATFORM_86 ] \
    && [ $_platform != $PLATFORM_86_64 ]); then
  echo "平台设置错误，查看帮助 -h"
  checking_ret=0
fi
if [ -z $_api ] || [ $_api -lt "26" ]; then
  echo "最小api为26，查看帮组 -h"
  checking_ret=0
fi
if [ -z $_out ] || [ -z $_out ]; then
  echo "输出目录无效，查看帮组 -h"
  checking_ret=0
else
  mkdir -p $_out
  if [ ! -d $_out ]; then
    echo "输出目录无效，查看帮组 -h"
    checking_ret=0
  fi
fi

tool_platform=""
if [ $_platform == $PLATFORM_ARMEABI ]; then
  tool_platform=arm-linux-androideabi-4.9
elif [ $_platform == $PLATFORM_ARM64 ]; then
  tool_platform=aarch64-linux-android-4.9
elif [ $_platform == $PLATFORM_86 ]; then
  tool_platform=x86-4.9
elif [ $_platform == $PLATFORM_86_64 ]; then
  tool_platform=x86_64-4.9
fi

tool_path=$_ndk_root/toolchains/$tool_platform/prebuilt/$_toolchain/bin
llvm_tool_path=$_ndk_root/toolchains/llvm/prebuilt/$_toolchain/bin
if [ ! -d $tool_path ]; then
  echo "目录不存在，请检测NDK版本，需21及以上版本: $tool_path"
  checking_ret=0
fi
if [ ! -d $llvm_tool_path ]; then
  echo "目录不存在，请检测NDK版本，需21及以上版本: $llvm_tool_path"
  checking_ret=0
fi

if [ $checking_ret != 1 ]; then
  exit $EXIT_CODE_ERROR_PARAM
fi

echo """
设置成功：
NDK root       :$_ndk_root
Tool path      :$tool_path
               :$llvm_tool_path
Toolchain      :$_toolchain
Platform       :$_platform
Android api    :$_api
Build out      :$_out
"""

# 在Google官网中有定义编译选项：https://developer.android.com/ndk/guides/other_build_systems
# 克隆下来文件：git clone https://github.com/glennrp/libpng -b v1.6.37
# cd libpng
# export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/depending on your build machine...
# export TARGET=aarch64-linux-android（depending on your device...）
# export API=21
# export AR=$TOOLCHAIN/bin/llvm-ar
# export CC=$TOOLCHAIN/bin/$TARGET$API-clang
# export AS=$CC
# export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
# export LD=$TOOLCHAIN/bin/ld
# export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
# export STRIP=$TOOLCHAIN/bin/llvm-strip
# ./configure --host $TARGET
# make

#####################################################################
# export ANDROID_NDK_HOME=/home/yuri/AndroidSDK/ndk/21.1.6352462
# PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:
#      $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:
#      $PATH
# ./Configure android-arm64 -D__ANDROID_API__=26 --prefix=/home/yuri/WorkSpace/OpenSSL/out-arm
# make & make install
####################################################################

cipher=""
if [ $_platform == $PLATFORM_ARMEABI ]; then
  cipher=android-arm
elif [ $_platform == $PLATFORM_ARM64 ]; then
  cipher=android-arm64
elif [ $_platform == $PLATFORM_86 ]; then
  cipher=android-x86
elif [ $_platform == $PLATFORM_86_64 ]; then
  cipher=android-x86_64
fi

export ANDROID_NDK_HOME=$_ndk_root

PATH=$tool_path:$llvm_tool_path:$PATH

echo $PATH

echo "./Configure $cipher -D__ANDROID_API__=$_api --prefix=$_out"

./Configure $cipher -D__ANDROID_API__=$_api --prefix=$_out

echo "开始编译......"

make clean & make -j4 & make install

echo "开始完成......"
