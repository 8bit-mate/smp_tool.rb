# frozen_string_literal: true

require "bindata"
require "dec_radix_50"
require "dry/validation"
require "injalid_dejice"
require "zeitwerk"

require_relative "smp_tool/autoloader"
require_relative "smp_tool/version"

SMPTool::Autoloader.setup

#
# Lib to work with Elektronika MK90 bin volumes.
#
module SMPTool
  class Error < StandardError; end

end
