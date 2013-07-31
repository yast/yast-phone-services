# encoding: utf-8

# File:	modules/Answering_machine.ycp
# Package:	phone-services
# Summary:     Configuration of a phone answering machine
# Authors:	Karsten Keil <kkeil@suse.de>
#
# $Id$
require "yast"

module Yast
  class Answering_machineClass < Module
    def main
      textdomain "phone-services"

      Yast.import "Package"
      Yast.import "Users"
      Yast.import "UsersCache"

      # All Answering machine configured user data
      @aconfig = {}

      # All Answering machine global settings
      @gconfig = {}

      # Data was modified?
      @modified = false

      # List of available users
      @users = []

      # All configurations read at the start
      @aconfig_init = {}
      @gconfig_init = {}

      # config file location
      @conf_file = "/etc/capisuite/answering_machine.conf"

      # needed packages

      @need_pkgs = ["capisuite"]
    end

    # Read config settings
    # @return true if success
    def Read
      # read config
      cf = Builtins.add(path(".phone-services.section"), @conf_file)
      if Ops.greater_than(SCR.Read(path(".target.size"), @conf_file), 0)
        @aconfig = Builtins.listmap(SCR.Dir(cf)) do |s|
          pp = Builtins.add(
            Builtins.add(path(".phone-services.v"), @conf_file),
            s
          )
          { s => Builtins.listmap(SCR.Dir(pp)) do |vs|
            { vs => SCR.Read(Builtins.add(pp, vs)) }
          end }
        end
      end
      Builtins.y2debug("aconfig=%1", @aconfig)

      @users = []

      @aconfig = Builtins.filter(@aconfig) do |k, v|
        if k == "GLOBAL"
          @gconfig = Convert.convert(
            v,
            :from => "map",
            :to   => "map <string, string>"
          )
          next false
        else
          @users = Builtins.add(@users, k)
          next true
        end
      end

      Builtins.y2debug("aconfig=%1", @aconfig)
      Builtins.y2debug("gconfig=%1", @gconfig)

      # save values to check for changes later
      @gconfig_init = deep_copy(@gconfig)
      @aconfig_init = deep_copy(@aconfig)

      # readin Userdatabase
      Users.SetGUI(false)
      Users.Read
      Users.ReadNewSet("nis") if Users.NISAvailable

      @users = Convert.convert(
        Builtins.merge(
          UsersCache.GetUsernames("local"),
          UsersCache.GetUsernames("nis")
        ),
        :from => "list",
        :to   => "list <string>"
      )
      Users.SetGUI(true)
      Builtins.y2debug("users=%1", @users)

      true
    end

    # Write answering_machine settings and apply changes
    # @return true if success
    def Write
      return true if !@modified
      Builtins.y2milestone("Writing configuration")

      # Check if there is anything to do
      if @aconfig_init == @aconfig && @gconfig_init == @gconfig
        Builtins.y2debug("config not modified")
        return true
      end

      # check for installed packages
      Package.InstallAll(@need_pkgs)

      # build a list of deleted entries
      deleted = []
      Builtins.foreach(@aconfig_init) do |u, m|
        deleted = Builtins.add(deleted, u) if Ops.get(@aconfig, u, {}) == {}
      end
      Builtins.y2debug("deleted %1", deleted)

      # create if not exists, otherwise backup
      if Ops.less_than(SCR.Read(path(".target.size"), @conf_file), 0)
        SCR.Write(path(".target.string"), @conf_file, "")
      else
        SCR.Execute(
          path(".target.bash"),
          Ops.add(
            Ops.add(Ops.add(Ops.add("/bin/cp ", @conf_file), " "), @conf_file),
            ".YaST2save"
          )
        )
      end

      ret = false

      # update the global config
      cf = Builtins.add(path(".phone-services.v"), @conf_file)
      cfs = Builtins.add(cf, "GLOBAL")

      Builtins.foreach(@gconfig) do |k, v|
        p = Builtins.add(cfs, k)
        ret = SCR.Write(p, v)
      end

      # remove deleted user sections
      if deleted != []
        cf = Builtins.add(path(".phone-services.section"), @conf_file)
        Builtins.foreach(deleted) do |d|
          cfs = Builtins.add(cf, d)
          ret = SCR.Write(cfs, nil)
        end
      end

      # update the users config
      cf = Builtins.add(path(".phone-services.v"), @conf_file)
      Builtins.foreach(@aconfig) do |s, m|
        cfs = Builtins.add(cf, s)
        Builtins.foreach(
          Convert.convert(m, :from => "map", :to => "map <string, any>")
        ) do |k, v|
          p = Builtins.add(cfs, k)
          ret = SCR.Write(p, v)
        end
      end

      Builtins.y2debug("write %1 ret %2", cfs, ret)

      # flush it on disc
      SCR.Write(path(".phone-services"), nil)

      @modified = false
      if ret == true
        # start capisuite
        if Ops.greater_than(
            SCR.Read(path(".target.size"), "/etc/init.d/capisuite"),
            0
          )
          SCR.Execute(path(".target.bash"), "/sbin/insserv -d capisuite")
          SCR.Execute(path(".target.bash"), "/etc/init.d/capisuite start")
        end
      end
      ret == true
    end

    publish :variable => :aconfig, :type => "map <string, map>"
    publish :variable => :gconfig, :type => "map <string, string>"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :users, :type => "list"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Answering_machine = Answering_machineClass.new
  Answering_machine.main
end
