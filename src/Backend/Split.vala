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
