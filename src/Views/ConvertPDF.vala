/*
* Copyright (c) 2019 Murilo Venturoso
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

public class PDFTricks.ConvertPDF : PDFTricks.PageTemplate {

    private PDFTricks.FileChooserButton filechooser;
    private Gtk.DropDown format_conversion;
    private Gtk.Button convert_button;

    public ConvertPDF (Gtk.Window window) {
        Object (window: window,
                title: _("Convert PDF"));
    }
    construct {

        filechooser = new PDFTricks.FileChooserButton (_("Select the file to convert"));

        var jpg_filter = new Gtk.FileFilter () {name = Format.JPG.to_friendly_string ()};
        jpg_filter.add_mime_type ("image/jpeg");

        var png_filter = new Gtk.FileFilter () {name = Format.PNG.to_friendly_string ()};
        png_filter.add_mime_type ("image/png");

        var svg_filter = new Gtk.FileFilter () {name = Format.SVG.to_friendly_string ()};
        svg_filter.add_mime_type ("image/svg+xml");

        var bmp_filter = new Gtk.FileFilter () {name = Format.BMP.to_friendly_string ()};
        bmp_filter.add_mime_type ("image/bmp");

        var txt_filter = new Gtk.FileFilter () {name = Format.TXT.to_friendly_string ()};
        txt_filter.add_mime_type ("text/plain");

        filechooser.filter_model.append (jpg_filter);
        filechooser.filter_model.append (png_filter);
        filechooser.filter_model.append (svg_filter);
        filechooser.filter_model.append (bmp_filter);
        filechooser.filter_model.append (txt_filter);

        format_conversion = new Gtk.DropDown.from_strings ({
                Format.PDF.to_friendly_string (),
                Format.JPG.to_friendly_string (),
                Format.PNG.to_friendly_string (),
                Format.TXT.to_friendly_string (),
        });

        convert_button = new Gtk.Button.with_label (_("Convert"));
        convert_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        convert_button.vexpand = true;
        convert_button.set_sensitive (false);
        convert_button.clicked.connect (confirm_convert);

        filechooser.selected.connect (on_file_selected);

        grid.attach (new Granite.HeaderLabel (_("File to Convert:")) {valign = Gtk.Align.CENTER}, 0, 0, 1, 1);
        grid.attach (filechooser, 1, 0, 1, 1);

        grid.attach (new Granite.HeaderLabel (_("Format to Convert:")) {valign = Gtk.Align.CENTER}, 0, 1, 1, 1);
        grid.attach (format_conversion, 1, 1, 1, 1);

        grid.attach (convert_button, 0, 2, 2, 2);


        process_begin.connect (
            () => {
                convert_button.set_sensitive (false);
        });

        process_finished.connect (
            (result) => {
                convert_button.set_sensitive (true);
                if (result) {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("File converted."), "process-completed", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                    message_dialog.destroy ();
                } else {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("Could not convert this file."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for (window);
                    message_dialog.show ();
                    message_dialog.destroy ();
                };
        });

    }

    private void on_file_selected () {
        var file_pdf = filechooser.selected_file;

        if (file_pdf == null) {
            convert_button.sensitive = false;
            return;
        };

        var input_format = Format.from_file (file_pdf);

        switch (input_format) {
            case PDF:
                format_conversion = new Gtk.DropDown.from_strings ({
                    Format.JPG.to_friendly_string (),
                    Format.PNG.to_friendly_string (),
                    Format.TXT.to_friendly_string ()});
                break;

            default:
                format_conversion = new Gtk.DropDown.from_strings ({
                    Format.PDF.to_friendly_string ()});
                break;
        }

        format_conversion.selected = 0;
        convert_button.sensitive = true;
    }


    private void confirm_convert () {
        var file_pdf = filechooser.selected_file;
        var new_name = file_pdf.get_basename ();
        new_name = new_name.substring (0, new_name.length - 4);
        new_name = new_name + "." + ((Format)format_conversion.selected).to_string ().ascii_down ();

        var chooser_output = new Gtk.FileDialog () {
            title = _("Select the file to save"),
            initial_name = new_name
        };

        chooser_output.save.begin (window, null, (obj, res) => {
            try {

                var output_file = chooser_output.save.end (res);

                if (output_file != null) {
                    process_begin ();

                    convert_file.begin (file_pdf.get_path (), output_file.get_path (),
                        (obj, res) => {
                            process_finished (convert_file.end (res));
                        });
                }

            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    private async bool convert_file (string input, string output_file) {
        bool ret = true;
        SourceFunc callback = convert_file.callback;
        ThreadFunc<void*> run = () => {
            string output, stderr, cmd = "";
            int exit_status = 0;

            var format_input = Format.from_file (filechooser.selected_file);
            var format_output = (Format)format_conversion.selected;

            if (format_input == PDF) {
                if (format_output == JPG) {
                    var n_output_file = output_file.replace (".jpg", "-%03d.jpg");
                    cmd = "gs -sDEVICE=jpeg -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \"" + input + "\"";
                } else if (format_output == PNG) {
                    var n_output_file = output_file.replace (".png", "-%03d.png");
                    cmd = "gs -sDEVICE=png16m -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \"" + input + "\"";

                } else if (format_output == TXT) {
                    var n_output_file = output_file;
                    cmd = "gs -ps2ascii -sDEVICE=txtwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \"" + input + "\"";
                }
            } else if (format_input == JPG) {
                var n_output_file = output_file;
                cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

            } else if (format_input == PNG) {
                var n_output_file = output_file;
                cmd = "convert -verbose \"" + input + "\" \"" + n_output_file + "\"";

            } else if (format_input == SVG) {
                var n_output_file = output_file;
                cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

            } else if (format_input == BMP){
                var n_output_file = output_file;
                cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

            }
            if (cmd != "") {
                try {
                    Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                } catch (Error e) {
                    critical (e.message);
                    ret = false;
                }
                if (output != "" || exit_status != 0 || stderr != "") {
                    if (output.contains ("Error")) {
                        ret = false;
                    }
                    if (stderr.contains ("not authorized")) {
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("ImageMagick Policies"), _("Change the ImageMagick security policies that prevent this operation and try again."), "process-stop", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for (window);
                        message_dialog.show ();
                        message_dialog.destroy ();
                        ret = false;
                    }
                    if (exit_status != 0) {
                        ret = false;
                    }
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
