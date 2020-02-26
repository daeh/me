# Script to install git, vim, tmux, zsh locally
# Original tmux install script: https://gist.github.com/ryin/3106801

# exit on error
set -e

TMUX_VERSION=2.9a
LIBEVENT_VERSION=2.1.8-stable
NCURSES_VERSION=6.1
GIT_VERSION=2.25.0
VIM_VERSION=8.2.0316
ZSH_VERSION=5.8
INSTALL_TO=$(pwd)/bin2
TEMP_DIR=$INSTALL_TO/temp

mkdir -p $INSTALL_TO $TEMP_DIR $INSTALL_TO/dependencies
cd $TEMP_DIR

# on AWS, make sure we have gcc 
which gcc || sudo yum groupinstall "Development Tools"


# ---------------------- Dependencies ------------------------

############
# libevent #
############
wget https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz
tar xvzf libevent-${LIBEVENT_VERSION}.tar.gz
cd libevent-${LIBEVENT_VERSION}
./configure --prefix=$INSTALL_TO/dependencies/libevent --disable-shared
make install
cd ..

#############
## ncurses  #
#############
wget https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
tar xvzf ncurses-${NCURSES_VERSION}.tar.gz
cd ncurses-${NCURSES_VERSION}
./configure --prefix=$INSTALL_TO/dependencies/ncurses CXXFLAGS="-fPIC" CFLAGS="-fPIC"
make install
cd ..



## ---------------------- Packages ------------------------
includes="-I$INSTALL_TO/dependencies/libevent/include -I$INSTALL_TO/dependencies/ncurses/include -I$INSTALL_TO/dependencies/ncurses/include/ncurses"
libs="-L$INSTALL_TO/dependencies/libevent/lib -L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/libevent/include -L$INSTALL_TO/dependencies/ncurses/include -L$INSTALL_TO/dependencies/ncurses/include/ncurses"

############
#   git    #
############
wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz
tar -xvf git-${GIT_VERSION}.tar.xz
cd git-${GIT_VERSION}
./configure --prefix=$INSTALL_TO/git
make install
path_extra="$INSTALL_TO/git/bin:$path_extra"
cd ..

############
#   tmux   #
############
wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
tar xvzf tmux-${TMUX_VERSION}.tar.gz
cd tmux-${TMUX_VERSION}
CFLAGS="$includes" LDFLAGS="$libs" \
  ./configure --prefix=$INSTALL_TO/tmux 
CPPFLAGS="$includes" LDFLAGS="-static $libs" \
  make install
cd ..

############
#   vim    #
############
wget https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz
tar -xvf v${VIM_VERSION}.tar.gz
cd vim-${VIM_VERSION}
vim_cv_tgetent=zero LDFLAGS="-L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/ncurses/bin" \
  ./configure --prefix=$INSTALL_TO/vim
make install
cd ..

############
#   zsh    #
############
wget https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download -O zsh-${ZSH_VERSION}.tar.xz
tar -xvf zsh-${ZSH_VERSION}.tar.xz
cd zsh-${ZSH_VERSION}
CFLAGS="$includes" LDFLAGS="$libs" \
  ./configure --prefix=$INSTALL_TO/zsh
CPPFLAGS="$includes" LDFLAGS="-static $libs" \
  make install
cd ..



# -----------------------------------------------------

# cleanup
rm -rf $TEMP_DIR

# for the in order to add to the .bashrc (for /sh/bash) comment-in below line
# echo 'export PATH="$HOME/local/bin:$PATH"' >> $HOME/.bashrc
