# Script to install git, vim, tmux, zsh locally
# Original tmux install script: https://gist.github.com/ryin/3106801

# exit on error
set -e

### check for Rocky 8
### srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 -w node092 --pty zsh
### srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 -w node092 --pty zsh
# srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 --constraint=rocky8 --pty zsh
### lsb_release -d

### srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 --constraint=centos7 --pty bash
### srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 --constraint=rocky8 --pty bash
### lsb_release -d

### make sure we're in bash
echo "Current SHELL: $0"
ps -p $$

source /usr/share/Modules/init/bash
# export LD_LIBRARY_PATH=/home/daeda/me/dependencies/ncurses/lib:$LD_LIBRARY_PATH

if [ -f /etc/os-release ]; then
	# Get the distribution ID
	DISTRO_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
	DISTRO_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
	# cat /etc/os-release
	# hostnamectl
	# echo $(rpm -E "%{rhel}")
else
	echo "Cannot determine OS distribution"
fi

printf "\nFound OS %s %s\n" "${DISTRO_ID}" "${DISTRO_VERSION}"

case "$DISTRO_ID" in
	"centos")
		module load openmind/gcc/12.2.0
		DEFAULT_INSTALL_TO="${HOME}/me7"
		printf "\n\nCentos 7 detected\n\n"
		;;
	"rocky")
		module load openmind8/gcc/12.2.0
		DEFAULT_INSTALL_TO="${HOME}/me"
		printf "\n\Rocky 8 detected\n\n"
		;;
	*)
		printf "Unknown OS: %s %s. Default settings will be applied.\n\n" "${DISTRO_ID}" "${DISTRO_VERSION}"
		DEFAULT_INSTALL_TO="${ME_PATH:-$HOME/me_default}"
		;;
esac


DEFAULT_INSTALL_TO=${ME_PATH:-$HOME/me}


printf "\nInstalling to %s\n\n" "${DEFAULT_INSTALL_TO}"

module load openmind/isl/0.23
module load openmind/mpfr/4.1.0  openmind/mpc/1.2.1 
module load openmind/make/4.3

LIBEVENT_VERSION=2.1.12-stable # https://libevent.org/
NCURSES_VERSION=6.5 # https://invisible-island.net/ncurses/announce.html#h2-release-notes
CURL_VERSION=8.13.0 # https://curl.se/download.html
OPENSSL_VERSION=3.5.0 # https://www.openssl.org/source/
GIT_VERSION=2.49.0 # https://git-scm.com/download/linux
GIT_MIN_VERSION=2.49
TMUX_VERSION=3.5a # https://github.com/tmux/tmux/wiki
VIM_VERSION=9.1.1374 # https://github.com/vim/vim/tags
ZSH_VERSION=5.9 # http://zsh.sourceforge.net/releases.html
# NVM_VERSION=0.30.3 # https://github.com/nvm-sh/nvm/releases
NODE_VERSION=24.0.1 # https://nodejs.org/en/download


#### WARNING - DOES NOT WORK
# INSTALL_TO=${INSTALL_TO:-$DEFAULT_INSTALL_TO}
read -p "Install to: [$DEFAULT_INSTALL_TO]: " INSTALL_TO
INSTALL_TO=${INSTALL_TO:-"$DEFAULT_INSTALL_TO"}

echo "Installing to: $INSTALL_TO"
echo ""
sleep 1

# Step 2: Prompt for user input with the default value shown
read -p "Install to: [$DEFAULT_INSTALL_TO]: " INSTALL_TO

# Step 3: Set INSTALL_TO to DEFAULT_INSTALL_TO if the input was empty
if [ -z "$INSTALL_TO" ]; then
	INSTALL_TO="$DEFAULT_INSTALL_TO"
fi

# Step 4: Confirm the installation path
printf "Installing to: %s\n" "$INSTALL_TO"

# INSTALL_TO="/home/daeda/me"


TEMP_DIR=$INSTALL_TO/temp_install
### for clean install ###
# rm -r $TEMP_DIR 
# rm -r "${INSTALL_TO}/dependencies"
### ###
mkdir -p $INSTALL_TO $TEMP_DIR $INSTALL_TO/dependencies
cd "${TEMP_DIR}" || exit

path_extra=''

# Make sure we have gcc
which gcc || sudo -n yum groupinstall -y "Development Tools" || ( echo no gcc; exit 1 )

# compare version numbers
version_gt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}


# INSTALL_TO=
# TEMP_DIR=
echo "INSTALL_TO :: $INSTALL_TO"
echo "TEMP_DIR :: $TEMP_DIR"
echo "DISTRO_ID :: $DISTRO_ID"
echo "DISTRO_VERSION :: $DISTRO_VERSION"
echo "path_extra :: $path_extra"

# ---------------------- Dependencies ------------------------

############
# libevent # (for tmux)
############
if [ ! -d $INSTALL_TO/dependencies/libevent ]; then
	cd "${TEMP_DIR}"
	wget "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz"
	tar -xvzf "libevent-${LIBEVENT_VERSION}.tar.gz"
	cd "libevent-${LIBEVENT_VERSION}"
	./configure --prefix="${INSTALL_TO}/dependencies/libevent" --disable-shared
	make install
	cd "${TEMP_DIR}"
fi

############
# ncurses  # (for tmux, zsh)
############
case "$DISTRO_ID" in
	"centos")
		############
		# ncurses Centos 7 # (for tmux, zsh)
		############
		if [ ! -d $INSTALL_TO/dependencies/ncurses ]; then
			cd "${TEMP_DIR}"
			wget --no-check-certificate "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
			tar -xvzf "ncurses-${NCURSES_VERSION}.tar.gz"
			cd "ncurses-${NCURSES_VERSION}"
			./configure --prefix="${INSTALL_TO}/dependencies/ncurses" CXXFLAGS="-fPIC" CFLAGS="-fPIC" ### for libncursesw.so.6 , --enable-widec for *w, --with-shared for *.so.6
			make install
			cd "${TEMP_DIR}"
		fi
		;;
	"rocky")
		############
		# ncurses Rocky 8 # (for tmux, zsh)
		############
		if [ ! -d $INSTALL_TO/dependencies/ncurses ]; then
			cd "${TEMP_DIR}"
			wget --no-check-certificate "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
			tar -xvzf "ncurses-${NCURSES_VERSION}.tar.gz"
			cd "ncurses-${NCURSES_VERSION}"
			./configure --prefix="${INSTALL_TO}/dependencies/ncurses" --enable-widec --with-shared CXXFLAGS="-fPIC" CFLAGS="-fPIC" ### for libncursesw.so.6 , --enable-widec for *w, --with-shared for *.so.6
			make install
			cd "${TEMP_DIR}"
		fi
		;;
	*)
		printf "Unknown OS: %s %s. Default settings will be applied.\n\n" "${DISTRO_ID}" "${DISTRO_VERSION}"
		exit 1
		;;
esac

### ldconfig -p | grep libncursesw
# [daeda@node084 zsh-5.9]$ ldconfig -p | grep libncursesw
# 	libncursesw.so.6 (libc6,x86-64) => /lib64/libncursesw.so.6
# 	libncursesw.so.5 (libc6,x86-64) => /lib64/libncursesw.so.5


############
#   curl   # (for git)
############
### module add openmind/curl/7.85.0
# If curl is not already installed...
which curl-config || \
sudo -n yum install -y curl-devel || \
if [ ! -d $INSTALL_TO/dependencies/curl ]; then
	cd "${TEMP_DIR}"
	wget --no-check-certificate "https://curl.se/download/curl-${CURL_VERSION}.tar.gz"
	tar -xvf "curl-${CURL_VERSION}.tar.gz"
	cd "curl-${CURL_VERSION}"
	./configure --prefix=$INSTALL_TO/dependencies/curl -enable-shared --with-ssl || (
		cd "${TEMP_DIR}"
		# might need to install openssl
		if [ ! -d "${INSTALL_TO}/dependencies/openssl" ]; then
			wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
			tar -xvf "openssl-${OPENSSL_VERSION}.tar.gz"
			cd "openssl-${OPENSSL_VERSION}"
			./config --prefix="${INSTALL_TO}/dependencies/openssl"
			make install
			cd "${TEMP_DIR}"
		fi
		cd "curl-${CURL_VERSION}"
		./configure --prefix="${INSTALL_TO}/dependencies/curl" -enable-shared --with-ssl="${INSTALL_TO}/dependencies/openssl"
	)
	make install
	cd "${TEMP_DIR}"
fi

## ---------------------- Packages ------------------------

# includes="-I${INSTALL_TO}/dependencies/libevent/include -I${INSTALL_TO}/dependencies/ncurses/include -I${INSTALL_TO}/dependencies/ncurses/include/ncurses"
# libs="-L${INSTALL_TO}/dependencies/libevent/lib -L${INSTALL_TO}/dependencies/ncurses/lib -L${INSTALL_TO}/dependencies/libevent/include -L${INSTALL_TO}/dependencies/ncurses/include -L${INSTALL_TO}/dependencies/ncurses/include/ncurses"

case "$DISTRO_ID" in
	"centos")
		includes="-I${INSTALL_TO}/dependencies/libevent/include -I${INSTALL_TO}/dependencies/ncurses/include -I${INSTALL_TO}/dependencies/ncurses/include/ncurses"
		libs="-L${INSTALL_TO}/dependencies/libevent/lib -L${INSTALL_TO}/dependencies/ncurses/lib"
		;;
	"rocky")
		includes="-I${INSTALL_TO}/dependencies/libevent/include -I${INSTALL_TO}/dependencies/ncurses/include -I${INSTALL_TO}/dependencies/ncurses/include/ncursesw"
		libs="-L${INSTALL_TO}/dependencies/libevent/lib -L${INSTALL_TO}/dependencies/ncurses/lib"
		;;
	*)
		printf "Unknown OS: %s %s. Default settings will be applied.\n\n" "${DISTRO_ID}" "${DISTRO_VERSION}"
		exit 1
		;;
esac


########################################################################

############
#   zsh    #
############
if [ ! -d $INSTALL_TO/zsh ]; then
	cd "${TEMP_DIR}"
	wget --no-check-certificate -O "zsh-${ZSH_VERSION}.tar.xz" "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/zsh-${ZSH_VERSION}.tar.xz/download"
	tar -xvf "zsh-${ZSH_VERSION}.tar.xz"
	cd "zsh-${ZSH_VERSION}"
	CFLAGS="$includes" LDFLAGS="$libs" ./configure --prefix="${INSTALL_TO}/zsh"
	CPPFLAGS="$includes" LDFLAGS="-static $libs" make install
	cd "${TEMP_DIR}"
fi
path_extra="${INSTALL_TO}/zsh/bin:$path_extra"

############
#   tmux   #
############
if [ ! -d $INSTALL_TO/tmux ]; then
	cd "${TEMP_DIR}"
	wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
	tar xvzf "tmux-${TMUX_VERSION}.tar.gz"
	cd "tmux-${TMUX_VERSION}"
	CFLAGS="$includes" LDFLAGS="$libs" ./configure --prefix="${INSTALL_TO}/tmux"
	CPPFLAGS="$includes" LDFLAGS="-static $libs" make install
	cd "${TEMP_DIR}"
fi
path_extra="${INSTALL_TO}/tmux/bin:$path_extra"

############
#   vim    #
############
if [ ! -d $INSTALL_TO/vim ]; then
	cd "${TEMP_DIR}"
	wget "https://github.com/vim/vim/archive/v${VIM_VERSION}.tar.gz"
	tar -xvf "v${VIM_VERSION}.tar.gz"
	cd "vim-${VIM_VERSION}"
	### does this need /bin?
	vim_cv_tgetent=zero LDFLAGS="-L${INSTALL_TO}/dependencies/ncurses/lib -L${INSTALL_TO}/dependencies/ncurses/bin" \
		./configure --prefix="${INSTALL_TO}/vim"
	make install
	cd "${TEMP_DIR}"
fi
path_extra="${INSTALL_TO}/vim/bin:$path_extra"

############
#   git    #
############
if [ ! -d $INSTALL_TO/git ]; then
	which git && version_gt $(git --version | cut -d" " -f3) $GIT_MIN_VERSION && has_git=1
	if [ $has_git ]; then
		echo "Using already-installed git";
	else
		cd "${TEMP_DIR}"
		wget --no-check-certificate "https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz"
		tar -xvf "git-${GIT_VERSION}.tar.xz"
		cd "git-${GIT_VERSION}"
		if [ -d $INSTALL_TO/dependencies/curl ]; then
			PATH=$INSTALL_TO/dependencies/curl/bin:$PATH \
			./configure --prefix="${INSTALL_TO}/git" --with-curl=$INSTALL_TO/dependencies/curl
		else
			./configure --prefix="${INSTALL_TO}/git" --with-curl
		fi
		make install
		cd "${TEMP_DIR}"
	fi
fi
path_extra="${INSTALL_TO}/git/bin:$path_extra"


########################################################################

############
#  rmate   #
############
case "$DISTRO_ID" in
	"centos")
		echo "bypassing rmate install for centos 7"
		;;
	"rocky")
		if [ ! -f $INSTALL_TO/rmate/bin ]; then
			cd "${INSTALL_TO}"
			mkdir -p "${INSTALL_TO}/rmate/bin/"
			curl -Lo "${INSTALL_TO}/rmate/bin/rmate" "https://raw.githubusercontent.com/textmate/rmate/master/bin/rmate"
			chmod a+x "${INSTALL_TO}/rmate/bin/rmate"
			cd "${TEMP_DIR}"
		fi
		### given alias in me.conf
		# path_extra="${INSTALL_TO}/rmate/bin:$path_extra"
		;;
	*)
		printf "Unknown OS: %s %s. Default settings will be applied.\n\n" "${DISTRO_ID}" "${DISTRO_VERSION}"
		exit 1
		;;
esac



########################################################################
########################################################################

# ------------- Extensions / Config -------------------
export PATH=$path_extra$PATH

case "$DISTRO_ID" in
	"centos")
		echo "bypassing install for centos 7"
		;;
	"rocky")
		# Dotfiles
		if [ ! -d $INSTALL_TO/me ]; then
			git clone "https://github.com/daeh/me.git" "${INSTALL_TO}/me"
		fi
		cd "${INSTALL_TO}/me" || exit 1
		git pull
		### force if need be
		# git fetch origin main
		# git reset --hard origin/main

		# for dotfile in $(ls -a $INSTALL_TO/me/dotfiles | grep [^.]); do
		for dotfilesrc in $(ls -a $INSTALL_TO/me/dotfiles); do

			# if [ ${#dotfile} -ge 3 ]; then ### skip . and ..
			if [[ $dotfilesrc != .* ]]; then ### skip ., .., .DS_*
				dotfile=".${dotfilesrc}"
				echo "Addding dotfile: ${dotfile}"

				if [ -L $HOME/$dotfile ]; then ### is symbolic link
					rm "$HOME/$dotfile"
				elif [ -f $HOME/$dotfile ]; then ### is file
					mv "$HOME/$dotfile" "$HOME/${dotfile}_"$(date +"%F_%H.%M.%S")
				fi
				ln -s "$INSTALL_TO/me/dotfiles/$dotfilesrc" "$HOME/$dotfile"
			else
				echo "Skipping dotfilesrc: ${dotfilesrc}"
			fi 

		done
		;;
	*)
		printf "Unknown OS: %s %s. Default settings will be applied.\n\n" "${DISTRO_ID}" "${DISTRO_VERSION}"
		exit 1
		;;
esac


###TODO install prezto instead
# https://github.com/sorin-ionescu/prezto

# Oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
	PATH=${INSTALL_TO}/zsh/bin:$PATH RUNZSH=no CHSH=no sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
fi

# Zsh plugins
zshcustom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
# if [ ! -f ${zshcustom}/bullet-train.zsh-theme ]; then
# 	wget http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -O ${zshcustom}/bullet-train.zsh-theme
# fi
if [ ! -d ${zshcustom}/themes/powerlevel10k ]; then
	git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "${zshcustom}/themes/powerlevel10k"
fi
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
	git clone "https://github.com/zsh-users/zsh-autosuggestions" "${zshcustom}/plugins/zsh-autosuggestions"
fi
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]; then
	git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${zshcustom}/plugins/zsh-syntax-highlighting"
fi

# tmux plugin manager
if [ ! -d $HOME/.tmux/plugins/tpm ]; then
	git clone "https://github.com/tmux-plugins/tpm" "$HOME/.tmux/plugins/tpm"
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


########################################################################
########################################################################

########################################################################
########################################################################
### other install locations
########################################################################
########################################################################


############
#  uv      #
############
# https://docs.astral.sh/uv/getting-started/installation/
# https://docs.astral.sh/uv/configuration/installer/
# if [ ! -d /om/weka/gablab/daeda/software/miniconda3 ]; then
	cd "${TEMP_DIR}"
	mkdir uv
	cd uv

	# curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --help

	# curl -LsSf https://astral.sh/uv/install.sh | bash ### works
	curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="${INSTALL_TO}/uv" INSTALLER_NO_MODIFY_PATH=1 bash ### don't modify path
	
	# curl -LsSf https://astral.sh/uv/install.sh | bash
	# curl -LsSf https://astral.sh/uv/install.sh | zsh
	### 
	
	### BY DEFAULT
	#### installs to ~/.local/bin/uv

	#### UPDATE INSTALL PATH
	# curl --proto '=https' --tlsv1.2 -LsSf https://github.com/astral-sh/uv/releases/download/0.7.3/uv-installer.sh | env UV_INSTALL_DIR="${HOME}/me7" zsh

# fi

############
# FNM      #
############
# https://github.com/Schniz/fnm
# curl -fsSL https://fnm.vercel.app/install | bash ### workd
# curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${HOME}/.local/share/fnm" --skip-shell
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "${INSTALL_TO}/fnm" --skip-shell
### THEN :: install node ###
# FNM_PATH="${HOME}/.local/share/fnm"
# if [ -d "$FNM_PATH" ]; then
#   export PATH="$FNM_PATH:$PATH"
#   eval "`fnm env`"
# fi
# eval "$(fnm env --corepack-enabled --version-file-strategy=recursive --shell zsh)"
# print "Remotes"
# fnm list-remote
# print "\nInstalled"
# fnm list
# print "\nActive"
# fnm current
# fnm install --progress auto --corepack-enabled "v${NODE_VERSION}"
# fnm default "v${NODE_VERSION}"
### IMPORTANT:: change install location

############
#  conda   #
############
#### NOT COMPLETE
#### REQUIRES INTERACTION
if [ ! -d /om/weka/gablab/daeda/software/miniconda3 ]; then
	cd "${TEMP_DIR}"
	mkdir conda
	cd conda
	wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
	bash Miniconda3-latest-Linux-x86_64.sh
	### after zsh is set up ###
	### pivot to zsh
	# eval "$(/om/weka/gablab/daeda/software/miniconda3/bin/conda shell.zsh hook)"
	# cd ${HOME}/me/me/additional_scripts ***** check centos version
	# conda env create -f env_omlab.yml
fi



# ############
# # NVM / Node.js
# ############
# if [ -d ${HOME}/.nvm/versions/node ]; then
# 	# cd "/om2/user/daeda/software"
# 	# wget "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"
# 	# tar xf "node-v${NODE_VERSION}-linux-x64.tar.xz"
# 	cd "${TEMP_DIR}"
# 	wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
# 	# The script clones the nvm repository to ~/.nvm, and attempts to add the source lines from the snippet below to the correct profile file (~/.bash_profile, ~/.zshrc, ~/.profile, or ~/.bashrc).
# 	# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# 	# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# 	### GET code from local script to finish installing node, webppl, etc.

# 	### important - remove paths from profile

# 	# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# 	# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# 	##### nvm install node --latest-npm
# 	##### nvm install --lts --latest-npm
# 	# nvm install ${NODE_VERSION}
# 	# nvm use ${NODE_VERSION}
# 	# npm install -g webppl
# 	# npm install -g jshint
# 	# npm install --prefix ~/.webppl webppl-json --force
# fi

############
# latex
############

#### NB do this in a tmux session

if [ -d /om2/user/daeda/software ]; then
	if [ ! -d /om2/user/daeda/software/texlive ]; then
		
		cd "${TEMP_DIR}"
		wget --no-check-certificate "https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"
		zcat install-tl-unx.tar.gz | tar xf -
		# cd install-tl-*
		cd $(find . -maxdepth 1 -type d -name 'install-tl-*' -print -quit)

# mkdir "${INSTALL_TO}/texlive"
# mkdir "${HOME}/texlive-config"
#D
# <1> TEXDIR:         /om2/user/daeda/software/texlive
# <5> TEXMFVAR:       /home/daeda/texlive-config/.texlive/texmf-var
# <6> TEXMFCONFIG:    /home/daeda/texlive-config/.texlive/texmf-config
# <7> TEXMFHOME:      /home/daeda/texlive-config/texmf
#
# <O> options:
#  [X] use letter size instead of A4 by default

		# rm -r /om2/user/daeda/software/texlive
		# rm -r /home/daeda/texlive-config/.texlive/texmf-config

cat > texlive.profile << EOL
# selected_scheme scheme-small
selected_scheme scheme-full
TEXDIR /om2/user/daeda/software/texlive
TEXMFCONFIG /home/daeda/texlive-config/.texlive/texmf-config
TEXMFHOME /home/daeda/texlive-config/texmf
TEXMFLOCAL /om2/user/daeda/software/texlive/texmf-local
TEXMFSYSCONFIG /om2/user/daeda/software/texlive/texmf-config
TEXMFSYSVAR /om2/user/daeda/software/texlive/texmf-var
TEXMFVAR /home/daeda/texlive-config/.texlive/texmf-var
binary_x86_64-linux 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 1
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 1
tlpdbopt_file_assocs 1
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 1
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 1
EOL

		perl ./install-tl --profile texlive.profile
	fi
fi
### tlmgr update --all

# tlmgr update --list
# tlmgr update --self
# tlmgr update --self --all --reinstall-forcibly-removed

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





# -----------------------------------------------------

# cleanup
rm -rf "${TEMP_DIR}"

### .merc file updated manually now ###
# Create .merc file
# echo "export PATH=$path_extra:\$PATH" > "$HOME/.merc"
# echo "export DEFAULT_TMUX_SHELL=$INSTALL_TO/zsh/bin/zsh" >> "$HOME/.merc"
# echo "export ME_PATH=$INSTALL_TO" >> "$HOME/.merc"

### now in zshrc
# echo "source \$HOME/.me.conf" >> "$HOME/.merc"

# grep "source \$HOME/.merc" "$HOME/.bash_profile" || echo "source \$HOME/.merc" >> "$HOME/.bash_profile" || 
# grep "source \$HOME/.merc" "$HOME/.bashrc" || echo "source \$HOME/.merc" >> "$HOME/.bashrc"

### for some reason, I need this in my .bashrc :
# export PATH=$HOME/local/bin:$PATH

echo "Installled to: $INSTALL_TO"
