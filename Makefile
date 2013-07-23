#!/usr/bin/env make

COFFEE := node_modules/.bin/coffee
HUBOT  := node_modules/.bin/hubot


ifeq ($(wildcard Makefile.vars),)
default: node_modules init

else
include Makefile.vars
default: node_modules start

endif


init:
	$(COFFEE) init.coffee

start:
	$(HUBOT) --adapter hipchat

node_modules:
	npm i

