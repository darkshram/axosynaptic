# vim: set ft=automake ts=8 sts=8 sw=8 :
include $(top_srcdir)/Makefile.common

noinst_LTLIBRARIES = libaxosynapticcore.la

VAPIDIR = $(top_srcdir)/vapi

libaxosynapticcore_la_VALAFLAGS = \
	$(AXOSYNAPTIC_COMMON_VALAFLAGS) \
	$(AXOSYNAPTIC_MODULES_VALAFLAGS) \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

libaxosynapticcore_la_CFLAGS = $(AXOSYNAPTIC_MODULES_CFLAGS) -include config.h -w
libaxosynapticcore_la_LIBADD = $(AXOSYNAPTIC_MODULES_LIBS) $(LIBM)
libaxosynapticcore_la_VALASOURCES = \
	common-actions.vala \
	config-service.vala \
	data-sink.vala \
	dbus-service.vala \
	desktop-file-service.vala \
	match.vala \
	plugin.vala \
	query.vala \
	relevancy-service.vala \
	result-set.vala \
	utils.vala \
	volume-service.vala \
	$(NULL)

if HAVE_ZEITGEIST
libaxosynapticcore_la_VALASOURCES += relevancy-backend-zg.vala
libaxosynapticcore_la_VALAFLAGS += $(ZEITGEIST_VALAFLAGS)
libaxosynapticcore_la_CFLAGS += $(ZEITGEIST_CFLAGS)
libaxosynapticcore_la_LIBADD += $(ZEITGEIST_LIBS)
endif

nodist_libaxosynapticcore_la_SOURCES = \
	$(libaxosynapticcore_la_VALASOURCES:.vala=.c) \
	$(NULL)

axosynaptic-core.h axosynaptic-core.vapi: axosynaptic-core.vala.stamp

axosynaptic-core.vala.stamp: $(libaxosynapticcore_la_VALASOURCES) Makefile
	$(AM_V_VALA)$(VALAC) $(libaxosynapticcore_la_VALAFLAGS) -C -H axosynaptic-core.h --library axosynaptic-core $(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

BUILT_SOURCES = \
	axosynaptic-core.vala.stamp \
	axosynaptic-core.h \
	$(NULL)

EXTRA_DIST = \
	$(libaxosynapticcore_la_VALASOURCES) \
	$(NULL)

CLEANFILES = \
	$(nodist_libaxosynapticcore_la_SOURCES) \
	axosynaptic-core.vala.stamp \
	axosynaptic-core.vapi \
	axosynaptic-core.h \
	$(NULL)

