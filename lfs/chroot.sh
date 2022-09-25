#!/bin/sh
#run this program how root  

#solving the id user
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac  

#kernel share virtual file systems
mkdir -pv $LFS/{dev,proc,sys,run}

#/dev create a mirror of the host
mount -v --bind /dev $LFS/dev

#virtual kernel files
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run 

#check if there is symbolic link to /dev/shm
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi 

#entering to the chroot  
#i -> clear all variables 
#"$LFS" -> the root directory 

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login 


#Creating the complete layout of the lfs
mkdir -pv /{boot,home,mnt,opt,srv} 

#Create the necessary subdirectories 
#layout specification is under by FHS (Filesystem Hierarchy Standard)
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp


# maintions a list of mounted file system in /etc/mtab
ln -sv /proc/self/mounts /etc/mtab 

# Create the basic hosts (How when we installed Arch Linux)
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF 

# Create the /etc/passwd to identified the users
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF 

# Create the Groups  
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF 


# the creation of group isn't a standard
# if you can write a minimal setup 
# root:x:0
# bin:x:1 
# tty:x:5 

# test user
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester 

# re-login to the chroot
exec /usr/bin/bash --login 

# Ensures that logs will be writing  
#wtmp -> login and logouts 
#lastlog -> last logged
#faillog -> fail logs
#btpm -> bod login  
#utmp currently logged in

touch /var/log/{btmp,lastlog,faillog,wtmp} 
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp 

#-- gettext: internationalization and locations 
cd /sources 
GETTEXT_VERSION=0.21
GETTEXT=gettext-$GETTEXT_VERSION
tar -xvf $GETTEXT.tar.xz
cd $GETTEXT 
  ./configure --disable-shared
  make -j16

  # copy msgfmt, msgmerge, xgettext
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin 
cd ..
rm -rf $GETTEXT
cd  # get back to the root user directory 


#-- bison: parser generator
BISON_VERSION=3.8.2
BISON=bison-$BISON_VERSION

cd /sources
tar -xvf $BISON.tar.xz
cd $BISON 
  #docdir -> install documentation into the ...
  ./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2  
cd ..
rm -rf $BISON
cd  

#-- perl
PERL_VERSION=5.36.0
PERL=perl-$PERL_VERSION

tar -xvf $PERL.tar.xz
cd $PERL   
  #des -> 
  #    d -> default
  #    e -> ensure completion task
  #    s -> silent
  sh Configure -des                                        \
               -Dprefix=/usr                               \
               -Dvendorprefix=/usr                         \
               -Dprivlib=/usr/lib/perl5/5.36/core_perl     \
               -Darchlib=/usr/lib/perl5/5.36/core_perl     \
               -Dsitelib=/usr/lib/perl5/5.36/site_perl     \
               -Dsitearch=/usr/lib/perl5/5.36/site_perl    \
               -Dvendorlib=/usr/lib/perl5/5.36/vendor_perl \
               -Dvendorarch=/usr/lib/perl5/5.36/vendor_perl
  make -j16
  make install
cd ..
rm -rf $BISON
cd 


#-- Python
PYTHON_VERSION=3.10.6
PYTHON=Python-$PYTHON_VERSION 

tar -xvf $PYTHON.tar.xz
cd $PYTHON
  #without-ensurepip disable pip
  ./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip 

  make -j16
  make install
cd ..
rm -rf $PYTHON
cd 

#-- textinfo: reading and writing info pages
TEXTINFO_VERSION=6.8
TEXTINFO=textinfo-$TEXTINFO_VERSION

tar -xvf $TEXTINFO.tar.xz 
cd $TEXTINFO 
  ./configure --prefix=/usr
  make -j16
  make install
cd ..
rm -rf TEXTINFO
cd  

#--utillinux
UTILLINUX_VERSION=2.38.1
UTILLINUX=util-linux-$UTILLINUX_VERSION

tar -xvf $UTILLINUX.tar.xz 

cd $UTILLINUX 
  #create the adjtime
 mkdir -pv /var/lib/hwclock  
  #ajdtime_path -> directory of adjtime
  #libdir       -> targeting supported
  #runstatedir  -> the path of the socket to uuidd
 ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --libdir=/usr/lib    \
            --docdir=/usr/share/doc/util-linux-2.38.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            runstatedir=/run 

 make -j16
 make install

cd .. 
rm -rf $UTILLINUX
cd 

# Removing unnecessary temporal documentation
rm -rf /usr/share/{info,man,doc}/*
# Remove shared libtool
find /usr/{lib,libexec} -name \*.la -delete 
# We can delete the cross compilers tools
rm -rf /tools

# Create and backup
