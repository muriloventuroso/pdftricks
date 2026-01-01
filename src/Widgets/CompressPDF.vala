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

public class PDFTricks.CompressPDF : Gtk.Box{
        public signal void proccess_begin ();
        public signal void proccess_finished (bool result);
        private Gtk.FileChooserButton filechooser;
        private Gtk.ListStore resolution_store;
        private Gtk.TreeIter iter;
        private Gtk.ComboBox resolution_box;
        public Gtk.Window window { get; construct; }
        private Gtk.Grid grid;
        private Gtk.Spinner spinner;
        private Gtk.Label level_description;

        public CompressPDF (Gtk.Window window) {
            Object (
                margin_start: 20,
                margin_end: 20,
                window: window,
                hexpand: true,
                homogeneous: true
            );
        }
        construct {
            filechooser = new Gtk.FileChooserButton (_("Select the file to compress"), Gtk.FileChooserAction.OPEN);
            level_description = new Gtk.Label(_("Good quality, good compression"));
            Gtk.FileFilter filter = new Gtk.FileFilter ();
            filter.add_mime_type ("application/pdf");
            filechooser.set_filter (filter);
            resolution_store =  new Gtk.ListStore (2, typeof (string), typeof (string));
            resolution_store.append(out iter);
            resolution_store.set (iter, 0, "screen", 1, _("Extreme Compression"));
            resolution_store.append(out iter);
            resolution_store.set (iter, 0, "ebook", 1, _("Medium Compression"));
            resolution_store.append(out iter);
            resolution_store.set (iter, 0, "printer", 1, _("Recommended Compression"));
            resolution_store.append(out iter);
            resolution_store.set (iter, 0, "prepress", 1, _("Less Compression"));

            resolution_box = new Gtk.ComboBox.with_model (resolution_store);
            resolution_box.set_sensitive (false);

            resolution_box.changed.connect(() => {
                Value resolution;
                var compress = false;
                resolution_box.get_active_iter (out iter);
                resolution_store.get_value (iter, 0, out resolution);
                var str_resolution = resolution.dup_string();
                if(str_resolution == "screen"){
                    level_description.label = _("Less quality, high compression");
                }else if(str_resolution == "printer"){
                    level_description.label = _("Good quality, optimized for printing");
                }else if(str_resolution == "ebook"){
                    level_description.label = _("Good quality, good compression");
                }else if(str_resolution == "prepress"){
                    level_description.label = _("High quality, less compression");
                }
            });

            var renderer = new Gtk.CellRendererText ();
            resolution_box.pack_start (renderer, true);
            resolution_box.add_attribute (renderer, "text", 1);
            resolution_box.active = 2;

            var compress_button = new Gtk.Button.with_label (_("Compress"));
            compress_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            compress_button.can_default = true;
            compress_button.vexpand = true;
            compress_button.set_sensitive(false);
            compress_button.clicked.connect (confirm_compress);

            filechooser.file_set.connect(() => {

                compress_button.set_sensitive (true);
                resolution_box.set_sensitive (true);
            });

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.halign = Gtk.Align.CENTER;
            grid.valign = Gtk.Align.CENTER;
            grid.column_spacing = 16;
            grid.row_spacing = 8;
            grid.set_column_homogeneous(true);

            grid.attach (new Granite.HeaderLabel (_("File to Compress:")), 0, 0, 1, 1);
            grid.attach (filechooser, 1, 0, 1, 1);

            grid.attach (new Granite.HeaderLabel (_("Compression Level:")), 0, 1, 1, 1);
            grid.attach (resolution_box, 1, 1, 1, 1);

            grid.attach (level_description, 0, 2, 2, 1);

            grid.attach (compress_button, 0, 3, 2, 2);
            spinner = new Gtk.Spinner();
            spinner.active = false;

            grid.attach (spinner, 0, 5, 2, 2);
            add(grid);

            proccess_begin.connect (
                () => {
                    spinner.active = true;
                    compress_button.set_sensitive (false);
                });
            proccess_finished.connect (
                (result) => {
                    spinner.active = false;
                    compress_button.set_sensitive (true);
                    if(result){
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully compressed."), "process-completed", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    }else{
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem compressing your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    };
                });

        }

        private void confirm_compress(){
            Value resolution;
            var compress = false;
            resolution_box.get_active_iter (out iter);
            resolution_store.get_value (iter, 0, out resolution);

            var file_pdf = filechooser.get_filename();
            var str_resolution = resolution.dup_string();
            var output_file = "";
            Gtk.FileChooserNative chooser_output = new Gtk.FileChooserNative (
                _("Select the file to save"), window, Gtk.FileChooserAction.SAVE,
                _("Save"),
                _("Cancel"));
            var split_filename = file_pdf.split("/");
            var filename = split_filename[split_filename.length - 1];
            chooser_output.set_current_folder(Path.get_dirname(file_pdf));
            chooser_output.set_current_name(filename.split(".")[0] + "_compressed.pdf");
            chooser_output.do_overwrite_confirmation = true;
            if (chooser_output.run () == Gtk.ResponseType.ACCEPT) {
                output_file = chooser_output.get_filename();
                compress = true;
            }
            chooser_output.destroy();
            if(compress == true && output_file != ""){
                proccess_begin ();
                compress_file.begin (file_pdf, output_file, str_resolution,
                    (obj, res) => {
                        proccess_finished (compress_file.end (res));
                    });
            }
        }

        private async bool compress_file(string input, string output_file, string resolution){
            bool ret = true;
            SourceFunc callback = compress_file.callback;
            ThreadFunc<void*> run = () => {
                string output, stderr  = "";
                int exit_status = 0;

                try{
                    var cmd = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/" + resolution + " -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"" + output_file + "\" \"" + input + "\"";
                    Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                } catch (Error e) {
                    critical (e.message);
                    ret = false;
                }
                if(output != ""){
                    if(output.contains("Error")){
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
