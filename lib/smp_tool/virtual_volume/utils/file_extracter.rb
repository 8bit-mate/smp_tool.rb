# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Extracts files.
      #
      class FileExtracter
        def initialize(data)
          @data = data.reject { |e| e.status == EMPTY_ENTRY }
        end

        #
        # Extract file as is.
        #
        # @param [Filename] file_id
        #
        # @return [FileInterface]
        #
        def f_extract_raw(file_id)
          FileInterface.new(
            filename: file_id.print_ascii,
            data: _extract_raw_data(file_id)
          )
        end

        #
        # Extract file as array of strings.
        #
        # @param [Filename] file_id
        #
        # @yield [str]
        #
        # @return [FileInterface]
        #
        def f_extract_txt(file_id, &block)
          FileInterface.new(
            filename: file_id.print_ascii,
            data: _text_data(file_id, &block)
          )
        end

        private

        #
        # Extract file content as an array of strings.
        #
        # @param [Filename] id
        #
        # @yield [str]
        #
        # @return [Array<Strings>]
        #   Line by line content of the file.
        #
        def _text_data(id, &block)
          _payload(id).split("\r\n")
                      .reject(&:empty?)
                      .map(&block)
        end

        #
        # Return payload of a file.
        #
        # @param [Filename] id
        #
        # @return [String]
        #
        def _payload(id)
          _extract_raw_data(id).split(/\x00/).first
        end

        #
        # Extract raw data of a file.
        #
        # @param [Filename]
        #
        # @return [String]
        #
        def _extract_raw_data(id)
          index = @data.find_index { |e| e.filename == id.radix50 }

          raise ArgumentError, "File '#{id.ascii}' not found in the volume." unless index

          @data[index].data
        end
      end
    end
  end
end
