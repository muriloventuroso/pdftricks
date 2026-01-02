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

public enum PDFTricks.Compression {
    STRONG,
    MEDIUM,
    RECOMMENDED,
    LESS;

    public string to_friendly_string () {
        switch (this) {
            case STRONG: return _("Extreme compression");
            case MEDIUM: return _("Medium compression");
            case RECOMMENDED: return _("Recommended compression");
            case LESS: return _("Less compression");
            default: return _("Recommended compression");
        }
    }

    public string to_comment () {
        switch (this) {
            case STRONG: return _("Less quality, high compression");
            case MEDIUM: return _("Good quality, optimized for printing");
            case RECOMMENDED: return _("Good quality, good compression");
            case LESS: return _("High quality, less compression");
            default: return _("Good quality, good compression");
        }
    }

    public string to_parameter () {
        switch (this) {
            case STRONG: return "screen";
            case MEDIUM: return "printer";
            case RECOMMENDED: return "ebook";
            case LESS: return "prepress";
            default: return _("Good quality, good compression");
        }
    }

    public static string[] choices () {
        return {
            STRONG.to_friendly_string (),
            MEDIUM.to_friendly_string (),
            RECOMMENDED.to_friendly_string (),
            LESS.to_friendly_string ()
        };
    }
}
