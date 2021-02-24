echo "Cloning into emacs source..."
git clone https://github.com/emacs-mirror/emacs.git

echo "Checking out native-comp branch..."
git checkout features/native-comp

libs=(
    /usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0_4
    /usr/lib/
    /usr/lib/p11-kit/
)
export CFLAGS="-I/usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0/include -O3 -march=native"
export LDFLAGS="-L/usr/lib/"

export PATH="/usr/local/Cellar/gcc/:${PATH}"
export LIBRARY_PATH="/usr/lib:${LIBRARY_PATH:-}"

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
    --with-nativecomp \
    --with-json \
    --without-dbus \
    --without-imagemagick \
    --with-mailutils \
    --with-json \
    --with-cairo \
    --with-modules \
    --with-xml2 \
    --with-gnutls \
    --with-rsvg \
