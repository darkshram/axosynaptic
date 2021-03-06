/*
 * Copyright (C) 2010 Michal Hruby <michal.mhr@gmail.com>
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
 * Authored by Alberto Aldegheri <albyrock87+dev@gmail.com>
 *
 */

namespace AxoSynaptic
{
  public class ChatActions : Object, Activatable, ActionProvider
  {
    public bool enabled { get; set; default = true; }

    public void activate ()
    {

    }

    public void deactivate ()
    {

    }

    private class OpenChat : Action
    {
      public OpenChat ()
      {
        Object (title: _("Open chat"),
                description: _("Open a chat with selected contact"),
                icon_name: "empathy", has_thumbnail: false,
                default_relevancy: MatchScore.EXCELLENT);
      }

      public override void do_execute (Match match, Match? target = null)
      {
        unowned ContactMatch? cm = match as ContactMatch;
        if ( match == null ) return;
        cm.open_chat ();
      }

      public override bool valid_for_match (Match match)
      {
        return (match is ContactMatch);
      }
    }

    private class SendMessage : Action
    {
      public SendMessage ()
      {
        Object (title: _("Send a message"),
                description: _("Send a message to the contact"),
                icon_name: "message", has_thumbnail: false,
                default_relevancy: MatchScore.VERY_GOOD);
      }

      public override void do_execute (Match match, Match? target = null)
      {
        unowned ContactMatch? cm = match as ContactMatch;
        if ( match == null || target == null ) return;
        cm.send_message (target.title, false);
      }

      public override bool valid_for_match (Match match)
      {
        return (match is ContactMatch);
      }


      public override bool needs_target ()
      {
        return true;
      }

      public override QueryFlags target_flags ()
      {
        return QueryFlags.TEXT;
      }
    }

    private class SendMessageTo : Action
    {
      public SendMessageTo ()
      {
        Object (title: _("Send message to.."),
                description: _("Send a message to a contact"),
                icon_name: "message", has_thumbnail: false,
                default_relevancy: MatchScore.VERY_GOOD);
      }

      public override void do_execute (Match match, Match? target = null)
      {
        if ( match == null || target == null ) return;
        unowned ContactMatch? cm = target as ContactMatch;
        unowned TextMatch? text = match as TextMatch;
        if ( cm == null || text == null ) return;
        cm.send_message (text.get_text (), false);
      }

      public override bool valid_for_match (Match match)
      {
        return (match is TextMatch);
      }

      public override bool needs_target ()
      {
        return true;
      }

      public override QueryFlags target_flags ()
      {
        return QueryFlags.CONTACTS;
      }
    }

    static void register_plugin ()
    {
      PluginRegistry.get_default ().register_plugin (
        typeof (ChatActions),
        _("Chat actions"),
        _("Open chat, or send a message with your favorite IM"),
        "empathy",
        register_plugin
      );
    }

    static construct
    {
      register_plugin ();
    }

    private Gee.List<Action> actions;

    construct
    {
      actions = new Gee.ArrayList<Action> ();

      actions.add (new OpenChat ());
      actions.add (new SendMessage ());
      actions.add (new SendMessageTo ());
    }

    public ResultSet? find_for_match (ref Query query, Match match)
    {
      bool query_empty = query.query_string == "";
      var results = new ResultSet ();

      if (query_empty)
      {
        foreach (var action in actions)
        {
          if (!action.valid_for_match (match)) continue;
          results.add (action, action.default_relevancy);
        }
      }
      else
      {
        var matchers = Query.get_matchers_for_query (query.query_string, 0,
          RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS);
        foreach (var action in actions)
        {
          if (!action.valid_for_match (match)) continue;
          foreach (var matcher in matchers)
          {
            if (matcher.key.match (action.title))
            {
              results.add (action, matcher.value);
              break;
            }
          }
        }
      }

      return results;
    }
  }
}
