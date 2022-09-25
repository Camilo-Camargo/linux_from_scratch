# Replacing the default configuration 

cat > .bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > .bashrc << "EOF"
# refresh the commands (or don't use hash function)
set +h 
# All files that user creates are only writable by the owner.
umask 022 
LFS=/mnt/lfs 
# Controls the location of certain programs.
LC_ALL=POSIX 
# Cross Compilation
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH 

# Change the site config, because some installation read it.
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF
