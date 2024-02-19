# frozen_string_literal: true

module SMPTool
  module VolumeIO
    class FileContent < BinData::String
      default_parameter read_length: -> { all_entries.to_a[index].n_clusters * CLUSTER_SIZE }
      default_parameter pad_byte: PAD_BYTE
    end
  end
end
