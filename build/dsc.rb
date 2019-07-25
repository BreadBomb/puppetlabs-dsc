require 'json'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'erb'
require 'open-uri'
require 'find'
require 'logger'

# Bundler group 'build'
if Bundler.rubygems.find_name('mof').any?
  require 'mof'
  require 'cim'
  require 'charlock_holmes/string'
end

# Debug
require 'pry' if Bundler.rubygems.find_name('pry').any?

LIB_PATH = File.dirname(__FILE__)

require "#{LIB_PATH}/dsc/version"
require "#{LIB_PATH}/dsc/mof"
require "#{LIB_PATH}/dsc/property"
require "#{LIB_PATH}/dsc/resource"
require "#{LIB_PATH}/dsc/psmodule"
require "#{LIB_PATH}/dsc/manager"
require "#{LIB_PATH}/dsc/typebuilder"
require "#{LIB_PATH}/dsc/typecleaner"
require "#{LIB_PATH}/dsc/typeimporter"
require "#{LIB_PATH}/dsc/documentbuilder"

# Empty declaration for builder
module Dsc
end
