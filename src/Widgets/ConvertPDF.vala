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

                convert_button.set_sensitive (true);
                var file_pdf = filechooser.get_uri().split(":")[1].replace("///", "/").replace("%20", " ");
                var input_format = file_pdf.substring(file_pdf.length - 3, 3);
                format_conversion.remove_all();
                if(input_format == "pdf"){
                    format_conversion.append_text ("jpg");
                    format_conversion.append_text ("png");
                    format_conversion.append_text ("txt");
                    format_conversion.active = 0;
                }

            });

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.halign = Gtk.Align.CENTER;
            grid.valign = Gtk.Align.CENTER;
            grid.column_spacing = 12;
            grid.row_spacing = 6;

            grid.attach (new Granite.HeaderLabel (_("File to Convert:")), 0, 0, 1, 1);
            grid.attach (filechooser, 1, 0, 1, 1);

            grid.attach (new Granite.HeaderLabel (_("Format to Convert:")), 0, 1, 1, 1);
            grid.attach (format_conversion, 1, 1, 1, 1);

            grid.attach (convert_button, 0, 2, 2, 2);
            spinner = new Gtk.Spinner();
            spinner.active = true;

            grid.attach (spinner, 0, 4, 2, 2);
            add(grid);

        }
        public void hide_spinner(){
            spinner.hide();
        }

        private void confirm_convert(){
            var convert = false;
            var format = format_conversion.get_active_text();

            var file_pdf = filechooser.get_uri().split(":")[1].replace("///", "/").replace("%20", " ");
            var input_format = file_pdf.substring(file_pdf.length - 3, 3);
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
            chooser_output.set_current_name(filename.split(".")[0] + "." + format);
            chooser_output.do_overwrite_confirmation = true;
            if (chooser_output.run () == Gtk.ResponseType.ACCEPT) {
                output_file = chooser_output.get_uri().split(":")[1].replace("///", "/").replace("%20", "\\ ");
                convert = true;
            }
            chooser_output.destroy();
            if(convert == true){
                var result_convert = convert_file(file_pdf, output_file, input_format, format);
                if(result_convert){
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully converted."), "process-completed", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for(window);
                    message_dialog.show_all ();
                    message_dialog.run ();
                    message_dialog.destroy ();
                }else{
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem converting your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for(window);
                    message_dialog.show_all ();
                    message_dialog.run ();
                    message_dialog.destroy ();
                };
            }
        }

        private bool convert_file(string input, string output_file, string format_input, string format_output){

            string output, stderr, cmd  = "";
            int exit_status = 0;
            spinner.show();
            if(format_input == "pdf"){
                if(format_output == "jpg"){
                    var n_output_file = output_file.replace(".jpg", "-%03d.jpg");
                    cmd = "gs -sDEVICE=jpeg -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=" + n_output_file + " " + input.replace(" ", "\\ ");
                }else if (format_output == "png") {
                    var n_output_file = output_file.replace(".png", "-%03d.png");
                    cmd = "gs -sDEVICE=png16m -r144 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=" + n_output_file + " " + input.replace(" ", "\\ ");

                }else if(format_output == "txt"){
                    var n_output_file = output_file;
                    cmd = "gs -ps2ascii -sDEVICE=txtwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile=" + n_output_file + " " + input.replace(" ", "\\ ");
                }
            }
            if(cmd != ""){
                try{
                    Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                } catch (Error e) {
                    critical (e.message);
                    spinner.hide();
                    return false;
                }
                if(output != ""){
                    if(output.contains("Error")){
                        spinner.hide();
                        return false;
                    }
                }
            }
            spinner.hide();
            return true;
        }


    }
}