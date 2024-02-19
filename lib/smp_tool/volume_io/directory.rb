# frozen_string_literal: true

require_relative "dir_seg"

module SMPTool
  module VolumeIO
    #
    # From the DEC's manual [DEC]:
    #
    # The directory consists of a series of two-block segments. Each segment is 512 words
    # long and contains information about files such as name, length, and creation date.
    #
    class Directory < BinData::Record
      endian :little

      # Last dirseg should set 'i_next_seg' word in the header to 0,
      # so that indicates the last segment in the directory.
      array :segments, read_until: -> { element.header.i_next_seg.zero? } do
        dir_seg
      end

      # Total number of entries (from all dirsegs) in this dir.
      virtual :n_entries, initial_value: -> { segments.to_ary.sum(&:n_entries) }
    end
  end
end
