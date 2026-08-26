{ pkgs, user, ... }:

{
  # Determinate's daemon owns /etc/nix/nix.conf and the nix daemon; nix-darwin
  # must not manage nix, or activation aborts. This makes all nix.* options inert.
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";
  system.stateVersion = 6;

  # The comprehensive-Mac layer. Grows over time; add settings incrementally.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;             # fast key repeat
      InitialKeyRepeat = 15;     # short delay before repeat kicks in
      AppleShowAllExtensions = true;

      # Kill macOS's automatic text meddling (autocorrect, smart quotes, etc.).
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
    };
    dock.autohide = true;
    dock.show-recents = false;   # keep the curated dock from filling up with recents
    # This list IS the pinned dock — declaring it drops Safari/Mail/etc.
    dock.persistent-apps = [
      "/Applications/Google Chrome.app"
      "/Applications/Obsidian.app"
      "/Applications/WezTerm.app"
      "/System/Applications/System Settings.app"
    ];
    dock.persistent-others = [ ];  # no folders/stacks on the right side
    menuExtraClock.ShowSeconds = true;     # menu bar clock with seconds
    controlcenter.BatteryShowPercentage = true;
    finder.AppleShowAllFiles = true;       # show hidden files; relaunch Finder to see it
    finder.FXPreferredViewStyle = "Nlsv";  # list view
    finder.CreateDesktop = false;          # no icons on the desktop
    WindowManager.StandardHideWidgets = true;  # no widgets on the desktop either
    trackpad.Clicking = true;              # tap to click

    # "Show Input menu in menu bar" off — no dedicated nix-darwin option for it.
    CustomUserPreferences."com.apple.TextInputMenu".visible = false;
  };

  # Never sleep on idle (applies to both battery and AC — systemsetup has no
  # per-source setting) so long-running agents stay active. The display still
  # sleeps on its own schedule, and closing the lid still sleeps the machine.
  power.sleep.computer = "never";

  # Swap ⌘ and ⌥ on the external MX Keys ONLY (its Bolt receiver is 0x46d/0xc548),
  # so the physical Alt/Start cluster matches an Apple keyboard's ⌥/⌘ order. Done
  # as a device-scoped hidutil agent rather than nix-darwin's
  # system.keyboard.userKeyMapping, because that option is global and would also
  # swap the built-in MacBook keyboard. 0x7000000E3 = left ⌘, 0x7000000E2 = left ⌥.
  launchd.user.agents.mx-keys-swap-cmd-option.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/hidutil" "property"
      "--matching" ''{"VendorID":0x46D,"ProductID":0xC548}''
      "--set" ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E3,"HIDKeyboardModifierMappingDst":0x7000000E2},{"HIDKeyboardModifierMappingSrc":0x7000000E2,"HIDKeyboardModifierMappingDst":0x7000000E3}]}''
    ];
    RunAtLoad = true;
  };

  # nix-homebrew installs and owns Homebrew itself — nothing installs brew
  # imperatively. autoMigrate lets it adopt this machine's pre-existing
  # imperative install; it's a no-op on a fresh machine (nothing to migrate).
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };

  # nix-darwin declares packages; nix-homebrew provides the brew they run against.
  # cleanup = "zap" removes anything not declared here on every switch, keeping
  # this file the single source of truth for what's installed.
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    # herdr: not in nixpkgs 26.05; formula tracks upstream better anyway.
    brews = [ "herdr" ];
    casks = [
      "codex"                  # OpenAI's terminal coding agent
      "google-chrome"
      "wezterm"
      "raycast"
      "obsidian"
      "spotify"
      "wispr-flow"           # voice dictation
      "1password"              # desktop app
      "1password-cli"          # `op` — secrets never live in this repo
      "tailscale-app"          # GUI menu-bar app (bundles tailscaled)
      "ilok-license-manager"   # the Neural DSP plugin itself is a manual, licensed download
    ];
  };

  # Installed system-wide (the macOS-correct path); wezterm renders in it.
  fonts.packages = [ pkgs.nerd-fonts.hack ];
}
