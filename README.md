# [Lunatic runtime] flake

**Try without installing**

```bash
$ nix run github:tqwewe/lunatic-flake
# Or
$ nix run github:tqwewe/lunatic-flake#unstable
```

**Enter dev shell with lunatic and rust `1.66.1`**

```bash
$ nix develop github:tqwewe/lunatic-flake
# Or
$ nix develop github:tqwewe/lunatic-flake#unstable
```

**Install in flake**

```nix
{
  inputs = {
    lunatic.url = "github:tqwewe/lunatic-flake";
  };

  # Add to system packages
  systemPackages = [ inputs.lunatic.packages.x86_64-linux.default ];

  # Or add to home manager packages
  home.packages = [ inputs.lunatic.packages.x86_64-linux.default ];

  # Unstable can be used with inputs.lunatic.packages.x86_64-linux.unstable
}
```

[lunatic runtime]: https://github.com/lunatic-solutions/lunatic
