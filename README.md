##  Nanobsd configuration scripts

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

Require Patchs [255639](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255639) and [271078](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271078)