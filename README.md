# Configmonkey CLI

Configmonkey is a very simple tool to "deploy" configurations on servers. Chef/Puppet for the brainless.

---

## Help
If you need help or have problems [open an issue](https://github.com/2called-chaos/configmonkey_cli/issues/new).


## Features

  * …


## ToDo

  * logging
  * manifest generation
  * [add something to the list](https://github.com/2called-chaos/configmonkey_cli/issues/new)


## Requirements

  * Ruby (>= 2.6)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others), sorry Windows
  * config files


## Installation

  * `gem install configmonkey_cli`
  * Go into a folder with your configs (manage them in sub folders)
  * ~~`configmonkey --generate-manifest`~~
  * ~~Edit the created file manifest.rb to fit your needs~~
  * Run `configmonkey -h`
  * Check out the additional features below


## Usage

To get a list of available options invoke Configmonkey with the `--help` or `-h` option:

    Usage: configmonkey [options]
    # Application options
            --generate-manifest          Generates an example manifest in current directory
        -a, --accept                     accept all defaults
        -b, --bell                       ring a bell when asked
        -D, --diff                       change default diff tool
        -f, --fake-host HOST             override hostname
        -i, --in DIR                     operate from this source directory instead of pwd
        -o, --out DIR                    operate on this target directory instead of /
        -l, --log [file]                 Log changes to file, defaults to ~/.configmonkey/logs/configmonkey.log
        -M, --merge                      change default merge tool
        -n, --dry-run                    Simulate changes only, does not perform destructive operations
        -y, --yes                        accept all prompts with yes
            --dev-dump-actions           Dump actions and exit

    # General options
        -d, --debug [lvl=1]              Enable debug output
        -m, --monochrome                 Don't colorize output
        -h, --help                       Shows this help
        -v, --version                    Shows version and other info
        -z                               Do not check for updates on GitHub (with -v/--version)

## Application configuration

…


## Contributing

  Contributions are very welcome! Either report errors, bugs and propose features or directly submit code:

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request

  This might be helpful: `./bin/configmonkey.sh -nd 120 -i ./dev/gamesplanet-config -o ./dev/servers/www3 -f www3`


## Legal

* © 2020, Sven Pachnit (www.bmonkeys.net)
* configmonkey_cli is licensed under the MIT license.
