STDOUT.sync = true

# stdlib
require "benchmark"
require "fileutils"
require "optparse"
require "open3"
require "shellwords"
require "digest/sha1"

# 3rd party
require "active_support"
require "active_support/core_ext"
require "active_support/time_with_zone"
begin ; require "pry" ; rescue LoadError ; end
require "httparty"
require "thor"

# lib
require "configmonkey_cli/version"
require "configmonkey_cli/helper"
require "configmonkey_cli/application/core"
require "configmonkey_cli/application/output_helper"
require "configmonkey_cli/application/colorize"
require "configmonkey_cli/application/manifest"
require "configmonkey_cli/application/configuration"
require "configmonkey_cli/application/dispatch"
require "configmonkey_cli/application"

# actions
require "configmonkey_cli/application/manifest_actions/base"
require "configmonkey_cli/application/manifest_actions/chmod"
require "configmonkey_cli/application/manifest_actions/copy"
require "configmonkey_cli/application/manifest_actions/custom"
require "configmonkey_cli/application/manifest_actions/inplace"
require "configmonkey_cli/application/manifest_actions/invoke"
require "configmonkey_cli/application/manifest_actions/link"
require "configmonkey_cli/application/manifest_actions/mkdir"
require "configmonkey_cli/application/manifest_actions/rsync"
require "configmonkey_cli/application/manifest_actions/remove"
require "configmonkey_cli/application/manifest_actions/rtfm"
require "configmonkey_cli/application/manifest_actions/sync_links"
require "configmonkey_cli/application/manifest_actions/template"
