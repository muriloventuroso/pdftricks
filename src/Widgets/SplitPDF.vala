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
    public class SplitPDF : Gtk.Box {
        private Gtk.FileChooserButton filechooser;
        public Gtk.Window window { get; construct; }
        private int page_size;
        private Gtk.Entry entry_range;
        private string type_split;
        private Gtk.Spinner spinner;

        public SplitPDF (Gtk.Window window) {
            Object (
                margin_start: 20,
                margin_end: 20,
                window: window,
                hexpand: true,
                homogeneous: true
            );
        }
        construct {
            page_size = 0;
            type_split = "all";

            filechooser = new Gtk.FileChooserButton (_("Select the file to compress"), Gtk.FileChooserAction.OPEN);

            Gtk.FileFilter filter = new Gtk.FileFilter ();
            filechooser.set_filter (filter);
            filter.add_mime_type ("application/pdf");

            Gtk.RadioButton btn_all = new Gtk.RadioButton.with_label_from_widget (null, _("Extract all pages"));
            btn_all.set_sensitive (false);

            Gtk.RadioButton btn_range = new Gtk.RadioButton.with_label_from_widget (btn_all, _("Select range of pages"));
            btn_range.set_sensitive (false);

            var revealer = new Gtk.Revealer();

            Gtk.ListStore model_thumbs = new Gtk.ListStore (2, typeof (Gdk.Pixbuf), typeof (string));
            Gtk.TreeIter iter;

            Gtk.IconView view_thumbs = new Gtk.IconView.with_model (model_thumbs);
            view_thumbs.set_pixbuf_column (0);
            view_thumbs.set_text_column (1);
            view_thumbs.set_selection_mode(Gtk.SelectionMode.MULTIPLE);
            view_thumbs.set_item_width(105);
            view_thumbs.hexpand = true;
            view_thumbs.vexpand = true;
            view_thumbs.set_item_padding(5);

            var scrolled_thumbs = new Gtk.ScrolledWindow(null, null);
            scrolled_thumbs.hexpand = true;
            scrolled_thumbs.vexpand = true;
            scrolled_thumbs.set_policy(Gtk.PolicyType.ALWAYS, Gtk.PolicyType.NEVER);

            scrolled_thumbs.add(view_thumbs);

            entry_range = new Gtk.Entry();
            entry_range.set_placeholder_text("1-3,5,9");

            var range_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            range_box.pack_start (scrolled_thumbs, false, false, 0);
            range_box.pack_start (entry_range, false, false, 0);
            revealer.add(range_box);

            view_thumbs.selection_changed.connect(() => {
                List<Gtk.TreePath> paths = view_thumbs.get_selected_items ();
                Value title;
                string result = "";
                foreach (Gtk.TreePath path in paths) {
                    bool tmp = model_thumbs.get_iter (out iter, path);
                    assert (tmp == true);

                    model_thumbs.get_value (iter, 1, out title);
                    if(result == ""){
                        result = title.dup_string();
                    }else{
                        result = title.dup_string() + "," + result;
                    }
                }

                var list_result = result.split(",");
                var first = list_result[0];
                var last = list_result[0];
                var result_grouped = "";
                for(int a = 0; a < list_result.length; a++){
                    if(a == 0){
                        continue;
                    }
                    var n = list_result[a];

                    if(int.parse(n) - 1 == int.parse(last)){
                        last = n;
                    }else{
                        if(first == last){
                            if(result_grouped == ""){
                                result_grouped = first;
                            }else{
                                result_grouped = result_grouped + "," + first;
                            }
                        }else{
                            if(result_grouped == ""){
                                result_grouped = first + "-" + last;
                            }else{
                                result_grouped = result_grouped + "," + first + "-" + last;
                            }
                        }
                        first = n;
                        last = n;
                    }
                }
                if(first == last){
                    if(result_grouped == ""){
                        result_grouped = first;
                    }else{
                        result_grouped = result_grouped + "," + first;
                    }
                }else{
                    if(result_grouped == ""){
                        result_grouped = first + "-" + last;
                    }else{
                        result_grouped = result_grouped + "," + first + "-" + last;
                    }
                }
                if(result_grouped != ""){
                    entry_range.set_text(result_grouped);
                }

            });
            btn_range.toggled.connect(() => {
                if(btn_range.get_active() == true){
                    model_thumbs.clear();
                    type_split = "range";
                    var file_pdf = filechooser.get_uri().split(":")[1].replace("///", "/").replace("%20", " ");
                    view_thumbs.set_columns(page_size);
                    if(create_thumbs(file_pdf)){
                        for (int a = 1; a <= page_size; a++) {
                            try {
                                model_thumbs.append (out iter);
                                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file ("/tmp/h" + a.to_string() + ".jpg");
                                model_thumbs.set (iter, 0, pixbuf, 1, a.to_string());

                            } catch (Error e) {
                                print("erro");
                            }
                        }
                    }

                    revealer.set_reveal_child(true);
                }

            });
            btn_all.toggled.connect(() => {
                if(btn_all.get_active() == true){
                    type_split = "all";
                    revealer.set_reveal_child(false);
                }
            });
            var split_button = new Gtk.Button.with_label (_("Split"));
            split_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            split_button.can_default = true;
            split_button.vexpand = true;
            split_button.clicked.connect (confirm_split);
            split_button.set_sensitive(false);

            filechooser.file_set.connect(() => {
                var file_pdf = filechooser.get_uri().split(":")[1].replace("///", "/").replace("%20", " ");
                page_size = get_page_count(file_pdf);
                split_button.set_sensitive (true);
                btn_all.set_sensitive (true);
                btn_range.set_sensitive (true);
                model_thumbs.clear();
                if(btn_range.get_active() == true){
                    view_thumbs.set_columns(page_size);
                    if(create_thumbs(file_pdf)){
                        for (int a = 1; a <= page_size; a++) {
                            try {
                                model_thumbs.append (out iter);
                                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file ("/tmp/h" + a.to_string() + ".jpg");
                                model_thumbs.set (iter, 0, pixbuf, 1, a.to_string());

                            } catch (Error e) {
                                print("erro");
                            }
                        }
                    }
                }
            });

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.halign = Gtk.Align.CENTER;
            grid.valign = Gtk.Align.CENTER;
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.set_column_homogeneous(true);
            grid.hexpand = true;
            grid.vexpand = true;

            grid.attach (new Granite.HeaderLabel (_("File to Split:")), 1, 0, 1, 1);
            grid.attach (filechooser, 2, 0, 1, 1);

            grid.attach (btn_all, 1, 1, 1, 1);
            grid.attach (btn_range, 2, 1, 1, 1);
            grid.attach (revealer, 0, 2, 4, 2);
            grid.attach (split_button, 1, 5, 2, 1);

            spinner = new Gtk.Spinner();
            spinner.active = true;

            grid.attach (spinner, 1, 6, 2, 1);
            pack_start(grid, true, true, 0);

        }

        public void hide_spinner(){
            spinner.hide();
        }

        private void confirm_split(){
            var split = false;


            var file_pdf = filechooser.get_uri().split(":")[1].replace("///", "/").replace("%20", " ");
            var output_file = "";
            Gtk.FileChooserNative chooser_output = new Gtk.FileChooserNative (
                _("Select the file to compress"), window, Gtk.FileChooserAction.SAVE,
                _("Save"),
                _("Cancel"));
            var split_filename = file_pdf.split("/");
            var filename = split_filename[split_filename.length - 1];
            chooser_output.set_current_name(filename);
            chooser_output.do_overwrite_confirmation = false;
            if (chooser_output.run () == Gtk.ResponseType.ACCEPT) {
                output_file = chooser_output.get_uri().split(":")[1].replace("///", "/").replace("%20", "\\ ");
                split = true;
            }
            chooser_output.destroy();
            if(split == true){
                var result_split = false;
                if(type_split == "all"){
                    if(split_file_all(file_pdf, output_file)){
                        result_split = true;
                    };
                }else if (type_split == "range") {
                    var pages = entry_range.get_text();
                    if(split_file_range(file_pdf, output_file, pages)){
                        result_split = true;
                    };
                }

                if(result_split = true){
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Success."), _("Your file was succefully splited."), "process-completed", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for(window);
                    message_dialog.show_all ();
                    message_dialog.run ();
                    message_dialog.destroy ();
                }else{
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Failure."), _("There was a problem spliting your file."), "process-stop", Gtk.ButtonsType.CLOSE);
                    message_dialog.set_transient_for(window);
                    message_dialog.show_all ();
                    message_dialog.run ();
                    message_dialog.destroy ();
                };
            }
        }

        private bool split_file_all(string input, string output_file) {
            for (int a = 1; a <= page_size; a++) {
                split_page_range(input, output_file, a, a, a.to_string());
            }
            return true;
        }

        private bool split_file_range(string input, string output_file, string pages) {
            var list_pages = pages.split(",");
            for (int a = 0; a < list_pages.length; a++) {
                var page = list_pages[a];
                var start_page = page;
                var end_page = page;
                if(page.contains("-") && page.split("-").length == 2){
                    start_page = page.split("-")[0];
                    end_page = page.split("-")[1];
                }
                split_page_range(input, output_file, int.parse(start_page), int.parse(end_page), page);
            }
            return true;
        }

        private bool split_page_range(string input, string output_file, int page_start, int page_end, string label){
            string output, stderr  = "";
            int exit_status = 0;
            string output_filename = output_file.replace(".pdf", "_" + label + ".pdf");
            spinner.show();
            try{
                var cmd = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -dAutoFilterColorImages=false -dEncodeColorImages=true -dColorImageFilter=/DCTEncode -dColorConversionStrategy=/LeaveColorUnchange -dFirstPage=" + page_start.to_string() + " -dLastPage=" + page_end.to_string() + " -sOutputFile=" + output_filename +" " + input.replace(" ", "\\ ");
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
            spinner.hide();
            return true;
        }

        private int get_page_count(string input_file){
            string output, stderr  = "";
            int exit_status = 0;
            int result = 0;
            try{
                var cmd = "gs -q -dNODISPLAY -c \"(" + input_file + ") (r) file runpdfbegin pdfpagecount = quit\"";
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
                result = int.parse(output);
            } catch (Error e) {
                critical (e.message);
                return 0;
            }
            if(output != ""){
                if(output.contains("Error")){
                    return 0;
                }
            }
            return result;

        }

        private bool create_thumbs(string input_file) {
            string output, stderr  = "";
            int exit_status = 0;
            try{
                var cmd = "gs -dNumRenderingThreads=4 -dNOPAUSE -sDEVICE=jpeg -g125x175 -dPDFFitPage -sOutputFile=/tmp/h%d.jpg -dJPEGQ=100 -r300 -q " + input_file.replace(" ", "\\ ") +" -c quit";
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            } catch (Error e) {
                critical (e.message);
                return false;
            }
            if(output != ""){
                if(output.contains("Error")){
                    return false;
                }
            }
            return true;
        }


    }
}