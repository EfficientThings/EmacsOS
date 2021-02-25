EMACSOS_DIR=$(pwd)

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

function melpa_ensure()
{
    printf "Installing package $1... "
    if emacs -q -l "$EMACSOS_DIR/melpa-conf.el" -batch -eval "(package-install '$1)" &> /dev/null; then
        printf_good "done.\n"
    else
        printf_bad "failed.\n"
        exit 1
    fi
}

function curl_ensure()
{
    echo "Downloading $2... "
    if ! curl $1 > $2; then
        printf_bad "Failed.\n"
        exit 1
    fi
}

echo "Cloning into emacs source..."
#git submodule add https://github.com/emacs-mirror/emacs.git
printf "\u001b[32mDone cloning emacs!\u001b[0m\n"

echo "Checking out native-comp branch..."
#cd emacs
#git checkout features/native-comp &> /dev/null
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

printf "Running ./autogen.sh (progress visible in ./autogen.log)... "
if ./autogen.sh > ./autogen.log; then
    printf_good "done.\n"
else
    printf_bad "failed.\n"
fi

read -p "Which compiler do you want to use? (clang/gcc) " SEL_CC

if [[ $SEL_CC == "clang" ]]; then
    export CC="clang"
elif [[ $SEL_CC == "gcc" ]]; then
    export CC="gcc"
fi

QUESTIONS=("Enable native compilation? (y/n/?)" "Enable dbus support? (y/n/?)" "Enable json support? (y/n/?)" "Use Cairo instead of ImageMagick? (y/n/?)")
EXPECTED_ANSWERS=("y" "y" "y" "n" "y" "y")
DOCUMENTATION=(
"gccemacs (or native-comp) is a modified Emacs capable of compiling and running Emacs Lisp as native code in form of re-loadable elf files. As the name suggests this is achieved by blending together Emacs and the gcc infrastructure."

"Emacs will autolaunch a D-Bus session bus, when the environment variable DISPLAY is set, but no session bus is running. This might be inconvenient for Emacs when running as daemon or running via a remote ssh connection."

"Compile with native JSON support."

"Cairo is a 2D graphics library with support for multiple output devices. Cairo is designed to produce consistent output on all output media while taking advantage of display hardware acceleration when available (eg. through the X Render Extension)."
)
FLAGS=("--with-nativecomp" "--without-dbus --without-gconf --without-gsettings" "--with-json" "--with-cairo --without-imagemagick")

CONFIGURE_COMMAND="./configure"

read -p "Use default build options? (y/n) " ANS
if [ $ANS == "y" ]; then
    CONFIGURE_COMMAND+=" --disable-silent-rules --with-nativecomp --with-json --without-dbus --without-imagemagick"
    CONFIGURE_COMMAND+="--with-mailutils --with-cairo --with-modules --with-xml2 --with-gnutls --with-rsvg"
elif [ $ANS == "n" ]; then
    for (( i=0; i<${#QUESTIONS[@]}; i++ )); do
        read -p "${QUESTIONS[$i]} " ANS
        if [[ $ANS == $EXPECTED_ANSWERS[$i] ]]; then
            CONFIGURE_COMMAND+=" ${FLAGS[$i]}"
        elif [[ $ANS == "?" ]]; then
            printf "\u001b[2m${DOCUMENTATION[$i]}\u001b[0m\n"
            i=$i-1
        fi
    done
fi

if [[ $OS == "Darwin" ]]; then
    CONFIGURE_COMMAND+=" --with-ns --with-cocoa"
fi

printf "Running ./configure (progress visible in ./configure.log, should take a bit)... "
if $CONFIGURE_COMMAND > ./configure.log; then
    printf_good "finished.\n"
else
    printf_bad "failed.\n"
fi

printf "Compiling (progress visible in ./configure.log, will take a WHILE)... "
if make > ./compile.log; then
    printf_good "finished.\n"
else
    printf_bad "failed.\n"
fi
cd ..

printf_good "Installed!\n"

read -p "Create a new .emacs.d? (y/n) " ANS
if [ $ANS == "y" ]; then
    if [ -d ~/.emacs.d ]; then
        echo "Detected existing Emacs configuration directory! Moving it to ~/.emacs.d.bak"
        if [ -d ~/.emacs.d.bak ]; then
            echo "Backup already exists! Please rename."
            exit 1
        fi
        mv ~/.emacs.d ~/.emacs.d.bak
        mkdir ~/.emacs.d
        touch ~/.emacs.d/init.el
        mkdir ~/.emacs.d/lisp
    fi
else
    echo "Fine, but you may run into unexpected behavior!"
fi

printf "Applying MELPA config... "
cp melpa-conf.el ~/.emacs.d/lisp/melpa-conf.el
echo "(add-to-list 'load-path \"~/.emacs.d/lisp/\")
(load 'melpa-conf)" >> ~/.emacs.d/init.el
printf_good "done.\n"

melpa_ensure exwm
printf "Applying exwm config... "
echo "(require 'exwm)
(require 'exwm-config)
(exwm-config-example)" >> ~/.emacs.d/init.el
printf_good "done.\n"
printf "Backing up .xinitrc to .xinitrc.bak..."
if [ -f ~/.xinitrc.bak ]; then
    printf "\n"
    echo "Backup already exists! Please rename."
    exit 1
else
    mv ~/.xinitrc ~/.xinitrc.bak
    printf_good "done.\n"
fi
printf "Writing to xinitrc... "
echo "#xhost +SI:localuser:$USER
#export _JAVA_AWT_WM_NONREPARENTING=1
#xsetroot -cursor_name left_ptr
#xset r rate 200 60
#exec emacs" > ~/.xinitrc
printf_good "done.\n"

melpa_ensure use-package

read -p "Install Doom Emacs theme packages? (y/n) " ANS
if [ $ANS == "y" ]; then
    melpa_ensure doom-themes
    melpa_ensure doom-modeline
    melpa_ensure solaire-mode
    melpa_ensure centaur-tabs
    printf "Applying relevant default configurations...\n"
    curl_ensure https://raw.githubusercontent.com/EfficientThings/emacsOS-config/master/doom-themeage.el ~/.emacs.d/lisp/doom-themeage.el
    echo "(load 'doom-themeage)" >> ~/.emacs.d/init.el
    printf_good "Done!\n"
fi
read -p "Install Ivy and associated packages? (y/n) " ANS
if [ $ANS == "y" ]; then
    melpa_ensure ivy
    melpa_ensure ivy-prescient
    melpa_ensure counsel
    melpa_ensure swiper
    printf "Applying relevant default configurations...\n"
    curl_ensure https://raw.githubusercontent.com/EfficientThings/emacsOS-config/master/ivy-config.el ~/.emacs.d/lisp/ivy-config.el
    echo "(load 'ivy-config)" >> ~/.emacs.d/init.el
    printf_good "Done!\n"
fi
read -p "Install code utility packages like lsp, company, yasnippet? (y/n) " ANS
if [ $ANS == "y" ]; then
    melpa_ensure lsp
    melpa_ensure lsp-ui
    melpa_ensure treemacs
    melpa_ensure lsp-treemacs
    melpa_ensure flycheck
    melpa_ensure company
    melpa_ensure yasnippet
    printf "Applying relevant default configurations...\n"
    curl_ensure https://raw.githubusercontent.com/EfficientThings/emacsOS-config/master/code-utils-config.el ~/.emacs.d/lisp/code-utils-config.el
    echo "(load 'code-utils-config)" >> ~/.emacs.d/init.el
    printf_good "Done!\n"
fi

printf_good "Ready for reboot!\n"
