/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Michal Hruby <michal.mhr@gmail.com>
 *             Alberto Aldegheri <albyrock87+dev@gmail.com>
 *
 */

namespace AxoSynaptic
{
  errordomain DesktopFileError
  {
    UNINTERESTING_ENTRY
  }

  // registered environments from http://standards.freedesktop.org/menu-spec/latest
  [Flags]
  public enum DesktopEnvironmentType
  {
    GNOME = 1 << 0,
    KDE   = 1 << 1,
    LXDE  = 1 << 2,
    MATE  = 1 << 3,
    RAZOR = 1 << 4,
    ROX   = 1 << 5,
    TDE   = 1 << 6,
    UNITY = 1 << 7,
    XFCE  = 1 << 8,
    EDE   = 1 << 9,
    CINNAMON = 1 << 10,
    PANTHEON = 1 << 11,

    OLD   = 1 << 12,
    ALL   = 0xFFF;

    public static DesktopEnvironmentType from_strings (string[] environments)
    {
      DesktopEnvironmentType result = 0;
      foreach (unowned string env in environments)
      {
        string env_up = env.up ();
        switch (env_up)
        {
          case "GNOME": result |= DesktopEnvironmentType.GNOME; break;
          case "KDE": result |= DesktopEnvironmentType.KDE; break;
          case "LXDE": result |= DesktopEnvironmentType.LXDE; break;
          case "MATE": result |= DesktopEnvironmentType.MATE; break;
          case "RAZOR": result |= DesktopEnvironmentType.RAZOR; break;
          case "ROX": result |= DesktopEnvironmentType.ROX; break;
          case "TDE": result |= DesktopEnvironmentType.TDE; break;
          case "UNITY": result |= DesktopEnvironmentType.UNITY; break;
          case "XFCE": result |= DesktopEnvironmentType.XFCE; break;
          case "EDE": result |= DesktopEnvironmentType.EDE; break;
          case "CINNAMON": result |= DesktopEnvironmentType.CINNAMON; break;
          case "OLD": result |= DesktopEnvironmentType.OLD; break;

          case "PANTHEON": result |= DesktopEnvironmentType.PANTHEON; break;

          default: warning ("%s is not understood", env); break;
        }
      }
      return result;
    }
  }

  public class DesktopFileInfo : Object
  {
    public string desktop_id { get; construct set; }
    public string name { get; construct set; }
    public string comment { get; set; default = ""; }
    public string icon_name { get; construct set; default = ""; }

    public bool needs_terminal { get; set; default = false; }
    public string filename { get; construct set; }

    public string exec { get; set; }

    public bool is_hidden { get; private set; default = false; }
    public bool is_valid { get; private set; default = true; }

    public string[] actions = null;
    public string[] mime_types = null;

    private string? name_folded = null;
    public unowned string get_name_folded ()
    {
      if (name_folded == null) name_folded = name.casefold ();
      return name_folded;
    }

    public DesktopEnvironmentType show_in { get; set; default = DesktopEnvironmentType.ALL; }

    public DesktopFileInfo.for_keyfile (string path, KeyFile keyfile,
                                        string desktop_id)
    {
      Object (filename: path, desktop_id: desktop_id);

      init_from_keyfile (keyfile);
    }

    private void init_from_keyfile (KeyFile keyfile)
    {
      try
      {
        if (keyfile.get_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE) != KeyFileDesktop.TYPE_APPLICATION)
        {
          throw new DesktopFileError.UNINTERESTING_ENTRY ("Not Application-type desktop entry");
        }

        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES))
        {
          string[] categories = keyfile.get_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_CATEGORIES);
          if ("Screensaver" in categories)
          {
            throw new DesktopFileError.UNINTERESTING_ENTRY ("Screensaver desktop entry");
          }
        }

        DesktopAppInfo app_info;
        app_info = new DesktopAppInfo.from_keyfile (keyfile);

        if (app_info == null)
        {
          throw new DesktopFileError.UNINTERESTING_ENTRY ("Unable to create AppInfo for %s".printf (filename));
        }

        name = app_info.get_name ();
        exec = app_info.get_commandline ();
        if (exec == null)
        {
          throw new DesktopFileError.UNINTERESTING_ENTRY ("Unable to get exec for %s".printf (name));
        }

        // check for hidden desktop files
        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_HIDDEN) &&
          keyfile.get_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_HIDDEN))
        {
          is_hidden = true;
        }
        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NO_DISPLAY) &&
          keyfile.get_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NO_DISPLAY))
        {
          is_hidden = true;
        }

        comment = app_info.get_description () ?? "";

        var icon = app_info.get_icon () ?? new ThemedIcon ("application-default-icon");
        icon_name = icon.to_string ();

        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE))
        {
          mime_types = keyfile.get_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_MIME_TYPE);
        }
        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TERMINAL))
        {
          needs_terminal = keyfile.get_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TERMINAL);
        }
        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ONLY_SHOW_IN))
        {
          show_in = DesktopEnvironmentType.from_strings (keyfile.get_string_list (KeyFileDesktop.GROUP,
                                                                 KeyFileDesktop.KEY_ONLY_SHOW_IN));
        }
        else if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NOT_SHOW_IN))
        {
          var not_show = DesktopEnvironmentType.from_strings (keyfile.get_string_list (KeyFileDesktop.GROUP,
                                             KeyFileDesktop.KEY_NOT_SHOW_IN));
          show_in = DesktopEnvironmentType.ALL ^ not_show;
        }
        if (keyfile.has_key (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ACTIONS))
          actions = keyfile.get_string_list (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ACTIONS);

        // special case these, people are using them quite often and wonder
        // why they don't appear
        if (filename.has_suffix ("gconf-editor.desktop") ||
            filename.has_suffix ("dconf-editor.desktop"))
        {
          is_hidden = false;
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
        is_valid = false;
      }
    }
  }

  public class DesktopFileService : Object
  {
    private static unowned DesktopFileService? instance;
    private Utils.AsyncOnce<bool> init_once;

    // singleton that can be easily destroyed
    public static DesktopFileService get_default ()
    {
      return instance ?? new DesktopFileService ();
    }

    private DesktopFileService ()
    {
    }

    private Gee.List<FileMonitor> directory_monitors;
    private Gee.List<DesktopFileInfo> all_desktop_files;
    private Gee.List<DesktopFileInfo> non_hidden_desktop_files;
    private Gee.Map<unowned string, Gee.List<DesktopFileInfo>> mimetype_map;
    private Gee.Map<string, Gee.List<DesktopFileInfo>> exec_map;
    private Gee.Map<string, DesktopFileInfo> desktop_id_map;
    private Gee.MultiMap<string, string> mimetype_parent_map;

    construct
    {
      instance = this;

      directory_monitors = new Gee.ArrayList<FileMonitor> ();
      all_desktop_files = new Gee.ArrayList<DesktopFileInfo> ();
      non_hidden_desktop_files = new Gee.ArrayList<DesktopFileInfo> ();
      mimetype_parent_map = new Gee.HashMultiMap<string, string> ();
      init_once = new Utils.AsyncOnce<bool> ();

      initialize.begin ();
    }

    ~DesktopFileService ()
    {
      instance = null;
    }

    public async void initialize ()
    {
      if (init_once.is_initialized ()) return;
      var is_locked = yield init_once.enter ();
      if (!is_locked) return;

      get_environment_type ();
      DesktopAppInfo.set_desktop_env (session_type_str);

      Idle.add_full (Priority.LOW, initialize.callback);
      yield;

      yield load_all_desktop_files ();

      init_once.leave (true);
    }

    private DesktopEnvironmentType session_type = DesktopEnvironmentType.GNOME;
    private unowned string session_type_str = "GNOME";

    public DesktopEnvironmentType get_environment ()
    {
      return this.session_type;
    }

    private void get_environment_type ()
    {
      unowned string? session_var;
      session_var = Environment.get_variable ("XDG_CURRENT_DESKTOP");
      if (session_var == null)
      {
        session_var = Environment.get_variable ("DESKTOP_SESSION");
      }

      if (session_var == null) return;

      string session = session_var.down ();

      if (session.has_prefix ("unity") || session.has_prefix ("ubuntu"))
      {
        session_type = DesktopEnvironmentType.UNITY;
        session_type_str = "Unity";
      }
      else if (session.has_prefix ("kde"))
      {
        session_type = DesktopEnvironmentType.KDE;
        session_type_str = "KDE";
      }
      else if (session.has_prefix ("gnome"))
      {
        session_type = DesktopEnvironmentType.GNOME;
        session_type_str = "GNOME";
      }
      else if (session.has_prefix ("lx"))
      {
        session_type = DesktopEnvironmentType.LXDE;
        session_type_str = "LXDE";
      }
      else if (session.has_prefix ("xfce"))
      {
        session_type = DesktopEnvironmentType.XFCE;
        session_type_str = "XFCE";
      }
      else if (session.has_prefix ("mate"))
      {
        session_type = DesktopEnvironmentType.MATE;
        session_type_str = "MATE";
      }
      else if (session.has_prefix ("razor"))
      {
        session_type = DesktopEnvironmentType.RAZOR;
        session_type_str = "Razor";
      }
      else if (session.has_prefix ("tde"))
      {
        session_type = DesktopEnvironmentType.TDE;
        session_type_str = "TDE";
      }
      else if (session.has_prefix ("rox"))
      {
        session_type = DesktopEnvironmentType.ROX;
        session_type_str = "ROX";
      }
      else if (session.has_prefix ("ede"))
      {
        session_type = DesktopEnvironmentType.EDE;
        session_type_str = "EDE";
      }
      else if (session.has_prefix ("cinnamon"))
      {
        session_type = DesktopEnvironmentType.CINNAMON;
        session_type_str = "Cinnamon";
      }
      else if (session.has_prefix ("pantheon"))
      {
        session_type = DesktopEnvironmentType.PANTHEON;
        session_type_str = "Pantheon";
      }
      else
      {
        warning ("Desktop session type is not recognized, assuming GNOME.");
      }
    }

    private string? get_cache_file_name (string dir_name)
    {
      // FIXME: should we use this? it's Ubuntu-specific
      unowned string? locale = Intl.setlocale (LocaleCategory.MESSAGES, null);
      if (locale == null) return null;

      // even though this is what the patch in gnome-menus does, the name
      // of the file is different here (utf is uppercase)
      string filename = "desktop.%s.cache".printf (
        locale.replace (".UTF-8", ".utf8"));

      return Path.build_filename (dir_name, filename, null);
    }

    private async void process_directory (File directory,
                                          string id_prefix,
                                          Gee.Set<File> monitored_dirs)
    {
      try
      {
        string path = directory.get_path ();
        // we need to skip menu-xdg directory, see lp:686624
        if (path != null && path.has_suffix ("menu-xdg")) return;
        // screensavers don't interest us, skip those
        if (path != null && path.has_suffix ("/screensavers")) return;

        debug ("Searching for desktop files in: %s", path);
        bool exists = yield Utils.query_exists_async (directory);
        if (!exists) return;
        /* Check if we already scanned this directory // lp:686624 */
        foreach (var scanned_dir in monitored_dirs)
        {
          if (path == scanned_dir.get_path ()) return;
        }
        monitored_dirs.add (directory);
        var enumerator = yield directory.enumerate_children_async (
          FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
          0, 0);
        var files = yield enumerator.next_files_async (1024, 0);
        foreach (var f in files)
        {
          unowned string name = f.get_name ();
          if (f.get_file_type () == FileType.DIRECTORY)
          {
            // FIXME: this could cause too many open files error, or?
            var subdir = directory.get_child (name);
            var new_prefix = "%s%s-".printf (id_prefix, subdir.get_basename ());
            yield process_directory (subdir, new_prefix, monitored_dirs);
          }
          else
          {
            // ignore ourselves
            if (name.has_suffix ("org.mate.axosynaptic.desktop")) continue;
            if (name.has_suffix (".desktop"))
            {
              yield load_desktop_file (directory.get_child (name), id_prefix);
            }
          }
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
      }
    }

    private async void load_all_desktop_files ()
    {
      string[] data_dirs = Environment.get_system_data_dirs ();
      data_dirs += Environment.get_user_data_dir ();

      Gee.Set<File> desktop_file_dirs = new Gee.HashSet<File> ();

      mimetype_parent_map.clear ();

      foreach (unowned string data_dir in data_dirs)
      {
        string dir_path = Path.build_filename (data_dir, "applications", null);
        var directory = File.new_for_path (dir_path);
        yield process_directory (directory, "", desktop_file_dirs);
        dir_path = Path.build_filename (data_dir, "mime", "subclasses");
        yield load_mime_parents_from_file (dir_path);
      }

      create_indices ();

      directory_monitors = new Gee.ArrayList<FileMonitor> ();
      foreach (File d in desktop_file_dirs)
      {
        try
        {
          FileMonitor monitor = d.monitor_directory (0, null);
          monitor.changed.connect (this.desktop_file_directory_changed);
          directory_monitors.add (monitor);
        }
        catch (Error err)
        {
          warning ("Unable to monitor directory: %s", err.message);
        }
      }
    }

    private uint timer_id = 0;

    public signal void reload_started ();
    public signal void reload_done ();

    private void desktop_file_directory_changed ()
    {
      reload_started ();
      if (timer_id != 0)
      {
        Source.remove (timer_id);
      }

      timer_id = Timeout.add (5000, () => {
        timer_id = 0;
        reload_desktop_files.begin ();
        return false;
      });
    }

    private async void reload_desktop_files ()
    {
      debug ("Reloading desktop files...");
      all_desktop_files.clear ();
      non_hidden_desktop_files.clear ();
      yield load_all_desktop_files ();

      reload_done ();
    }

    private async void load_desktop_file (File file, string id_prefix)
    {
      try
      {
        uint8[] file_contents;
        bool success = yield file.load_contents_async (null, out file_contents,
                                                       null);
        if (success)
        {
          var keyfile = new KeyFile ();
          keyfile.load_from_data ((string) file_contents,
                                  file_contents.length, 0);

          var desktop_id = "%s%s".printf (id_prefix, file.get_basename ());
          var dfi = new DesktopFileInfo.for_keyfile (file.get_path (),
                                                     keyfile,
                                                     desktop_id);
          if (dfi.is_valid)
          {
            all_desktop_files.add (dfi);
            if (!dfi.is_hidden && session_type in dfi.show_in)
            {
              non_hidden_desktop_files.add (dfi);
            }
          }
        }
      }
      catch (Error err)
      {
        warning ("%s", err.message);
      }
    }

    private void create_indices ()
    {
      // create mimetype maps
      mimetype_map =
        new Gee.HashMap<unowned string, Gee.List<DesktopFileInfo>> ();
      // and exec map
      exec_map =
        new Gee.HashMap<string, Gee.List<DesktopFileInfo>> ();
      // and desktop id map
      desktop_id_map =
        new Gee.HashMap<string, DesktopFileInfo> ();

      Regex exec_re;
      try
      {
        exec_re = new Regex ("%[fFuU]");
      }
      catch (Error err)
      {
        critical ("%s", err.message);
        return;
      }

      foreach (var dfi in all_desktop_files)
      {
        string exec = "";
        try
        {
          exec = exec_re.replace_literal (dfi.exec, -1, 0, "");
        }
        catch (RegexError err)
        {
          critical ("%s", err.message);
        }
        exec = exec.strip ();
        // update exec map
        Gee.List<DesktopFileInfo>? exec_list = exec_map[exec];
        if (exec_list == null)
        {
          exec_list = new Gee.ArrayList<DesktopFileInfo> ();
          exec_map[exec] = exec_list;
        }
        exec_list.add (dfi);

        // update desktop id map
        var desktop_id = dfi.desktop_id ?? Path.get_basename (dfi.filename);
        desktop_id_map[desktop_id] = dfi;

        // update mimetype map
        if (dfi.is_hidden || dfi.mime_types == null) continue;

        foreach (unowned string mime_type in dfi.mime_types)
        {
          Gee.List<DesktopFileInfo>? list = mimetype_map[mime_type];
          if (list == null)
          {
            list = new Gee.ArrayList<DesktopFileInfo> ();
            mimetype_map[mime_type] = list;
          }
          list.add (dfi);
        }
      }
    }

    private async void load_mime_parents_from_file (string fi)
    {
      var file = File.new_for_path (fi);
      bool exists = yield Utils.query_exists_async (file);
      if (!exists) return;
      try
      {
        var fis = yield file.read_async (GLib.Priority.DEFAULT);
        var dis = new DataInputStream (fis);
        string line = null;
        string[] mimes = null;
        int len = 0;
        // Read lines until end of file (null) is reached
        do {
          line = yield dis.read_line_async (GLib.Priority.DEFAULT);
          if (line == null) break;
          if (line.has_prefix ("#")) continue; //comment line
          mimes = line.split (" ");
          len = (int)GLib.strv_length (mimes);
          if (len != 2) continue;
          // cannot be parent of myself!
          if (mimes[0] == mimes[1]) continue;
          //debug ("Map %s -> %s", mimes[0], mimes[1]);
          mimetype_parent_map.set (mimes[0], mimes[1]);
        } while (true);
      } catch (GLib.Error err) { /* can't read file */ }
    }

    private void add_dfi_for_mime (string mime, Gee.Set<DesktopFileInfo> ret)
    {
      var dfis = mimetype_map[mime];
      if (dfis != null) ret.add_all (dfis);

      var parents = mimetype_parent_map[mime];
      if (parents == null) return;
      foreach (string parent in parents)
        add_dfi_for_mime (parent, ret);
    }

    // retuns desktop files available on the system (without hidden ones)
    public Gee.List<DesktopFileInfo> get_desktop_files ()
    {
      return non_hidden_desktop_files.read_only_view;
    }

    // returns all desktop files available on the system (even the ones which
    // are hidden by default)
    public Gee.List<DesktopFileInfo> get_all_desktop_files ()
    {
      return all_desktop_files.read_only_view;
    }

    public Gee.List<DesktopFileInfo> get_desktop_files_for_type (string mime_type)
    {
      var dfi_set = new Gee.HashSet<DesktopFileInfo> ();
      add_dfi_for_mime (mime_type, dfi_set);
      var ret = new Gee.ArrayList<DesktopFileInfo> ();
      ret.add_all (dfi_set);
      return ret;
    }

    public Gee.List<DesktopFileInfo> get_desktop_files_for_exec (string exec)
    {
      return exec_map[exec] ?? new Gee.ArrayList<DesktopFileInfo> ();
    }

    public DesktopFileInfo? get_desktop_file_for_id (string desktop_id)
    {
      return desktop_id_map[desktop_id];
    }
  }
}

