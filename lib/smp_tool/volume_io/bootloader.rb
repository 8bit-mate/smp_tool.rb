# frozen_string_literal: true

module SMPTool
  module VolumeIO
    #
    # Bootloader.
    #
    class Bootloader < BinData::Record
      endian :little

      array :bytes, initial_length: -> { CLUSTER_SIZE } do
        uint8
      end

      # string :padding, length: -> { CLUSTER_SIZE - padding.rel_offset }, pad_byte: PAD_BYTE
    end
  end
end
