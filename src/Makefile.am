# Sources for phone-services

module_DATA = \
  modules/Fax.rb \
  modules/Answering_machine.rb

client_DATA = \
  clients/fax.rb \
  clients/answering_machine.rb

yncludedir = @yncludedir@/phone-services
ynclude_DATA = \
  include/phone-services/fax.rb \
  include/phone-services/answering_machine.rb

scrconf_DATA = \
  scrconf/phone-services.scr

desktop_DATA = \
  desktop/answering_machine.desktop \
  desktop/fax.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common