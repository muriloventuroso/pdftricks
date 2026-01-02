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

public enum PDFTricks.Format {
    PDF,
    JPG,
    PNG,
    SVG,
    BMP,
    TXT,
    UNKNOWN;

    public string to_string () {
        switch (this) {
            case PDF: return "PDF";
            case JPG: return "JPG";
            case PNG: return "PNG";
            case SVG: return "SVG";
            case BMP: return "BMP";
            case TXT: return "TXT";
            case UNKNOWN: return "UNKNOWN";
            default: return "UNKNOWN";
        }
    }

    public string to_friendly_string () {
        switch (this) {
            case PDF: return _("PDF Document");
            case JPG: return _("JPG Image");
            case PNG: return _("Portable Network Graphics (PNG)");
            case SVG: return _("Vector image (SVG)");
            case BMP: return _("Bitmap image (BMP)");
            case TXT: return _("Text (TXT)");
            case UNKNOWN: return _("Unhandled format");
            default: return _("Unhandled format");
        }
    }

    public static Format from_file (File file) {
        FileInfo info;

        try {
            info = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
        } catch (Error e) {
            warning (e.message);
            return Format.UNKNOWN;
        }

        var mimetype = info.get_content_type ();
        if (mimetype == null) {
            warning ("Failed to get content type");
            return Format.UNKNOWN;
        }

        switch (mimetype) {
            case "application/pdf": return Format.PDF;
            case "image/jpeg": return Format.JPG;
            case "image/png": return Format.PNG;
            case "image/svg+xml": return Format.SVG;
            case "image/bmp": return Format.BMP;
            case "text/plain": return Format.TXT;
            default: return Format.UNKNOWN;
        }
    }
}
