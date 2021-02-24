libs=(
    /usr/local/Cellar/gcc/10.2.0_4
    /usr/local/Cellar/giflib/5.2.1
    /usr/local/Cellar/jpeg/9d
    /usr/local/Cellar/libtiff/4.2.0
    /usr/local/Cellar/gnutls/3.6.15

    # Required by gnutls
    /usr/local/Cellar/nettle/3.7
    /usr/local/Cellar/libtasn1/4.16.0
    /usr/local/Cellar/p11-kit/0.23.22
)
export CFLAGS="-I/usr/local/Cellar/gcc/10.2.0_4/include -O2 -march=native"
export LDFLAGS="-L/usr/local/Cellar/gcc/10.2.0_4/lib/gcc/10 -I/usr/local/Cellar/gcc/10.2.0_4/include"

export PATH="/usr/local/Cellar/gcc/:${PATH}"
export LIBRARY_PATH="/usr/local/Cellar/gcc/10.2.0_4/lib/gcc/10:${LIBRARY_PATH:-}"

#export CXX="c++-10"
PKG_CONFIG_PATH=""

export CPPFLAGS="${CFLAGS}"
export CFLAGS
export LDFLAGS
export PKG_CONFIG_PATH

./autogen.sh

export CC="clang"

./configure \
    --disable-silent-rules \
    --with-cocoa \
    --with-nativecomp \
    --with-json \
    --without-dbus \
    --without-imagemagick \
    --with-mailutils \
    --with-ns \
    --with-json \
    --with-cairo \
    --with-modules \
    --with-xml2 \
    --with-gnutls \
    --with-rsvg \


