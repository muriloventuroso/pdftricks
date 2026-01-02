/*
* Copyright (c) 2018 Murilo Venturoso
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Murilo Venturoso <muriloventuroso@gmail.com>
*/

public class PDFTricks.Application : Gtk.Application {

        public static PDFTricks.MainWindow main_window;

        public const string ACTION_PREFIX = "app.";
        public const string ACTION_QUIT = "quit";

        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_QUIT, quit}
        };

        public Application () {
            Object (application_id: "com.github.muriloventuroso.pdftricks");
        }

        construct {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
            Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Constants.GETTEXT_PACKAGE);
        }

    public override void startup () {
        base.startup ();
        Gtk.init ();
        Granite.init ();

        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", {"<Control>Q"});
        set_accels_for_action ("win.back", {"<Alt>Left", "Back"});

        // Force the eOS icon theme, and set the blueberry as fallback, if for some reason it fails for individual notes
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_icon_theme_name = "elementary";
        gtk_settings.gtk_theme_name = "elementary";

        gtk_settings.gtk_application_prefer_dark_theme = (
	            granite_settings.prefers_color_scheme == DARK
        );
	
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                    granite_settings.prefers_color_scheme == DARK
                );
        });
    }
        public override void activate () {
            if (main_window != null) {
                main_window.present ();
                return;
            }

            main_window = new MainWindow (this);
            main_window.show ();
            main_window.present ();
        }

        private static int main (string[] args) {
            return new Application ().run (args);
        }
}
