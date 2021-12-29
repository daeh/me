# Script to install git, vim, tmux, zsh locally
# Original tmux install script: https://gist.github.com/ryin/3106801

# exit on error
set -e

### openmind specific modules
module load openmind/gcc/11.1.0
module load openmind/isl/0.23
module load openmind/mpfr/4.1.0  openmind/mpc/1.2.1 
module load openmind/make/4.3

LIBEVENT_VERSION=2.1.12-stable # https://libevent.org/
NCURSES_VERSION=6.3 # https://invisible-island.net/ncurses/announce.html#h2-release-notes
CURL_VERSION=7.80.0 # https://curl.haxx.se/download.html
GIT_VERSION=2.34.1 # https://git-scm.com/download/linux
GIT_MIN_VERSION=2.17
TMUX_VERSION=3.2a # https://github.com/tmux/tmux/wiki
VIM_VERSION=8.2.1379
ZSH_VERSION=5.8 # http://zsh.sourceforge.net/releases.html

DEFAULT_INSTALL_TO="${ME_PATH:-$HOME/me}"
read -p "Install to: [$DEFAULT_INSTALL_TO]: " INSTALL_TO
INSTALL_TO="${INSTALL_TO:-$DEFAULT_INSTALL_TO}"

echo "Installing to: $INSTALL_TO"
sleep 1

TEMP_DIR=$INSTALL_TO/temp_install
mkdir -p $INSTALL_TO $TEMP_DIR $INSTALL_TO/dependencies
cd $TEMP_DIR

# Make sure we have gcc
which gcc || sudo -n yum groupinstall -y "Development Tools" || ( echo no gcc; exit 1 )

# compare version numbers
version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

# ---------------------- Dependencies ------------------------

############
# libevent # (for tmux)
############
if [ ! -d $INSTALL_TO/dependencies/libevent ]; then
	wget "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz"
	tar -xvzf "libevent-${LIBEVENT_VERSION}.tar.gz"
	cd "libevent-${LIBEVENT_VERSION}"
	./configure --prefix=$INSTALL_TO/dependencies/libevent --disable-shared
	make install
	cd ..
fi


############
# ncurses  # (for tmux, zsh)
############
if [ ! -d $INSTALL_TO/dependencies/ncurses ]; then
	wget "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz" --no-check-certificate
	tar -xvzf "ncurses-${NCURSES_VERSION}.tar.gz"
	cd "ncurses-${NCURSES_VERSION}"
	./configure --prefix=$INSTALL_TO/dependencies/ncurses CXXFLAGS="-fPIC" CFLAGS="-fPIC"
	make install
	cd ..
fi

############
#   curl   # (for git)
############
# If curl is not already installled...
which curl-config || sudo -n yum install -y curl-devel || \
if [ ! -d $INSTALL_TO/dependencies/curl ]; then
	wget "http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz"
	tar -xvf "curl-${CURL_VERSION}.tar.gz"
	cd "curl-${CURL_VERSION}"
	./configure --prefix=$INSTALL_TO/dependencies/curl -enable-shared --with-ssl || (
		cd ..
		# might need to install openssl
		if [ ! -d $INSTALL_TO/dependencies/openssl ]; then
			wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
			tar -xvf openssl-1.1.1b.tar.gz
			cd openssl-1.1.1b
			./config --prefix=$INSTALL_TO/dependencies/openssl
			make install
			cd ..
		fi
		cd "curl-${CURL_VERSION}"
		./configure --prefix=$INSTALL_TO/dependencies/curl -enable-shared --with-ssl=$INSTALL_TO/dependencies/openssl
	)
	make install
	cd ..
fi

## ---------------------- Packages ------------------------
includes="-I$INSTALL_TO/dependencies/libevent/include -I$INSTALL_TO/dependencies/ncurses/include -I$INSTALL_TO/dependencies/ncurses/include/ncurses"
libs="-L$INSTALL_TO/dependencies/libevent/lib -L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/libevent/include -L$INSTALL_TO/dependencies/ncurses/include -L$INSTALL_TO/dependencies/ncurses/include/ncurses"

############
#   git    #
############
if [ ! -d $INSTALL_TO/git ]; then
	which git && version_gt $(git --version | cut -d" " -f3) $GIT_MIN_VERSION && has_git=1
	if [ $has_git ]; then
		echo "Using already-installed git";
	else
		wget "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz" --no-check-certificate
		tar -xvf "git-${GIT_VERSION}.tar.xz"
		cd "git-${GIT_VERSION}"
		if [ -d $INSTALL_TO/dependencies/curl ]; then
		  PATH=$INSTALL_TO/dependencies/curl/bin:$PATH \
		    ./configure --prefix=$INSTALL_TO/git --with-curl=$INSTALL_TO/dependencies/curl
		else
		  ./configure --prefix=$INSTALL_TO/git --with-curl
		fi
		make install
		cd ..
	fi
fi
path_extra="$INSTALL_TO/git/bin:$path_extra"

############
#   tmux   #
############
if [ ! -d $INSTALL_TO/tmux ]; then
	wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
	tar xvzf "tmux-${TMUX_VERSION}.tar.gz"
	cd "tmux-${TMUX_VERSION}"
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
	wget "https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz"
	tar -xvf "v${VIM_VERSION}.tar.gz"
	cd "vim-${VIM_VERSION}"
	vim_cv_tgetent=zero LDFLAGS="-L$INSTALL_TO/dependencies/ncurses/lib -L$INSTALL_TO/dependencies/ncurses/bin" \
	  ./configure --prefix=$INSTALL_TO/vim
	make install
	cd ..
fi
path_extra="$INSTALL_TO/vim/bin:$path_extra"

############
#   zsh    #
############
if [ ! -d $INSTALL_TO/zsh ]; then
	wget "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download -O zsh-${ZSH_VERSION}.tar.xz"
	tar -xvf "zsh-${ZSH_VERSION}.tar.xz"
	cd "zsh-${ZSH_VERSION}"
	CFLAGS="$includes" LDFLAGS="$libs" \
	  ./configure --prefix=$INSTALL_TO/zsh
	CPPFLAGS="$includes" LDFLAGS="-static $libs" \
	  make install
	cd ..
fi
path_extra="$INSTALL_TO/zsh/bin:$path_extra"


############
#freesurfer#
############
### install instructions https://surfer.nmr.mgh.harvard.edu/fswiki//FS7_linux
### downloads https://surfer.nmr.mgh.harvard.edu/fswiki/rel7downloads
# cat /etc/centos-release ### check which centos release
# cd /om2/user/daeda/software || exit
# rm -r freesurfer ### remove old version
# wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.1/freesurfer-linux-centos7_x86_64-7.1.1.tar.gz
# tar -zxvpf freesurfer-linux-centos7_x86_64-7.1.1.tar.gz
# rm freesurfer-linux-centos7_x86_64-7.1.1.tar.gz
# cd freesurfer

# ### add to .me.conf ###
# export FREESURFER_HOME=/om2/user/daeda/software/freesurfer ### 7.1.1
# export SUBJECTS_DIR=$FREESURFER_HOME/subjects
# export FS_LICENSE='/gablab/p/ADHDER/data/adhder/code/license.txt'
# source $FREESURFER_HOME/SetUpFreeSurfer.sh


# ------------- Extensions / Config -------------------
export PATH=$path_extra:$PATH

# Dotfiles
if [ ! -d $INSTALL_TO/me ]; then
	git clone https://github.com/daeh/me.git $INSTALL_TO/me
fi
cd $INSTALL_TO/me
git pull

# for dotfile in $(ls -a $INSTALL_TO/me/dotfiles | grep [^.]); do
for dotfilesrc in $(ls -a $INSTALL_TO/me/dotfiles); do

    # if [ ${#dotfile} -ge 3 ]; then ### skip . and ..
    if [[ $dotfilesrc != .* ]]; then ### skip ., .., .DS_*
		dotfile=".${dotfilesrc}"
		echo "Addding dotfile: ${dotfile}"

		if [ -L $HOME/$dotfile ]; then ### is symbolic link
			rm $HOME/$dotfile	
		elif [ -f $HOME/$dotfile ]; then ### is file
			mv $HOME/$dotfile "$HOME/${dotfile}_"$(date +"%F_%H.%M.%S")
		fi
		ln -s $INSTALL_TO/me/dotfiles/$dotfilesrc $HOME/$dotfile
	else
		echo "Skipping dotfilesrc: ${dotfilesrc}"
    fi 

done


# Oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
	PATH=$INSTALL_TO/zsh/bin:$PATH RUNZSH=no CHSH=no sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
fi

# Zsh plugins
zshcustom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
# if [ ! -f ${zshcustom}/bullet-train.zsh-theme ]; then
# 	wget http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -O ${zshcustom}/bullet-train.zsh-theme
# fi
if [ ! -d ${zshcustom}/themes/powerlevel10k ]; then
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${zshcustom}/themes/powerlevel10k
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
# in case tmux is running
tmux kill-server
# start a server but don't attach to it
tmux start-server
# create a new session but don't attach to it either
tmux new-session -d
# install the plugins
$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh
# killing the server is not required, I guess
tmux kill-server


# -----------------------------------------------------

# cleanup
rm -rf $TEMP_DIR

# Create .merc file
echo "export PATH=$path_extra:\$PATH" > $HOME/.merc
echo "export DEFAULT_TMUX_SHELL=$INSTALL_TO/zsh/bin/zsh" >> $HOME/.merc
echo "export ME_PATH=$INSTALL_TO" >> $HOME/.merc
echo "source \$HOME/.me.conf" >> $HOME/.merc
grep "source \$HOME/.merc" $HOME/.bash_profile || echo "source \$HOME/.merc" >> $HOME/.bash_profile || 
grep "source \$HOME/.merc" $HOME/.bashrc || echo "source \$HOME/.merc" >> $HOME/.bashrc

### for some reason, I need this in my .bashrc :
# export PATH=$HOME/local/bin:$PATH
# having source $HOME/.merc in .bash_profile alone does not work, having that and `source $HOME/.merc` in $HOME/.bashrc does not work.

echo Installled to: $INSTALL_TO
