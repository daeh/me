
# exit on error
set -e


################### CmdStan
CMDSTAN_VERSION=2.24.1

g++ --version
make --version

cd /om/user/daeda/software/ || exit
wget https://github.com/stan-dev/cmdstan/releases/download/v${CMDSTAN_VERSION}/cmdstan-${CMDSTAN_VERSION}.tar.gz

tar xvzf cmdstan-${CMDSTAN_VERSION}.tar.gz
cd cmdstan-${CMDSTAN_VERSION} || exit
make -j6 build

cd .. || exit
rm cmdstan-${CMDSTAN_VERSION}.tar.gz

cd ~ || exit


# https://nodejs.org/en/download/
# https://nodejs.org/dist/v12.18.3/node-v12.18.3-linux-x64.tar.xz

#######
node -v
##### https://johnpapa.net/node-and-npm-without-sudo/
# Install Node.js from https://nodejs.org/en/download/
#####

#######
node -v
# https://github.com/nvm-sh/nvm/issues/1706
# https://github.com/nvm-sh/nvm

### update nvm -> https://github.com/nvm-sh/nvm
### e.g. curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | zsh ####NB zsh
prev_ver=$(nvm current)
nvm install node --latest-npm --reinstall-packages-from=node
### i think same as this, which doesn't work:  nvm install --lts --latest-npm --reinstall-packages-from='lts/*'
new_ver=$(nvm current)
nvm ls
nvm alias default $new_ver
nvm uninstall $prev_ver
nvm ls

node -v
npm version
# https://futurestud.io/tutorials/npm-quick-tips-3-show-installed-and-outdated-packages
npm list -g --depth=0
npm outdated -g --depth=0
npm install -g npm@latest
npm update -g jshint
npm update -g webppl
npm install --prefix ~/.webppl webppl-json --force



