# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts hashes to data entry objects.
      #
      module FileConverter
        class << self
          private

          def _calc_n_clusters(str)
            (str.length.to_f / CLUSTER_SIZE).ceil
          end

          def _make_header(ascii_filename, n_clusters, extra_word)
            {
              status: PERM_ENTRY,
              filename: Filename.new(ascii: ascii_filename).radix50,
              n_clusters: n_clusters,
              ch_job: DEF_CH_JOB,
              date: DEF_DATE,
              extra_word: extra_word
            }
          end

          def _make_data(data, &block)
            str = _process_lines(data, &block)
            str.ljust(_calc_n_clusters(str) * CLUSTER_SIZE, PAD_CHR)
          end

          def _process_lines(data, &block)
            data.map(&block)
                .join("\r\n")
                .prepend(0x0A.chr)
                .prepend(0x0D.chr)
                .concat(0x0D.chr)
                .concat(0x0A.chr)
                .concat(0x00.chr)
          end
        end

        def self.hash_to_data_entry(f_hash, extra_word, &block)
          data = _make_data(f_hash[:data], &block)

          header_params = _make_header(f_hash[:filename], _calc_n_clusters(data), extra_word)

          DataEntry.new(
            header: DataEntryHeader.new(header_params),
            data: data
          )
        end
      end
    end
  end
end
