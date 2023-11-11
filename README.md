#  Nanobsd configuration scripts

## Howto

To build a generic `nanobsd` image:

    git clone https://github.com/lhondareyte/nanobsd.git  
    cd nanobsd/etc  && make install
    cd ..

Edit `$HOME/.etc/build.conf` to set day of month, then

    ./build.sh generic all

## ARMv7 plateform

The following directories are configuration files for armv7 SOC

    armv7/
    nanopi/

Each directory include a patched `common` configuration file that fix the following PRs :

 * [`PR255639`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255639)
 * [`PR271078`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271078)
 * [`PR271098`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271098)

### u-boot installation

The resulting image is not bootable, you need to install the u-boot binary file which depend of your motherboard. In example, for a foo SBC, install u-boot-foo on your build system, then:

    dd if=/usr/local/share/u-boot/foo/bar-spl.bin of=/dev/da0 bs=1k seek=8 conv=sync

Options depend of the board, see `/usr/local/share/u-boot/foo/README` for details.

### Limitation(s)

When building an armv7 image in a cross-compiling environment, you cannot install additional packages at build time. This can be achieved manually at run time:

First, increase `var` size:

    mount -orw /
    echo 163840 > /conf/base/var/md_size

Second, reboot an install your package :

    mount -orw /
    /usr/sbin/pkg install python3

Reset initial `var` size:

    echo 8192 > /conf/base/var/md_size
    
