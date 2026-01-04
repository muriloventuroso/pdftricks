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

public class PDFTricks.PageTemplate : Gtk.Box {
    public Gtk.Window window { get; construct; }
    private Granite.HeaderLabel headerlabel;
    public Gtk.Grid grid;

    public signal void process_begin ();
    public signal void process_finished (bool result);

    public string title {get; construct;}


    public Gee.ArrayList<Gtk.Widget> freeze_list;

    public PageTemplate (Gtk.Window window, string title) {
        Object (
            window: window,
            title: title
        );
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 0;
        freeze_list = new Gee.ArrayList<Gtk.Widget> ();

        headerlabel = new Granite.HeaderLabel (title) {
            margin_top = 24,
            margin_bottom = 12,
            valign = Gtk.Align.START,
            halign = Gtk.Align.CENTER,
        };
        headerlabel.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            column_spacing = 32,
            row_spacing = 20,
            column_homogeneous = true,
            hexpand = true,
            vexpand = true,
        };

        //append (headerlabel);
        append (grid);

        process_begin.connect (() => {freeze_widgets (true);});
        process_finished.connect (on_result);
    }

    public void freeze_widgets (bool if_freeze) {
        foreach (var widget in freeze_list) {
            widget.sensitive = !if_freeze;
        }
    }

    private void on_result () {
        freeze_widgets (false);
        //  if (result == 0) {
        //      var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("File split."), "process-completed", Gtk.ButtonsType.CLOSE);
        //      message_dialog.set_transient_for (window);
        //      message_dialog.show ();

        //  } else {
        //      var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("Could not split this file."), "process-stop", Gtk.ButtonsType.CLOSE);
        //      message_dialog.set_transient_for (window);
        //      message_dialog.show ();

        //  };
    }
}
