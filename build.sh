#!/bin/bash

PATH="$PATH:/usr/local/bin"

valac --pkg gio-2.0 --pkg gee-1.0 src/*.vala -o trace_analyzer