#!/usr/bin/env make

include Makefile.vars

COFFEE := node_modules/.bin/coffee
HUBOT  := node_modules/.bin/hubot


ifeq ($(HUBOT_HIPCHAT_ROOMS),)
default: node_modules init
else
default: node_modules start
endif

debug:
	$(COFFEE) test.coffee

init:
	$(COFFEE) init.coffee

start:
	$(HUBOT) --adapter hipchat

node_modules:
	npm i

