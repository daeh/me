# Auto-setup for zsh, tmux, vim, git

To install:

from local machine:

`scp ~/coding/-GitRepos/me/setup.sh daeda@openmind7.mit.edu:/home/daeda/setup.sh`

from remote machine:

`bash setup.sh`



---



# To update



git pull repo to directory ~/me/me

```sh
cd ${HOME}/me/me || exit
git pull
```

or if local changes need to be overwritten
```sh
cd ${HOME}/me/me || exit
git fetch origin
git reset --hard origin/main
```



(exit mounted drives)

exit tmux

`tmux kill-server`

exit zsh

`exec bash`
`ps aux | grep zsh`

remove everything in `~/me` that needs to be updated (leave the `me` dir)

step through `setup.sh`
