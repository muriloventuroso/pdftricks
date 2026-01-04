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

public void PDFTricks.Function () {

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
