/bin/bash

sudo pacman -Syu kate git dolphin termite zsh ark dolphin-plugins gwenview kgpg kleopatra kmix ksystemlog kteatime okular print-manager spectacle chromium openssh ttf-hack ttf-dejavu noto-fonts ttf-roboto ttf-liberation dina-font otf-overpass code adapta-kde adapta-kde adapta-gtk-theme kvantum-qt5 kvantum-theme-adapta
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

mkdir -p ~/doc/desktop ~/dev ~/img ~/tmp
cd ~/tmp

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay enpass 
yay spotify


