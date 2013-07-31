# encoding: utf-8

# File:	include/phone-services/answering_machine.ycp
# Package:	Communication
# Summary:     phone answering machine dialogs
# Authors:	Karsten Keil <kkeil@suse.de>
#
# $Id$
#
#
module Yast
  module PhoneServicesAnsweringMachineInclude
    def initialize_phone_services_answering_machine(include_target)
      Yast.import "UI"

      textdomain "phone-services"

      Yast.import "Answering_machine"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Popup"


      @actionmap = {
        "MailAndSave" => _("MailAndSave"),
        "SaveOnly"    => _("SaveOnly")
      }
    end

    # Main answering machine dialog
    # @param standalone true if not run from another ycp client
    # @return dialog result
    def Answering_machineMainDialog
      # dialog caption
      caption = _("Answering Machine Configuration")

      # some variables

      theader = Header(
        # Table header 1/5
        _("User"),
        # Table header 2/5
        _("Phone Numbers"),
        # Table header 3/5
        _("Delay"),
        # Table header 4/5
        _("Duration"),
        # Table header 5/5
        _("Action")
      )

      # Answering machine general help 1/2
      help = _(
        "<p>An answering machine for one or more users can be\n" +
          "set up in this dialog. Each user must have at least one unique phone\n" +
          "number configured. Refer to the telecommunication chapter in the manuals\n" +
          "for further details.</p>\n"
      ) +
        # Answering machine general help 2/2
        _(
          "<p>When adding or editing a user, a dialog will be shown with\nthe following details:</p>"
        ) +
        # Answering machine help for options 1/6
        _(
          "<p><b>User</b>: The system user who wants to receive calls with the\nanswering machine.</p>"
        ) +
        # Answering machine help for options 2/6
        _(
          "<p><b>Phone Numbers</b>: One or more phone numbers (separated by\n" +
            "commas) that belong (only) to this user. You can also enter <tt>*</tt>,\n" +
            "which means the user will get <b>any</b> call.</p>\n"
        ) +
        # Answering machine help for options 3/6
        _(
          "<p><b>Delay</b>: Delay in seconds before the answering machine responds\nto the call.</p>"
        ) +
        # Answering machine help for options 4/6
        _("<p><b>Duration</b>: Maximum record length for one call.</p>") +
        # Answering machine help for options 5/6
        _(
          "<p><b>Action</b>: By using the default <tt>MailAndSave</tt>, recorded\n" +
            "calls are sent to the user as mail and saved to disk. To\n" +
            "disable the mails, set this to <tt>SaveOnly</tt>. <tt>None</tt> forbids\n" +
            "recording -- the answering machine only plays the announcement.</p>\n"
        ) +
        # Answering machine help for options 6/6
        _(
          "<p><b>Pin</b>: Identification code for the remote inquiry function.</p>"
        )

      max = 0
      items = 0
      table_items = []
      userconf = deep_copy(Answering_machine.aconfig)

      # make ui items from config map
      item = nil
      Builtins.foreach(userconf) do |k, m|
        item = Item(
          Id(k),
          k,
          Ops.get_string(m, "voice_numbers", ""),
          Ops.get_string(m, "voice_delay", ""),
          Ops.get_string(m, "record_length", ""),
          Ops.get(@actionmap, Ops.get_string(m, "voice_action", ""), "")
        )
        table_items = Builtins.add(table_items, item)
        items = Ops.add(items, 1)
      end

      Builtins.y2debug("table_items=%1", table_items)
      Builtins.y2debug("items=%1", items)
      Builtins.y2debug("userconf=%1", userconf)
      max = items

      # main dialog contents
      contents = HBox(
        HSpacing(5),
        VBox(
          VStretch(),
          VSpacing(1),
          Frame(
            _("&User Table"),
            VBox(
              Table(Id(:table), theader, []),
              # http://en.opensuse.org/openSUSE:YaST_style_guide
              Left(
                HBox(
                  PushButton(Id(:add), Label.AddButton),
                  PushButton(Id(:edit), Opt(:disabled), Label.EditButton),
                  PushButton(Id(:delete), Opt(:disabled), Label.DeleteButton)
                )
              )
            )
          ),
          VSpacing(1),
          VStretch()
        ),
        HSpacing(5)
      )

      # style guide: OK, Cancel
      # http://lists.opensuse.org/yast-devel/2009-01/msg00021.html
      Wizard.SetContents(caption, contents, help, true, true)
      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      Wizard.HideBackButton

      UI.ChangeWidget(Id(:table), :Items, table_items)
      UI.SetFocus(Id(:table))

      ret = nil
      while true
        new_table = false
        cur_item = {}

        UI.ChangeWidget(Id(:edit), :Enabled, Ops.greater_than(items, 0))
        UI.ChangeWidget(Id(:delete), :Enabled, Ops.greater_than(items, 0))

        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel
          # TODO: handle the changed dialog values
          if !Answering_machine.modified || Popup.ReallyAbort(true)
            break
          else
            next
          end
        # edit user settings
        elsif ret == :edit
          cur = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))

          Builtins.y2debug("cur=%1", cur)

          cur_item = AM_UserEditDialog(cur, userconf)
          Builtins.y2debug("cur_item=%1", cur_item)
          if cur_item == nil
            next
          else
            cur = Ops.get_string(cur_item, "ID", "")
            next if cur == ""
            cur_item = Builtins.filter(cur_item) { |k, v| k != "ID" }
            new_table = true
            userconf = Builtins.add(userconf, cur, cur_item)
            Builtins.y2debug("userconf=%1", userconf)
          end
        # add user
        elsif ret == :add
          cur_item = AM_UserEditDialog("", userconf)
          if cur_item == nil
            next
          else
            cur = Ops.get_string(cur_item, "ID", "")
            next if cur == ""
            cur_item = Builtins.filter(cur_item) { |k, v| k != "ID" }
            new_table = true
            userconf = Builtins.add(userconf, cur, cur_item)
          end
        # delete user
        elsif ret == :delete
          items = Ops.subtract(items, 1)
          cur = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))
          table_items = Builtins.filter(table_items) do |e|
            cur != Ops.get_string(e, [0, 0], "")
          end
          userconf = Convert.convert(
            Builtins.filter(userconf) { |k, v| k != cur },
            :from => "map",
            :to   => "map <string, map>"
          )
          new_table = true
        elsif ret == :back
          break
        elsif ret == :next
          break
        else
          Builtins.y2debug("Unexpected retcode: %1", ret)
          next
        end
        if new_table
          items = 0
          table_items = []
          Builtins.foreach(userconf) do |k, m|
            item = Item(
              Id(k),
              k,
              Ops.get_string(m, "voice_numbers", ""),
              Ops.get_string(m, "voice_delay", ""),
              Ops.get_string(m, "record_length", ""),
              Ops.get(@actionmap, Ops.get_string(m, "voice_action", ""), "")
            )
            table_items = Builtins.add(table_items, item)
            items = Ops.add(items, 1)
          end
          max = items
          UI.ChangeWidget(Id(:table), :Items, table_items)
          UI.ChangeWidget(Id(:table), :CurrentItem, max)
          Answering_machine.modified = true
        end
      end

      # update settings from widgets
      if ret == :next
        if Answering_machine.aconfig != userconf
          Answering_machine.aconfig = deep_copy(userconf)
          Answering_machine.modified = true
        end
      end
      deep_copy(ret)
    end
    def AM_UserEditDialog(uname, uconf)
      uconf = deep_copy(uconf)
      uc = Ops.get_map(uconf, uname, {})

      if uc == {}
        # set globals as defaults
        Ops.set(
          uc,
          "voice_delay",
          Ops.get(Answering_machine.gconfig, "voice_delay", "10")
        )
        Ops.set(
          uc,
          "record_length",
          Ops.get(Answering_machine.gconfig, "record_length", "60")
        )
        Ops.set(
          uc,
          "voice_action",
          Ops.get(Answering_machine.gconfig, "voice_action", "MailAndSave")
        )
      end

      # values for delay
      delay_val = [
        "",
        "0",
        "5",
        "10",
        "15",
        "20",
        "30",
        "40",
        "50",
        "60",
        "90",
        "120"
      ]
      if !Builtins.contains(delay_val, Ops.get_string(uc, "voice_delay", ""))
        delay_val = Builtins.add(
          delay_val,
          Ops.get_string(uc, "voice_delay", "")
        )
      end

      # values for record_length
      rlength_val = [
        "",
        "0",
        "10",
        "20",
        "30",
        "45",
        "60",
        "90",
        "120",
        "150",
        "180",
        "240",
        "300"
      ]
      if !Builtins.contains(
          rlength_val,
          Ops.get_string(uc, "record_length", "")
        )
        rlength_val = Builtins.add(
          rlength_val,
          Ops.get_string(uc, "record_length", "")
        )
      end

      # add at least the user
      if uname != "" && !Builtins.contains(Answering_machine.users, uname)
        Answering_machine.users = Builtins.add(Answering_machine.users, uname)
        Answering_machine.users = Builtins.sort(Answering_machine.users)
      end

      Builtins.y2debug("uc=%1", uc)

      UI.OpenDialog(
        Opt(:decorated),
        VBox(
          HSpacing(1),
          VBox(
            # ComboBox label
            ComboBox(
              Id(:user),
              Opt(:editable, :hstretch),
              _("&User"),
              Answering_machine.users
            ),
            # TextEntry label
            TextEntry(
              Id(:phone),
              _("&Phone Numbers"),
              Ops.get_string(uc, "voice_numbers", "")
            ),
            # ComboBox label
            ComboBox(
              Id(:delay),
              Opt(:editable, :hstretch),
              _("&Delay"),
              delay_val
            ),
            # ComboBox label
            ComboBox(
              Id(:duration),
              Opt(:editable, :hstretch),
              _("D&uration"),
              rlength_val
            ),
            # ComboBox label
            ComboBox(
              Id(:action),
              Opt(:hstretch),
              _("&Action"),
              [
                Item(Id(:MailAndSave), Ops.get(@actionmap, "MailAndSave", "")),
                Item(Id(:SaveOnly), Ops.get(@actionmap, "SaveOnly", ""))
              ]
            ),
            # TextEntry label
            TextEntry(Id(:pin), _("P&in"), Ops.get_string(uc, "pin", ""))
          ),
          HSpacing(1),
          ButtonBox(
            PushButton(Id(:ok), Opt(:default), Label.OKButton),
            PushButton(Id(:cancel), Label.CancelButton)
          )
        )
      )

      UI.ChangeWidget(Id(:user), :Value, uname) if uname != ""
      UI.ChangeWidget(
        Id(:delay),
        :Value,
        Ops.get_string(uc, "voice_delay", "10")
      )
      UI.ChangeWidget(
        Id(:duration),
        :Value,
        Ops.get_string(uc, "record_length", "60")
      )
      if Ops.get_string(uc, "voice_action", "") == "MailAndSave"
        UI.ChangeWidget(Id(:action), :Value, :MailAndSave)
      else
        UI.ChangeWidget(Id(:action), :Value, :SaveOnly)
      end

      UI.ChangeWidget(Id(:phone), :ValidChars, "0123456789#*,")
      UI.ChangeWidget(Id(:delay), :ValidChars, "0123456789")
      UI.ChangeWidget(Id(:duration), :ValidChars, "0123456789")
      UI.ChangeWidget(Id(:pin), :ValidChars, "0123456789*#")
      UI.SetFocus(Id(:user))

      ret = nil
      user = ""
      sval = ""
      aval = nil

      while true
        ret = UI.UserInput
        break if ret != :ok

        user = Convert.to_string(UI.QueryWidget(Id(:user), :Value))
        if user == nil || user == ""
          # Popup::Error text
          Popup.Error(_("User must be set."))
          UI.SetFocus(Id(:user))
          next
        end
        uc = Builtins.add(uc, "ID", user)

        sval = Convert.to_string(UI.QueryWidget(Id(:phone), :Value))
        if sval == nil || sval == ""
          # Popup::Error text
          Popup.Error(_("Phone numbers must not be empty."))
          UI.SetFocus(Id(:phone))
          next
        end
        uc = Builtins.add(uc, "voice_numbers", sval)

        sval = Convert.to_string(UI.QueryWidget(Id(:delay), :Value))
        if sval == ""
          # Popup::Error text
          Popup.Error(_("Delay is invalid."))
          UI.SetFocus(Id(:delay))
          next
        end
        uc = Builtins.add(uc, "voice_delay", sval)

        sval = Convert.to_string(UI.QueryWidget(Id(:duration), :Value))
        # Duration "" is OK, default value
        uc = Builtins.add(uc, "record_length", sval)

        aval = UI.QueryWidget(Id(:action), :Value)
        if aval == nil
          # Popup::Error text
          Popup.Error(_("Action is invalid."))
          UI.SetFocus(Id(:action))
          next
        elsif aval == :MailAndSave
          uc = Builtins.add(uc, "voice_action", "MailAndSave")
        elsif aval == :SaveOnly
          uc = Builtins.add(uc, "voice_action", "SaveOnly")
        end

        sval = Convert.to_string(UI.QueryWidget(Id(:pin), :Value))
        # Pin "" is OK, no remote control
        uc = Builtins.add(uc, "pin", sval)
        break
      end
      Builtins.y2debug("ret=%1", ret)
      UI.CloseDialog
      return nil if ret != :ok
      deep_copy(uc)
    end
  end
end
