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
      datadir = "${schema}/share/gsetting-schemas/${schema.name}";
    in
    ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme 'WhiteSur-dark'
      gsettings set $gnome_schema cursor-theme 'capitaine-cursors-white'
    '';
}
