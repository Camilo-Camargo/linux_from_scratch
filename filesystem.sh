#!/bin/sh

LFS=/mnt/lfs

cd $LFS  
	#simple layout
	mkdir -pv $LFS/{etc,var} $LFS/usr/{bin/lib,sbin}

	for i in bin lib sbin; do
		ln -sv usr/$i $LFS/$i
	done 

	case $(uname -m) in
		x86_64) mkdir -pv $LFS/lib64 ;;
	esac 
 
	# for cross compilation
	mkdir -pv $LFS/tools 
	
	#Create a unprivileged user, to ensure don't crash all system.
	groupadd lfs
	useradd -s /bin/zsh -g lfs -m -k /dev/null lfs
	password lfs lfs

	# Granted permissions
	chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
	case $(uname -m) in
		x86_64) chown -v lfs $LFS/lib64 ;;
	esac 

	#login 
	su - lfs


