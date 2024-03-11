# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Header of a 'virtual' data entry.
    #
    class DataEntryHeader
      attr_reader :filename, :status, :n_clusters, :ch_job, :date, :extra_word

      def initialize(params)
        @status = params[:status]
        @filename = params[:filename]
        @n_clusters = params[:n_clusters]
        @ch_job = params[:ch_job]
        @date = params[:date]
        @extra_word = params[:extra_word] || Basic10::ENTRY_EXTRA_WORD
      end

      def print_ascii_filename
        Filename.new(radix50: @filename).print_ascii
      end

      def snapshot
        {
          status: _status_snapshot,
          filename: print_ascii_filename,
          n_clusters: @n_clusters,
          ch_job: @ch_job,
          date: @date,
          extra_word: @extra_word
        }
      end

      def resize(new_size)
        @n_clusters = new_size
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

        rename(
          [PAD_WORD, PAD_WORD, PAD_WORD]
        )
      end

      def rename(new_radix_id)
        @filename = new_radix_id
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
      end
    end
  end
end
