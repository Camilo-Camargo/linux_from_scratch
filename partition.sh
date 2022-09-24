#!/bin/sh 

# Create a fake disk 
LFS_PARTITION="lfs.disk" 
LFS_BOOT_PARTITION="boot.disk"
LFS_HOME_PARTITION="home.disk"

mkdir -p disk 
cd disk
	fallocate -l 15GB  $LFS_PARTITION
	fallocate -l 20GB  $LFS_HOME_PARTITION
	fallocate -l 500MB $LFS_BOOT_PARTITION

	# Formating the fake disk 
	mkfs.ext4 $LFS_PARTITION
	mkfs.ext4 $LFS_HOME_PARTITION
	mkfs.vfat -F32 $LFS_BOOT_PARTITION  

	# Mounting the file system structure 
	LFS=/mnt/lfs

	mount $LFS_PARTITION $LFS
	mkdir -p $LFS/boot
	mount $LFS_BOOT_PARTITION $LFS/boot
	mkdir -p $LFS/home
	mount $LFS_HOME_PARTITION $LFS/home
	export LFS 
cd ..  
echo "LFS Partitions successfully."



