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

public class PDFTricks.SplitCheckButtons : Gtk.Box {

    private Gtk.CheckButton btn_all;
    private Gtk.CheckButton btn_range;

    private Granite.ValidatedEntry entry_range;
    private Gtk.Revealer entry_revealer;

    private Gtk.CheckButton btn_colors;

    public enum SplitType {ALL, RANGE, COLORS, NONE;}
    public SplitType selected {
        get {
            if (btn_all.active) {return SplitType.ALL;}
            if (btn_range.active) {return SplitType.RANGE;}
            if (btn_colors.active) {return SplitType.COLORS;};
            return SplitType.NONE;
        }
    }

    public string range {
        get {return entry_range.text;}
    }

    public bool is_valid {
        get {return entry_range.is_valid;}
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 0;

        btn_all = new Gtk.CheckButton.with_label (_("Extract all pages")) {
            active = true,
            margin_bottom = 9
        };

        btn_range = new Gtk.CheckButton.with_label (_("Select range of pages"));
        btn_range.group = btn_all;

        entry_range = new Granite.ValidatedEntry () {
            placeholder_text = "1-3,5,9",
            margin_top = 6
        };

        // Regex: As in the placeholder: Numbers, dashes and commas
        // TODO: Ensure only one dash or comma, to avoid stuff like 8--3,,,5
        // Im not sure if ghostscript can work with that though....
        try {
            var regex = new Regex ("^[0-9,-]*$");
            entry_range.regex = regex;
        } catch (Error e) {
            critical (e.message);
        }

        entry_revealer = new Gtk.Revealer () {
            child = entry_range,
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            margin_bottom = 9
        };

        btn_colors = new Gtk.CheckButton.with_label (_("Separate colored pages"));
        btn_colors.group = btn_all;



        btn_range.bind_property (
            "active",
            entry_revealer, "reveal_child",
            GLib.BindingFlags.SYNC_CREATE
        );

        append (btn_all);
        append (btn_range);
        append (entry_revealer);
        append (btn_colors);
    }
}
