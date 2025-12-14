{ config, lib, pkgs, ... }:

{
  imports = [ ./development ./packages ./hardware ];
}
