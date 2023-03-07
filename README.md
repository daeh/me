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



exit tmux

exit zsh

remove everything in `~/me` that needs to be updated (leave the `me` dir)

step through `setup.sh`
