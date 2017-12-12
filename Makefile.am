include $(top_srcdir)/Makefile.common

SUBDIRS = \
	src \
	vapi \
	data \
	po \
	$(NULL)

ACLOCAL_AMFLAGS = --install -I m4 ${ACLOCAL_FLAGS}

EXTRA_DIST = \
	Makefile.common \
	COPYING.GPL2 \
	COPYING.LGPL2.1 \
	README.md \
	NEWS.md \
	AUTHORS \
	$(NULL)

distclean-local:
	if test "x$(srcdir)" = "x."; then :; else \
		rm -f ChangeLog; \
	fi

