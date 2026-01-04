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

public class PDFTricks.SplitPDF : PDFTricks.PageTemplate {

    public signal void create_thumb_begin ();
    public signal void create_thumb_finished (bool result);

    private PDFTricks.FileChooserButton filechooser;

    private int page_size = 0;

    private PDFTricks.SplitCheckButtons checkbuttons;

    public SplitPDF (Gtk.Window window) {
        Object (window: window,
                title: _("Split PDF"));
    }

    construct {
        filechooser = new PDFTricks.FileChooserButton (_("Select the file to split"));
        checkbuttons = new PDFTricks.SplitCheckButtons ();

        var split_button = new Gtk.Button.with_label (_("Split")) {
            vexpand = true
        };
        split_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        freeze_list.add (split_button);


        grid.attach (new Granite.HeaderLabel (_("File to Split:")) {valign = Gtk.Align.CENTER}, 1, 0);
        grid.attach (filechooser, 2, 0);
        grid.attach (checkbuttons, 2, 1);
        grid.attach (split_button, 1, 2, 2);

        freeze_widgets (true);

        /* ---------------- CONNECTS & BINDS ---------------- */
        filechooser.selected.connect (() => {
            var file_pdf = filechooser.selected_file.get_path ();
            page_size = get_page_count (file_pdf);
            split_button.set_sensitive (true);
            checkbuttons.set_sensitive (true);
        });

        split_button.clicked.connect (confirm_split);
    }

    private void confirm_split () {
        var split = false;
        var file_pdf = filechooser.selected_file;

        var chooser_output = new Gtk.FileDialog () {
            title = _("Select the file to save to")
        };

        chooser_output.save.begin (window, null, (obj, res) => {
            try {

                var output_file = chooser_output.save.end (res).get_path ();

                if (split == true) {
                    if (checkbuttons.selected == SplitCheckButtons.SplitType.ALL) {
                        process_begin ();
                        split_file_all.begin (file_pdf.get_path (), output_file,
                            (obj, res) => {
                                process_finished (split_file_all.end (res));
                            });
                    } else if (checkbuttons.selected == SplitCheckButtons.SplitType.RANGE) {
                        var pages = checkbuttons.range;
                        process_begin ();
                        split_file_range.begin (file_pdf.get_path (), output_file, pages,
                            (obj, res) => {
                                process_finished (split_file_range.end (res));
                            });
                    }else if (checkbuttons.selected == SplitCheckButtons.SplitType.COLORS) {
                        var pages = get_colors (file_pdf.get_path ());
                        if (pages != "" && pages != ";") {
                            var pages_black = group_list (pages.split (";")[0]);
                            var pages_colored = group_list (pages.split (";")[1]);
                            var output_file_black = output_file.replace (".pdf", "_" + _("black") + ".pdf");
                            var output_file_colored = output_file.replace (".pdf", "_" + _("colored") + ".pdf");
                            process_begin ();
                            split_file_range.begin (file_pdf.get_path (), output_file_black, pages_black);
                            split_file_range.begin (file_pdf.get_path (), output_file_colored, pages_colored,
                                (obj, res) => {
                                    process_finished (split_file_range.end (res));
                                });
                        }
                    }

                }
            } catch (Error e) {
                critical (e.message);
            }
        });

    }

    private string get_colors (string input) {
        string file_pdf = input;
        string output, stderr = "";
        int exit_status = 0;
        try {
            var cmd = "gs -dNOPAUSE -dQUIET -dBATCH -q  -o - -sDEVICE=inkcov \"" + file_pdf + "\" -c quit  | grep -v Page";
            Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
        } catch (Error e) {
            critical (e.message);
            return "";
        }
        if (output == "") {
            return "";
        }
        var split_output = output.split ("\n");
        var pages_color = "";
        var pages_black = "";
        for (var i = 0; i < split_output.length; i++) {
            var page = split_output[i].strip ();
            if (page.contains ("CMYK OK")) {
                var cmyk = page.replace ("  ", " ").split (" ");
                if (cmyk[0] == "0.00000" && cmyk[1] == "0.00000" && cmyk[2] == "0.00000") {
                    pages_black = pages_black + (i + 1).to_string () + ",";
                } else {
                    pages_color = pages_color + (i + 1).to_string () + ",";
                }
            }
        }
        if (pages_black.substring (pages_black.length - 1) == ",") {
            pages_black = pages_black.substring (0, pages_black.length - 1);
        }
        if (pages_color.substring (pages_color.length - 1) == ",") {
            pages_color = pages_color.substring (0, pages_color.length - 1);
        }
        return pages_black + ";" + pages_color;
    }

    private async bool split_file_all (string input, string output_file) {
        bool ret = true;
        SourceFunc callback = split_file_all.callback;
        ThreadFunc<void*> run = () => {
            for (int a = 1; a <= page_size; a++) {
                split_page_range (input, output_file, a, a, a.to_string ());
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

    private async bool split_file_range (string input, string output_file, string pages) {
        bool ret = true;
        SourceFunc callback = split_file_range.callback;
            ThreadFunc<void*> run = () => {
            var list_pages = pages.split (",");
            for (int a = 0; a < list_pages.length; a++) {
                var page = list_pages[a];
                var start_page = page;
                var end_page = page;
                if (page.contains ("-") && page.split ("-").length == 2) {
                    start_page = page.split ("-")[0];
                    end_page = page.split ("-")[1];
                }
                split_page_range (input, output_file, int.parse (start_page), int.parse (end_page), page);
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

    private bool split_page_range (string input, string output_file, int page_start, int page_end, string label) {
        string file_pdf = input;
        string output, stderr = "";
        int exit_status = 0;
        string output_filename = output_file.replace (".pdf", "_" + label + ".pdf");
        try {
            var cmd = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -dAutoFilterColorImages=false -dEncodeColorImages=true -dColorImageFilter=/DCTEncode -dFirstPage=" + page_start.to_string () + " -dLastPage=" + page_end.to_string () + " -sOutputFile=\"" + output_filename + "\" \"" + file_pdf + "\"";
            Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
        } catch (Error e) {
            critical (e.message);
            return false;
        }
        if (output != "") {
            if (output.contains ("Error")) {
                return false;
            }
        }
        return true;
    }

    private int get_page_count (string input_file) {
        string file_pdf = input_file;
        string output, stderr = "";
        int exit_status = 0;
        int result = 0;
        try {
            var cmd = "gs -q -dNODISPLAY -c \"(\"" + file_pdf + "\") (r) file runpdfbegin pdfpagecount = quit\"";
            Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            result = int.parse (output);
        } catch (Error e) {
            critical (e.message);
            return 0;
        }
        if (output != "") {
            if (output.contains ("Error")) {
                return 0;
            }
        }
        return result;

    }

    private string group_list (string result) {
        var list_result = result.split (",");
        var first = list_result[0];
        var last = list_result[0];
        var result_grouped = "";
        for (int a = 0; a < list_result.length; a++) {
            if (a == 0) {
                continue;
            }
            var n = list_result[a];

            if (int.parse (n) - 1 == int.parse (last)) {
                last = n;
            } else {
                if (first == last) {
                    if (result_grouped == "") {
                        result_grouped = first;
                    } else {
                        result_grouped = result_grouped + "," + first;
                    }
                } else {
                    if (result_grouped == "") {
                        result_grouped = first + "-" + last;
                    } else {
                        result_grouped = result_grouped + "," + first + "-" + last;
                    }
                }
                first = n;
                last = n;
            }
        }
        if (first == last) {
            if (result_grouped == "") {
                result_grouped = first;
            } else {
                result_grouped = result_grouped + "," + first;
            }
        } else {
            if (result_grouped == "") {
                result_grouped = first + "-" + last;
            } else {
                result_grouped = result_grouped + "," + first + "-" + last;
            }
        }

        return result_grouped;
    }
}
