# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Header of a 'virtual' data entry.
    #
    class DataEntryHeader
      attr_reader :status, :n_clusters, :ch_job, :date, :extra_word

      def initialize(parameters)
        @status = parameters.status
        @filename = Filename.new(radix50: parameters.filename)
        @n_clusters = parameters.n_clusters
        @ch_job = parameters.ch_job
        @date = parameters.date
        @extra_word = parameters.extra_word
      end

      def resize(new_size)
        @n_clusters = new_size
      end

      def filename
        @filename.radix50
      end

      def permanent_entry?
        @status == PERM_ENTRY
      end

      def empty_entry?
        @status == EMPTY_ENTRY
      end

      def make_permanent
        _set_status(PERM_ENTRY)
      end

      def make_empty
        _set_status(EMPTY_ENTRY)
      end

      def clean_filename
        _new_filename(
          [PAD_WORD, PAD_WORD, PAD_WORD]
        )
      end

      def rename(new_radix_id)
        _new_filename(
          new_radix_id
        )
      end

      private

      def _set_status(new_status)
        @status = new_status

        self
      end

      def _new_filename(radix50_id)
        @filename = Filename.new(radix50: radix50_id)

        self
      end
    end
  end
end
