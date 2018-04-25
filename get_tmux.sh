#!/bin/bash

# Script for installing tmux on systems where you don't have root access.
# tmux will be installed in ${INSTALL_TO}/bin.
# It's assumed that wget and a C/C++ compiler are installed.

INSTALL_TO=/om/user/lbh/

# exit on error
set -e

#TMUX_VERSION=1.8
TMUX_VERSION=2.7

# create our directories
mkdir -p ${INSTALL_TO} $HOME/tmux_tmp
cd $HOME/tmux_tmp

# download source files for tmux, libevent, and ncurses
wget -O tmux-${TMUX_VERSION}.tar.gz http://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
wget https://github.com/downloads/libevent/libevent/libevent-2.0.19-stable.tar.gz
wget ftp://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz

# extract files, configure, and compile

############
# libevent #
############
tar xvzf libevent-2.0.19-stable.tar.gz
cd libevent-2.0.19-stable
./configure --prefix=${INSTALL_TO} --disable-shared
make
make install
cd ..

############
# ncurses  #
############
tar xvzf ncurses-5.9.tar.gz
cd ncurses-5.9
./configure --prefix=${INSTALL_TO}
make
make install
cd ..

############
# tmux     #
############
tar xvzf tmux-${TMUX_VERSION}.tar.gz
cd tmux-${TMUX_VERSION}
./configure CFLAGS="-I${INSTALL_TO}/include -I${INSTALL_TO}/include/ncurses" LDFLAGS="-L${INSTALL_TO}/lib -L${INSTALL_TO}/include/ncurses -L${INSTALL_TO}/include"
CPPFLAGS="-I${INSTALL_TO}/include -I${INSTALL_TO}/include/ncurses" LDFLAGS="-static -L${INSTALL_TO}/include -L${INSTALL_TO}/include/ncurses -L${INSTALL_TO}/lib" make
cp tmux ${INSTALL_TO}/bin
cd ..

# cleanup
rm -rf $HOME/tmux_tmp

echo "${INSTALL_TO}/bin/tmux is now available. You can optionally add ${INSTALL_TO}/bin to your PATH."
