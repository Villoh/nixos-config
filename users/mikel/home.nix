{ config, ... }:

{
  imports = [
    ../../modules/home/core
    ../../modules/home/cloud
    ../../modules/home/communication
    ../../modules/home/desktop
    ../../modules/home/development
    ../../modules/home/media
    ../../modules/home/security
    ../../modules/home/shell
    ../../modules/home/terminals
  ];

  home.username = "mikel";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "26.05";

  # chezmoi owns this file (and sshcontrol); HM manages only the agent/service.
  home.file."${config.programs.gpg.homedir}/gpg-agent.conf".enable = false;
}
