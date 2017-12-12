# vim: set ft=automake ts=8 sts=8 sw=8 :
include $(top_srcdir)/Makefile.common

bin_PROGRAMS = axosynaptic

VAPIDIR = $(top_srcdir)/vapi

axosynaptic_VALAFLAGS = \
	$(AXOSYNAPTIC_COMMON_VALAFLAGS) \
	$(AXOSYNAPTIC_MODULES_VALAFLAGS) \
	--basedir $(srcdir) \
	--directory $(builddir) \
	--vapidir $(top_builddir)/src/core \
	--pkg axosynaptic-core \
	--vapidir $(top_builddir)/src/plugins \
	--pkg plugins \
	--vapidir $(VAPIDIR) \
	$(VAPIDIR)/config.vapi \
	$(NULL)

axosynaptic_CFLAGS = \
	$(AXOSYNAPTIC_MODULES_CFLAGS) \
	-include config.h -w \
	-I$(top_builddir)/src/core \
	-I$(top_builddir)/src/plugins \
	$(NULL)

axosynaptic_LDADD = \
	$(AXOSYNAPTIC_MODULES_LIBS) \
	$(top_builddir)/src/core/libaxosynapticcore.la \
	$(top_builddir)/src/plugins/libplugins.la \
	$(LIBM) \
	$(NULL)

if HAVE_INDICATOR
axosynaptic_VALAFLAGS += $(APP_INDICATOR_VALAFLAGS)
axosynaptic_CFLAGS += $(APP_INDICATOR_CFLAGS)
axosynaptic_LDADD += $(APP_INDICATOR_LIBS)
endif

if HAVE_LIBREST
axosynaptic_VALAFLAGS += $(REST_VALAFLAGS)
axosynaptic_CFLAGS += $(REST_CFLAGS)
axosynaptic_LDADD += $(REST_LIBS)
endif

if HAVE_ZEITGEIST
axosynaptic_VALAFLAGS += $(ZEITGEIST_VALAFLAGS)
axosynaptic_CFLAGS += $(ZEITGEIST_CFLAGS)
axosynaptic_LDADD += $(ZEITGEIST_LIBS)
endif

axosynaptic_VALASOURCES = \
	axosynaptic-main.vala \
	keybindings.vala \
	category.vala \
	interfaces.vala \
	controller.vala \
	model.vala \
	view-base.vala \
	view-default.vala \
	view-essential.vala \
	view-doish.vala \
	view-side-doish.vala \
	view-virgilio.vala \
	widgets.vala \
	widgets-matchlistview.vala \
	icon-cache-service.vala \
	utils.vala \
	settings.vala \
	tile-view/abstract-tile-object.vala \
	tile-view/tile.vala \
	tile-view/tile-view.vala \
	tile-view/wrap-label.vala \
	$(NULL)

nodist_axosynaptic_SOURCES = \
	$(axosynaptic_VALASOURCES:.vala=.c) \
	$(NULL)

axosynaptic.vala.stamp: $(axosynaptic_VALASOURCES) $(top_builddir)/src/core/axosynaptic-core.vapi $(top_builddir)/src/plugins/plugins.vapi Makefile
	$(AM_V_VALA)$(VALAC) $(axosynaptic_VALAFLAGS) $(VALAFLAGS) -C $(filter %.vala %.c,$^)
	$(AM_V_at)touch $@

BUILT_SOURCES = \
	axosynaptic.vala.stamp \
	$(NULL)

EXTRA_DIST = \
	$(axosynaptic_VALASOURCES) \
	$(NULL)

CLEANFILES = \
	$(nodist_axosynaptic_SOURCES) \
	axosynaptic.vala.stamp \
	$(NULL)

