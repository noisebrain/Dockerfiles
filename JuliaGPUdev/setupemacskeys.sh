#! /bin/sh

# this does not really work yet. It mentions the manual steps that work, however 
# 1) gsettings does not exist in the docker container. can equivalently make a .ini file (see emacskeys doc)
# 2) the PATH also needs to be set in the container (not just here) before launching jupyter I think
# But using real emacs as a client is probably the better approach anyway (e.g. dzop/emacs-jupyter)

# optionally install jupyterlab emacskeys binding - 
# (but github.com/dzop/emacs-jupyter is better)

# need to run this AFTER enabling jupyter extensions.
# the .jupyter folder does not exist at first
[ -f /root/.jupyter/lab/user-settings ] || (echo "enable jupyter extensions"; exit )

/root/.julia/conda/3/bin/conda install nodejs 
export PATH="${PATH}:/root/.julia/conda/3/bin" 
jupyter labextension install jupyterlab-emacskeys 
mkdir /root/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extensions
cp /install/emacskeys /root/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extensions/shortcuts.jupyterlab-settings
gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
