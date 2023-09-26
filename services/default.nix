{ lib, ... }:

let
  # Get the path of the services directory
  servicesDir = ./.;

  # List all items in the services directory
  serviceNames = builtins.attrNames (builtins.readDir servicesDir);

  # Filter only directories (each service should be a directory containing default.nix)
  serviceDirs = lib.filter (name: (builtins.readDir servicesDir)."${name}" == "directory") serviceNames;

  # Import all the service modules
  importedServices = map (name: import "${servicesDir}/${name}/default.nix") serviceDirs;
in
# Merge all imported service modules into a single module
lib.foldl' (acc: mod: lib.recursiveUpdate acc mod) { } importedServices
