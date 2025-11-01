{pkgs,inputs,username,lib,config, ...}: {

   programs = {
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      theme_background = false; # make btop transparent
    };
  };

  programs.fastfetch = { enable = true; };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = username;
        email = "taoboy03@qq.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };

    extraConfig = {
      "url.https://gh-proxy.com/github.com/:" = {
        insteadOf = "https://github.com/";
      };
    };
  };
}