# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Simplified Ruby representation of the volume.
    #
    class Volume
      extend Forwardable

      def_delegators :@data, :squeeze

      attr_reader :data

      def initialize(volume_params:, volume_data:)
        @bootloader = volume_params[:bootloader]
        @home_block = volume_params[:home_block]
        @n_clusters_allocated = volume_params[:n_clusters_allocated]
        @n_extra_bytes_per_entry = volume_params[:n_extra_bytes_per_entry]
        @n_clusters_per_dir_seg = volume_params[:n_clusters_per_dir_seg]
        @n_max_entries_per_dir_seg = volume_params[:n_max_entries_per_dir_seg]
        @n_dir_segs = volume_params[:n_dir_segs]
        @n_max_entries = @n_dir_segs * @n_max_entries_per_dir_seg
        @data = volume_data
      end

      def to_raw_volume
        Utils::ConverterToRawVolume.new(
          _volume_params,
          @data
        ).call
      end

      #
      # Extract a file by an ASCII filename.
      #
      # @param [<String>] *ascii_ids
      #   ASCII filenames.
      #
      # @return [<Type>] <description>
      #
      def extract_file(*ascii_ids)
        filenames = *ascii_ids.map { |id| Filename.new(ascii: id) }

        _extract_file(*filenames)
      end

      def extract_all_files
        filenames = @data.reject { |e| e.status == EMPTY_ENTRY }
                         .map { |e| Filename.new(radix50: e.filename) }

        _extract_file(*filenames)
      end

      #
      # Rename file.
      #
      # @param [<String>] old_filename
      # @param [<String>] new_filename
      #
      # @return [Volume] self
      #
      def rename_file(old_filename, new_filename)
        @data.rename_file(
          Filename.new(ascii: old_filename),
          Filename.new(ascii: new_filename)
        )

        self
      end

      #
      # Delete file.
      #
      # @param [<String>] filename
      #
      # @return [Volume] self
      #
      def delete_file(filename)
        @data.delete_file(Filename.new(ascii: filename))

        self
      end

      private

      def _extract_file(*filenames)
        Utils::FileExtracter.new(@data).extract_file(*filenames)
      end

      def _volume_params
        {
          bootloader: @bootloader,
          home_block: @home_block,
          n_clusters_allocated: @n_clusters_allocated,
          n_extra_bytes_per_entry: @n_extra_bytes_per_entry,
          n_clusters_per_dir_seg: @n_clusters_per_dir_seg,
          n_max_entries_per_dir_seg: @n_max_entries_per_dir_seg,
          n_dir_segs: @n_dir_segs
        }
      end
    end
  end
end
