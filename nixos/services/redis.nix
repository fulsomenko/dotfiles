{ config, lib, ... }:

with lib;
let
in
{

  services.redis = {
    enable = true;
    port = 6999;
  };

}
