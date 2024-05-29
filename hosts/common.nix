{ inputs, outputs, lib, config, pkgs, ... }: {
  fileSystems = {
    "/mnt/video" = {
      device = "172.31.0.100:/volume1/video";
      fsType = "nfs";
    };
    "/mnt/music" = {
      device = "172.31.0.100:/volume1/music";
      fsType = "nfs";
    };
    "/mnt/books" = {
      device = "172.31.0.100:/volume1/books";
      fsType = "nfs";
    };
  };

}
