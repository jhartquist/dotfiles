{ user, ... }:

{
  home.homeDirectory = "/Users/${user}";

  # All SSH auth goes through 1Password's agent — keys live in the vault
  # (biometric-gated, synced), never as files in ~/.ssh.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*".IdentityAgent =
      ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
  };
}
