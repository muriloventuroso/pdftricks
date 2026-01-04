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

public class PDFTricks.MergeList : Granite.Bin {

    public Gtk.TreeView view;
    public Gtk.ListStore list_store;

    construct {
        list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        Gtk.TreeIter iter;

        // The View:
        view = new Gtk.TreeView.with_model (list_store) {
            hexpand = true,
            vexpand = true
        };

        Gtk.CellRendererText cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Files"), cell, "text", 0);
        view.insert_column_with_attributes (-1, _("Pages"), cell, "text", 1);

        var scroll = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true
        };
        scroll.child = view;

        child = scroll;
    }
}
