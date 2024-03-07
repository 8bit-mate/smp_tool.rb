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

        #
        # Extract file(s) as is.
        #
        # @param [Array<Filename>] file_ids
        #
        # @return [Array<FileInterface>]
        #
        def f_extract_raw(file_ids)
          _f_extract(file_ids)
        end

        #
        # Extract file(s) as array of strings.
        #
        # @param [Array<Filename>] file_ids
        #
        # @yield [str]
        #
        # @return [Array<FileInterface>]
        #
        def f_extract_txt(file_ids, &block)
          ext_block = lambda { |id|
            FileInterface.new(
              filename: id.print_ascii,
              data: _text_data(id, &block)
            )
          }

          _f_extract(file_ids, &ext_block)
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
        # Extract content of each file from the `file_ids`
        #
        # @param [Array<Filename>] file_ids
        #
        # @yield [str]
        #   Each line of the file gets passed through this block. The default block
        #   returns file content as a 'raw' string (as-is). Custom block is used to
        #   split it to an array of strings, and then proccess each string.
        #
        # @return [Array<FileInterface>]
        #
        def _f_extract(file_ids, &block)
          unless block_given?
            block = lambda { |id|
              FileInterface.new(
                filename: id.print_ascii,
                data: _extract_raw_data(id)
              )
            }
          end

          file_ids.map(&block)
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
