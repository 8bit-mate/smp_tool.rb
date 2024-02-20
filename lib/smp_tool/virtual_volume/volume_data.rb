# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Provides additional features for the Volume#data.
    #
    class VolumeData < SimpleDelegator
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
      #   - File `old_id` not found.
      #
      def delete_file(file_id)
        idx = _find_idx(file_id)

        _raise_file_not_found(file_id) unless idx

        self[idx].clean

        self
      end

      private

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
