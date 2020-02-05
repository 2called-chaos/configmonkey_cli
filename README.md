# Configmonkey CLI

Configmonkey is a very simple tool to "deploy" configurations on servers. Chef/Puppet for the brainless.

---

## Help
If you need help or have problems [open an issue](https://github.com/2called-chaos/configmonkey_cli/issues/new).


## Features

  * …


## Requirements

  * Ruby (>= 2.6)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others), sorry Windows
  * config files


## Installation

  * `gem install configmonkey_cli`
  * Go into a folder with your configs (manage them in sub folders)
  * `configmonkey --generate-manifest`
  * Edit the created file manifest.rb to fit your needs
  * Run `configmonkey`
  * Check out the additional features below


## Usage

To get a list of available options invoke Configmonkey with the `--help` or `-h` option:

    Usage: configmonkey [options]
    # Application options
            --generate-manifest [myconfig] Generates an example manifest in current folder
        ###-l, --log [file]                   Log to file, defaults to ~/.configmonkey/logs/configmonkey.log
        ###-t, --threads [NUM]                Amount of threads to be used for checking (default: 10)
        ###-s, --silent                       Only print errors and infos
        ###-q, --quiet                        Only print errors

    # General options
        ###-d, --debug [lvl=1]              Enable debug output
        ###-m, --monochrome                 Don't colorize output
        ###-h, --help                       Shows this help
        ###-v, --version                    Shows version and other info
        ###-z                               Do not check for updates on GitHub (with -v/--version)
        ###    --dump-core                  for developers


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
