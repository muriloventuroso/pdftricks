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

public class PDFTricks.Welcome : Granite.Bin {
    construct {
        var welcome = new Granite.Placeholder (_("PDF Tricks")) {
            description = _("Tricks for PDF files")
        };

        var compress = welcome.append_button (new ThemedIcon ("compress"), _("Compress PDF"), _("Compress a PDF file to get the same quality with reduced filesize."));
        var split = welcome.append_button (new ThemedIcon ("split"), _("Split PDF"), _("Split a PDF file by page ranges, or extract all PDF pages to multiple PDF files."));
        var merge = welcome.append_button (new ThemedIcon ("merge"), _("Merge PDF"), _("Select multiple PDF files or images, and merge them in seconds."));
        var convert = welcome.append_button (new ThemedIcon ("convert"), _("Convert PDF"), _("Convert PDF files to JPG, PNG and TXT formats."));

        compress.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_COMPRESS_PDF;
        split.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SPLIT_PDF;
        merge.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_MERGE_PDF;
        convert.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_CONVERT_PDF;

        child = welcome;
    }
}
