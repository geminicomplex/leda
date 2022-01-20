#
# Leda -- The Gemini DOTS compiler makefile
#
# Copyright (c) 2015-2021 Gemini Complex Corporation. All rights reserved.
#

INCLUDES := -I. -I./libgcore -I./libgcore/lib/jsmn -I./libgcore/lib/avl -I./libgcore/lib/lz4 -I./libgcore/lib/capnp -I./libgcore/lib/slog -I./libgcore/lib/uthash  -I./libgcore/lib/sqlite -I./libgcore/lib/sha2
CFLAGS := ${ARM_CFLAGS} -g -ggdb -O2 -c -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS := -lm -ldl

CFLAGS += -DSQLITE_ENABLE_COLUMN_METADATA=1 \
    -DSQLITE_ENABLE_UNLOCK_NOTIFY \
    -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
    -DSQLITE_ENABLE_FTS3_TOKENIZER=1 \
    -DSQLITE_SECURE_DELETE \
    -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
    -DSQLITE_MAX_EXPR_DEPTH=10000

OS := $(shell uname)
ifeq ($(MAKECMDGOALS),gemini)
	PLAT := gemini
	CC := arm-linux-gnueabihf-gcc
	ARM_CFLAGS := -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard
	CFLAGS := ${ARM_CFLAGS} $(CFLAGS) -D_FILE_OFFSET_BITS=64 -D_XOPEN_SOURCE=700
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
	CFLAGS += -D_XOPEN_SOURCE=700
	LDFLAGS += -lpthread
	BUILD_PATH := build/linux
endif
endif

EXEC := $(BUILD_PATH)/leda

SRCS := libgcore/common.c libgcore/dots.c libgcore/util.c libgcore/profile.c libgcore/stim.c libgcore/subvec.c \
	   libgcore/serialize/stim_serdes.capnp.c libgcore/config.c libgcore/lib/capnp/capn.c libgcore/lib/capnp/capn-malloc.c \
	   libgcore/lib/capnp/capn-stream.c libgcore/lib/lz4/lz4hc.c libgcore/lib/lz4/lz4frame.c libgcore/lib/lz4/xxhash.c \
	   libgcore/lib/lz4/lz4.c libgcore/lib/jsmn/jsmn.c libgcore/lib/avl/avl.c libgcore/lib/slog/slog.c libgcore/lib/fe/fe.c \
	   libgcore/lib/sha2/sha-256.c libgcore/lib/sqlite/sqlite3.c libgcore/db.c main.c

HEADERS := libgcore/profile.h libgcore/stim.h libgcore/config.h libgcore/ libgcore/dots.h libgcore/common.h libgcore/subvec.h libgcore/util.h \
		libgcore/serialize/stim_serdes.capnp.h libgcore/lib/capnp/capnp_priv.h libgcore/lib/capnp/capnp_c.h \
		llibgcore/lib/lz4/xxhash.h libgcore/lib/lz4/lz4.h libgcore/lib/lz4/lz4frame_static.h libgcore/lib/lz4/lz4hc.h \
		libgcore/lib/lz4/lz4frame.h libgcore/lib/jsmn/jsmn.h libgcore/lib/avl/avl.h libgcore/lib/slog/slog.h libgcore/lib/fe/fe.h \
		libgcore/lib/sqlite/sqlite3.h libgcore/lib/sqlite/sqlite3ext.h libgcore/lib/sha2/sha-256.h libgcore/sql.h libgcore/db.h

OBJS = $(SRCS:%.c=%.o)

# compile for mac or linux
all: $(EXEC)

# compile for Gemini Tester
gemini: $(EXEC)

$(EXEC) : submodules $(OBJS)
	mkdir -p $(BUILD_PATH)
	$(CC) $(INCLUDES) $(LDFLAGS) $(OBJS) -o $(EXEC)
	ln -s -f $(EXEC) leda

%.o : %.c %.h 
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
            echo "INFO: Need to reinitialize git submodules"; \
            git submodule update --init; \
    fi

# installs for mac or linux
install: $(EXEC)
	cp -fv $(EXEC) /usr/local/bin/leda

uninstall:
	rm -f /usr/local/bin/leda

clean:
	find . -name "*.o" -delete
	rm -rf leda build

.PHONY : all clean gemini submodules

