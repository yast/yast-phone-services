# encoding: utf-8

# File:	clients/answering_machine.ycp
# Package:	phone-services
# Summary:     Configuration of a phone answering machine
# Authors:	Karsten Keil <kkeil@suse.de>
#
# $Id$
#
#
module Yast
  class AnsweringMachineClient < Client
    def main
      Yast.import "UI"

      textdomain "phone-services"

      Yast.import "Answering_machine"
      Yast.import "CommandLine"
      Yast.import "Label"
      Yast.import "String"
      Yast.import "Summary"
      Yast.import "Wizard"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("answering_machine module started")

      Yast.include self, "phone-services/answering_machine.rb"

      @ret = :back

      # -- the command line description map --------------------------------------
      @cmdline = {
        "id"         => "answering_machine",
        # translators: command line help text for answering_machine module
        "help"       => _(
          "Answering machine configuration."
        ),
        "guihandler" => fun_ref(method(:Answering_machineSequence), "any ()"),
        "initialize" => fun_ref(Answering_machine.method(:Read), "boolean ()"),
        "finish"     => fun_ref(Answering_machine.method(:Write), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler" => fun_ref(
              method(:Answering_machineSummaryHandler),
              "boolean (map)"
            ),
            # command line help text for 'summary' action
            "help"    => _(
              "Answering machine configuration summary."
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

    # main sequence for a.m.
    def Answering_machineSequence
      Answering_machine.Read

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("answering_machine")
      Wizard.SetNextButton(:next, Label.FinishButton)

      # main ui function
      ret = Answering_machineMainDialog()
      Builtins.y2debug("ret == %1", ret)

      Answering_machine.Write if ret == :next && Answering_machine.modified
      UI.CloseDialog
      deep_copy(ret)
    end

    # command line summary handler
    def Answering_machineSummaryHandler(options)
      options = deep_copy(options)
      items = []
      Builtins.foreach(Answering_machine.aconfig) do |user, m|
        items = Builtins.add(
          items,
          [
            user,
            Ops.get_string(m, "voice_numbers", ""),
            Ops.get_string(m, "voice_delay", ""),
            Ops.get_string(m, "record_length", ""),
            Ops.get_string(m, "voice_action", "")
          ]
        )
      end
      if Ops.greater_than(Builtins.size(items), 0)
        CommandLine.Print(
          String.TextTable(
            [
              _("User"),
              _("Phone Numbers"),
              _("Delay"),
              _("Duration"),
              _("Action")
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

Yast::AnsweringMachineClient.new.main
