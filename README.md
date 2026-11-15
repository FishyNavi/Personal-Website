# My personal website!
That's a very cool and amazing website ~~(partially because it's mine)~~ 
[Check it out!](https://cynamondev.com/) 

The website is built on [Astro](https://astro.build/) framework. Mobile support is not added yet but will be done in future.

### Features checklist:
- [x] The website
- [x] Blogs
- [x] Mobile support(Kinda)
- [ ] Music player?
- [ ] Dark/Light mode switch
- [x] Automated \<img> tag replacement
- [x] Statistics

## Build
### Depencdencies: 
- nodejs_22
```
git clone https://github.com/FishyNavi/Personal-Website.git
cd Personal-Website/website

nix develop # if using nix. 

npm install
npm run build

```
### Deployment:
include:
```nix
imports = [
  # ...
  (builtins.getFlake "github:FishyNavi/Personal-Website/main?dir=nix/website").nixosModules.default
];
  
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  auto-optimise-store = true;
};

security.acme = {
  acceptTerms = true;
  defaults.email = "mail";
};
services.nginx.enable = true;

services.personal-website = {
  enable = true;
  domain = "cynamondev.com";
  repoUrl = "https://github.com/FishyNavi/Personal-Website.git"; 
  branch = "main";
};
```
into `configuration.nix` on host machine
