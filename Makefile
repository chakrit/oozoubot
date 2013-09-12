#!/usr/bin/env make

COFFEE := node_modules/.bin/coffee
HUBOT  := node_modules/.bin/hubot


ifneq ($(wildcard Makefile.vars),)
include Makefile.vars
endif

ifeq ($(OOZOUBOT2),)
default: node_modules init
else
default: node_modules start
endif


init:
	$(COFFEE) init.coffee
	chmod +x heroku.bash
	@echo "./heroku.bash # to initialize heroku variables."

start:
	$(HUBOT) --adapter hipchat

node_modules:
	npm i

