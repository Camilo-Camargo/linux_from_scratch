#!/bin/sh

LFS=/mnt/lfs

mkdir -p $LFS/sources
#Sticky directory
chmod -v a+wt $LFS/sources 
# Retrieving the necessary resources 
LFS_PACKAGES_VERSION=11.2   
LFS_PACKAGES=lfs-packages-$LFS_PACKAGES_VERSION.tar

wget https://ftp.osuosl.org/pub/lfs/lfs-packages/$LFS_PACKAGES --directory-prefix=$LFS/sources  

cd $LFS/sources 
	tar -xvf $LFS_PACKAGES -C . --strip-components=1 

	#Check the checksum for every file 
	pushd .
		md5sum  -c md5sums || exit
	popd
cd .. 

echo "You have the sources at $LFS/sources"




