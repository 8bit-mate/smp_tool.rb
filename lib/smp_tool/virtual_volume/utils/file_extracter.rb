# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Extracts file.
      #
      class FileExtracter
        def initialize(data)
          @data = data.reject { |e| e.status == EMPTY_ENTRY }
        end

        def extract_file(*file_ids)
          file_ids.map do |id|
            _extract_file(id)
          end
        end

        private

        def _extract_file(id)
          index = @data.find_index { |e| e.filename == id.radix50 }

          raise ArgumentError, "File '#{id.ascii}' not found in the volume." unless index

          { filename: id.ascii, content: @data[index].data }
        end
      end
    end
  end
end
