#  Nanobsd configuration scripts

Tested OK on FreeBSD 13.2

## Howto

To build a generic ```nanobsd``` image:

    git clone https://github.com/lhondareyte/nanobsd.git  
    cd nanobsd/etc  && make install
    cd ..

Edit ```$HOME/.etc/build.conf``` to set day of month, then

    ./build.sh generic all

## ARMv7 plateform

The following directories are configuration files for armv7 SOC

    armv7/
    nanopi/
    nginx/

Require the followings patchs 

 * [255639](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255639) 
 * [271078](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271078)
 * [271098](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271098)

### u-boot installation

The resulting image is not bootable, you need to install the u-boot binary file :

    dd if=/usr/local/share/u-boot/foo/bar-spl.bin of=/dev/da0 bs=1k seek=8 conv=sync

