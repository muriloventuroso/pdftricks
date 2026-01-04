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

public class PDFTricks.MergePDF : PDFTricks.PageTemplate {

    private Gtk.TreeView view;
    private Gtk.ListStore list_store;
    //  private const Gtk.TargetEntry[] TARGETS = {
    //      {"STRING", 0, 0}
    //  };

    private const Format[] SUPPORTED_INPUT = {PDF, PNG, JPG, SVG, BMP};

    private Gtk.FileDialog chooser_file;

    public MergePDF (Gtk.Window window) {
        Object (window: window,
                title: _("Merge PDF"));
    }
    construct {

        // The Model:
        var add_button = new Gtk.Button.with_label (_("Add File"));
        var del_button = new Gtk.Button.with_label (_("Remove Selected"));
        var clear_button = new Gtk.Button.with_label (_("Clear All"));

        list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        Gtk.TreeIter iter;
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_mime_type ("application/pdf");
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/bmp");
        filter.add_mime_type ("image/svg+xml");

        // The View:
        view = new Gtk.TreeView.with_model (list_store) {
            hexpand = true,
            vexpand = true
        };

        add_button.clicked.connect (on_add_files);

        del_button.clicked.connect (() => {
            Gtk.TreeModel model;
            var selection = view.get_selection ();
            foreach (Gtk.TreePath path in selection.get_selected_rows (out model)) {
                Gtk.TreeIter r_iter;
                model.get_iter (out r_iter, path);
                list_store.remove (ref r_iter);
            }
        });

        clear_button.clicked.connect (() => {
            list_store.clear ();
        });


        Gtk.CellRendererText cell = new Gtk.CellRendererText ();
        view.insert_column_with_attributes (-1, _("Files"), cell, "text", 0);
        view.insert_column_with_attributes (-1, _("Pages"), cell, "text", 1);



        var merge_button = new Gtk.Button.with_label (_("Merge"));
        merge_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        merge_button.vexpand = true;
        merge_button.clicked.connect (confirm_merge);

        var scroll = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true
        };
        scroll.child = view;

        grid.attach (add_button, 1, 0);
        grid.attach (del_button, 2, 0);
        grid.attach (clear_button, 3, 0);
        grid.attach (scroll, 0, 1, 5, 6);
        grid.attach (merge_button, 1, 7, 3);

        process_begin.connect (
            () => {
                merge_button.set_sensitive (false);
            });

        process_finished.connect (
            (result) => {
                merge_button.set_sensitive (true);
                if (result) {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully merged."), "process-completed", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                    message_dialog.destroy ();
                } else {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem merging your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                    message_dialog.destroy ();
                };
            });
    }

    private void on_add_files () {
        chooser_file = new Gtk.FileDialog () {
            title = _("Select the file to compress")
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

    private void confirm_merge () {
        var merge = false;
        var files_pdf = "";
        list_store.foreach ((model, path, iter) => {
            GLib.Value cell1;

            list_store.get_value (iter, 0, out cell1);
            var file_pdf = (string) cell1;
            if (!file_pdf.contains (".pdf")) {
                file_pdf = convert_to_pdf (file_pdf);
                if (file_pdf == "") {
                    files_pdf = "";
                    return true;
                }
            }
            files_pdf = files_pdf + " " + file_pdf.replace (" ", "\\ ").replace ("'", "\\'");
            return false;
        });
        if (files_pdf == "") {
            return;
        }

        var chooser_output = new Gtk.FileDialog () {
            title = _("Select the file to save to")
        };

        chooser_output.save.begin (window, null, (obj, res) => {
            try {

                var output_file = chooser_output.save.end (res);

                if (output_file != null) {
                    process_begin ();

                    merge_file.begin (files_pdf, output_file.get_path (),
                        (obj, res) => {
                            process_finished (merge_file.end (res));
                        });
                }

            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    private string convert_to_pdf (string input_file) {
        string output, stderr, cmd, result_file = "";
        int exit_status = 0;
        result_file = "/tmp/c_" + GLib.Uuid.string_random () + ".pdf";
        cmd = "convert \"" + input_file + "\" \"" + result_file + "\"";
        try {
            Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
        } catch (Error e) {
            critical (e.message);
            return "";
        }
        if (output != "" || exit_status != 0 || stderr != "") {
            if (output.contains ("Error")) {
                return "";
            }
            if (stderr.contains ("not allowed")) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("ImageMagick Policies"), _("Change the ImageMagick security policies that prevent this operation and try again."), "process-stop", Gtk.ButtonsType.CLOSE);
                message_dialog.set_transient_for (window);
                message_dialog.show ();
                message_dialog.destroy ();
                return "";
            }
            if (exit_status != 0) {
                return "";
            }
        }
        return result_file;
    }

    private async bool merge_file (string inputs, string output_file) {
        bool ret = true;
        SourceFunc callback = merge_file.callback;
        ThreadFunc<void*> run = () => {
            string output, stderr = "";
            int exit_status = 0;
            try {
                var cmd = "gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=" + output_file + " -dBATCH " + inputs;
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            } catch (Error e) {
                critical (e.message);
                ret = false;
            }
            if (output != "" || exit_status != 0 || stderr != "") {
                if (output.contains ("Error")) {
                    ret = false;
                }
                if (exit_status != 0) {
                    ret = false;
                }
            }
            Idle.add ((owned) callback);
            return null;
        };
        try {
            new Thread<void*>.try (null, run);
        } catch (Error e) {
            warning (e.message);
        }
        yield;
        return ret;
    }
}
