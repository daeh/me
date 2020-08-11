source ~/.zshrc || exit

zsh --version
echo "current tmux:"
tmux -V
echo "update via https://gist.github.com/ryin/3106801"

omz update

cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || exit
git pull --rebase --stat origin master

cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || exit
git pull --rebase --stat origin master

cd ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions || exit
git pull --rebase --stat origin master

cd ~ || exit

################### CmdStan

g++ --version
make --version

cd /om/user/daeda/software/ || exit
wget https://github.com/stan-dev/cmdstan/releases/download/v2.24.1/cmdstan-2.24.1.tar.gz

tar xvzf cmdstan-2.24.1.tar.gz
cd cmdstan-2.24.1
make -j6 build

cd ~ || exit

###################

tb_conda

conda update -n base -c defaults conda
conda update -n base -c defaults python

conda update -n omlab -c defaults anaconda
conda update -n omlab -c defaults python
conda update -n omlab --all -c defaults

pip install --upgrade pip
pip install --upgrade tmuxp

#######
# env_iaa
# conda update -n ve_iaa_pyro -c conda-forge anaconda
# conda update -n ve_iaa_pyro -c conda-forge python
# conda update -n ve_iaa_pyro --all -c pytorch -c conda-forge
# pip install --upgrade pip
# pip install -U pystan
# pip install -U tmuxp


env_iaa_cmdstan
conda update -n ve_iaa_cmdstanpy --all -c conda-forge
pip install --upgrade pip
pip install --upgrade tmuxp
pip install --upgrade "cmdstanpy[all]"


conda clean --all


#######
node -v
##### https://johnpapa.net/node-and-npm-without-sudo/
# Install Node.js from https://nodejs.org/en/download/
#####

npm version
npm install -g npm
#
npm version
npm update -g jshint
npm update -g webppl
npm install --prefix ~/.webppl webppl-json --force

