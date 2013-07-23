
# OOZOUBOT Mk.II

See the [original hubot README][0] for hubot setup information. You might also wants to
checkout [hipchat hubot adapter README][1].

Below are information (very) specific to our setup:

### RUNNING LOCALLY

Runs `make`, this should prompts you to enter all the credentials needed to connect to
HipChat. Entered values will be saved into a file called `Makefile.vars`. Should you make
any mistake, you can run `make init` again to re-initialize.

Once this is done `make` again should now starts the bot and have it connects to the
configured chatrooms.

### ADDING A SCRIPT

Make sure you follow these steps when adding a new script:

1. Adds the script file to the `/scripts` folder or install the needed npm module.
2. Run `make` and test to make sure that your script works.
   * In most cases, you will need additional dependencies. Install them via the standard
     `npm install package_name_here --save` (make sure not to forget the `--save`).
3. Adds your scripts and **also** add `package.json` so all the scripts' dependencies are
   also properly recorded so other people can properly use the bot later on.

[0]: README-HUBOT.md
[1]: https://github.com/hipchat/hubot-hipchat/blob/master/README.md

