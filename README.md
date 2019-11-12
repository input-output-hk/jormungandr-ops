# Deployment Tips

* File `.envrc` needs to be created for each deployment.  See examples dir.
* Run `direnv allow` to enable direnv to load the `.envrc` file
* File `globals.nix` needs to be created for each deployment.  See examples dir.
* File `deployments/${NIXOPS_DEPLOYMENT}.nix` needs to be created for the deployment.
* File `clusters/${NIXOPS_DEPLOYMENT}.nix` needs to be created for the deployment.
* Niv update any source repos as needed
* Create the secrets dir populated with any required secrets
* Create the static dir and populate with any required keys using the `genesis-generator` tool
* Update the public IDs in the secrets dir with the `scripts/update-jormungandr-public-ids.rb` tool
* Create the nixops clusters with the required params:

```
nixops create -d $NIXOPS_DEPLOYMENT -I nixpkgs=./nix deployments/${NIXOPS_DEPLOYMENT}.nix
nixops set-args --arg globals 'import ./globals.nix'
```

* Deploy as needed, utilizing scripts from the `scripts` folder if desired
