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

public class PDFTricks.MainWindow : Gtk.ApplicationWindow {

    private Gtk.Revealer navigation_revealer;
    private Gtk.Button navigation_button;

    private Gtk.HeaderBar headerbar;
    private Welcome welcome;
    private CompressPDF compress_pdf;
    private SplitPDF split_pdf;
    private MergePDF merge_pdf;
    private ConvertPDF convert_pdf;
    private Gtk.Stack stack;

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_BACK = "back";
    public const string ACTION_COMPRESS_PDF = "action_compress_pdf";
    public const string ACTION_SPLIT_PDF = "action_split_pdf";
    public const string ACTION_MERGE_PDF = "action_merge_pdf";
    public const string ACTION_CONVERT_PDF = "action_convert_pdf";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_BACK, handle_navigation_button_clicked },
        { ACTION_COMPRESS_PDF, action_compress_pdf },
        { ACTION_SPLIT_PDF, action_split_pdf },
        { ACTION_MERGE_PDF, action_merge_pdf },
        { ACTION_CONVERT_PDF, action_convert_pdf }
    };

    public MainWindow (Application application) {
        Object (application: application);
    }

    construct {
        Intl.setlocale ();
        title = _("PDFTricks");
        icon_name = "com.github.muriloventuroso.pdftricks";

        var actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group ("win", actions);

        navigation_button = new Gtk.Button.with_label (_("Back")) {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_BACK
        };
        navigation_button.add_css_class ("back-button");

        navigation_revealer = new Gtk.Revealer () {
            child = navigation_button,
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };

        var title_widget = new Gtk.Label (_("PDFTricks"));
        title_widget.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        headerbar = new Gtk.HeaderBar () {
            title_widget = title_widget
        };
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        headerbar.pack_start (navigation_revealer);
        titlebar = headerbar;

        welcome = new Welcome ();
        compress_pdf = new CompressPDF (this);
        split_pdf = new SplitPDF (this);
        merge_pdf = new MergePDF (this);
        convert_pdf = new ConvertPDF (this);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (welcome, "welcome");
        stack.add_named (compress_pdf, "compress_pdf");
        stack.add_named (split_pdf, "split_pdf");
        stack.add_named (merge_pdf, "merge_pdf");
        stack.add_named (convert_pdf, "convert_pdf");

        var handle = new Gtk.WindowHandle () {
            child = stack
        };

        child = handle;
    }

    public void handle_navigation_button_clicked () {
        stack.visible_child = welcome;
        navigation_revealer.reveal_child = false;
    }

    public void action_compress_pdf () {
        stack.visible_child = compress_pdf;
        navigation_revealer.reveal_child = true;
    }

    public void action_split_pdf () {
        stack.visible_child = split_pdf;
        navigation_revealer.reveal_child = true;
    }

    public void action_merge_pdf () {
        stack.visible_child = merge_pdf;
        navigation_revealer.reveal_child = true;
    }

    public void action_convert_pdf () {
        stack.visible_child = convert_pdf;
        navigation_revealer.reveal_child = true;
    }
}
