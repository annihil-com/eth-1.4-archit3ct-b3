# GPL License - see http://opensource.org/licenses/gpl-license.php
# Copyright 2006 *nixCoders team - don't forget to credit us

VERSION = $(shell cat version.def)

CFLAGS = -Wall -fPIC -march=i686 -fno-strict-aliasing -fvisibility=hidden
LDFLAGS = -ldl -lm -shared

# Release/Debug flags
ifdef DEBUG
	CFLAGS += -g -ggdb3 -DETH_DEBUG
else
	CFLAGS += -O3 -ffast-math
	LDFLAGS += -s
endif

OBJS = aimbot.o backtrace.o commands.o drawtools.o engine.o eth.o g_functions.o hook.o \
	hud.o medias.o medicbot.o menu.o net.o punkbuster.o spycam.o visuals.o windows.o tracer.o
HEADERS = eth.h offsets.h hud.h menu.h net.h types.h windows.h tracer.h
PROG = libarch.so

# libghf
LIBGHF_VERSION = 0.5-2
LIBGHF_FOLDER = ghf
LIBGHF_DISTFILE = ghf-$(LIBGHF_VERSION).tar.gz
LIBGHF_URL = http://eth.sourceforge.net/$(LIBGHF_FOLDER)/
LIBGHF = $(LIBGHF_FOLDER)/libghf.a
LIBGHF_LDFLAGS = -lz -L$(LIBGHF_FOLDER) -lghf

# Release/Debug flags
ifdef DEBUG
	LIBGHF_LDFLAGS += -lelf -lbfd -lopcodes
else
	LIBGHF_LDFLAGS += /usr/lib/libelf.a /usr/lib/libbfd.a /usr/lib/libopcodes.a
endif

# pk3
PK3_FOLDER = pk3
PK3_FILE = zzz_arch.pk3

# auto-generate shaders file
SHADERS_SCRIPT = pk3/scripts/eth.shader
SHADERS_DEFINE = shaders.h
HEADERS += $(SHADERS_DEFINE)
SHADERS_MAKER = makeshaders.sh

# sdk
SDK_FOLDER = sdk
SDK_URL = ftp://ftp.mirror.nl/pub/mirror/idsoftware/idstuff/et/sdk/
SDK_FILE = et-linux-2.60-sdk.x86.run

DIST_FILES += $(OBJS:.o=.c) $(HEADERS) $(PROG) $(LIBGHF_DISTFILE) $(PK3_FILE) $(SDK_FOLDER) $(PK3_FOLDER) \
	$(SHADERS_MAKER) CHANGELOG CREDITS INSTALL LICENSE Makefile README run.sh version.def
DIST_FOLDER = eth-$(VERSION)

# Private
ifdef PRIVATE
	CFLAGS += -DETH_PRIVATE
	OBJS += private.o
	HEADERS += private.h
endif

# Default

intro	:
	@echo
	@echo "\033[0;33m      _   _"
	@echo "\033[0;33m  ___| |_| |__    *--------------*"
	@echo "\033[0;33m / _ \\ __| '_ \\    \033[0;33mHACK INFOS :"
	@echo "\033[0;33m|  __/ |_| | | |  \033[0;31m version\033[0;33m[\033[0m$(VERSION)\033[0;33m]"
	@echo "\033[0;33m \\___|\\__|_| | |  \033[0;31m website\033[0;33m[\033[0methcoders.free.fr\033[0;33m]"
	@echo "\033[0;33m  by EthCoders /  *--------------*\033[0m"
	@echo
	@echo

outro	:
	@echo
	@echo "\033[0;34mIt looks like \033[3;33m$(VERSION)\033[0;34m have successfully compiled !"
	@echo "Please never use it in clanwar. Have fun ! :)\033[0m"
	@echo
	@echo "visit us at http://ethcoders.free.fr/"
	@echo

all: intro $(SDK_FOLDER) $(LIBGHF) $(SHADERS_DEFINE) $(PK3_FILE) $(PROG) outro

# Compile
%.o	: %.c $(HEADERS) Makefile
	$(CC) $(CFLAGS) $(shell pkg-config --cflags libelf 2> /dev/null) -DETH_PK3_FILE=\"$(PK3_FILE)\" -DETH_VERSION=\"$(VERSION)\"  -c -o $@ $<

q_math.o: sdk/src/game/q_math.c Makefile
	$(CC) $(CFLAGS) -c -o $@ $<

title	:
	@echo
	@echo "\033[0;34mCompiling \033[3;33m$(VERSION)\033[0;34m ...\033[0m"

# Link
$(PROG)	: title $(OBJS) q_math.o
	@echo
	@echo "\033[0;34mLinking \033[3;33m$(VERSION)\033[0;34m ...\033[0m"
	$(CC) $(OBJS) q_math.o -o $(PROG) $(LDFLAGS) $(LIBGHF_LDFLAGS) 

# libghf
$(LIBGHF): $(LIBGHF_DISTFILE)
	@echo
	@echo "\033[0;34mExtracting \033[3;33mghf-$(LIBGHF_VERSION)\033[0;34m ...\033[0m"
	@tar xvf $(LIBGHF_DISTFILE)
	@echo
	@echo "\033[0;34mCompiling \033[3;33mghf-$(LIBGHF_VERSION)\033[0;34m ...\033[0m"
	@make -C $(LIBGHF_FOLDER) clean all $(if $(DEBUG), DEBUG=1)

$(LIBGHF_DISTFILE):
	wget $(LIBGHF_URL)$(LIBGHF_DISTFILE)

# sdk
$(SDK_FOLDER):
	@echo
	@test -f $(SDK_FILE) || wget $(SDK_URL)$(SDK_FILE)
	@echo "\033[0;34mExtracting \033[3;33mET SDK\033[0;34m ...\033[0m"
	mkdir $(SDK_FOLDER)
	/bin/sh $(SDK_FILE) --tar xfC $(SDK_FOLDER)
	@echo
	@echo "\033[0;34mCleaning \033[3;33mET SDK\033[0;34m ...\033[0m"
	find $(SDK_FOLDER) -not -name "q_math.c" -not -iname "*.h" -exec rm -f {} \; 2> /dev/null || /bin/true
	find $(SDK_FOLDER) -type d -exec rmdir -p {} \; 2> /dev/null || /bin/true
	rm -rf $(SDK_FOLDER)/src/botai
	@# Changing some var names in ET SDK to avoid conflict with system libs ...
	sed -i -e "s/Window/eth_Window/" $(SDK_FOLDER)/src/ui/ui_shared.h
	sed -i -e "s/DT_NUM/eth_DT_NUM/" $(SDK_FOLDER)/src/game/q_shared.h
	sed -i -e "s/EV_NONE/eth_EV_NONE/" $(SDK_FOLDER)/src/game/bg_public.h

# pk3
$(PK3_FILE): $(SHADERS_SCRIPT)
	cd $(PK3_FOLDER) && zip -q9r ../$(PK3_FILE) . -x '*.svn*' 

# auto-generate shaders files
$(SHADERS_DEFINE) $(SHADERS_SCRIPT): $(SHADERS_MAKER)
	/bin/sh $(SHADERS_MAKER)

clean	:
	@echo "\033[0;34mCleaning \033[3;33m$(VERSION)\033[0;34m directory ...\033[0m"
	rm -rf $(PROG) $(OBJS) $(LIBGHF_FOLDER) $(PK3_FILE) $(SDK_FOLDER) \
	 $(SHADERS_SCRIPT) $(SHADERS_DEFINE) q_math.o private.o

re	: clean all
	cp libarch.so ~/
	cp zzz_arch.pk3 ~/.etwolf/etmain/

dist	: re
	@echo
	@echo "\033[0;34mCreating \033[3;33m$(VERSION)\033[0;34m tarball ...\033[0m"
	rm -f $(VERSION).tar.gz
	mkdir $(DIST_FOLDER)
	cp -R $(DIST_FILES) $(DIST_FOLDER)
	find $(DIST_FOLDER) -type d -name ".svn" -exec rm -rf {} \; 2> /dev/null || /bin/true
	tar --numeric-owner -czf $(VERSION).tar.gz $(DIST_FOLDER)
	rm -rf $(DIST_FOLDER)

help:
	@echo "For this Makefile options see README"
