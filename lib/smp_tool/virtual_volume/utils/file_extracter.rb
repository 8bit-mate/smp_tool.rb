# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Extracts file(s).
      #
      class FileExtracter
        def initialize(data)
          @data = data.reject { |e| e.status == EMPTY_ENTRY }
        end

        def f_extract(*file_ids)
          file_ids.map do |id|
            _f_extract(id)
          end
        end

        private

        def _f_extract(id)
          index = @data.find_index { |e| e.filename == id.radix50 }

          raise ArgumentError, "File '#{id.ascii}' not found in the volume." unless index

          { filename: id.print_ascii("."), data: @data[index].data }
        end
      end
    end
  end
end
