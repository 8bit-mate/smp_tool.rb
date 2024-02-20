# frozen_string_literal: true

module SMPTool
  module VolumeIO
    #
    # Volume data.
    #
    class Data < BinData::Array
      default_parameter read_until: -> { index == all_entries.length - 1 }

      file_content
    end
  end
end
