# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Provides set of methods to work with volume's data.
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
      # @return [Array<SMPTool::Filename>]
      #   Old and new filenames of a renamed file.
      #
      # @raise [ArgumentError]
      #   - Can't assign name `new_id` to the file since another file with
      #   the same name already exists;
      #   - File `old_id` not found.
      #
      def f_rename(old_id, new_id)
        _raise_already_exists(new_id.print_ascii) if _already_exists?(new_id.radix50)

        idx = _find_idx(old_id.radix50)

        _raise_file_not_found(old_id.print_ascii) unless idx

        self[idx].rename(new_id.radix50)

        [old_id, new_id]
      end

      #
      # Delete file from the virtual volume.
      #
      # @param [SMPTool::Filename] file_id
      #
      # @return [SMPTool::Filename]
      #   Filename of deleted file.
      #
      # @raise [ArgumentError]
      #   - File with `file_id` not found.
      #
      def f_delete(file_id)
        idx = _find_idx(file_id.radix50)

        _raise_file_not_found(file_id.print_ascii) unless idx

        self[idx].clean

        file_id
      end

      #
      # Consolidate all free space at the end of the volume.
      #
      # @return [Integer] n_free_clusters
      #   Number of free clusters that were joined.
      #
      def squeeze
        n_free_clusters = calc_n_free_clusters

        return n_free_clusters if n_free_clusters.zero?

        reject!(&:empty_entry?)

        push_empty_entry(n_free_clusters)

        n_free_clusters
      end

      #
      # Calculate total number of free clusters.
      #
      # @return [Integer]
      #
      def calc_n_free_clusters
        self.select(&:empty_entry?)
            .sum(&:n_clusters)
      end

      #
      # Append a file.
      #
      # @param [SMPTool::VirtualVolume::DataEntry] file
      #
      # @return [VolumeData] self
      #
      def f_push(file)
        _raise_already_exists(file.ascii_filename) if _already_exists?(file.filename)

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

      #
      # <Description>
      #
      # @param [Integer] n_clusters
      #   Number of clusters to add (pos. int.) or to trim (neg. int.).
      #
      # @return [Integer] n_clusters
      #   Number of clusters that were added/trimmed.
      #
      def resize(n_clusters)
        n_free_clusters = calc_n_free_clusters
        diff = n_free_clusters + n_clusters

        if reject(&:empty_entry?).empty? && diff < 1
          raise ArgumentError, "Can't trim: volume should keep at least one empty/file entry"
        end

        reject!(&:empty_entry?)
        push_empty_entry(diff) unless diff.zero?

        n_clusters
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

      def _raise_file_not_found(filename)
        raise ArgumentError, "File '#{filename}' not found on the volume."
      end

      def _raise_already_exists(filename)
        raise ArgumentError, "File with the filename '#{filename}' already exists on the volume."
      end

      #
      # Check if file with the Radix-50 filename `file_id` already exists.
      #
      # @param [Array<Integer>] file_id
      #   RADIX-50 filename.
      #
      # @return [Boolean]
      #
      def _already_exists?(file_id)
        idx = _find_idx(file_id)
        idx.nil? ? false : true
      end

      #
      # Find index of a file with the Radix-50 filename `file_id`.
      #
      # @param [Array<Integer>] file_id
      #   RADIX-50 filename.
      #
      # @return [Integer, nil]
      #
      def _find_idx(file_id)
        find_index { |e| e.filename == file_id }
      end
    end
  end
end
