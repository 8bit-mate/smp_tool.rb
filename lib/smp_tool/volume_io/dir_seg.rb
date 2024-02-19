# frozen_string_literal: true

require_relative "dir_seg_header"
require_relative "dir_entry"

module SMPTool
  module VolumeIO
    #
    # A single segment from the directory.
    #
    class DirSeg < BinData::Record
      endian :little
      hide :padding

      dir_seg_header :header

      array :dir_seg_entries, read_until: -> { element.status == DIR_SEG_FOOTER } do
        dir_entry :dir_entry
      end

      virtual :n_clusters_per_dir_seg, initial_value: N_CLUSTERS_PER_DIR_SEG
      virtual :entry_size, initial_value: -> { ENTRY_BASE_SIZE + header.n_extra_bytes_per_entry }
      virtual :n_max_entries, initial_value: lambda {
        (((n_clusters_per_dir_seg * CLUSTER_SIZE) - header.num_bytes - FOOTER_SIZE) / entry_size).floor
      }

      string :padding, length: -> { n_clusters_per_dir_seg * CLUSTER_SIZE - padding.rel_offset }, pad_byte: PAD_BYTE

      # Number of entries in this dirseg:
      virtual :n_entries, initial_value: -> { dir_seg_entries.reject { |e| e.status == DIR_SEG_FOOTER }.length }
    end
  end
end
