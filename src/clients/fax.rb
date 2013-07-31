# encoding: utf-8

# File:	clients/fax.ycp
# Package:	phone-services
# Summary:     Configuration of a FAX machine
# Authors:	Karsten Keil <kkeil@suse.de>
#
# $Id$
#
#
module Yast
  class FaxClient < Client
    def main
      Yast.import "UI"

      textdomain "phone-services"

      Yast.import "CommandLine"
      Yast.import "Fax"
      Yast.import "Label"
      Yast.import "String"
      Yast.import "Summary"
      Yast.import "Wizard"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("fax module started")

      Yast.include self, "phone-services/fax.rb"

      @ret = :back


      # -- the command line description map --------------------------------------
      @cmdline = {
        "id"         => "fax",
        # translators: command line help text for fax module
        "help"       => _(
          "Fax configuration."
        ),
        "guihandler" => fun_ref(method(:FaxSequence), "any ()"),
        "initialize" => fun_ref(Fax.method(:Read), "boolean ()"),
        "finish"     => fun_ref(Fax.method(:Write), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler" => fun_ref(method(:FaxSummaryHandler), "boolean (map)"),
            # command line help text for 'summary' action
            "help"    => _(
              "Fax configuration summary."
            )
          }
        }
      }

      @ret = CommandLine.Run(@cmdline)

      # Finish
      Builtins.y2milestone("Returning with %1", @ret)
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end

    # main sequence
    def FaxSequence
      Fax.Read

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("fax")
      Wizard.SetNextButton(:next, Label.FinishButton)

      # main ui function
      ret = FaxMainDialog()
      Builtins.y2debug("ret == %1", ret)

      Fax.Write if ret == :next && Fax.modified
      UI.CloseDialog
      deep_copy(ret)
    end

    # command line summary handler
    def FaxSummaryHandler(options)
      options = deep_copy(options)
      items = []
      Builtins.foreach(Fax.aconfig) do |user, m|
        items = Builtins.add(
          items,
          [
            user,
            Ops.get_string(m, "fax_numbers", ""),
            Ops.get_string(m, "outgoing_MSN", ""),
            Ops.get_string(m, "fax_action", ""),
            Ops.get_string(m, "fax_stationID", ""),
            Ops.get_string(m, "fax_headline", "")
          ]
        )
      end
      if Ops.greater_than(Builtins.size(items), 0)
        CommandLine.Print(
          String.TextTable(
            [
              _("User"),
              _("Fax Numbers"),
              _("MSN"),
              _("Action"),
              _("StationID"),
              _("Headline")
            ],
            items,
            {}
          )
        )
      else
        CommandLine.Print(Summary.NotConfigured)
      end
      false
    end
  end
end

Yast::FaxClient.new.main
