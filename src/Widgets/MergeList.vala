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
    public Gtk.Window window { get; construct; }
    public Gtk.TreeView view;
    public Gtk.ListStore list_store;

    private const Format[] SUPPORTED_INPUT = {PDF, PNG, JPG, SVG, BMP};

    public MergeList (Gtk.Window window) {
        Object (window: window);
    }

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

    private int get_page_count (string input_file) {
        string output, stderr = "";
        int exit_status = 0;
        int result = 0;
        var file_name_split = input_file.split (".");
        var input_format = file_name_split[file_name_split.length - 1];
        if (input_format != "pdf") {
            return 1;
        }
        try {
            var cmd = "gs -q -dNODISPLAY -c \"(\"" + input_file + "\") (r) file runpdfbegin pdfpagecount = quit\"";
            Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            result = int.parse (output);
        } catch (Error e) {
            critical (e.message);
        }
        return result;
    }

    private void on_add_files () {
        var all_files_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_files_filter.add_pattern ("*");

        var pdf_files_filter = new Gtk.FileFilter () {
            name = _("PDF Files"),
        };
        pdf_files_filter.add_mime_type ("application/pdf");

        var filter_model = new ListStore (typeof (Gtk.FileFilter));
        filter_model.append (all_files_filter);
        filter_model.append (pdf_files_filter);

        var chooser_file = new Gtk.FileDialog () {
            title = _("Select the file to merge"),
            filters = filter_model
        };

        chooser_file.open_multiple.begin (window, null, (obj, res) => {
            var all_files = chooser_file.open_multiple.end (res);
            for (int i = 0; i < all_files.get_n_items (); i++) {
                var pdf_file = (File)all_files.get_item (i);

                if (Format.from_file (pdf_file) in SUPPORTED_INPUT) {
                    var page_size = get_page_count (pdf_file.get_path ());
                    Gtk.TreeIter iter;
                    list_store.append (out iter);
                    list_store.set (iter, 0, pdf_file, 1, page_size.to_string ());
                }
            }
            });
    }

}
