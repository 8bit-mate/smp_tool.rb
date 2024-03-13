# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Virtual volume parameters.
    #
    class VolumeParams
      attr_accessor :n_clusters_allocated

      attr_reader :n_extra_bytes_per_entry, :n_dir_segs,
                  :n_clusters_per_dir_seg, :extra_word, :n_max_entries_per_dir_seg,
                  :n_max_entries

      def initialize(
        n_clusters_allocated:,
        n_extra_bytes_per_entry:,
        n_dir_segs:,
        n_clusters_per_dir_seg:,
        extra_word:
      )
        @n_clusters_allocated = n_clusters_allocated
        @n_extra_bytes_per_entry = n_extra_bytes_per_entry
        @n_dir_segs = n_dir_segs
        @n_clusters_per_dir_seg = n_clusters_per_dir_seg
        @extra_word = extra_word

        _validate_input

        @n_max_entries_per_dir_seg = _calc_n_max_entries_per_dir_seg
        @n_max_entries = @n_dir_segs * @n_max_entries_per_dir_seg
      end

      def snapshot
        {
          n_clusters_allocated: @n_clusters_allocated,
          n_extra_bytes_per_entry: @n_extra_bytes_per_entry,
          n_dir_segs: @n_dir_segs,
          n_clusters_per_dir_seg: @n_clusters_per_dir_seg,
          extra_word: @extra_word,
          n_max_entries_per_dir_seg: @n_max_entries_per_dir_seg,
          n_max_entries: @n_max_entries
        }
      end

      private

      def _validate_input
        result = VolumeParamsContract.new.call(_input_snapshot)

        raise ArgumentError, result.errors.to_h.to_a.join(": ") unless result.success?
      end

      def _input_snapshot
        {
          n_clusters_allocated: @n_clusters_allocated,
          n_extra_bytes_per_entry: @n_extra_bytes_per_entry,
          n_dir_segs: @n_dir_segs,
          n_clusters_per_dir_seg: @n_clusters_per_dir_seg,
          extra_word: @extra_word
        }
      end

      def _calc_n_max_entries_per_dir_seg
        entry_size = ENTRY_BASE_SIZE + @n_extra_bytes_per_entry
        (((@n_clusters_per_dir_seg * CLUSTER_SIZE) - HEADER_SIZE - FOOTER_SIZE) / entry_size).floor
      end
    end
  end
end
