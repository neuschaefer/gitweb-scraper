SRCS = scraper.m
CFLAGS += -g --arc

all: gitweb-scraper

gitweb-scraper: $(SRCS)
	objfw-compile $(SRCS) -o $@ $(CFLAGS)
