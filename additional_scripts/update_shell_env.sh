source ~/.zshrc || exit


print "current zsh:"
zsh --version
print "current tmux:"
tmux -V

tmux new -s updateconda
##---
interactlong
# srun --cpus-per-task=6 --mem=25G --time=2-00:00:00 --pty zsh

###

cd "${HOME}/me/me" || exit
git fetch origin master
git merge origin/master
###
# git pull

cd "${HOME}" || exit

###

omz update

cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || exit
git pull --rebase --stat origin master

cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || exit
git pull --rebase --stat origin master

# cd ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions || exit
# git pull --rebase --stat origin master

cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || exit
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

print "done"

cd ~ || exit

################### CmdStan
CMDSTAN_VERSION="2.28.2"

module load openmind/gcc/11.1.0
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
conda update -n base -c defaults conda
#===
conda update -n base -c defaults python

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

env_iaa_cmdstan
#
conda update -n ve_iaa_pytorch --all -c pytorch -c conda-forge
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


##### https://johnpapa.net/node-and-npm-without-sudo/
# Install Node.js from https://nodejs.org/en/download/
#####

node -v
npm version
npm list -g --depth=0
npm outdated -g --depth=0

#

npm install -g npm@latest
#
npm update -g jshint

npm outdated --prefix ~/.webppl --depth=0
npm update -g webppl
npm install --prefix ~/.webppl webppl-json --force

