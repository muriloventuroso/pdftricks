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

namespace pdftricks {
    public class ConvertPDF : Gtk.Box{
        public signal void proccess_begin ();
        public signal void proccess_finished (bool result);
        private Gtk.FileChooserButton filechooser;
        public Gtk.Window window { get; construct; }
        private Gtk.Grid grid;
        private Gtk.Spinner spinner;
        private Gtk.ComboBoxText format_conversion;

        public ConvertPDF (Gtk.Window window) {
            Object (
                margin_start: 20,
                margin_end: 20,
                window: window,
                hexpand: true,
                homogeneous: true
            );
        }
        construct {
            filechooser = new Gtk.FileChooserButton (_("Select the file to convert"), Gtk.FileChooserAction.OPEN);

            format_conversion = new Gtk.ComboBoxText();
            format_conversion.append_text ("pdf");
            format_conversion.append_text ("jpg");
            format_conversion.append_text ("png");
            format_conversion.append_text ("txt");

            var convert_button = new Gtk.Button.with_label (_("Convert"));
            convert_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            convert_button.can_default = true;
            convert_button.vexpand = true;
            convert_button.set_sensitive(false);
            convert_button.clicked.connect (confirm_convert);

            filechooser.file_set.connect(() => {

                var file_pdf = filechooser.get_filename().replace("%20", " ");
                var file_name_split = file_pdf.split(".");
                var input_format = file_name_split[file_name_split.length - 1];
                format_conversion.remove_all();
                if(input_format == "pdf"){
                    format_conversion.append_text ("jpg");
                    format_conversion.append_text ("png");
                    format_conversion.append_text ("txt");
                    format_conversion.active = 0;
                }else if(input_format == "jpg"){
                    format_conversion.append_text ("pdf");
                    format_conversion.active = 0;
                }else if(input_format == "png"){
                    format_conversion.append_text ("pdf");
                    format_conversion.active = 0;
                }else if(input_format == "jpeg"){
                    format_conversion.append_text ("pdf");
                    format_conversion.active = 0;
                }else if(input_format == "svg"){
                    format_conversion.append_text ("pdf");
                    format_conversion.active = 0;
                }else if(input_format == "bmp"){
                    format_conversion.append_text ("pdf");
                    format_conversion.active = 0;
                }else {
                    return;
                }
                convert_button.set_sensitive (true);

            });

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.halign = Gtk.Align.CENTER;
            grid.valign = Gtk.Align.CENTER;
            grid.column_spacing = 16;
            grid.row_spacing = 8;
            grid.set_column_homogeneous(true);

            grid.attach (new Granite.HeaderLabel (_("File to Convert:")), 0, 0, 1, 1);
            grid.attach (filechooser, 1, 0, 1, 1);

            grid.attach (new Granite.HeaderLabel (_("Format to Convert:")), 0, 1, 1, 1);
            grid.attach (format_conversion, 1, 1, 1, 1);

            grid.attach (convert_button, 0, 2, 2, 2);
            spinner = new Gtk.Spinner();
            spinner.active = false;

            grid.attach (spinner, 0, 5, 2, 2);
            add(grid);

            proccess_begin.connect (
                () => {
                    spinner.active = true;
                    convert_button.set_sensitive (false);
                });
            proccess_finished.connect (
                (result) => {
                    spinner.active = false;
                    convert_button.set_sensitive (true);
                    if(result){
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("File converted."), "process-completed", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    }else{
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("Could not convert this file."), "process-stop", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    };
                });

        }
        private void confirm_convert(){
            var convert = false;
            var format = format_conversion.get_active_text();

            var file_pdf = filechooser.get_filename();
            var file_name_split = file_pdf.split(".");
            var input_format = file_name_split[file_name_split.length - 1];
            if(input_format == format){
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("The input format is the same as the output format."), "process-stop", Gtk.ButtonsType.CLOSE);
                message_dialog.set_transient_for(window);
                message_dialog.show_all ();
                message_dialog.run ();
                message_dialog.destroy ();
                return;
            }
            var output_file = "";
            Gtk.FileChooserNative chooser_output = new Gtk.FileChooserNative (
                _("Select the file to save"), window, Gtk.FileChooserAction.SAVE,
                _("Save"),
                _("Cancel"));
            var split_filename = file_pdf.split("/");
            var filename = split_filename[split_filename.length - 1];
            chooser_output.set_current_folder(file_pdf);
            chooser_output.set_current_name(filename.split(".")[0] + "." + format);
            chooser_output.do_overwrite_confirmation = true;
            if (chooser_output.run () == Gtk.ResponseType.ACCEPT) {
                output_file = chooser_output.get_filename();
                convert = true;
            }
            chooser_output.destroy();
            if(convert == true){
                proccess_begin ();
                convert_file.begin (file_pdf, output_file, input_format, format,
                    (obj, res) => {
                        proccess_finished (convert_file.end (res));
                    });

            }
        }

        private async bool convert_file(string input, string output_file, string format_input, string format_output){
            bool ret = true;
            SourceFunc callback = convert_file.callback;
            ThreadFunc<void*> run = () => {
                string output, stderr, cmd  = "";
                int exit_status = 0;
                if(format_input == "pdf"){
                    if(format_output == "jpg"){
                        var n_output_file = output_file.replace(".jpg", "-%03d.jpg");
                        cmd = "gs -sDEVICE=jpeg -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \"" + input + "\"";
                    }else if (format_output == "png") {
                        var n_output_file = output_file.replace(".png", "-%03d.png");
                        cmd = "gs -sDEVICE=png16m -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \""+ input + "\"";

                    }else if(format_output == "txt"){
                        var n_output_file = output_file;
                        cmd = "gs -ps2ascii -sDEVICE=txtwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + n_output_file + "\" \"" + input + "\"";
                    }
                }else if(format_input == "jpg"){
                    var n_output_file = output_file;
                    cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

                }else if(format_input == "png"){
                    var n_output_file = output_file;
                    cmd = "convert -verbose \"" + input + "\" \"" + n_output_file + "\"";

                }else if(format_input == "jpeg"){
                    var n_output_file = output_file;
                    cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

                }else if(format_input == "svg"){
                    var n_output_file = output_file;
                    cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

                }else if(format_input == "bmp"){
                    var n_output_file = output_file;
                    cmd = "convert \"" + input + "\" \"" + n_output_file + "\"";

                }
                if(cmd != ""){
                    try{
                        Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                    } catch (Error e) {
                        critical (e.message);
                        ret = false;
                    }
                    if(output != "" || exit_status != 0 || stderr != ""){
                        if(output.contains("Error")){
                            ret = false;
                        }
                        if(stderr.contains("not authorized")){
                            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("ImageMagick Policies"), _("Change the ImageMagick security policies that prevent this operation and try again."), "process-stop", Gtk.ButtonsType.CLOSE);
                            message_dialog.set_transient_for(window);
                            message_dialog.show_all ();
                            message_dialog.run ();
                            message_dialog.destroy ();
                            ret = false;
                        }
                        if(exit_status != 0){
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
}
