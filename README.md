##  Nanobsd configuration scripts

Tested OK on FreeBSD 10.3, 11.1, 12.0 and 13.1. If you're still use FreeBSD 9.x, replace 
```
NANO_BOOLOADER="boot/mbr"
```
by
```
NANO_BOOLOADER="boot/boot0"
```
And remove ```cust_pkgng``` and ```cust_local``` functions in the configuration file.

