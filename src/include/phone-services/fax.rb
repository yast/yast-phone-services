# encoding: utf-8

# File:	include/phone-services/fax.ycp
# Package:	Communication
# Summary:     Fax machine dialogs
# Authors:	Karsten Keil <kkeil@suse.de>
#
# $Id$
#
#
module Yast
  module PhoneServicesFaxInclude
    def initialize_phone_services_fax(include_target)
      Yast.import "UI"

      textdomain "phone-services"

      Yast.import "Fax"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Popup"

      @actionmap = {
        "MailAndSave" => _("MailAndSave"),
        "SaveOnly"    => _("SaveOnly")
      }
    end

    # Main Fax machine dialog
    # @param standalone true if not run from another ycp client
    # @return dialog result
    def FaxMainDialog
      # dialog caption
      caption = _("Fax Machine Configuration")

      # some variables

      theader = Header(
        # Table header 1/6
        _("User"),
        # Table header 2/6
        _("Fax Numbers"),
        # Table header 3/6
        _("MSN"),
        # Table header 4/6
        _("Action"),
        # Table header 5/6
        _("StationID"),
        # Table header 6/6
        _("Headline")
      )

      # Fax dialog general help 1/3
      help = _(
        "<p>The fax system for one or more users can be\n" +
          "set up in this dialog. Each user must have at least one unique fax\n" +
          "number configured. Refer to the telecommunication chapter in the\n" +
          "manuals for further details.</p>\n"
      ) +
        # Fax dialog general help 2/3
        _(
          "<p><b>Prefix</b>: Only for users behind a PBX. Enter the\n" +
            "prefix number for getting a public line. This number will be dialed\n" +
            "before any destination number.</p>\n"
        ) +
        # Fax dialog general help 3/3
        _(
          "<p>When adding or editing a user, a dialog will be shown with\nthe following fields:</p>"
        ) +
        # Fax dialog help for options 1/6
        _(
          "<p><b>User</b>: The system user to which this fax account belongs.</p> \n"
        ) +
        # Fax dialog help for options 2/6
        _(
          "<p><b>Fax Numbers</b>: The numbers (separated by commas)\n" +
            "on which faxes should be received for this user. If you enter\n" +
            "<tt>*</tt>, the user gets <b>any</b> call. Leave\n" +
            "this empty for a send-only account.</p>\n"
        ) +
        # Fax dialog help for options 3/6
        _(
          "<p><b>Outgoing MSN</b>: The number to use for outgoing calls. If\nempty, the first number of <b>Fax Numbers</b> is used.</p>\n"
        ) +
        # Fax dialog help for options 4/6
        _(
          "<p><b>StationID</b>: The fax station ID. Set it to the external\nnumber in international format, such as <tt>+49 89 12345</tt>.</p>\n"
        ) +
        # Fax dialog help for options 5/6
        _(
          "<p><b>Headline</b>: The headline used for sending faxes -- normally\na string containing some name.</p>\n"
        ) +
        # Fax dialog help for options 6/6
        _(
          "<p><b>Action</b>: By using the default <tt>MailAndSave</tt>,\n" +
            "received faxes are sent to the user as mail and saved to disk.\n" +
            "To disable the mails, set this to <tt>SaveOnly</tt>.</p>\n"
        )

      max = 0
      items = 0
      table_items = []
      userconf = deep_copy(Fax.aconfig)
      prefix = Ops.get(Fax.gconfig, "dial_prefix", "")

      # make ui items from config map
      item = nil
      Builtins.foreach(userconf) do |k, m|
        item = Item(
          Id(k),
          k,
          Ops.get_string(m, "fax_numbers", ""),
          Ops.get_string(m, "outgoing_MSN", ""),
          Ops.get(@actionmap, Ops.get_string(m, "fax_action", ""), ""),
          Ops.get_string(m, "fax_stationID", ""),
          Ops.get_string(m, "fax_headline", "")
        )
        table_items = Builtins.add(table_items, item)
        items = Ops.add(items, 1)
      end

      Builtins.y2debug("table_items=%1", table_items)
      Builtins.y2debug("items=%1", items)
      Builtins.y2debug("userconf=%1", userconf)
      max = items

      # main dialog contents
      contents = VBox(
        VSpacing(2),
        HBox(
          HSpacing(1), #	    `HSpacing(1)
          VBox(
            VSpacing(1), #		`VStretch()
            #		`VStretch(),
            # Frame title
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
            VSpacing(1)
          )
        ),
        HBox(
          HSpacing(1),
          # TextEntry label
          TextEntry(Id(:prefix), Opt(:shrinkable), _("&Prefix"), prefix),
          HSpacing(10),
          HSpacing(10),
          HSpacing(10),
          HSpacing(10)
        ),
        VSpacing(2)
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
          if !Fax.modified || Popup.ReallyAbort(true)
            break
          else
            next
          end
        # edit user settings
        elsif ret == :edit
          cur = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))

          Builtins.y2debug("cur=%1", cur)

          cur_item = Fax_UserEditDialog(cur, userconf)
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
          cur_item = Fax_UserEditDialog("", userconf)
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
              Ops.get_string(m, "fax_numbers", ""),
              Ops.get_string(m, "outgoing_MSN", ""),
              Ops.get(@actionmap, Ops.get_string(m, "fax_action", ""), ""),
              Ops.get_string(m, "fax_stationID", ""),
              Ops.get_string(m, "fax_headline", "")
            )
            table_items = Builtins.add(table_items, item)
            items = Ops.add(items, 1)
          end
          max = items
          UI.ChangeWidget(Id(:table), :Items, table_items)
          UI.ChangeWidget(Id(:table), :CurrentItem, max)
          Fax.modified = true
        end
      end

      # update settings from widgets
      if ret == :next
        prefix = Convert.to_string(UI.QueryWidget(Id(:prefix), :Value))
        if Ops.get(Fax.gconfig, "dial_prefix", "") != prefix
          Fax.gconfig = Builtins.add(Fax.gconfig, "dial_prefix", prefix)
          Fax.modified = true
        end
        if Fax.aconfig != userconf
          Fax.aconfig = deep_copy(userconf)
          Fax.modified = true
        end
      end
      deep_copy(ret)
    end
    def Fax_UserEditDialog(uname, uconf)
      uconf = deep_copy(uconf)
      uc = Ops.get_map(uconf, uname, {})

      if uc == {}
        # set globals as defaults
        Ops.set(uc, "fax_stationID", Ops.get(Fax.gconfig, "fax_stationID", ""))
        Ops.set(uc, "fax_headline", Ops.get(Fax.gconfig, "fax_headline", ""))
        Ops.set(
          uc,
          "fax_action",
          Ops.get(Fax.gconfig, "fax_action", "MailAndSave")
        )
        Ops.set(uc, "outgoing_MSN", Ops.get(Fax.gconfig, "outgoing_MSN", ""))
      end
      # add at least the user
      if uname != "" && !Builtins.contains(Fax.users, uname)
        Fax.users = Builtins.add(Fax.users, uname)
        Fax.users = Builtins.sort(Fax.users)
      end

      Builtins.y2debug("uc=%1", uc)

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(2),
          VBox(
            # ComboBox label
            ComboBox(
              Id(:user),
              Opt(:editable, :hstretch),
              _("&User"),
              Fax.users
            ),
            VSpacing(0.5),
            # TextEntry label
            TextEntry(
              Id(:phone),
              _("&Fax Numbers"),
              Ops.get_string(uc, "fax_numbers", "")
            ),
            VSpacing(0.5),
            # TextEntry label
            TextEntry(
              Id(:outgoing),
              _("Outgoing &MSN"),
              Ops.get_string(uc, "outgoing_MSN", "")
            ),
            VSpacing(0.5),
            # TextEntry label
            TextEntry(
              Id(:station),
              _("&StationID"),
              Ops.get_string(uc, "fax_stationID", "")
            ),
            VSpacing(0.5),
            # TextEntry label
            TextEntry(
              Id(:headline),
              _("&Headline"),
              Ops.get_string(uc, "fax_headline", "")
            ),
            VSpacing(0.5),
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
            VSpacing(1),
            ButtonBox(
              PushButton(Id(:ok), Opt(:default), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          ),
          HSpacing(2)
        )
      )

      UI.ChangeWidget(Id(:user), :Value, uname) if uname != ""
      UI.ChangeWidget(Id(:phone), :ValidChars, "0123456789#*,")
      UI.ChangeWidget(Id(:station), :ValidChars, "0123456789+ ")
      if Ops.get_string(uc, "fax_action", "") == "MailAndSave"
        UI.ChangeWidget(Id(:action), :Value, :MailAndSave)
      else
        UI.ChangeWidget(Id(:action), :Value, :SaveOnly)
      end

      UI.SetFocus(Id(:user))

      ret = nil
      user = ""
      sval = ""
      oval = ""
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
        oval = Convert.to_string(UI.QueryWidget(Id(:outgoing), :Value))
        if (sval == nil || sval == "") && (oval == nil || oval == "")
          # Popup::Error text
          Popup.Error(_("Fax Numbers and Outgoing MSN must not both be empty"))
          UI.SetFocus(Id(:phone))
          next
        end
        uc = Builtins.add(uc, "fax_numbers", sval) if sval != nil
        uc = Builtins.add(uc, "outgoing_MSN", oval) if oval != nil

        sval = Convert.to_string(UI.QueryWidget(Id(:station), :Value))
        if sval == ""
          # Popup::Error text
          Popup.Error(_("StationID is invalid."))
          UI.SetFocus(Id(:station))
          next
        elsif Ops.less_than(20, Builtins.size(sval))
          # Popup::Error text
          Popup.Error(_("The maximum length for a StationID is twenty."))
          UI.SetFocus(Id(:station))
          next
        end
        uc = Builtins.add(uc, "fax_stationID", sval)

        sval = Convert.to_string(UI.QueryWidget(Id(:headline), :Value))
        # fax_headline "" is OK, default value
        if Ops.less_than(50, Builtins.size(sval))
          # Popup::Error text
          Popup.Error(_("The maximum length for a headline is fifty."))
          UI.SetFocus(Id(:headline))
          next
        end
        uc = Builtins.add(uc, "fax_headline", sval)

        aval = UI.QueryWidget(Id(:action), :Value)
        if aval == nil
          # Popup::Error text
          Popup.Error(_("Action is invalid."))
          UI.SetFocus(Id(:action))
          next
        elsif aval == :MailAndSave
          uc = Builtins.add(uc, "fax_action", "MailAndSave")
        elsif aval == :SaveOnly
          uc = Builtins.add(uc, "fax_action", "SaveOnly")
        end

        break
      end
      Builtins.y2debug("ret=%1", ret)
      UI.CloseDialog
      return nil if ret != :ok
      deep_copy(uc)
    end
  end
end
