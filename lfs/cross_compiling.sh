#!/bin/bash

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
cd $LFS/sources
 

#-- M4: Macro processor 
M4_VERSION=1.4.19
M4=m4-$M4_VERSION

tar -xvf $M4.tar.xz
cd $M4 
	./configure --prefix=/usr   \
					--host=$LFS_TGT \
					--build=$(build-aux/config.guess) 
	# we can get an error but this maybe because we don't
	# install the limit.h 
	#> $LFS/tools/libexec/gcc/$LFS_TGT/12.2.0/install-tools/mkheaders

	make
	make DESTDIR=$LFS install
 
cd .. 
rm -rf $M4


#-- ncurses: terminal TUI
NCURSES_VERSION=6.3
NCURSES=ncurses-$NCURSES_VERSION 

tar -xvf $NCURSES.tar.xz

cd $NCURSES  
   #ensure the present of gawk
	sed -i s/mawk// configure	 

	mkdir build
	#build tic
	pushd build
	  ../configure
	  make -C include
	  make -C progs tic
	popd
	#with-manpage-format/narmal -> install uncompress manual
	#with-shared                -> install shared libraries
	#without-normal             -> don't install or building static libraries
	#with-cxx-shared            -> install c++ libraries
	#without-ada                -> don't support ada compiler 
	#disable-stripping          -> don't used strip program 
	#enable-widec               -> use wide character libraries.
	./configure --prefix=/usr                \
					--host=$LFS_TGT              \
					--build=$(./config.guess)    \
					--mandir=/usr/share/man      \
					--with-manpage-format=normal \
					--with-shared                \
					--without-normal             \
					--with-cxx-shared            \
					--without-debug              \
					--without-ada                \
					--disable-stripping          \
					--enable-widec                
	make -j16
	make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
	# set the tic program that we just build 

	#set the library libncurses.so that is needed
	echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so

cd ..
rm -rf $NCURSES 

#-- BASH
BASH_VERSION=5.1.16
BASH=bash-$BASH_VERSION 

tar -xvf $BASH.tar.xz
cd $BASH  
	#without-bash-malloc -> disable the memory allocation that cause segmentation faults.
	./configure --prefix=/usr                   \
            --build=$(support/config.guess)    \
            --host=$LFS_TGT                    \
            --without-bash-malloc 

	make -j16
	make DESTDIR=$LFS install

	#sh link to bash
	ln -sv bash $LFS/bin/sh
cd ..
rm -rf  $BASH 

#-- Coreutils: basic system characteristics
COREUTILS_VERSION=9.1
COREUTILS=coreutils-$COREUTILS_VERSION

tar -xvf $COREUTILS.tar.xz
cd $COREUTILS 
	#enable-install-program -> hostname build and installed required by perl.
	./configure --prefix=/usr                   \ 
            --build=$(support/config.guess)    \
            --host=$LFS_TGT                    \
            --without-bash-malloc	 
	make -j16
	make DESTDIR=$LFS install

	#Move programs to the final location
	mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
	mkdir -pv $LFS/usr/share/man/man8
	mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
	sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8


cd .. 
rm -rf $COREUTILS 


#-- diffutils: shows differences between  files 
DIFFUTILS_VERSION=3.8
DIFFUTILS=diffutils-$DIFFUTILS_VERSION 

tar -xvf $DIFFUTILS.tar.xz
cd $DIFFUTILS 
	./configure --prefix=/usr --host=$LFS_TGT
	make
	make DESTDIR=$LFS install
cd ..
rm -rf $DIFFUTILS 

#--  FILE: file utilities
FILE_VERSION=5.42
FILE=file-$FILE_VERSION

tar -xvf $FILE.tar.xz

cd $FILE 
	# the file the same version with the host
	mkdir build
	pushd build
	  ../configure --disable-bzlib      \
						--disable-libseccomp \
						--disable-xzlib      \
						--disable-zlib
	  make
	popd
 

	./configure --prefix=/usr --host=$LFS_TGT 
	make FILE_COMPILE=$(pwd)/build/src/file
	make DESTDIR=$LFS install
	#remove the libtool, harmful for cross compilation.
	make DESTDIR=$LFS install

cd ..
rm -rf $FILE 

#-- findutils: find files utility
FINDUTILS_VERSION=4.9.0
FINDUTILS=findutils-$FINDUTILS_VERSION

tar -xvf $FINDUTILS.tar.xz

cd $FINDUTILS 
	./configure --prefix=/usr                   \
					--localstatedir=/var/lib/locate \
					--host=$LFS_TGT                 \
					--build=$(build-aux/config.guess) 
	make
	make DESTDIR$LFS install
cd ..
rm -rf $FINDUTILS 


#--gwak 
GAWK_VERSION=5.1.1
GAWK=gawk-$GAWK_VERSION


tar -xvf $GAWK.tar.xz

cd $GAWK
	#unneeded files
	sed -i 's/extras//' Makefile.in
	./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) 

	make
	make DESTDIR=$LFS install
cd ..
rm -rf $GAWK 

#-- grep: find 
GREP_VERSION=3.7
GREP=grep-$GREP_VERSION
 
tar -xvf $GREP.tar.xz

cd $GREP
	./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)	 

	make
	make DESTDIR=$LFS install
cd .. 
rm -rf $GREP 

#-- gzip

GZIP_VERSION=1.12
GZIP=gzip-$GZIP_VERSION

tar -xvf $GZIP.tar.xz

cd $GZIP 
	./configure --prefix=/usr --host=$LFS_TGT
	make
	make DESTDIR=$LFS install
cd ..

rm -rf $GZIP


#-- make

MAKE_VERSION=4.3
MAKE=make-$MAKE_VERSION

tar -xvf $MAKE.tar.xz

cd $MAKE
	#without-guile -> because this packages find for guile, prevents it
	./configure --prefix=/usr   \
					--without-guile \
					--host=$LFS_TGT \
					--build=$(build-aux/config.guess)
 
	make 
	make DESTDIR=$LFS install
cd ..
rm -rf $MAKE 

#-- Patch

PATCH_VERSION=2.7.6
PATCH=patch-$PATCH_VERSION 

tar -xvf $PATCH.tar.xz

cd $PATCH
	./configure --prefix=/usr   \
					--host=$LFS_TGT \
					--build=$(build-aux/config.guess) 

	make
	make DESTDIR=$LFS install
cd .. 
rm -rf $PATCH 

#-- sed

SED_VERSION=4.8
SED=sed-$SED_VERSION 

tar -xvf $SED.tar.xz
cd $SED 
	./configure --prefix=/usr   \
            --host=$LFS_TGT
	make 
	make DESTDIR=$LFS install
cd ..
rm -rf $SED

#-- tar
TAR_VERSION=1.34
TAR=sed-$SED_VERSION 

tar -xvf $TAR.tar.xz
cd $TAR 
	./configure --prefix=/usr                     \
					--host=$LFS_TGT                   \
					--build=$(build-aux/config.guess)
	make 
	make DESTDIR=$LFS install
cd ..
rm -rf $TAR

#--xz

#-- tar
XZ_VERSION=5.2.6
XZ=sed-$SED_VERSION 

tar -xvf $XZ.tar.xz
cd $XZ 

	./configure --prefix=/usr                     \
					--host=$LFS_TGT                   \
					--build=$(build-aux/config.guess) \
					--disable-static                  \
					--docdir=/usr/share/doc/xz-5.2.6	
	make 
	make DESTDIR=$LFS install

	#remove libtool
	rm -v $LFS/usr/lib/liblzma.la
cd ..
rm -rf $XZ

#-- binutils pass 2
BINUTILS_VERSION=2.39
BINUTILS=-$BINUTILS_VERSION

tar -xvf $BINUTILS.tar.xz


cd $BINUTILS
	#remove deprecation
	rm -v $LFS/usr/lib/liblzma.la

	mkdir build
	cd build  
	#enable-shared     -> build libbfd
	#enable-64-bit-bfd -> Enables 64-bit support.
	./configure                   \
		 --prefix=/usr              \
		 --build=$(../config.guess) \
		 --host=$LFS_TGT            \
		 --disable-nls              \
		 --enable-shared            \
		 --enable-gprofng=no        \
		 --disable-werror           \
		 --enable-64-bit-bfd  

	make -j16
	make DESTDIR=$LFS install

	# remove libtool
	rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes}.{a,la}
cd ..
rm -rf $BINUTILS 


#-- gcc 
GCC_VERSION=12.2.0
GCC=gcc-$GCC_VERSION 

MPFR_VERSION=4.1.0A
MPFR=mpfr-$MPFR_VERSION 

GMP_VERSION=6.2.1
GMP=gpm-$GMP_VERSION

MPC_VERSION=1.2.1
MPC=mpc-$MPC_VERSION


tar -xvf $GCC.tar.xz
cd $GCC 
	tar -xf ../$MPFR.tar.xz
	mv -v $MPFR mpfr 
	tar -xf ../$GMP.tar.xz
	mv -v $GMP gmp
	tar -xf ../$MPC.tar.xz
	mv -v $MPC mpc	
	
	#64 lib
	case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
	esac 

	#Allow POSIX threads
	sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

	mkdir build
	cd build
 	#with-build-sysroot -> change the global location for cross compilation
	#target -> build gcc with gcc pass 1
	#ldflags_for_target -> used shared libgcc instead of static version. 
	#enable-initfini-array -> we need to explicitly set this option.
	../configure                                       \
		 --build=$(../config.guess)                     \
		 --host=$LFS_TGT                                \
		 --target=$LFS_TGT                              \
		 LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
		 --prefix=/usr                                  \
		 --with-build-sysroot=$LFS                      \
		 --enable-initfini-array                        \
		 --disable-nls                                  \
		 --disable-multilib                             \
		 --disable-decimal-float                        \
		 --disable-libatomic                            \
		 --disable-libgomp                              \
		 --disable-libquadmath                          \
		 --disable-libssp                               \
		 --disable-libvtv                               \ 
		 --enable-languages=c,c++ 

	make -j16
	make DESTDIR=$LFS install  

	# generic compiler cc or gcc
	ln -sv gcc $LFS/usr/bin/cc
cd ..
rm -rf $GCC

