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

public class PDFTricks.FileChooserButton : Gtk.Button {

    public signal void selected ();

    private File? _selected;
    public File? selected_file {
        get {
            return _selected;
        }
        set {
            _selected = value;
            label.label = value.get_basename () ?? _("None");
            selected ();
        }
    }

    private Gtk.FileFilter pdf_files_filter;
    public ListStore filter_model;
    private new Gtk.Label label;
    private string open_title;

    public FileChooserButton (string title) {
        open_title = title;

        var box = new Gtk.Box (HORIZONTAL, 3) {
            margin_start = 3,
            margin_end = 3
        };

        label = new Gtk.Label (_("None")) {
            hexpand = true,
            halign = Gtk.Align.START,
            width_request = 32
        };

        box.append (label);
        box.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        box.append (new Gtk.Image.from_icon_name ("folder-open-symbolic"));

        child = box;


        var all_files_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_files_filter.add_pattern ("*");

        pdf_files_filter = new Gtk.FileFilter () {
            name = _("PDF Files"),
        };
        pdf_files_filter.add_mime_type ("application/pdf");

        filter_model = new ListStore (typeof (Gtk.FileFilter));
        filter_model.append (all_files_filter);
        filter_model.append (pdf_files_filter);

        clicked.connect (on_clicked);
    }

    private void on_clicked () {
        var open_dialog = new Gtk.FileDialog () {
            default_filter = pdf_files_filter,
            filters = filter_model,
            title = open_title,
        };

        open_dialog.open.begin (Application.main_window, null, (obj, res) => {
            try {
                selected_file = open_dialog.open.end (res);

            } catch (Error err) {
                warning ("Failed to select file to open: %s", err.message);
            }
        });
    }
}
