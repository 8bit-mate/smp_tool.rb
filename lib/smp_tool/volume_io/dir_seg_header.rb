# frozen_string_literal: true

module SMPTool
  module VolumeIO
    #
    # Directory segment header. See Table 1-2: Directory Segment Header Words [DEC].
    #
    # Notes:
    # - word #4 should be set to 0x0000 for the BASIC v.1.0, 0x0002 for the BASIC v.2.0.
    # - word #5 allows to use only one cluster for the entire directory.
    #
    class DirSegHeader < BinData::Record
      endian :little

      uint16le :n_dir_segs                    # The total number of segments in this directory.
      uint16le :i_next_seg                    # The index of the next logical directory segment.
      uint16le :i_high_seg,                   # The index of the highest segment currently in use.
               initial_value: 1
      uint16le :n_extra_bytes_per_entry       # The number of extra bytes per directory entry, an even number.
      uint16le :data_offset                   # The block number where the actual stored data begins.
    end
  end
end
