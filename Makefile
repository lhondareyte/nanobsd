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

DEVICE     = /dev/da0
NANODIR    = /usr/src/tools/tools/nanobsd
NANOSCRIPT = $(NANODIR)/nanobsd.sh
IDENT      = NANOBSD
MACHINE   != uname -m
KERNEL     = kernel.$(MACHINE)
NANOCFG    = nanobsd.conf
DISKIMAGE  = /usr/obj/nanobsd.$(IDENT)/_.disk.full 

SUBDIRS    = generic spectro450

usage:
        @printf "usage : \n\tmake [ $(SUBDIRS) ] && make all\n"

$(SUBDIRS) :
        cp ./$@/nanobsd.conf $(NANOCFG)

.PHONY: $(SUBDIRS)

all: $(SUBDIRS)
	@cp $(KERNEL) /usr/src/sys/$(MACHINE)/conf/$(IDENT)
	@/bin/sh $(NANOSCRIPT) -c $(NANOCFG)

world: $(SUBDIRS)
	@/bin/sh $(NANOSCRIPT) -k -i -c $(NANOCFG)

kernel: $(SUBDIRS)
	@cp $(KERNEL) /usr/src/sys/$(MACHINE)/conf/$(IDENT)
	@/bin/sh $(NANOSCRIPT) -w -i -c $(NANOCFG)

diskimage: $(SUBDIRS)
	@/bin/sh $(NANOSCRIPT) -k -w -b -c $(NANOCFG)
	@mv $(DISKIMAGE) nanobsd.img

install:  $(SUBDIRS)
	@printf "Writing image to disk..."
	@dd if=nanobsd.img of=$(DEVICE) bs=64k > /dev/null 2>&1
	@echo "done."

clean:
	@printf "Cleaning tree ..."
	@rm -rf /usr/obj/nanobsd.$(IDENT) nanobsd.img nanobsd.env $(NANOCFG) $(NANODIR)/Pkg/*.txz
	@echo "done."

