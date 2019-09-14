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

namespace pdftricks {
    public class MergePDF : Gtk.Box {
        public signal void proccess_begin ();
        public signal void proccess_finished (bool result);
        public Gtk.Window window { get; construct; }
        private Gtk.TreeView view;
        private Gtk.ListStore list_store;
        private Gtk.Spinner spinner;
        private const Gtk.TargetEntry[] targets = {
            {"STRING",0,0}
        };

        public MergePDF (Gtk.Window window) {
            Object (
                margin_start: 20,
                margin_end: 20,
                window: window,
                hexpand: true,
                homogeneous: true
            );
        }
        construct {
            string[] input_formats = {"pdf", "png", "jpg", "jpeg", "svg", "bmp"};
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
            view = new Gtk.TreeView.with_model (list_store);
            view.hexpand = true;
            view.vexpand = true;
            view.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK,
                                                targets,
                                                Gdk.DragAction.MOVE);
            view.enable_model_drag_dest(targets,
                                             Gdk.DragAction.DEFAULT);
            view.drag_data_get.connect(on_drag_data_get);
            view.drag_data_received.connect(on_drag_data_received);
            add_button.clicked.connect(() => {
                Gtk.FileChooserNative chooser_file = new Gtk.FileChooserNative (
                _("Select the file to compress"), window, Gtk.FileChooserAction.OPEN,
                _("Open"),
                _("Cancel"));

                chooser_file.set_filter (filter);
                chooser_file.set_select_multiple(true);

                if (chooser_file.run () == Gtk.ResponseType.ACCEPT) {
                    foreach(string pdf_file in chooser_file.get_filenames()){
                        pdf_file = pdf_file.replace("%20", " ");
                        var file_name_split = pdf_file.split(".");
                        var input_format = file_name_split[file_name_split.length - 1];
                        if(input_format in input_formats){
                            var page_size = get_page_count(pdf_file);
                            list_store.append (out iter);
                            list_store.set (iter, 0, pdf_file, 1, page_size.to_string());
                        }
                    }
                }
                chooser_file.destroy();
            });

            del_button.clicked.connect(() => {
                Gtk.TreeModel model;
                var selection = view.get_selection();
                foreach(Gtk.TreePath path in selection.get_selected_rows(out model)){
                    Gtk.TreeIter r_iter;
                    model.get_iter(out r_iter, path);
                    list_store.remove(ref r_iter);
                }
            });

            clear_button.clicked.connect(() => {
                list_store.clear();
            });


            Gtk.CellRendererText cell = new Gtk.CellRendererText ();
            view.insert_column_with_attributes (-1, _("Files"), cell, "text", 0);
            view.insert_column_with_attributes (-1, _("Pages"), cell, "text", 1);

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.halign = Gtk.Align.CENTER;
            grid.valign = Gtk.Align.CENTER;
            grid.column_spacing = 16;
            grid.row_spacing = 8;
            grid.set_column_homogeneous(true);
            grid.set_row_homogeneous(true);
            grid.hexpand = true;
            grid.vexpand = true;

            var merge_button = new Gtk.Button.with_label (_("Merge"));
            merge_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            merge_button.can_default = true;
            merge_button.vexpand = true;
            merge_button.clicked.connect (confirm_merge);
            var scroll = new Gtk.ScrolledWindow(null, null);
            scroll.vexpand = true;
            scroll.hexpand = true;
            scroll.add(view);
            grid.attach (add_button, 1, 0);
            grid.attach (del_button, 2, 0);
            grid.attach (clear_button, 3, 0);
            grid.attach (scroll, 0, 1, 5, 6);
            grid.attach (merge_button, 1, 7, 3);
            spinner = new Gtk.Spinner();
            spinner.active = false;
            grid.attach (spinner, 2, 9);
            pack_start(grid, true, true, 0);

            proccess_begin.connect (
                () => {
                    spinner.active = true;
                    merge_button.set_sensitive (false);
                });
            proccess_finished.connect (
                (result) => {
                    spinner.active = false;
                    merge_button.set_sensitive (true);
                    if(result){
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully merged."), "process-completed", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    }else{
                        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem merging your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                        message_dialog.set_transient_for(window);
                        message_dialog.show_all ();
                        message_dialog.run ();
                        message_dialog.destroy ();
                    };
                });
        }

        private int get_page_count(string input_file){
            string output, stderr  = "";
            int exit_status = 0;
            int result = 0;
            var file_name_split = input_file.split(".");
            var input_format = file_name_split[file_name_split.length - 1];
            if(input_format != "pdf"){
                return 1;
            }
            try{
                var cmd = "gs -q -dNODISPLAY -c \"(" + input_file.replace(" ", "\\ ") + ") (r) file runpdfbegin pdfpagecount = quit\"";
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                result = int.parse(output);
            } catch (Error e) {
                critical (e.message);
            }
            return result;

        }

        private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
                                   Gtk.SelectionData selection_data,
                                   uint target_type, uint time){
            var treeselection = view.get_selection();
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            Value data_value;
            treeselection.get_selected(out model, out iter);
            model.get_value(iter, 0, out data_value);
            var data = data_value.dup_string();
            selection_data.set(selection_data.get_target(), 8, (uchar [])data.to_utf8());
        }


        private void on_drag_data_received (Gtk.Widget widget, Gdk.DragContext context,
                                        int x, int y,
                                        Gtk.SelectionData selection_data,
                                        uint target_type, uint time) {
            var model = view.get_model();
            if ((selection_data != null) && (selection_data.get_length() >= 0)) {
                var data = (string) selection_data.get_data();
                var page_size = get_page_count(data).to_string();
                Gtk.TreePath? path;
                Gtk.TreeViewDropPosition position;
                var drop_info = view.get_dest_row_at_pos(x, y, out path, out position);
                Gtk.TreeIter new_iter;
                Gtk.TreeIter sibling;
                Gtk.TreeIter iter;
                model.get_iter(out sibling, path);
                if(drop_info = true){
                    model.get_iter(out iter, path);
                    if (position == Gtk.TreeViewDropPosition.BEFORE || position == Gtk.TreeViewDropPosition.INTO_OR_BEFORE){
                        list_store.insert_before(out new_iter, sibling);
                    }else{
                        list_store.insert_after(out new_iter, sibling);
                    }
                    list_store.set(new_iter, 0, data, 1, page_size);
                }else{
                    list_store.append(out new_iter);
                    list_store.set(new_iter, 0, data, 1, page_size);
                }
                if(context.get_suggested_action() == Gdk.DragAction.MOVE){
                    Gtk.drag_finish (context, true, true, time);
                }
            }

        }

        private void confirm_merge(){
            var merge = false;
            var files_pdf = "";
            list_store.foreach((model, path, iter) => {
                GLib.Value cell1;

                list_store.get_value (iter, 0, out cell1);
                var file_pdf = (string) cell1;
                if(!file_pdf.contains(".pdf")){
                    file_pdf = convert_to_pdf(file_pdf);
                    if (file_pdf == ""){
                        files_pdf = "";
                        return true;
                    }
                }
                files_pdf = files_pdf + " " + file_pdf.replace(" ", "\\ ");
                return false;
            });
            if(files_pdf == ""){
                return;
            }
            var output_file = "";
            Gtk.FileChooserNative chooser_output = new Gtk.FileChooserNative (
                _("Select the file to compress"), window, Gtk.FileChooserAction.SAVE,
                _("Save"),
                _("Cancel"));
            chooser_output.do_overwrite_confirmation = true;
            if (chooser_output.run () == Gtk.ResponseType.ACCEPT) {
                output_file = chooser_output.get_filename().replace(" ", "\\ ");
                merge = true;
            }
            chooser_output.destroy();
            if(merge == true){
                proccess_begin ();
                merge_file.begin (files_pdf, output_file,
                    (obj, res) => {
                        proccess_finished (merge_file.end (res));
                    });
            }
        }

        private string convert_to_pdf(string input_file){
            string output, stderr, cmd, result_file  = "";
            int exit_status = 0;
            result_file = "/tmp/c_" + GLib.Uuid.string_random() + ".pdf";
            cmd = "convert " + input_file.replace(" ", "\\ ") + " " + result_file;
            try{
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            } catch (Error e) {
                critical (e.message);
                return "";
            }
            if(output != "" || exit_status != 0 || stderr != ""){
                if(output.contains("Error")){
                    return "";
                }
                if(stderr.contains("not allowed")){
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("ImageMagick Policies"), _("Change the ImageMagick security policies that prevent this operation and try again."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for(window);
                    message_dialog.show_all ();
                    message_dialog.run ();
                    message_dialog.destroy ();
                    return "";
                }
                if(exit_status != 0){
                    return "";
                }
            }
            return result_file;
        }

        private async bool merge_file(string inputs, string output_file){
            bool ret = true;
            SourceFunc callback = merge_file.callback;
            ThreadFunc<void*> run = () => {
                string output, stderr  = "";
                int exit_status = 0;
                try{
                    var cmd = "gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=" + output_file +" -dBATCH " + inputs;
                    Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                } catch (Error e) {
                    critical (e.message);
                    ret = false;
                }
                if(output != "" || exit_status != 0 || stderr != ""){
                    if(output.contains("Error")){
                        ret = false;
                    }
                    if(exit_status != 0){
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
}
