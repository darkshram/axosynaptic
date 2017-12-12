# vim: set ft=automake ts=8 sts=8 sw=8 :
include $(top_srcdir)/Makefile.common

desktopdir = $(datarootdir)/applications
nodist_desktop_DATA = org.mate.axosynaptic.desktop

@INTLTOOL_DESKTOP_RULE@

dist_man_MANS = axosynaptic.1

svgicondir = $(datadir)/icons/hicolor/scalable/apps
dist_svgicon_DATA = axosynaptic.svg

svgstatusicondir = $(datadir)/icons/hicolor/scalable/status
dist_svgstatusicon_DATA = axosynaptic-status.svg

svgstatusicondarkdir = $(datadir)/icons/Numix/24/status
dist_svgstatusicondark_DATA = Numix/axosynaptic-status.svg

svgstatusiconlightdir = $(datadir)/icons/Numix-Light/24/status
dist_svgstatusiconlight_DATA = Numix-Light/axosynaptic-status.svg

appdatadir = $(datadir)/metainfo
dist_appdata = org.mate.axosynaptic.xml

EXTRA_DIST = \
	org.mate.axosynaptic.desktop.in \
	$(NULL)

CLEANFILES = \
	$(nodist_desktop_DATA) \
	$(NULL)

