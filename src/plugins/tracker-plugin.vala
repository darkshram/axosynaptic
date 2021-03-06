/*
 * Copyright (C) 2017 Joel Barrios <darkshram@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Authored by Joel Barrios <darkshram@gmail.com>
 *
 */

namespace AxoSynaptic
{
  public class TrackerPlugin : Object, Activatable, ActionProvider
  {
    public bool enabled { get; set; default = false; }

    public void activate ()
    {

    }

    public void deactivate ()
    {

    }

    private class TrackerItem : SearchMatch
    {
      public int default_relevancy { get; set; default = MatchScore.INCREMENT_SMALL; }

      // for SearchMatch interface
      public override async Gee.List<Match> search (string query,
                                           QueryFlags flags,
                                           ResultSet? dest_result_set,
                                           Cancellable? cancellable = null) throws SearchError
      {
        var q = Query (0, query, flags);
        q.cancellable = cancellable;
        ResultSet? results = yield plugin.tracker (q);
        dest_result_set.add_all (results);

        return dest_result_set.get_sorted_list ();
      }

      private unowned TrackerPlugin plugin;

      public TrackerItem (TrackerPlugin plugin)
      {
        Object (has_thumbnail: false,
                icon_name: "search",
                title: _("Tracker"),
                description: _("Search files with this name on the filesystem"));
        this.plugin = plugin;
      }
    }

    static void register_plugin ()
    {
      PluginRegistry.get_default ().register_plugin (
        typeof (TrackerPlugin),
        _("Tracker"),
        _("Runs tracker command to find files on the filesystem."),
        "search",
        register_plugin,
        Environment.find_program_in_path ("tracker") != null,
        _("Unable to find \"tracker\" binary")
      );
    }

    static construct
    {
      register_plugin ();
    }

    TrackerItem action;

    construct
    {
      action = new TrackerItem (this);
    }

    public bool handles_unknown ()
    {
      return true;
    }

    public async ResultSet? tracker (Query q) throws SearchError
    {
      var our_results = QueryFlags.AUDIO | QueryFlags.DOCUMENTS
        | QueryFlags.IMAGES | QueryFlags.UNCATEGORIZED | QueryFlags.VIDEO;

      var common_flags = q.query_type & our_results;
      // strip query
      q.query_string = q.query_string.strip ();
      // ignore short searches
      if (common_flags == 0 || q.query_string.char_count () <= 1) return null;

      q.check_cancellable ();

      q.max_results = 20;
      string regex = Regex.escape_string (q.query_string);
      // FIXME: split pattern into words and search using --regexp?
      string[] argv = {"tracker", "search", "-f", "--disable-snippets", 
                       "--disable-color", "-l", "%u".printf (q.max_results),
                       "%s".printf (regex.replace ("  file:/", ""))};

      Gee.Set<string> uris = new Gee.HashSet<string> ();

      try
      {
        Pid pid;
        int read_fd;

        // FIXME: fork on every letter... yey!
        Process.spawn_async_with_pipes (null, argv, null,
                                        SpawnFlags.SEARCH_PATH,
                                        null, out pid, null, out read_fd);

        UnixInputStream read_stream = new UnixInputStream (read_fd, true);
        DataInputStream tracker_output = new DataInputStream (read_stream);
        string? line = null;

        Regex filter_re = new Regex ("/\\."); // hidden file/directory
        do
        {
          line = yield tracker_output.read_line_async (Priority.DEFAULT_IDLE, q.cancellable);
          if (line != null)
          {
            if (filter_re.match (line)) continue;
            var file = File.new_for_path (line);
            uris.add (file.get_uri ());
          }
        } while (line != null);
      }
      catch (Error err)
      {
        if (!q.is_cancelled ()) warning ("%s", err.message);
      }

      q.check_cancellable ();

      var result = new ResultSet ();

      foreach (string s in uris)
      {
        var fi = new Utils.FileInfo (s, typeof (UriMatch));
        yield fi.initialize ();
        if (fi.match_obj != null && fi.file_type in q.query_type)
        {
          int relevancy = MatchScore.INCREMENT_SMALL; // FIXME: relevancy
          if (fi.uri.has_prefix ("file:///home/")) relevancy += MatchScore.INCREMENT_MINOR;
          result.add (fi.match_obj, relevancy);
        }
        q.check_cancellable ();
      }

      return result;
    }

    public ResultSet? find_for_match (ref Query q, Match match)
    {
      var our_results = QueryFlags.AUDIO | QueryFlags.DOCUMENTS
        | QueryFlags.IMAGES | QueryFlags.UNCATEGORIZED | QueryFlags.VIDEO;

      var common_flags = q.query_type & our_results;
      // ignore short searches
      if (common_flags == 0 || !(match is UnknownMatch)) return null;

      // strip query
      q.query_string = q.query_string.strip ();
      bool query_empty = q.query_string == "";
      var results = new ResultSet ();

      if (query_empty)
      {
        results.add (action, action.default_relevancy);
      }
      else
      {
        var matchers = Query.get_matchers_for_query (q.query_string, 0,
          RegexCompileFlags.CASELESS);
        foreach (var matcher in matchers)
        {
          if (matcher.key.match (action.title))
          {
            results.add (action, matcher.value);
            break;
          }
        }
      }

      return results;
    }
  }
}
