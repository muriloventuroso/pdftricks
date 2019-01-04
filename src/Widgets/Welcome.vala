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
    public class Welcome : Gtk.Grid {
        construct {
            var welcome = new Granite.Widgets.Welcome ("PDF Tricks", _("Tricks for PDF files"));
            welcome.append ("compress-pdf", _("Compress PDF"), _("Compress PDF file to get the same PDF quality but less filesize."));
            welcome.append ("split-pdf", _("Split PDF"), _("Split a PDF file by page ranges or extract all PDF pages to multiple PDF files."));
            welcome.append ("merge-pdf", _("Merge PDF"), _("Select multiple PDF files and merge them in seconds."));
            welcome.append ("view-refresh", _("Convert PDF"), _("Convert PDF files to jpg, png and txt formats."));
            add (welcome);

            welcome.get_button_from_index(0).action_name = Application.ACTION_PREFIX + Application.ACTION_COMPRESS_PDF;
            welcome.get_button_from_index(1).action_name = Application.ACTION_PREFIX + Application.ACTION_SPLIT_PDF;
            welcome.get_button_from_index(2).action_name = Application.ACTION_PREFIX + Application.ACTION_MERGE_PDF;
            welcome.get_button_from_index(3).action_name = Application.ACTION_PREFIX + Application.ACTION_CONVERT_PDF;
        }
    }
}