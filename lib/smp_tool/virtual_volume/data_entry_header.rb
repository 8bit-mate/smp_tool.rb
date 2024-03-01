# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Header of a 'virtual' data entry.
    #
    class DataEntryHeader
      attr_reader :status, :n_clusters, :ch_job, :date, :extra_word

      def initialize(params)
        @status = params[:status]
        @filename = Filename.new(radix50: params[:filename])
        @n_clusters = params[:n_clusters]
        @ch_job = params[:ch_job]
        @date = params[:date]
        @extra_word = params[:extra_word] || Basic10::ENTRY_EXTRA_WORD
      end

      def snapshot
        {
          status: _status_snapshot,
          filename: @filename.print_ascii,
          n_clusters: @n_clusters,
          ch_job: @ch_job,
          date: @date,
          extra_word: @extra_word
        }
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

      def clean
        make_empty

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

      def _status_snapshot
        case @status
        when EMPTY_ENTRY
          "empty"
        when PERM_ENTRY
          "file"
        else
          "unknown"
        end
      end

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
