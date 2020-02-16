#! /bin/sh
# optionally install jupyterlab emacskeys binding - 
# (but github.com/dzop/emacs-jupyter is better)

# need to run this AFTER enabling jupyter extensions.
# the .jupyter folder does not exist at first
[ -f /root/.jupyter/lab/user-settings ] || (echo "enable jupyter extensions"; exit )

/root/.julia/conda/3/bin/conda install nodejs 
export PATH="${PATH}:/root/.julia/conda/3/bin" 
jupyter labextension install jupyterlab-emacskeys 
cp /install/emacskeys /root/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extensions/shortcuts.jupyterlab-settings
gsettings set org.gnome.desktop.interface gtk-key-theme "Emacs"
