#!/bin/bash
script_path="$0"
script_full_path=$(realpath "$script_path")
script_directory=$(dirname "$script_full_path")
cd "$script_directory"
cd ..
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ conf file exist ?
if [ -e "common/conf.qapps.tmp" ]; then
rel_path="common/conf.qapps.tmp"
abs_path=$(realpath "$rel_path")
conffile=1
dcopRef=$(sudo kreadconfig --file "$abs_path" --group "Settings" --key "progressref")
kdicon="$script_directory/../common/Q4OSsebicon.png" 
helpdoc=0;installall=0
else
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ conf file exist end

helpdoc=0
installall=0
VALID_ARGS=$(getopt -o ha --long help,all -- "$@")
if [[ $? -ne 0 ]]; then
    exit 1;
fi
eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -h | --help)
        helpdoc=1
        shift
        ;;
    -a | --all)
        installall=1
        shift
        ;;
     --) shift; 
        break 
        ;;
  esac
done
if [ $helpdoc -eq 1 ]; then
script="Help Qapps"
else
script="   Qapps script   "
fi
source common/resizecons
fi
source common/begin
source common/progress

if [[ $conffile -eq 1 ]]; then
begin "$script" "conf" "$dcopRef"
qprogress () {
pro=$(( $2 / 5 ))
dcop "$dcopRef" setProgress $pro
}
else
begin "$script"
qprogress () {
progress "$1" "$2"
}
fi

USER_HOME=$(eval echo ~${SUDO_USER})

#========== set subscripts perms ================================================================================
qprogress "$script" 0
sudo chmod +x common/pklist

#=================== functions ==================================================================================
function isinstalled() {
local string="$1"
local file="$2"
if grep -q "$string" "$file"; then
return 0
else
return 1
fi
}


function installApp() {
local appName="$1"
local packageString="$2"
if ! isinstalled "$packageString" "common/packages_list.tmp"; then
echo -e "${YELLOW}"
sudo apt install -y "$appName"
echo -e "${NOCOLOR}"
else
echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
fi
if ! [[ -v $3 ]]; then
sep
echo
echo
echo
fi
}

osarch=$(dpkg --print-architecture)

itemdisp "Fetching latest version of the package list..."

if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Fetching latest version of the package list..."

konsole --nomenubar --nohist --notabbar --noframe --noscrollbar -e common/apt_update.sh "$dcopRef" "apps" -- &
kid=konsole-$!
session_count=$(dcop $kid konsole sessionCount 2>/dev/null)
while [[ $session_count -ne 1 ]]
do
sleep 0.1
session_count=$(dcop $kid konsole sessionCount)
done
dcop $kid konsole-mainwindow#1 setGeometry 5 5 600 500
dcop $kid konsole-mainwindow#1 lower
session_count=$(dcop $kid konsole sessionCount 2>/dev/null)
while [[ $session_count -eq 1 ]]
do
sleep 1
session_count=$(dcop $kid konsole sessionCount)
done

else

sudo apt update > /dev/null 2>&1
aptup=1
for (( i=5; i>0; i--)); do
printf "\rRunning apt upgrade in $i seconds.  Hit any key to cancel..."
read -s -n 1 -t 1 key
if [ $? -eq 0 ];then aptup=0;break;fi;done
if [[ $aptup -eq 1 ]];then echo;echo "processing..."
sudo dpkg --configure -a
sudo apt upgrade -y
else echo;echo "canceled.";fi

fi

sep
echo
echo
echo

#========== retrieve packages list ==============================================================================
qprogress "$script" 0
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Retrieve installed packages list...";fi
echo -e "    ${ORANGE}░▒▓█\033[0m Retrieve installed packages list...${NOCOLOR}"
echo
cd common
sudo ./pklist
cd ..
echo


#============== Install Apps (automatic) ========================================================================
itemdisp "Installing GIT..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing GIT...";fi
installApp "git" "git/stable"
qprogress "$script" 5

itemdisp "Installing 7zip..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing 7zip...";fi
installApp "7z" "p7zip-full/stable"
qprogress "$script" 5


#---------------------------------------Ark
if [[ $conffile -eq 1 ]]; then
instark=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Ark")
else instark=1;fi

if [[ $instark -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Ark...";fi
itemdisp "Installing Ark..."
installApp "ark" "ark/stable"
fi
qprogress "$script" 5


#---------------------------------------Dolphin
if [[ $conffile -eq 1 ]]; then
instdolph=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Dolphin")
else instdolph=1;fi

if [[ $instdolph -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Dolphin...";fi
itemdisp "Installing Dolphin..."
installApp "dolphin-trinity" "dolphin-trinity/"
fi
qprogress "$script" 10


#---------------------------------------system-config-printer
if [[ $conffile -eq 1 ]]; then
instsysprint=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "system-config-printer")
else instsysprint=1;fi

if [[ $instsysprint -eq 1 ]]; then
itemdisp "Installing system-config-printer..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing system-config-printer...";fi
installApp "system-config-printer" "system-config-printer/stable"
fi
qprogress "$script" 15

#---------------------------------------flashfetch
if [[ $conffile -eq 1 ]]; then
instflashf=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "flashfetch")
else instflashf=1;fi

if [[ $instflashf -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Flashfetch...";fi
itemdisp "Installing flashfetch"
cd apps
echo -e "${YELLOW}"
if [ "$osarch" = "amd64" ]; then
sudo 7z x -so flashfetch.tar.7z | sudo tar xf - -C /usr/bin/
fi
if [ "$osarch" = "i386" ]; then
sudo 7z x -so flashfetch_32.tar.7z | sudo tar xf - -C /usr/bin/
fi
if [ "$osarch" = "armhf" ]; then
sudo 7z x -so flashfetch_arm.tar.7z | sudo tar xf - -C /usr/bin/
fi
echo "flashfetch binary copied in /usr/bin/"
cd ..
echo -e "${NOCOLOR}"
#flashfetch
sep
echo
echo
echo
fi
qprogress "$script" 20


#---------------------------------------lx-taskmod
itemdisp "Installing lxtask-mod (simple lightweight taskmgr)"
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing lxtask-mod...";fi
if ! isinstalled "lxtask-mod/now" "common/packages_list.tmp"; then
cd apps
echo -e "${YELLOW}"
if [ "$osarch" = "armhf" ]; then
sudo apt install -y ./lxtask-mod_armhf.deb
else
if ( getconf LONG_BIT | grep -q 64 ); then
sudo apt install -y ./lxtask-mod.deb
else
sudo apt install -y ./lxtask-mod_i386.deb
fi
fi
cd ..
echo -e "${NOCOLOR}"
sep
echo
echo
echo
else
echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
fi
qprogress "$script" 25


#---------------------------------------Stacer
if [[ $conffile -eq 1 ]]; then
inststac=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Stacer")
else inststac=1;fi

if [[ $inststac -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Stacer...";fi
itemdisp "Installing Stacer..."
installApp "stacer" "stacer/stable"
fi
qprogress "$script" 30


#---------------------------------------bleachbit
if [[ $conffile -eq 1 ]]; then
instbleach=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "bleachbit")
else instbleach=1;fi

if [[ $instbleach -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing bleachbit...";fi
itemdisp "Installing bleachbit..."
installApp "bleachbit" "bleachbit/stable"
fi
qprogress "$script" 35


#---------------------------------------vlc
if [[ $conffile -eq 1 ]]; then
instvlc=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "vlc")
else instvlc=1;fi

if [[ $instvlc -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing vlc...";fi
itemdisp "Installing vlc..."
installApp "vlc" "vlc/stable"
fi
qprogress "$script" 40


#---------------------------------------console tools
if [[ $conffile -eq 1 ]]; then
instclit=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "console tools")
else instclit=1;fi

if [[ $instclit -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing console tools...";fi
itemdisp "Installing usefull console tools..."
installApp "duf" "duf/stable" 0
installApp "jdupes" "jdupes/stable"
fi
qprogress "$script" 45


#---------classics tools, may be already installed with desktop version
itemdisp "Installing Gwenview,Kolourpaint,KCharSelect,Ksnapshot,knotes,kcron, kdirstat, kpdf..."
echo


#---------------------------------------Gwenview
if [[ $conffile -eq 1 ]]; then
instgwen=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Gwenview")
else instgwen=1;fi
if [[ $instgwen -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Gwenview...";fi
echo -e "  \e[35m░▒▓█\033[0m Installing Gwenview..."
installApp "gwenview-trinity" "gwenview-trinity" 0
fi


#---------------------------------------Kolourpaint
if [[ $conffile -eq 1 ]]; then
instkpaint=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Kolourpaint")
else instkpaint=1;fi
if [[ $instkpaint -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Kolourpaint...";fi
echo -e "  \e[35m░▒▓█\033[0m Installing Kolourpaint..."
installApp "kolourpaint-trinity" "kolourpaint-trinity" 0
fi


#---------------------------------------KCharSelect
if [[ $conffile -eq 1 ]]; then
instkchar=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "KCharSelect")
else instkchar=1;fi
if [[ $instkchar -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing KCharSelect...";fi
echo -e "  \e[35m░▒▓█\033[0m Installing KCharSelect..."
installApp "kcharselect-trinity" "kcharselect-trinity" 0
fi

#---------------------------------------Ksnapshot
if [[ $conffile -eq 1 ]]; then
instksnap=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Ksnapshot")
else instksnap=1;fi
if [[ $instksnap -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Ksnapshot...";fi
echo -e " \e[35m░▒▓█\033[0m Installing Ksnapshot..."
installApp "ksnapshot-trinity" "ksnapshot-trinity" 0
fi


#---------------------------------------Knotes
if [[ $conffile -eq 1 ]]; then
instknot=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Knotes")
else instknot=1;fi
if [[ $instknot -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Knotes...";fi
echo -e " \e[35m░▒▓█\033[0m Installing Knotes..."
installApp "knotes-trinity" "knotes-trinity" 0
fi


#---------------------------------------Kcron
if [[ $conffile -eq 1 ]]; then
instkcro=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Kcron")
else instkcro=1;fi
if [[ $instkcro -eq 1 ]]; then
echo -e " \e[35m░▒▓█\033[0m Installing Kcron..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Kcron...";fi
installApp "kcron-trinity" "kcron-trinity" 0
fi


#---------------------------------------kdirstat
if [[ $conffile -eq 1 ]]; then
instkdirs=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "kdirstat")
else instkdirs=1;fi
if [[ $instkdirs -eq 1 ]]; then
echo -e " \e[35m░▒▓█\033[0m Installing kdirstat..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing kdirstat...";fi
installApp "kdirstat-trinity" "kdirstat-trinity" 0
fi

#---------------------------------------kpdf
if [[ $conffile -eq 1 ]]; then
instkpd=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "kpdf")
else instkpd=1;fi
if [[ $instkpd -eq 1 ]]; then
echo -e " \e[35m░▒▓█\033[0m Installing kpdf..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing kpdf...";fi
installApp "kpdf-trinity" "kpdf-trinity"
fi


#---------------------------------------Strawberry
if [[ $conffile -eq 1 ]]; then
inststraw=$(sudo kreadconfig --file "$abs_path" --group "Default Apps" --key "Strawberry")
else inststraw=1;fi
if [[ $inststraw -eq 1 ]]; then
itemdisp "Installing Strawberry..."
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Strawberry...";fi
installApp "strawberry" "strawberry/stable"
mkdir -p $USER_HOME/.configtde/strawberry/
tar -xzf theme/strawberry.conf.tar.gz -C $USER_HOME/.configtde/strawberry/
echo
fi

qprogress "$script" 55


#============== Install Apps (interactive) ======================================================================


#---------------------------------------qBittorent
if [[ $conffile -eq 1 ]]; then
instqbit=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "qBittorent")
else instqbit=1;fi
if [[ $instqbit -eq 1 ]]; then

itemdisp "Installing qbittorent"
#qbittorrent
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing qbittorrent...";fi
installApp "qbittorrent" "qbittorrent/stable"
else
echo
echo -e "${RED}█ ${ORANGE}Install qbittorrent ?${NOCOLOR}"
optionz=("Install qbittorrent" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install qbittorrent")
            echo -e "  \e[35m░▒▓█\033[0m Installing qbittorrent..."
            installApp "qbittorrent" "qbittorrent/stable"
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
qprogress "$script" 60


#---------------------------------------Guvcview
if [[ $conffile -eq 1 ]]; then
instguc=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Guvcview")
else instguc=1;fi
if [[ $instguc -eq 1 ]]; then

itemdisp "Installing guvcview"
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing guvcview...";fi
    installApp "guvcview" "guvcview/stable"
else
echo
echo -e "${RED}█ ${ORANGE}Install guvcview ?${NOCOLOR}"
optionz=("Install guvcview" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install guvcview")
            echo -e "  \e[35m░▒▓█\033[0m Installing guvcview..."
            installApp "guvcview" "guvcview/stable"
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi

fi
qprogress "$script" 60



#---------------------------------------Spotify
if [[ $conffile -eq 1 ]]; then
instspot=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Spotify")
else instspot=1;fi
if [[ $instspot -eq 1 ]]; then


if ( getconf LONG_BIT | grep -q 64 ); then
itemdisp "Installing spotify"
#spotify
installSpoty () {
            if ! isinstalled "spotify-client/stable" "common/packages_list.tmp"; then
            echo -e "${YELLOW}"
            curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
            sudo apt-get update
            sudo apt-get install -y spotify-client
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing spotify...";fi
    installSpoty
else
echo
echo -e "${RED}█ ${ORANGE}Install spotify ?${NOCOLOR}"
optionz=("Install spotify" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install spotify")
            echo -e "  \e[35m░▒▓█\033[0m Installing spotify..."
            installSpoty
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo

fi
fi
qprogress "$script" 65



#---------------------------------------Microsoft Edge Browser
if [[ $conffile -eq 1 ]]; then
instedge=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Microsoft Edge Browser")
else instedge=1;fi
if [[ $instedge -eq 1 ]]; then


if ( getconf LONG_BIT | grep -q 64 ); then
itemdisp "Installing Microsoft Edge Browser"
installEdge () {
            if ! isinstalled "microsoft-edge-stable/stable" "common/packages_list.tmp"; then
            echo -e "${YELLOW}"
            sudo apt install software-properties-common apt-transport-https ca-certificates 
            curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-edge.gpg > /dev/null
            echo 'deb [signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
            sudo apt update
            sudo apt install microsoft-edge-stable
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Microsoft Edge Browser...";fi
    installEdge
else
echo
echo -e "${RED}█ ${ORANGE}Install Edge Browser ?${NOCOLOR}"
optionz=("Install Edge" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install Edge")
            echo -e "  \e[35m░▒▓█\033[0m Installing Microsoft Edge Browser..."
            installEdge
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi
fi
qprogress "$script" 65


#---------------------------------------Gparted
if [[ $conffile -eq 1 ]]; then
instgpart=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Gparted")
else instgpart=1;fi
if [[ $instgpart -eq 1 ]]; then

itemdisp "Installing gparted"
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing gparted...";fi
    installApp "gparted" "gparted/stable"
else
#gparted
echo
echo -e "${RED}█ ${ORANGE}Install gparted ? (partitions manager)${NOCOLOR}"
optionz=("Install gparted" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install gparted")
            echo -e "  \e[35m░▒▓█\033[0m Installing gparted..."
            installApp "gparted" "gparted/stable"
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
qprogress "$script" 70


#---------------------------------------S4 Snapshot
if [[ $conffile -eq 1 ]]; then
instssnap=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "S4 Snapshot")
else instssnap=1;fi
if [[ $instssnap -eq 1 ]]; then

itemdisp "Installing S4 Snapshot"
#q4os-s4-snapshot
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing S4 Snapshot...";fi
            echo -e "${YELLOW}"
            cd apps
            sudo qsinst setup_q4os-s4-snapshot_4.1-a1_amd64.qsi
            cd ..
            echo -e "${NOCOLOR}"
else
echo
echo -e "${RED}█ ${ORANGE}Install S4 Snapshot ? (create an bootable iso of a running system)${NOCOLOR}"
optionz=("Install S4 Snapshot" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install S4 Snapshot")
            echo -e "  \e[35m░▒▓█\033[0m Installing S4 Snapshot..."
            echo -e "${YELLOW}"
            cd apps
            sudo qsinst setup_q4os-s4-snapshot_4.1-a1_amd64.qsi
            cd ..
            echo -e "${NOCOLOR}"
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi 
qprogress "$script" 75


#---------------------------------------Web app manager
if [[ $conffile -eq 1 ]]; then
instwapp=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Web app manager")
else instwapp=1;fi
if [[ $instwapp -eq 1 ]]; then

itemdisp "Installing Web app manager"
function installwebappman() {
           if ! isinstalled "webapp-manager/" "common/packages_list.tmp"; then
            echo -e "  \e[35m░▒▓█\033[0m Installing Web app manager..."
            echo -e "${YELLOW}"
cd apps
sudo apt install -y ./webapp-manager_1.3.4_all.deb
cd ..
#deleting redundant entry
sudo rm -f /usr/share/applications/kde4/webapp-manager.desktop
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Web app manager...";fi
installwebappman
else
echo
echo -e "${RED}█ ${ORANGE}Install Web app manager ?${NOCOLOR}"
optionz=("Install web app manager" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install web app manager")
            installwebappman
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
qprogress "$script" 75


#---------------------------------------Pinta
if [[ $conffile -eq 1 ]]; then
instpint=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Pinta")
else instpint=1;fi
if [[ $instpint -eq 1 ]]; then


itemdisp "Installing Pinta"
function installpinta() {
           if ! isinstalled "pinta/" "common/packages_list.tmp"; then
            echo -e "  \e[35m░▒▓█\033[0m Installing Pinta..."
            echo -e "${YELLOW}"
cd apps
sudo apt install -y ./pinta_1.7.1_all.deb
cd ..
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Pinta...";fi
installpinta
else
echo
echo -e "${RED}█ ${ORANGE}Install Pinta (paint.net like app) ?${NOCOLOR}"
optionz=("Install Pinta" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install Pinta")
            installpinta
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
qprogress "$script" 75



#---------------------------------------Remmina
if [[ $conffile -eq 1 ]]; then
instremm=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Remmina")
else instremm=1;fi
if [[ $instremm -eq 1 ]]; then

itemdisp "Installing remmina"
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Remmina...";fi
    installApp "remmina" "remmina/stable"
else
echo
echo -e "${RED}█ ${ORANGE}Install remmina ? (rdp / vnc / ssh remote desktop client)${NOCOLOR}"
optionz=("Install remmina" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install remmina")
            echo -e "  \e[35m░▒▓█\033[0m Installing remmina..."
            installApp "remmina" "remmina/stable"
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
qprogress "$script" 80


#---------------------------------------Free Office
if [[ $conffile -eq 1 ]]; then
instfreo=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Free Office")
else instfreo=1;fi
if [[ $instfreo -eq 1 ]]; then

itemdisp "Installing free office"
function installFreeO() {
           if ! isinstalled "softmaker-freeoffice-" "common/packages_list.tmp"; then
            echo -e "  \e[35m░▒▓█\033[0m Installing free office..."
            echo -e "${YELLOW}"
            mkdir -p /etc/apt/keyrings
            sudo bash -c 'wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor > /etc/apt/keyrings/softmaker.gpg'
            sudo bash -c 'echo "deb [signed-by=/etc/apt/keyrings/softmaker.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list'
            sudo apt update
            sudo apt install -y softmaker-freeoffice-2021
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
#softmaker-freeoffice-2021
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Free Office...";fi
installFreeO
else
echo
echo -e "${RED}█ ${ORANGE}Install free office (a word/excel/ppoint clone) ?${NOCOLOR}"
optionz=("Install free office" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install free office")
            installFreeO
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi
qprogress "$script" 85


#---------------------------------------OnlyOffice
if [[ $conffile -eq 1 ]]; then
instoof=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "OnlyOffice")
else instoof=1;fi
if [[ $instoof -eq 1 ]]; then

itemdisp "Installing OnlyOffice"
function installOnlyO() {
           if ! isinstalled "onlyoffice-desktopeditors" "common/packages_list.tmp"; then
            echo -e "  \e[35m░▒▓█\033[0m Installing OnlyOffice..."
            echo -e "${YELLOW}"
            sudo wget https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
            sudo apt install -y ./onlyoffice-desktopeditors_amd64.deb
            sudo rm -f ./onlyoffice-desktopeditors_amd64.deb
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Only Office...";fi
installOnlyO
else
echo
echo -e "${RED}█ ${ORANGE}Install OnlyOffice (another word/excel/ppoint clone) ?${NOCOLOR}"
optionz=("Install OnlyOffice" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install OnlyOffice")
            installOnlyO
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi
qprogress "$script" 85



#---------------------------------------Bpytop
if [[ $conffile -eq 1 ]]; then
instbpy=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Bpytop")
else instbpy=1;fi
if [[ $instbpy -eq 1 ]]; then


itemdisp "Installing bpytop"
#bpytop
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing bpytop...";fi
installApp "bpytop" "bpytop/stable"
else
echo
echo -e "${RED}█ ${ORANGE}Install bpytop ? (CLI htop alternative)${NOCOLOR}"
optionz=("Install bpytop" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install bpytop")
            echo -e "  \e[35m░▒▓█\033[0m Installing bpytop"
            installApp "bpytop" "bpytop/stable"
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi
qprogress "$script" 90



#---------------------------------------Virtualbox 7
if [[ $conffile -eq 1 ]]; then
instvbo=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Virtualbox 7")
else instvbo=1;fi
if [[ $instvbo -eq 1 ]]; then


if ( getconf LONG_BIT | grep -q 64 ); then
itemdisp "Installing virtualbox 7"
#spotify
installVbox () {
            if ! isinstalled "virtualbox-7.0/" "common/packages_list.tmp"; then
            echo -e "${YELLOW}"
            wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
            sudo apt update
            sudo apt install -y virtualbox-7.0
            sudo usermod -G vboxusers -a $USER
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Virtualbox 7...";fi
    installVbox
else
echo
echo -e "${RED}█ ${ORANGE}Install virtualbox 7 ?${NOCOLOR}"
optionz=("Install virtualbox" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install virtualbox")
            echo -e "  \e[35m░▒▓█\033[0m Installing virtualbox 7..."
            installVbox
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo

fi
fi
qprogress "$script" 95





#---------------------------------------Qtscrcpy
if [[ $conffile -eq 1 ]]; then
instscrcpy=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Qtscrcpy")
else instscrcpy=1;fi
if [[ $instscrcpy -eq 1 ]]; then

if ( getconf LONG_BIT | grep -q 64 ); then
itemdisp "Installing Qtscrcpy"
installQtscrcpy () {
            if [ ! -e "$USER_HOME/qtscrcpy/QtScrcpy" ]; then
            echo -e "${YELLOW}"
            cd apps
            sudo apt install -y libqt5multimedia5
            sudo 7z x -so qtscrcpy.tar.7z | sudo tar xf - -C $USER_HOME/
            sudo mkdir -p $USER_HOME/.local/bin
            sudo ln -s $USER_HOME/qtscrcpy/QtScrcpy $USER_HOME/.local/bin/QtScrcpy
            sudo mv $USER_HOME/qtscrcpy/qtscrcpy.desktop /usr/share/applications/qtscrcpy.desktop
            cd ..
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Qtscrcpy...";fi
    installQtscrcpy
else
echo
echo -e "${RED}█ ${ORANGE}Install Qtscrcpy ? (android phone screen mirroring+control)${NOCOLOR}"
optionz=("Install Qtscrcpy" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install Qtscrcpy")
            echo -e "  \e[35m░▒▓█\033[0m Installing Qtscrcpy..."
            installQtscrcpy
            break
            ;;
        "Skip")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
sep
echo
echo
echo
fi
fi
qprogress "$script" 95



#---------------------------------------Angry IP scanner
if [[ $conffile -eq 1 ]]; then
instipsc=$(sudo kreadconfig --file "$abs_path" --group "Extra Apps" --key "Angry IP scanner")
else instipsc=1;fi
if [[ $instipsc -eq 1 ]]; then

if [ ! "$osarch" = "armhf" ]; then
itemdisp "Installing Angry IP scanner"
function installangryip() {
           if ! isinstalled "ipscan/" "common/packages_list.tmp"; then
           echo -e "${YELLOW}"
cd apps
if ( getconf LONG_BIT | grep -q 64 ); then
sudo apt install -y ./ipscan_3.9.1_amd64.deb
else
sudo apt install -y ./ipscan_3.9.1_all.deb
fi
cd ..
            echo -e "${NOCOLOR}"
            else
            echo -e "${ORANGE}      ¤ Already installed.${NOCOLOR}"
            fi
}
if [ "$installall" -eq 1 ] || [[ "$conffile" -eq 1 ]]; then
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Installing Angry IP scanner...";fi
installangryip
else
echo
echo -e "${RED}█ ${ORANGE}Install Angry IP scanner ?${NOCOLOR}"
optionz=("Install angryip" "Skip")
select optz in "${optionz[@]}"
do
    case $optz in
        "Install angryip")
            echo -e "  \e[35m░▒▓█\033[0m Installing Angry IP scanner..."
            installangryip
            break
            ;;
        "Skip")
            sep
            echo
            echo
            echo
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi
fi
fi
qprogress "$script" 95



#---------------------------------------
if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" setLabel "Cleaning files...";fi
itemdisp "Cleaning files..."
echo
sudo rm -f common/packages_list.tmp
sudo apt clean
sudo apt autoremove -y
sep
echo
echo
echo
qprogress "$script" 100

if [[ $conffile -eq 1 ]]; then dcop "$dcopRef" close
sudo rm -f "$abs_path"
kdialog --title "■■ q4osXpack » qapps " --icon "$kdicon" --msgbox "⠀⠀⠀Installation Completed.⠀⠀⠀⠀⠀⠀"
else
alldone
fi

exit 2