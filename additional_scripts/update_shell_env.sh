source ~/.zshrc || exit


# tmglr
# conda
# nvm
# node

# tb_latex
# tlmgr update --list
# tlmgr update --self --all --reinstall-forcibly-removed

# tb_conda

# srun --constraint=rocky8 --cpus-per-task=4 --mem=20G --time=1-00:00:00 --pty zsh
# tmux new -s updateconda8


centos_version=$(rpm -E "%{rhel}")

case $centos_version in
	7)
		module load openmind/gcc/12.2.0
		printf "\nCentos 7 :: %s\n" "${ME_PATH}"
		;;
	8)
		module load openmind8/gcc/12.2.0
		printf "\nCentos 8 :: %s\n" "${ME_PATH}"
		;;
	*)
		echo "Unknown CentOS version: $centos_version. Default settings will be applied."
		module load openmind8/gcc/12.2.0
		printf "\nCentos UNKNOWN :: %s\n" "${ME_PATH}"
		;;
esac

print "current zsh:"
zsh --version
print "current tmux:"
tmux -V

# tmux new -s updateconda7
# ##---
# interactlong7
# srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 --exclude="dgx001,dgx002,node017,node[031-077],node086,node[100-116]" --pty zsh

###

cd "${ME_PATH}" || exit
# git fetch origin main
# git merge origin/main
# git reset --hard origin/main
###
git pull
###


cd "${HOME}" || exit

###

omz update
#===
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || exit
git pull --rebase --stat origin master
#===
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || exit
git pull --rebase --stat origin master
#===
# cd ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions || exit
# git pull --rebase --stat origin master
#===
cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || exit
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

print "done"

cd "${HOME}" || exit

################### CmdStan
CMDSTAN_VERSION="2.28.2"

# module load openmind/gcc/11.1.0
module load openmind8/gcc/12.2.0
module load openmind/isl/0.23
module load openmind/mpfr/4.1.0  openmind/mpc/1.2.1 
module load openmind/make/4.3
g++ --version
make --version

cd "/om/user/daeda/software/" || exit
wget "https://github.com/stan-dev/cmdstan/releases/download/v${CMDSTAN_VERSION}/cmdstan-${CMDSTAN_VERSION}.tar.gz"

tar xvzf "cmdstan-${CMDSTAN_VERSION}.tar.gz"
cd "cmdstan-${CMDSTAN_VERSION}" || exit
make -j6 build

cd .. || exit
rm "cmdstan-${CMDSTAN_VERSION}.tar.gz"

cd ~ || exit

###################

tb_conda

conda clean --all --yes
#
conda update -n base -c conda-forge conda
#===
conda update -n base -c conda-forge python

#===

conda update -n omlab --all -c conda-forge
#===
conda update -n omlab -c conda-forge python
#===
conda update -n omlab -c conda-forge jupyterlab
#===
pip install --upgrade pip
pip install --upgrade tmuxp

#######

env_cam
#
conda update -n env_cam --all -c pytorch -c conda-forge
#===
which pip
#
pip install --upgrade pip
pip install --upgrade tmuxp

# env_iaa
# conda update -n ve_iaa_pyro -c conda-forge anaconda
# conda update -n ve_iaa_pyro -c conda-forge python
# conda update -n ve_iaa_pyro --all -c pytorch -c conda-forge
# pip install --upgrade pip
# pip install -U pystan
# pip install -U tmuxp


# env_iaa_cmdstan
# conda update -n ve_iaa_cmdstanpy --all -c conda-forge
# which pip
# pip install --upgrade pip
# pip install --upgrade tmuxp
# pip install --upgrade "cmdstanpy[all]"

conda clean --all --yes


#######

tb_latex

tlmgr update --self
tlmgr update --list
tlmgr update --all
# tlmgr install missing_package

#######

##### https://johnpapa.net/node-and-npm-without-sudo/
# Install Node.js from https://nodejs.org/en/download/
#####

### NB node 17 is latest to work on Centos ###

### tb_webppl

fnm ....

# nvm ls-remote
# node -v

# nvm --version
# nvm ls
# npm list -g --depth=0


# prev_ver=$(nvm current)
# nvm install node --reinstall-packages-from=node --latest-npm
# ### or e.g. nvm install 20.13.1 --reinstall-packages-from=17.0.0 --latest-npm

# ### double check that new_ver is set
# new_ver=$(nvm current)
# nvm ls
# nvm alias default "$new_ver"
# # nvm uninstall "$prev_ver"

# nvm ls
# npm list -g --depth=0

# npm outdated -g --depth=0

# #

# npm install -g npm@latest
# #
# npm update -g corepack
# # npm update -g eslint
# # npm update -g eslint_d
# npm update -g jshint
# # npm update -g prettier
# npm update -g webppl

# npm outdated --prefix ~/.webppl --depth=0
# npm update -g webppl
# npm install --prefix ~/.webppl webppl-json --force

