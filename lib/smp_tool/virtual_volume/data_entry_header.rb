# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Header of a 'virtual' data entry.
    #
    class DataEntryHeader
      extend Forwardable

      # def_delegator :@filename, :radix50, :filename

      attr_reader :status, :n_clusters, :ch_job, :date, :extra_word

      def initialize(raw_dir_entry)
        @status = raw_dir_entry.status
        @filename = Filename.new(radix50: raw_dir_entry.filename)
        @n_clusters = raw_dir_entry.n_clusters
        @ch_job = raw_dir_entry.ch_job
        @date = raw_dir_entry.date
        @extra_word = raw_dir_entry.extra_word
      end

      def filename
        @filename.radix50
      end

      def make_permanent
        @status = PERM_ENTRY

        self
      end

      def make_empty
        @status = EMPTY_ENTRY

        self
      end

      def clean_filename
        @filename = _new_filename(
          [PAD_WORD, PAD_WORD, PAD_WORD]
        )

        self
      end

      def rename(new_radix_id)
        @filename = _new_filename(
          new_radix_id
        )

        self
      end

      private

      def _new_filename(radix50_id)
        Filename.new(radix50: radix50_id)
      end
    end
  end
end
