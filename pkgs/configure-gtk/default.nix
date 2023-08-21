{ pkgs
,
}:

pkgs.writeTextFile {
  name = "configure-gtk";
  destination = "/bin/configure/-gtk";
  executable = true;
  text =
    let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/:${schema}/share/gsettings-schemas/gsettings-desktop-schemas-44.0/glib-2.0/schemas";
    in
    ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme 'Catppuccin-Mocha-Compact-Lavender-dark'
      gsettings set $gnome_schema cursor-theme 'Catppuccin-Mocha-Compact-Lavender-dark'
    '';
}
