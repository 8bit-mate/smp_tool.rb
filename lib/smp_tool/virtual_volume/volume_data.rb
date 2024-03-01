# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Provides additional features for the Volume#data.
    #
    class VolumeData < SimpleDelegator
      def initialize(obj, extra_word)
        @obj = obj
        @extra_word = extra_word

        super(obj)
      end

      def snapshot
        map(&:snapshot)
      end

      #
      # Rename file on the virtual volume.
      #
      # @param [SMPTool::Filename] old_id
      # @param [SMPTool::Filename] new_id
      #
      # @return [VolumeData] self
      #
      # @raise [ArgumentError]
      #   - Can't assign name `new_id` to the file since another file with
      #   the same name already exists;
      #   - File `old_id` not found.
      #
      def f_rename(old_id, new_id)
        if _already_exists?(new_id)
          raise ArgumentError, "Can't rename file: file '#{new_id.print_ascii}' already exists on the volume"
        end

        idx = _find_idx(old_id)

        _raise_file_not_found(old_id) unless idx

        self[idx].rename(new_id.radix50)

        self
      end

      #
      # Delete file from the virtual volume.
      #
      # @param [SMPTool::Filename] file_id
      #
      # @return [VolumeData] self
      #
      # @raise [ArgumentError]
      #   - File `file_id` not found.
      #
      def f_delete(file_id)
        idx = _find_idx(file_id)

        _raise_file_not_found(file_id) unless idx

        self[idx].clean

        self
      end

      #
      # Consolidate all free space at the end of the volume.
      #
      def squeeze
        n_free_clusters = calc_n_free_clusters

        return self if n_free_clusters.zero?

        reject!(&:empty_entry?)

        push_empty_entry(n_free_clusters)

        self
      end

      def calc_n_free_clusters
        self.select(&:empty_entry?)
            .sum(&:n_clusters)
      end

      #
      # Append a file.
      #
      def f_push(file)
        # We're starting from the end of the array, since free space tend to locate
        # at the end of the volume (esp. after the 'squeeze' command).
        idx = index(reverse_each.detect { |e| e.n_clusters >= file.n_clusters && e.empty_entry? })

        unless idx
          raise ArgumentError,
                "no free space found to fit the file (try to squeeze, delete files or allocate more clusters)"
        end

        _f_push(file, idx)

        self
      end

      def push_empty_entry(n_free_clusters)
        push(_new_empty_entry(n_free_clusters))

        self
      end

      def trim
        n_free_clusters = calc_n_free_clusters

        reject!(&:empty_entry?)

        n_free_clusters
      end

      private

      def _new_empty_entry(n_free_clusters)
        DataEntry.new(
          header: DataEntryHeader.new(
            _free_entry_header_params(n_free_clusters)
          ),
          data: PAD_CHR * (n_free_clusters * CLUSTER_SIZE)
        )
      end

      def _f_push(file, idx)
        n_clusters_left = self[idx].n_clusters - file.n_clusters

        insert(idx, file)
        delete_at(idx + 1)

        return if n_clusters_left.zero?

        insert(-idx, _new_empty_entry(n_clusters_left))
      end

      def _free_entry_header_params(n_clusters)
        {
          status: EMPTY_ENTRY,
          filename: [PAD_WORD, PAD_WORD, PAD_WORD],
          n_clusters: n_clusters,
          ch_job: DEF_CH_JOB,
          date: DEF_DATE,
          extra_word: @extra_word
        }
      end

      def _raise_file_not_found(file_id)
        raise ArgumentError, "File '#{file_id.print_ascii}' not found on the volume"
      end

      def _already_exists?(file_id)
        idx = _find_idx(file_id)
        idx.nil? ? false : true
      end

      def _find_idx(file_id)
        find_index { |e| e.filename == file_id.radix50 }
      end
    end
  end
end
