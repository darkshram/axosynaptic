# vim: set ft=automake ts=8 sts=8 sw=8 :
include $(top_srcdir)/Makefile.common

desktopdir = $(datarootdir)/applications
nodist_desktop_DATA = org.mate.axosynaptic.desktop

@INTLTOOL_DESKTOP_RULE@

dist_man_MANS = axosynaptic.1

svgicondir = $(datadir)/icons/hicolor/scalable/apps
dist_svgicon_DATA = axosynaptic.svg

EXTRA_DIST = \
	org.mate.axosynaptic.desktop.in \
	$(NULL)

CLEANFILES = \
	$(nodist_desktop_DATA) \
	$(NULL)

