install tools

sudo dnf install pam-u2f
sudo dnf install pamu2fcfg

generate keys

mkdir ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
cat ~/.config/Yubico/u2f_keys


GUI вход

vim /etc/pam.d/sddm

add 1 line

auth      sufficient      pam_u2f.so   cue

sudo аунтификация

sudo vim /etc/pam.d/sudo

add 1 line

auth       sufficient   pam_u2f.so cue

lookscreen

sudo vim /etc/pam.d/kde

add 1 line

auth        sufficient    pam_u2f.so    cue
