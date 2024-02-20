# frozen_string_literal: true

require_relative "bootloader"
require_relative "home_block"
require_relative "directory"
require_relative "file_content"
require_relative "data"

module SMPTool
  module VolumeIO
    #
    # Full volume.
    #
    class RawVolume < BinData::Record
      #       hide :bootloader
      #       hide :home_block

      bootloader :bootloader
      home_block :home_block
      directory :directory
      data :data

      virtual :n_clusters_allocated, initial_value: -> { num_bytes / CLUSTER_SIZE }

      # Empty and permanent entries.
      virtual :all_entries,
              initial_value: lambda {
                directory.segments.flat_map(&:dir_seg_entries)
                         .reject { |e| e.status == DIR_SEG_FOOTER }
              }

      # Permanent entries (i.e. files) only.
      virtual :file_only_entries,
              initial_value: lambda {
                directory.segments.flat_map(&:dir_seg_entries)
                         .reject { |e| e.status == DIR_SEG_FOOTER }
                         .reject { |e| e.status == EMPTY_ENTRY }
              }

      virtual :n_extra_bytes_per_entry,
              initial_value: -> { directory.segments.first.header.n_extra_bytes_per_entry }

      virtual :n_max_entries_per_dir_seg,
              initial_value: -> { directory.segments.first.n_max_entries }

      virtual :n_dir_segs,
              initial_value: -> { directory.segments.length }

      virtual :n_clusters_per_dir_seg,
              initial_value: -> { directory.segments.first.n_clusters_per_dir_seg }
    end
  end
end
