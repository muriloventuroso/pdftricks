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

public class PDFTricks.CompressPDF : PDFTricks.PageTemplate {
    private PDFTricks.FileChooserButton filechooser;
    private Gtk.DropDown dropdown;
    private Gtk.Label level_description;
    private Gtk.Button compress_button;

    public CompressPDF (Gtk.Window window) {
        Object (window: window,
                title: _("Compress PDF"));
    }

    construct {
        filechooser = new PDFTricks.FileChooserButton (_("Select the file to compress"));

        level_description = new Gtk.Label (_("Good quality, good compression"));

        dropdown = new Gtk.DropDown.from_strings (Compression.choices ()) {
            sensitive = false
        };
        dropdown.selected = Compression.RECOMMENDED;

        dropdown.notify["selected"].connect (() => {
            level_description.label = ((Compression)dropdown.selected).to_comment ();
        });

        compress_button = new Gtk.Button.with_label (_("Compress")) {
            vexpand = true,
            sensitive = false
        };
        compress_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        grid.attach (new Granite.HeaderLabel (_("File to Compress:")), 0, 0, 1, 1);
        grid.attach (filechooser, 1, 0, 1, 1);

        grid.attach (new Granite.HeaderLabel (_("Compression Level:")), 0, 1, 1, 1);
        grid.attach (dropdown, 1, 1, 1, 1);

        grid.attach (level_description, 0, 2, 2, 1);
        grid.attach (compress_button, 0, 3, 2, 2);


        compress_button.clicked.connect (confirm_compress);

        filechooser.selected.connect (() => {
            if (filechooser.selected_file != null) {
                compress_button.sensitive = true;
                dropdown.sensitive = true;
            };
        });

        process_begin.connect (
            () => {
                compress_button.sensitive = false;
                dropdown.sensitive = false;
            });

        process_finished.connect (
            (result) => {
                compress_button.set_sensitive (true);
                if (result) {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully compressed."), "process-completed", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                } else {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem compressing your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                };
            });

    }

    private void confirm_compress () {
        var file_pdf = filechooser.selected_file;
        var new_name = file_pdf.get_basename ();
        new_name = new_name.substring (0, new_name.length - 4);
        new_name = new_name + "_" + _("compressed") + ".pdf";

        var chooser_output = new Gtk.FileDialog () {
            title = _("Select the file to save"),
            initial_name = new_name
        };

        chooser_output.save.begin (window, null, (obj, res) => {
            try {

                var output_file = chooser_output.save.end (res);

                if (output_file != null) {
                    process_begin ();

                    compress_file.begin (file_pdf.get_path (), output_file.get_path (),
                        (obj, res) => {
                            process_finished (compress_file.end (res));
                        });
                }

            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    private async bool compress_file (string input, string output_file) {
        bool ret = true;
        SourceFunc callback = compress_file.callback;
        ThreadFunc<void*> run = () => {
            string output, stderr = "";
            int exit_status = 0;

            try {
                var resolution = ((Compression)dropdown.selected).to_parameter ();
                var cmd = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/" + resolution + " -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + output_file + "\" \"" + input + "\"";
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            } catch (Error e) {
                critical (e.message);
                ret = false;
            }
            if (output != "") {
                if (output.contains ("Error")) {
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
