build:
	valac --pkg gio-2.0 --pkg gee-0.8 src/*.vala -o trace_analyzer

install: build
	install -d ${DESTDIR}/usr/local/bin/
	install -m 755 ./glide ${DESTDIR}/usr/local/bin/glide

test: build
	./trace_analyzer test.xt

clean:
	rm -f ./trace_analyzer



.PHONY: build test install clean
