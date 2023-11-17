#  Nanobsd configuration scripts

Scripts and configuration files to build NanoBSD images for amd64 and armv7.

## Howto

To build a generic `nanobsd` image:

    git clone https://github.com/lhondareyte/nanobsd.git  
    cd nanobsd/install  && make install
    cd ..

Edit `$HOME/.etc/build.conf` to set day of month, then

    ./build.sh generic all

## ARMv7 plateform

The following directories are configuration files for armv7 SOC :

    armv7/
    nanopi-neo/

Each directory include a patched `common` configuration file that fix the following PRs :

 * [`PR255639`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=255639)
 * [`PR271078`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271078)
 * [`PR271098`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271098)

### u-boot installation

The resulting image is not bootable, you need to install the u-boot binary file which depend of your motherboard. In example, for a foo SBC, install u-boot-foo on your build system, then:

    dd if=/usr/local/share/u-boot/foo/bar-spl.bin of=/dev/da0 bs=1k seek=8 conv=sync

Options depend of the board, see `/usr/local/share/u-boot/foo/README` for details.

### Optionnal packages

You can add official packages à build time with `NANO_PACKAGES` option. For example:

    NANO_PACKAGES="nginx modsecurity3-nginx"
