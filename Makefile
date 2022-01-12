#
# This file is part of the spectro-450 Project.
#
# Copyright (c)2016-2022  Luc Hondareyte
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in 
#    the documentation and/or other materials provided with the distribution.   
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
# OF THE POSSIBILITY OF SUCH DAMAGE.
#

IDENT      = NANOBSD
DEVICE     = /dev/da0

#
# Include local.conf if exist
-include local.conf

NANODIR    = /usr/src/tools/tools/nanobsd
NANOSCRIPT = $(NANODIR)/nanobsd.sh
MACHINE   != uname -m
KERNEL     = kernel.$(MACHINE)
NANOCFG    = nanobsd.conf
SUBDIRS    = generic spectro450
DISKIMAGE  = /usr/obj/nanobsd.$(IDENT)/_.disk.full 

usage:
	@printf "usage : \n\tmake [ $(SUBDIRS) ] && make all\n"

$(SUBDIRS) :
	[ -f ./$@/local.conf ] && cp ./$@/local.conf . || /usr//bin/true
	[ -f ./$@/$(NANOCFG) ] && cp ./$@/$(NANOCFG) . || cp generic/$(NANOCFG) .

.PHONY: $(SUBDIRS)

all: 
	@cp $(KERNEL) /usr/src/sys/$(MACHINE)/conf/$(IDENT)
	@/bin/sh $(NANOSCRIPT) -c $(NANOCFG)

world:
	@/bin/sh $(NANOSCRIPT) -k -i -c $(NANOCFG)

kernel:
	@cp $(KERNEL) /usr/src/sys/$(MACHINE)/conf/$(IDENT)
	@/bin/sh $(NANOSCRIPT) -w -i -c $(NANOCFG)

diskimage:
	@/bin/sh $(NANOSCRIPT) -k -w -b -c $(NANOCFG)
	@mv $(DISKIMAGE) nanobsd.img

install: 
	@printf "Writing image to disk..."
	@dd if=nanobsd.img of=$(DEVICE) bs=64k > /dev/null 2>&1
	@echo "done."

clean:
	@printf "Cleaning tree ..."
	@rm -rf local.conf nanobsd.env $(NANOCFG) 
	@echo "done."

mrproper: clean
	@rm -rf nanobsd.img /usr/obj/nanobsd.$(IDENT) $(NANODIR)/Pkg/*.txz

