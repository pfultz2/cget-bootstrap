#! /bin/sh
#

set -e

PREFIX_DIR=$HOME/usr
TMP_DIR=$PREFIX_DIR/tmp
DOWNLOAD_DIR=$TMP_DIR/download
BUILD_DIR=$TMP_DIR/build
PYTHON_VERSION="2.7.9"
GCC_VERSION="4.9.3"
CPU_COUNT=$(nproc)

mkdir -p $DOWNLOAD_DIR
mkdir -p $BUILD_DIR
cd $DOWNLOAD_DIR

if [ ! -e gcc-${GCC_VERSION}.tar.gz ] ; then
wget http://mirrors-usa.go-parts.com/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
fi
if [ ! -e bzip2-1.0.6.tar.gz ] ; then
wget http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz
fi
if [ ! -e xz-5.2.2.tar.gz ] ; then
wget http://tukaani.org/xz/xz-5.2.2.tar.gz
fi
if [ ! -e OpenSSL_1_0_1t.tar.gz ] ; then
wget https://github.com/openssl/openssl/archive/OpenSSL_1_0_1t.tar.gz -O OpenSSL_1_0_1t.tar.gz
fi
if [ ! -e curl-7.35.0.tar.gz ] ; then
wget --no-check-certificate http://curl.haxx.se/download/curl-7.35.0.tar.gz
fi
if [ ! -e sqlite-autoconf-3080300.tar.gz ] ; then
wget http://www.sqlite.org/2014/sqlite-autoconf-3080300.tar.gz
fi
if [ ! -e cmake-3.4.3.tar.gz ] ; then
wget --no-check-certificate http://cmake.org/files/v3.4/cmake-3.4.3.tar.gz
fi
if [ ! -e Python-${PYTHON_VERSION}.tar.xz ] ; then
wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
fi
if [ ! -e get-pip.py ] ; then
wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py
fi


#
# Build gcc first
#

if [ ! -e $PREFIX_DIR/bin/gcc ]; then

  # get the source code
  cd $BUILD_DIR
  echo "tar -xf $DOWNLOAD_DIR/gcc-${GCC_VERSION}.tar.gz"
  tar -xf $DOWNLOAD_DIR/gcc-${GCC_VERSION}.tar.gz

  # download the prerequisites
  cd gcc-${GCC_VERSION}
  ./contrib/download_prerequisites

  # create the build directory
  cd ..
  rm -rf gcc-build
  mkdir gcc-build
  cd gcc-build

  # build
  ../gcc-${GCC_VERSION}/configure     \
      --prefix=${PREFIX_DIR}          \
      --disable-multilib              \
      --enable-__cxa_atexit           \
      --enable-clocale=gnu            \
      --enable-languages=c,c++        \
  && make -j${CPU_COUNT} \
  && make install
fi

export PATH=$PREFIX_DIR/bin:$PATH
export PKG_CONFIG_PATH=$PREFIX_DIR/lib/pkgconfig:$PKG_CONFIG_PATH
export CC="$PREFIX_DIR/bin/gcc"
export CXX="$PREFIX_DIR/bin/g++"
export LDFLAGS="-Wl,-rpath,$PREFIX_DIR/lib64 -Wl,-rpath,$PREFIX_DIR/lib -L$PREFIX_DIR/lib -L$PREFIX_DIR/lib64"
export CPPFLAGS="-I$PREFIX_DIR/include $CPPFLAGS"
export CFLAGS="-I$PREFIX_DIR/include $CFLAGS"
export CXXFLAGS="-I$PREFIX_DIR/include $CXXFLAGS"

if [ ! -e $PREFIX_DIR/lib/libbz2.so.1.0.6 ]; then
  cd $PREFIX_DIR
  tar xvzf $DOWNLOAD_DIR/bzip2-1.0.6.tar.gz
  cd bzip2*
  make -f Makefile-libbz2_so -j${CPU_COUNT}
  make install PREFIX=$PREFIX_DIR
  cp libbz2.so.1.0 libbz2.so.1.0.6 $PREFIX_DIR/lib
fi

if [ ! -e $PREFIX_DIR/lib/liblzma.so.5.2.2 ]; then
  cd $PREFIX_DIR
  tar xvzf $DOWNLOAD_DIR/xz-5.2.2.tar.gz
  cd xz-*
  ./configure --prefix=$PREFIX_DIR
  make -j${CPU_COUNT}
  make install
fi

if [ ! -e $PREFIX_DIR/bin/openssl ]; then
   cd $BUILD_DIR
   tar xvzf $DOWNLOAD_DIR/OpenSSL_*
   cd openssl-*
   ./config --prefix=$PREFIX_DIR --openssldir=$PREFIX_DIR/etc/ssl --libdir=lib shared
   make -j${CPU_COUNT}
   make install
fi


if [ ! -e $PREFIX_DIR/bin/curl ]; then
   cd $BUILD_DIR
   tar xvzf $DOWNLOAD_DIR/curl-*
   cd curl-*
   ./configure --prefix=$PREFIX_DIR
   make -j${CPU_COUNT}
   make install
fi

if [ ! -e $PREFIX_DIR/bin/sqlite3 ]; then
   cd $BUILD_DIR
   tar xvzf $DOWNLOAD_DIR/sqlite*tar.gz
   cd sqlite-*
   ./configure --prefix=$PREFIX_DIR
   make -j${CPU_COUNT}
   make install
fi

if [ ! -e $PREFIX_DIR/bin/cmake ]; then
   cd $BUILD_DIR
   tar xvzf $DOWNLOAD_DIR/cmake*tar.gz
   cd cmake-*
   ./configure --prefix=$PREFIX_DIR
   make -j${CPU_COUNT}
   make install
fi

if [ ! -e $PREFIX_DIR/bin/python ]; then
   cd $BUILD_DIR
   tar xf $DOWNLOAD_DIR/Python*tar.xz
   cd Python-*
   ./configure --prefix=$PREFIX_DIR --without-gcc
   make -j${CPU_COUNT}
   make install
fi

$PREFIX_DIR/bin/python $DOWNLOAD_DIR/get-pip.py

pip --help

echo "Success. To proceed you may want to set"
echo 'export PATH=$PREFIX_DIR/bin:$PATH'
echo 'export PKG_CONFIG_PATH=$PREFIX_DIR/lib/pkgconfig:$PKG_CONFIG_PATH'
