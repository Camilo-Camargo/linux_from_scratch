#!/bin/bash

LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
cd $LFS/sources

# binutils pass 1 
BINUTILS_VERSION=2.39 
BINUTILS=binutils-$BINUTILS_VERSION
tar -xvf $BINUTILS.tar.xz
	cd $BINUTILS 
		mkdir build
		cd build  
		
		#prefix             -> save the output
		#with-sysroot       -> find the tools in it directory. 
		#target             ->  adjust linker for cross compilation 
		#disable-nls        -> disable i18n internationalization 
		#enable-gprofng=no  -> disable profng 
		#disable-werror     -> Don't stop if there is an error. 

		../configure --prefix=$LFS/tools \
						 --with-sysroot=$LFS \
						 --target=$LFS_TGT   \
						 --disable-nls       \
						 --disable-gprofng=no\
						 --disable-werror 


		make -j16
		make install 
		cd ..
	cd ..  

	rm -rf $BINUTILS   

	echo "Binutils pass 1 successfully"
#------------------------------------------------------- 
# gcc pass 1  
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
	
	#x86_64 the default directory is lib 
	case $(uname -m) in
	  x86_64)
		 sed -e '/m64=/s/lib64/lib/' \
			  -i.orig gcc/config/i386/t-linux64
	 ;;
	esac 

	mkdir build
	cd build 
	 
	#with-glibc-version -> the glibc version to the target
	#with-newlib        ->  without compilation of code that needs libc.
	#without-headers    ->  Without target headers concerns.
	#disable-shared     ->  Link internal library statically.
	#disable-multilib   ->  Harmless for x86.
	#enable-language    -> specify the compilers to built. 
	#-- the another is a disable to prevent errors.
	../configure --target=$LFS_TGT         \
					 --prefix=$LFS/tools       \
					 --with-glibc-version=2.36 \
					 --with-sysroot=$LFS		   \
					 --with-newlib             \
					 --without-headers         \
					 --disable-nls             \
					 --disable-shared          \
					 --disable-multilib        \
					 --disable-decimal-float   \
					 --disable-threads         \
					 --disable-libatomic       \
					 --disable-libgomp         \
					 --disable-libquadmath     \
					 --disable-libssp          \
					 --disable-libvtv          \
					 --disable-libstdcxx       \
					 --enable-languages=c,c++ 

	make -j16
	make install

	#copy some headers files
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  'dirname $($LFS_TGT-gcc -print-libgcc-file-name)'/install-tools/include/limits.h 
	cd ..
cd .. 
rm -rf $GCC  

#-- Linux headers 
LINUX_VERSION=5.19.2
LINUX=linux-$LINUX_VERSION
tar -xvf $LINUX.tar.xz

cd LINUX
	make mrproper
	make headers
	find usr/include -type f ! -name '*.h' -delete
	cp -rv usr/include $LFS/usr 
cd .. 

rm -rf $LINUX

#-- Glibc  
GLIB_VERSION=2.36
GLIB=glibc-$GLIB_VERSION
# x86_64 
tar -xvf $GLIB.tar.xz
cd $GLIB 
	case $(uname -m) in
		 i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
		 ;;
		 x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
					ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
		 ;;
	esac 

	#patch
	patch -Np1 -i ../glibc-2.36-fhs-1.patch
	mkdir build 

	cd build  
	#ensuring ldconfig and sln are in /usr/sbin
	echo "rootsbindir=/usr/sbin" > configparms 

	#host          -> auto configuration
	#enable-kernel -> supported kernel and later
	#with-headers  -> recompile headers.
	#libc_cv_slibdir -> install the library in /usr/lib
	../configure                             \
			--prefix=/usr                      \
			--host=$LFS_TGT                    \
			--build=$(../scripts/config.guess) \
			--enable-kernel=3.2                \
			--with-headers=$LFS/usr/include    \
			libc_cv_slibdir=/usr/lib 

	make 

	# DESTDIR -> the location where install package
	make DESTDIR=$LFS install  
 
	# Fix hardcoded path to execute ldd
	sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd 

	# checking
	#[TODO]: create the check
 
	#limit header to lfs
	sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

	cd ..

cd ..
rm -rf $GLIB 

## -- Libstdc++
tar -xvf $GCC.tar.xz
cd $GCC
	mkdir build 
	#host -> specified the cross compiler
	#disable-libtdcxx-pch -> don't install the pre-compiled include files.
	#with-gxx-include-dir -> where the compiler would search include files.
		../libstdc++-v3/configure          \
			--host=$LFS_TGT                 \
			--build=$(../config.guess)      \
		 	--prefix=/usr                   \
			--disable-multilib              \
			--disable-nls                   \
			--disable-libstdcxx-pch         \
			--with-gxx-include-dir=/tools/$LFS_TGT/include/c++/12.2.0
 
		make -j16
		make DESTDIR=$LFS install- 

		# Remove harmful libtools.	 
		rm -v $LFS/usr/lib/lib{stdc++,stdc++fs,supc++}.la
	cd build
cd .. 
rm -rf $GCC 

