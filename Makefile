#
# Leda -- The Gemini DOTS compiler makefile
#
# Copyright (c) 2015-2021 Gemini Complex Corporation. All rights reserved.
#

INCLUDES := -I. -I./lib/jsmn -I./lib/avl -I./lib/lz4 -I./lib/capnp -I./lib/slog 
CFLAGS := ${ARM_CFLAGS} -g -ggdb -O2 -c -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS := -fPIC

OS := $(shell uname)
ifeq ($(OS),Darwin)
	PLAT := mac
	CC := gcc
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

SRCS := common.c dots.c util.c profile.c stim.c subvec.c \
	   serialize/stim_serdes.capnp.c config.c lib/capnp/capn.c lib/capnp/capn-malloc.c \
	   lib/capnp/capn-stream.c lib/lz4/lz4hc.c lib/lz4/lz4frame.c lib/lz4/xxhash.c \
	   lib/lz4/lz4.c lib/jsmn/jsmn.c lib/avl/avl.c lib/slog/slog.c lib/fe/fe.c \
	   main.c

HEADERS := profile.h stim.h config.h  dots.h common.h subvec.h util.h \
		serialize/stim_serdes.capnp.h lib/capnp/capnp_priv.h lib/capnp/capnp_c.h \
		lib/lz4/xxhash.h lib/lz4/lz4.h lib/lz4/lz4frame_static.h lib/lz4/lz4hc.h \
		lib/lz4/lz4frame.h lib/jsmn/jsmn.h \
		lib/avl/avl.h lib/slog/slog.h lib/fe/fe.h

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
	rm -f leda build/mac/leda build/linux/leda build/arm/leda

.PHONY : all clean

