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

  #
  # Documentation sources:
  #
  # 1. [DEC] http://www.bitsavers.org/pdf/dec/pdp11/rt11/v5.6_Aug91/AA-PD6PA-TC_RT-11_Volume_and_File_Formats_Manual_Aug91.pdf
  #

  PAD_BYTE = 0x20

  # Sizes, in clusters:
  N_SYS_CLUSTERS = 2 # Bootloader + home block.
  N_CLUSTERS_PER_DIR_SEG = 2

  # Sizes, in bytes:
  CLUSTER_SIZE = 512
  FOOTER_SIZE = 2
  ENTRY_BASE_SIZE = 14

  # Directory entry status codes.
  EMPTY_ENTRY = 0x0200    # Empty entry.
  PERM_ENTRY = 0x0400     # Permanent file (occupied entry).
  DIR_SEG_FOOTER = 0x0800 # Directory segment footer, a.k.a. end-of-segment marker.
end
