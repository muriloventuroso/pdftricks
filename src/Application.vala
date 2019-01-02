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

namespace pdftricks {

    public class Application : Granite.Application {

        private Gtk.Window main_window;
        private Gtk.Button navigation_button;
        private Gtk.HeaderBar headerbar;
        private Welcome welcome;
        private CompressPDF compress_pdf;
        private SplitPDF split_pdf;
        private MergePDF merge_pdf;
        private Gtk.Stack stack;

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_COMPRESS_PDF = "action_compress_pdf";
        public const string ACTION_SPLIT_PDF = "action_split_pdf";
        public const string ACTION_MERGE_PDF = "action_merge_pdf";

        public SimpleActionGroup actions;
        public Gtk.ActionGroup main_actions;

        private const ActionEntry[] action_entries = {
            { ACTION_COMPRESS_PDF, action_compress_pdf },
            { ACTION_SPLIT_PDF, action_split_pdf },
            { ACTION_MERGE_PDF, action_merge_pdf }
        };

        public Application () {
            Object (application_id: "com.github.muriloventuroso.pdftricks",
            flags: ApplicationFlags.FLAGS_NONE);
        }

        construct {
            Intl.setlocale (LocaleCategory.ALL, "");
        }

        public override void activate () {
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }
            //patch for forcing elementary os theme and icons
            Gtk.Settings.get_default().set_property("gtk-theme-name", "elementary");
            Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");
            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            main_window = new Gtk.Window();
            navigation_button = new Gtk.Button ();
            navigation_button.action_name = "app.back";
            navigation_button.get_style_context ().add_class ("back-button");
            navigation_button.label = _("Back");

            headerbar = new Gtk.HeaderBar ();
            headerbar.has_subtitle = false;
            headerbar.show_close_button = true;
            headerbar.title = _("PDF Tricks");
            headerbar.pack_start (navigation_button);

            welcome = new Welcome();
            compress_pdf = new CompressPDF(main_window);
            split_pdf = new SplitPDF(main_window);
            merge_pdf = new MergePDF(main_window);
            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_named (welcome, "main");
            stack.add_named (compress_pdf, "compress_pdf");
            stack.add_named (split_pdf, "split_pdf");
            stack.add_named (merge_pdf, "merge_pdf");

            main_window.application = this;
            main_window.icon_name = "pdftricks";
            main_window.title = _("PDF Tricks");
            main_window.add (stack);
            main_window.set_size_request (910, 640);
            main_window.set_titlebar (headerbar);
            main_window.insert_action_group ("win", actions);
            main_window.show_all();
            navigation_button.hide();

            add_window (main_window);

            var quit_action = new SimpleAction ("quit", null);
            var back_action = new SimpleAction ("back", null);

            add_action (back_action);

            add_action (quit_action);

            quit_action.activate.connect (() => {
                if (main_window != null) {
                    main_window.destroy ();
                }
            });

            back_action.activate.connect (() => {
                handle_navigation_button_clicked ();
            });

            set_accels_for_action ("app.back", {"<Alt>Left", "Back"});
        }

        private void handle_navigation_button_clicked () {
            navigation_button.hide();
            stack.set_visible_child_name ("main");
        }

        private void action_compress_pdf() {
            stack.set_visible_child_name ("compress_pdf");
            navigation_button.show();
        }

        private void action_split_pdf() {
            stack.set_visible_child_name ("split_pdf");
            navigation_button.show();
        }

        private void action_merge_pdf() {
            stack.set_visible_child_name ("merge_pdf");
            navigation_button.show();
        }

        private static int main (string[] args) {
            Gtk.init (ref args);

            var app = new Application ();
            return app.run (args);
        }
    }
}