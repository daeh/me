# Script to install git, vim, tmux, zsh locally
# Original tmux install script: https://gist.github.com/ryin/3106801

# exit on error
set -e

TMUX_VERSION=2.9a
LIBEVENT_VERSION=2.1.8-stable
NCURSES_VERSION=6.1
CURL_VERSION=7.68.0
GIT_VERSION=2.25.0
VIM_VERSION=8.2.0316
ZSH_VERSION=5.8

DEFAULT_INSTALL_TO=$HOME/me
read -p "Install to: [$DEFAULT_INSTALL_TO]: " INSTALL_TO
INSTALL_TO=${INSTALL_TO:-$DEFAULT_INSTALL_TO}

TEMP_DIR=$INSTALL_TO/temp_install
mkdir -p $INSTALL_TO $TEMP_DIR $INSTALL_TO/dependencies
cd $TEMP_DIR

#  on AWS, make sure we have gcc and libcurl
which gcc || sudo -n yum groupinstall -y "Development Tools" || ( echo no gcc; exit )
which curl-config || sudo -n yum install -y curl-devel || ( echo no libcurl; exit )

# ---------------------- Dependencies ------------------------

############
# libevent # (for tmux)
############
if [ ! -d $INSTALL_TO/dependencies/libevent ]; then
	wget https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz
	tar -xvzf libevent-${LIBEVENT_VERSION}.tar.gz
	cd libevent-${LIBEVENT_VERSION}
	./configure --prefix=$INSTALL_TO/dependencies/libevent --disable-shared
	make install
	cd ..
fi


############
# ncurses  # (for tmux, zsh)
############
if [ ! -d $INSTALL_TO/dependencies/ncurses ]; then
	wget https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
	tar -xvzf ncurses-${NCURSES_VERSION}.tar.gz
	cd ncurses-${NCURSES_VERSION}
	./configure --prefix=$INSTALL_TO/dependencies/ncurses CXXFLAGS="-fPIC" CFLAGS="-fPIC"
	make install
	cd ..
fi


###############
### openssl  # (for git)
##############
#if [ ! -d $INSTALL_TO/dependencies/openssl ]; then
#	wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
#	tar -xvf openssl-1.1.1b.tar.gz
#	cd openssl-1.1.1b
#	./config --prefix=$INSTALL_TO/dependencies/openssl
#	make install
#	cd ..
#fi
#
##############
###   curl   # (for git)
##############
#if [ ! -d $INSTALL_TO/dependencies/curl ]; then
#	wget http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
#	tar -xvf curl-${CURL_VERSION}.tar.gz
#	cd curl-${CURL_VERSION}
#	./configure --prefix=$INSTALL_TO/dependencies/curl -enable-shared --with-ssl=$INSTALL_TO/dependencies/openssl
#	make install
#	cd ..
#fi
#
##############
###  expat   # (for git)
##############
#if [ ! -d $INSTALL_TO/dependencies/expat ]; then
#	wget http://downloads.sourceforge.net/expat/expat-2.1.0.tar.gz
#	tar expat-2.1.0.tar.gz
#	cd expat-2.1.0
#	./configure --prefix=$INSTALL_TO/dependencies/expat
#	make install
#	cd ..
#fi


## ---------------------- Packages ------------------------
includes="-I$INSTALL_TO/dependencies/libevent/include -I$INSTALL_TO/dependencies/ncurses/include -I$INSTALL_TO/dependencies/ncurses/include/ncurses"
libs="-L$INSTALL_TO/dependencies/libevent/lib -L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/libevent/include -L$INSTALL_TO/dependencies/ncurses/include -L$INSTALL_TO/dependencies/ncurses/include/ncurses"

############
#   git    #
############
rm -rf $INSTALL_TO/git
if [ ! -d $INSTALL_TO/git ]; then
	wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz
	tar -xvf git-${GIT_VERSION}.tar.xz
	cd git-${GIT_VERSION}
	./configure --prefix=$INSTALL_TO/git --with-curl
	make install
	cd ..
fi
path_extra="$INSTALL_TO/git/bin:$path_extra"

#rm -rf $INSTALL_TO/git
#if [ ! -d $INSTALL_TO/git ]; then
#	#wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz
#	#tar -xvf git-${GIT_VERSION}.tar.xz
#	cd git-${GIT_VERSION}
#	export PATH=$INSTALL_TO/dependencies/curl/bin:$PATH
#	CFLAGS="-I$INSTALL_TO/dependencies/curl/lib -I$INSTALL_TO/dependencies/curl/include" \
#	CPPFLAGS="-I$INSTALL_TO/dependencies/curl/lib -I$INSTALL_TO/dependencies/curl/include" \
#	LDFLAGS="-L$INSTALL_TO/dependencies/curl/lib -L$INSTALL_TO/dependencies/curl/include" \
#	  ./configure --prefix=$INSTALL_TO/git --with-curl=$INSTALL_TO/dependencies/curl --with-expat=$INSTALL_TO/dependencies/expat --with-openssl=$INSTALL_TO/dependencies/openssl
#	echo make install
#	sleep 5
#	make install
#	cd ..
#fi
#path_extra="$INSTALL_TO/git/bin:$path_extra"

############
#   tmux   #
############
if [ ! -d $INSTALL_TO/tmux ]; then
	wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
	tar xvzf tmux-${TMUX_VERSION}.tar.gz
	cd tmux-${TMUX_VERSION}
	CFLAGS="$includes" LDFLAGS="$libs" \
	  ./configure --prefix=$INSTALL_TO/tmux 
	CPPFLAGS="$includes" LDFLAGS="-static $libs" \
	  make install
	cd ..
fi
path_extra="$INSTALL_TO/tmux/bin:$path_extra"

############
#   vim    #
############
if [ ! -d $INSTALL_TO/vim ]; then
	wget https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz
	tar -xvf v${VIM_VERSION}.tar.gz
	cd vim-${VIM_VERSION}
	vim_cv_tgetent=zero LDFLAGS="-L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/ncurses/bin" \
	  ./configure --prefix=$INSTALL_TO/vim
	make install
	cd ..
fi
path_extra="$INSTALL_TO/vim/bin:$path_extra"

############
#   zsh    #
############
if [ ! -d $INSTALL_TO/vim ]; then
	wget https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download -O zsh-${ZSH_VERSION}.tar.xz
	tar -xvf zsh-${ZSH_VERSION}.tar.xz
	cd zsh-${ZSH_VERSION}
	CFLAGS="$includes" LDFLAGS="$libs" \
	  ./configure --prefix=$INSTALL_TO/zsh
	CPPFLAGS="$includes" LDFLAGS="-static $libs" \
	  make install
	cd ..
fi
path_extra="$INSTALL_TO/zsh/bin:$path_extra"



# ------------- Extensions / Config -------------------
# Oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
	PATH=$INSTALL_TO/zsh/bin:$PATH RUNZSH=no sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
fi

# Zsh plugins
zshcustom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
if [ ! -f ${zshcustom}/bullet-train.zsh-theme ]; then
	wget http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -O ${zshcustom}/bullet-train.zsh-theme
fi
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions ${zshcustom}/plugins/zsh-autosuggestions
fi
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${zshcustom}/plugins/zsh-syntax-highlighting
fi

# tmux plugin manager
if [ ! -d $HOME/.tmux/plugins/tpm ]; then
	git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


if [ ! -d $INSTALL_TO/me ]; then
	$INSTALL_TO/git/bin/git clone https://github.com/insperatum/me.git $INSTALL_TO/me
fi
cd $INSTALL_TO/me
git pull

for dotfile in $(ls -a $INSTALL_TO/me/dotfiles | grep [^.]); do
	echo Addding dotfile: $dotfile
	if [ -f $HOME/$dotfile ]; then
		if [ -L $HOME/$dotfile ]; then
			rm $HOME/$dotfile	
		else
			mv $HOME/$dotfile $HOME/${dotfile}_$(date +"%F_%H.%M.%S")
		fi
	fi
	ln -s $INSTALL_TO/me/dotfiles/$dotfile $HOME/$dotfile
done


# -----------------------------------------------------

# cleanup
rm -rf $TEMP_DIR

# Create .merc file
echo "export PATH=$path_extra:\$PATH" > $HOME/.merc
echo "export DEFAULT_TMUX_SHELL=$INSTALL_TO/zsh/bin/zsh" >> $HOME/.merc
grep "source \$HOME/.merc" $HOME/.bashrc || echo "source \$HOME/.merc" >> $HOME/.bashrc
