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

          def calc_n_clusters(str)
            (str.length.to_f / CLUSTER_SIZE).ceil
          end

          def make_header(ascii_filename, n_clusters, extra_word)
            {
              status: PERM_ENTRY,
              filename: Filename.new(ascii: ascii_filename).radix50,
              n_clusters: n_clusters,
              ch_job: DEF_CH_JOB,
              date: DEF_DATE,
              extra_word: extra_word
            }
          end

          def make_data(data, &block)
            str = data.map(&block)
                      .join("\r\n")
                      .prepend(0x0D.chr)
                      .prepend(0x0A.chr)
                      .concat(0x0D.chr)
                      .concat(0x0A.chr)
                      .concat(0x00.chr)

            str.ljust(calc_n_clusters(str) * CLUSTER_SIZE, PAD_CHR)
          end
        end

        def self.hash_to_data_entry(f_hash, extra_word, &block)
          data = make_data(f_hash[:data], &block)

          header_params = make_header(f_hash[:filename], calc_n_clusters(data), extra_word)

          DataEntry.new(
            header: DataEntryHeader.new(header_params),
            data: data
          )
        end
      end
    end
  end
end
