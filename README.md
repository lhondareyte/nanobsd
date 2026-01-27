#  Nanobsd configuration scripts

Scripts and configuration files to build NanoBSD images for amd64 (aka x86_64) and armv7.

## Howto

To build a generic amd64 `nanobsd` image:

    git clone https://github.com/lhondareyte/nanobsd.git  
    cd nanobsd/install  && make install
    cd ..

Edit `$HOME/.etc/build.conf` to set day of month, then

    ./build.sh amd64

## ARMv7 plateform

The following directories contain configuration files for armv7 SOC :

    armv7/
    nanopi-neo/

include a patched `embbeded/common` configuration file that fix the following PRs :

 * [`PR271098`](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=271098)

### u-boot installation

The resulting image is not bootable, you need to install the u-boot SPL (Secondary Program Loader) that depend on your SBC. In example, for a foo SBC, install u-boot-foo on your build system, then:

    dd if=/usr/local/share/u-boot/foo/bar-spl.bin \
        of=/path/to/foo.img bs=1k \
	seek=8 conv=sync,notrunc

Options may vary, see `/usr/local/share/u-boot/foo/README` for details.

### Optional packages

You can add official packages at build time with `NANO_PACKAGES` option: 

    NANO_PACKAGES="nginx modsecurity3-nginx"
