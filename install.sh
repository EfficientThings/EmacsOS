# only works on a single words since bash seems to split up strings into args :/
function printf_good()
{
    printf "\u001b[32m"$1"\u001b[0m"
}

# only works on a single words since bash seems to split up strings into args :/
function printf_bad()
{
    printf "\u001b[31m"$1"\u001b[0m"
}


function brew_ensure()
{
    printf "Checking for $1 dependency... "
    if brew list $1 &> /dev/null; then
        printf_good "found.\n"
        return 0
    else
        printf "\u001b[31mnot found.\u001b[0m\n"
        sleep 0.1
        printf "Installing $1... "
        if brew install $1 &> /dev/null; then
            printf_good "installed.\n"
        else
            printf_bad "failed.\n"
            exit 1
        fi
    fi
}

function pacman_ensure()
{
    printf "Checking for $1 dependency... "
    if pacman -Q $1 &> /dev/null; then
        printf_good "found.\n"
        return 0
    else
        printf "\u001b[31mnot found.\u001b[0m\n"
        printf "Installing $1... "
        if ! which yay &> /dev/null; then
            printf_bad " error - yay is required for auto-install.\n"
            return 1
        else
            if yay -S $1 &> /dev/null; then
                printf_good "installed.\n"
                return 0
            else
                printf_bad "failed.\n"
                exit 1
            fi
        fi
    fi
}

echo "Cloning into emacs source..."
git submodule add https://github.com/emacs-mirror/emacs.git
printf "\u001b[32mDone cloning emacs!\u001b[0m\n"

echo "Checking out native-comp branch..."
cd emacs
git checkout features/native-comp &> /dev/null
cd ..
printf "\u001b[32mDone checking out native-comp!\u001b[0m\n"

printf "Determining OS... "
if [ $(uname -s) == "Darwin" ]; then
    OS="Darwin"
    printf "Darwin.\n"
    printf "Checking for brew... "
    if ! which brew &> /dev/null; then
        printf "\u001b[31mnot installed.\u001b[0m\n"
        exit 1
    else
        printf_good "installed.\n"
    fi

    brew_ensure gcc@10
    brew_ensure libgccjit
    brew_ensure llvm
    brew_ensure jpeg
    brew_ensure libtiff
    brew_ensure gnutls
    brew_ensure nettle
    brew_ensure libtasn1
    brew_ensure p11-kit

    libs=(
        /usr/local/Cellar/gcc/10.2.0_4
        /usr/local/Cellar/giflib/5.2.1
        /usr/local/Cellar/jpeg/9d
        /usr/local/Cellar/libtiff/4.2.0
        /usr/local/Cellar/gnutls/3.6.15
        /usr/local/Cellar/nettle/3.7
        /usr/local/Cellar/libtasn1/4.16.0
        /usr/local/Cellar/p11-kit/0.23.22
    )
    export CFLAGS="-I/usr/local/Cellar/gcc/10.2.0_4/include -O2 -march=native"
    export LDFLAGS="-L/usr/local/Cellar/gcc/10.2.0_4/lib/gcc/10 -I/usr/local/Cellar/gcc/10.2.0_4/include"
    export PATH="/usr/local/Cellar/gcc/:${PATH}"
    export LIBRARY_PATH="/usr/local/Cellar/gcc/10.2.0_4/lib/gcc/10:${LIBRARY_PATH:-}"
else
    OS="Linux"
    printf "Linux (assumed to be Arch).\n"
    pacman_ensure gcc
    printf "Checking gcc version... "
    if [ $(gcc --version | grep ^gcc | sed 's/^.* //g') == "10.2.0" ]; then
        printf_good "good.\n"
    else
        printf_bad "bad!\n"
        exit 1
    fi
    pacman_ensure libgccjit
    printf "Checking that /usr/lib/libjpeg.so exists... "
    if [ -f "/usr/lib/libjpeg.so" ]; then
        printf_good "yup.\n"
    else
        printf_bad "nope!\n"
        exit 1
    fi
    pacman_ensure clang
    pacman_ensure libtiff
    pacman_ensure gnutls
    pacman_ensure nettle
    pacman_ensure libtasn1
    pacman_ensure p11-kit

    libs=(
        /usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0_4
        /usr/lib/
        /usr/lib/p11-kit/
    )
    export CFLAGS="-I/usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0/include -O2 -march=native"
    export LDFLAGS="-L/usr/lib/"
    export PATH="/usr/lib/gcc/x86_64-pc-linux-gnu/10.2.0:${PATH}"
    export LIBRARY_PATH="/usr/lib:${LIBRARY_PATH:-}"
fi

PKG_CONFIG_PATH=""

export CPPFLAGS="${CFLAGS}"
export CFLAGS
export LDFLAGS
export PKG_CONFIG_PATH


./autogen.sh

export CC="clang"

if [ $OS == "Darwin" ]; then
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
        --with-rsvg
else
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
        --with-rsvg
fi
printf_good "Done!\n"
