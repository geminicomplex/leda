#
# Leda -- The Gemini DOTS compiler makefile
#
# Copyright (c) 2015-2021 Gemini Complex Corporation. All rights reserved.
#

INCLUDES := -I. -I./libgcore -I./libgcore/lib/jsmn -I./libgcore/lib/avl -I./libgcore/lib/lz4 -I./libgcore/lib/capnp -I./libgcore/lib/slog 
CFLAGS := ${ARM_CFLAGS} -g -ggdb -O2 -c -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS := -fPIC

OS := $(shell uname)
ifeq ($(MAKECMDGOALS),gemini)
	PLAT := gemini
	CC := arm-linux-gnueabihf-gcc
	ARM_CFLAGS := -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
	CFLAGS := ${ARM_CFLAGS} $(CFLAGS) -D_FILE_OFFSET_BITS=64
	LDFLAGS += -lpthread
	BUILD_PATH := build/gemini
else
ifeq ($(OS),Darwin)
	PLAT := mac
	CC := clang
	LDFLAGS += -lpthread
	BUILD_PATH := build/macosx
else
	PLAT := linux
	CC := gcc
	LDFLAGS += -lpthread
	BUILD_PATH := build/linux
endif
endif

EXEC := $(BUILD_PATH)/leda

SRCS := libgcore/common.c libgcore/dots.c libgcore/util.c libgcore/profile.c libgcore/stim.c libgcore/subvec.c \
	   libgcore/serialize/stim_serdes.capnp.c libgcore/config.c libgcore/lib/capnp/capn.c libgcore/lib/capnp/capn-malloc.c \
	   libgcore/lib/capnp/capn-stream.c libgcore/lib/lz4/lz4hc.c libgcore/lib/lz4/lz4frame.c libgcore/lib/lz4/xxhash.c \
	   libgcore/lib/lz4/lz4.c libgcore/lib/jsmn/jsmn.c libgcore/lib/avl/avl.c libgcore/lib/slog/slog.c libgcore/lib/fe/fe.c \
	   main.c

HEADERS := libgcore/profile.h libgcore/stim.h libgcore/config.h libgcore/ libgcore/dots.h libgcore/common.h libgcore/subvec.h libgcore/util.h \
		libgcore/serialize/stim_serdes.capnp.h libgcore/lib/capnp/capnp_priv.h libgcore/lib/capnp/capnp_c.h \
		llibgcore/lib/lz4/xxhash.h libgcore/lib/lz4/lz4.h libgcore/lib/lz4/lz4frame_static.h libgcore/lib/lz4/lz4hc.h \
		libgcore/lib/lz4/lz4frame.h libgcore/lib/jsmn/jsmn.h \
		libgcore/lib/avl/avl.h libgcore/lib/slog/slog.h libgcore/lib/fe/fe.h

OBJS = $(SRCS:%.c=%.o)

# compile for mac or linux
all: $(EXEC)

# compile for Gemini Tester
gemini: $(EXEC)

$(EXEC) : $(OBJS)
	mkdir -p $(BUILD_PATH)
	$(CC) $(INCLUDES) $(LDFLAGS) $(OBJS) -o $(EXEC)
	ln -s -f $(EXEC) leda

%.o : %.c %.h 
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

# installs for mac or linux
install: $(EXEC)
	cp -fv $(EXEC) /usr/local/bin/leda

uninstall:
	rm -f /usr/local/bin/leda

clean:
	find . -name "*.o" -delete
	rm -rf leda build

.PHONY : all clean gemini

