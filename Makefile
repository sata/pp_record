.PHONY: compile all

R = ./rebar3

compile:
	$(R) compile

all:: compile
