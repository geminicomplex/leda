#
# Leda -- The Gemini DOTS compiler makefile
#
# Copyright (c) 2015-2021 Gemini Complex Corporation. All rights reserved.
#

INCLUDES := -I. -I./gcorelib -I./gcorelib/lib/jsmn -I./gcorelib/lib/avl -I./gcorelib/lib/lz4 -I./gcorelib/lib/capnp -I./gcorelib/lib/slog 
CFLAGS := ${ARM_CFLAGS} -g -ggdb -O2 -c -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS := -fPIC

OS := $(shell uname)
ifeq ($(OS),Darwin)
	PLAT := mac
	CC := clang
	LDFLAGS += -lpthread
	BUILD_PATH := build/macosx
else
ifeq ($(MAKECMDGOALS),arm)
	PLAT := arm
	CC := arm-linux-gnueabihf-gcc
	ARM_CFLAGS := -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
	CFLAGS := ${ARM_CFLAGS} $(CFLAGS) -D_FILE_OFFSET_BITS=64
	LDFLAGS += -lpthread
	BUILD_PATH := build/arm
else
	PLAT := linux
	CC := gcc
	LDFLAGS += -lpthread
	BUILD_PATH := build/linux
endif
endif

EXEC := $(BUILD_PATH)/leda

SRCS := gcorelib/common.c gcorelib/dots.c gcorelib/util.c gcorelib/profile.c gcorelib/stim.c gcorelib/subvec.c \
	   gcorelib/serialize/stim_serdes.capnp.c gcorelib/config.c gcorelib/lib/capnp/capn.c gcorelib/lib/capnp/capn-malloc.c \
	   gcorelib/lib/capnp/capn-stream.c gcorelib/lib/lz4/lz4hc.c gcorelib/lib/lz4/lz4frame.c gcorelib/lib/lz4/xxhash.c \
	   gcorelib/lib/lz4/lz4.c gcorelib/lib/jsmn/jsmn.c gcorelib/lib/avl/avl.c gcorelib/lib/slog/slog.c gcorelib/lib/fe/fe.c \
	   main.c

HEADERS := gcorelib/profile.h gcorelib/stim.h gcorelib/config.h gcorelib/ gcorelib/dots.h gcorelib/common.h gcorelib/subvec.h gcorelib/util.h \
		gcorelib/serialize/stim_serdes.capnp.h gcorelib/lib/capnp/capnp_priv.h gcorelib/lib/capnp/capnp_c.h \
		lgcorelib/ib/lz4/xxhash.h gcorelib/lib/lz4/lz4.h gcorelib/lib/lz4/lz4frame_static.h gcorelib/lib/lz4/lz4hc.h \
		lgcorelib/ib/lz4/lz4frame.h gcorelib/lib/jsmn/jsmn.h \
		lgcorelib/ib/avl/avl.h gcorelib/lib/slog/slog.h gcorelib/lib/fe/fe.h

OBJS = $(SRCS:%.c=%.o)

all: $(EXEC)

$(EXEC) : $(OBJS)
	mkdir -p $(BUILD_PATH)
	$(CC) $(INCLUDES) $(LDFLAGS) $(OBJS) -o $(EXEC)
	ln -s -f $(EXEC) leda

%.o : %.c %.h 
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

clean:
	find . -name "*.o" -delete
	rm -rf leda build

.PHONY : all clean

