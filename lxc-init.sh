#!/bin/sh

#
# Script to automatically set-up lxc containers (Ubuntu 19.04)
#

#
#set correct timezone and locale
#
timedatectl set-timezone Europe/Bratislava
locale-gen en_US.UTF-8

#
# Set up apt cacher 
#
echo "Acquire::http::Proxy \"http://10.0.0.107:3142\";" | tee /etc/apt/apt.conf.d/00proxy

#
# Update base distro
#
apt update -y
apt dist-upgrade -y 
apt install -y patch

#
# Enable bash auto completion 
#
patch /etc/bash.bashrc <<-EOF
35,41c35,41
< #if ! shopt -oq posix; then
< #  if [ -f /usr/share/bash-completion/bash_completion ]; then
< #    . /usr/share/bash-completion/bash_completion
< #  elif [ -f /etc/bash_completion ]; then
< #    . /etc/bash_completion
< #  fi
< #fi
---
> if ! shopt -oq posix; then
>   if [ -f /usr/share/bash-completion/bash_completion ]; then
>     . /usr/share/bash-completion/bash_completion
>   elif [ -f /etc/bash_completion ]; then
>     . /etc/bash_completion
>   fi
> fi
EOF

#
#configure unattended upgrades for the system
#
apt install -y unattended-upgrades
patch -l /etc/apt/apt.conf.d/50unattended-upgrades <<-EOF
14c14
< //    "\${distro_id}:\${distro_codename}-updates";
---
>       "\${distro_id}:\${distro_codename}-updates";
EOF

#
#prometheus
#
apt install -y prometheus-node-exporter

#
# disable logrotate compression (useful with ZFS)
#
cat <<EOF > /usr/local/bin/logrotate-nocompress-hook.sh
#!/bin/bash

# disable logfile compression for better deduplicatability
for i in /etc/logrotate.d/*
do
    sed -i -E 's/(\s+)(delay|)compress/\1#\2compress/' \$i
done
EOF

chmod +x /usr/local/bin/logrotate-nocompress-hook.sh

cat <<EOF > /etc/apt/apt.conf.d/99logrotate_compress_apt_hook
DPkg::Post-Invoke {"/usr/local/bin/logrotate-nocompress-hook.sh";};
EOF



#
# Various tools
#
apt install -y peco kitty-terminfo
