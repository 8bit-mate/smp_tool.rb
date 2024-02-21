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
      def rename_file(old_id, new_id)
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
      def delete_file(file_id)
        idx = _find_idx(file_id)

        _raise_file_not_found(file_id) unless idx

        self[idx].clean

        self
      end

      #
      # Consolidate all free space at the end of the volume.
      #
      def squeeze
        n_free_clusters = self.select(&:empty_entry?)
                              .sum(&:n_clusters)

        return self if n_free_clusters.zero?

        reject!(&:empty_entry?)

        _append_empty_entry(n_free_clusters)

        self
      end

      private

      def _append_empty_entry(n_free_clusters)
        _append_entry(
          DataEntryHeader.new(
            _free_entry_header_params(n_free_clusters)
          ),
          PAD_CHR * (n_free_clusters * CLUSTER_SIZE)
        )
      end

      def _append_entry(header, data)
        append(
          DataEntry.new(
            header: header,
            data: data
          )
        )
      end

      def _free_entry_header_params(n_clusters)
        Struct.new(:status, :filename, :n_clusters, :ch_job, :date, :extra_word)
              .new(
                status: EMPTY_ENTRY,
                filename: [PAD_WORD, PAD_WORD, PAD_WORD],
                n_clusters: n_clusters,
                ch_job: DEF_CH_JOB,
                date: DEF_DATE,
                extra_word: @extra_word
              )
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
