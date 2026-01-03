{ config, lib, pkgs, unstable, ... }:

{
  imports = [ ./development ./packages ./hardware ];
}
