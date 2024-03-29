# frozen_string_literal: true

require "bindata"
require "delegate"
require "dec_radix_50"
require "dry/validation"
require "forwardable"
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
  PAD_CHR = PAD_BYTE.chr.freeze
  PAD_WORD = 0x2020

  # Sizes, in clusters:
  N_SYS_CLUSTERS = 2 # Bootloader + home block.
  N_CLUSTERS_PER_DIR_SEG = 2
  N_CLUSTERS_MAX = 127

  # Sizes, in bytes:
  CLUSTER_SIZE = 512
  HEADER_SIZE = 10
  FOOTER_SIZE = 2
  ENTRY_BASE_SIZE = 14

  # Sizes, in 16-bit words:
  RAD50_FN_SIZE = 3 # RADIX-50 filename size.

  # Directory entry status codes.
  EMPTY_ENTRY = 0x0200    # Empty entry.
  PERM_ENTRY = 0x0400     # Permanent file (occupied entry).
  DIR_SEG_FOOTER = 0x0800 # Directory segment footer, a.k.a. end-of-segment marker.

  # Default entry attributes:
  DEF_CH_JOB = 0x0000
  DEF_DATE = 0xFFFF
end
