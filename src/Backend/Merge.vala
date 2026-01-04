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


    private async bool merge_file (string inputs, string output_file) {
        bool ret = true;
        SourceFunc callback = merge_file.callback;
        ThreadFunc<void*> run = () => {
            string output, stderr = "";
            int exit_status = 0;
            try {
                var cmd = "gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=" + output_file + " -dBATCH " + inputs;
                Process.spawn_command_line_sync (cmd, out output, out stderr, out exit_status);
            } catch (Error e) {
                critical (e.message);
                ret = false;
            }
            if (output != "" || exit_status != 0 || stderr != "") {
                if (output.contains ("Error")) {
                    ret = false;
                }
                if (exit_status != 0) {
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
