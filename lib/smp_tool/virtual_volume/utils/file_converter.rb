# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts hashes to data entry objects.
      #
      class FileConverter
        def initialize(f_hash, extra_word, &block)
          str = _process_data(f_hash[:data], &block)
          @n_clusters = _calc_n_clusters(str)
          @data = str.ljust(@n_clusters * CLUSTER_SIZE, PAD_CHR)

          @filename = f_hash[:filename]
          @extra_word = extra_word
        end

        def call
          DataEntry.new(
            header: _make_header,
            data: @data
          )
        end

        private

        def _make_header
          DataEntryHeader.new(
            status: PERM_ENTRY,
            filename: Filename.new(ascii: @filename).radix50,
            n_clusters: @n_clusters,
            ch_job: DEF_CH_JOB,
            date: DEF_DATE,
            extra_word: @extra_word
          )
        end

        def _process_data(arr, &block)
          arr.map(&block)
             .join("\r\n")
             .prepend(0x0A.chr)
             .prepend(0x0D.chr)
             .concat(0x0D.chr)
             .concat(0x0A.chr)
             .concat(0x00.chr)
        end

        def _calc_n_clusters(str)
          (str.length.to_f / CLUSTER_SIZE).ceil
        end
      end
    end
  end
end
