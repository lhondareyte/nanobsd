#  Nanobsd configuration scripts

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

The fixes associated with the following PRs are required

 * [`PR255639`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255639)
 * [`PR271098`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271098)

### u-boot installation

The resulting image is not bootable, you need to install the u-boot binary file  which depend of your motherboard. In example, for a [foo](https://en.wikipedia.org/wiki/Foobar) SBC, install `u-boot-foo` on your build system, then:

    dd if=/usr/local/share/u-boot/foo/bar-spl.bin of=/dev/da0 bs=1k seek=8 conv=sync

See `/usr/local/share/u-boot/foo/README` for options.

### Limitations

When building an armv7 image in a cross-compiling environment, you cannot install additional packages at build time. This can be achieved manually at run time:

    mount -t nfs Myserver:/With/my/binary/packages /mnt
    cd /mnt
    mount -orw /
    /usr/local/bin/pkg-static install nginx-1.24.0_6.txz
    
Optionnaly, you can save the current `pkg` database:

    cp /var/db/pkg/local.sqlite /conf/base/var/db/pkg/local.sqlite
    mount -oro /
    
