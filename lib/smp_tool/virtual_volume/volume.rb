# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Simplified Ruby representation of the volume.
    #
    class Volume
      attr_reader :data

      class << self
        private

        def zip_volume_data(entries, data)
          VolumeData.new(
            entries.each_with_index.map do |e, i|
              DataEntry.new(
                header: DataEntryHeader.new(e),
                data: data[i]
              )
            end
          )
        end
      end

      def self.read_io(io)
        read_raw_volume(
          SMPTool::VolumeIO::RawVolume.read(io)
        )
      end

      def self.read_raw_volume(raw_volume)
        entries = raw_volume.directory.segments.to_ary.flat_map(&:dir_seg_entries)
                            .reject { |e| e.status == DIR_SEG_FOOTER }

        data = raw_volume.data.to_ary

        raise ArgumentError, "entries => data sizes mismatch" unless entries.length == data.length

        new(
          volume_params: parse_volume_params(raw_volume),
          volume_data: zip_volume_data(entries, data)
        )
      end

      def self.parse_volume_params(raw_volume)
        {
          bootloader: raw_volume.bootloader.bytes,
          home_block: raw_volume.home_block.bytes,
          n_clusters_allocated: raw_volume.n_clusters_allocated,
          n_extra_bytes_per_entry: raw_volume.n_extra_bytes_per_entry,
          n_max_entries_per_dir_seg: raw_volume.n_max_entries_per_dir_seg,
          n_dir_segs: raw_volume.n_dir_segs,
          n_clusters_per_dir_seg: N_CLUSTERS_PER_DIR_SEG
        }
      end

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
        Utils::RawVolumeInitializer.new(
          _volume_params,
          @data
        ).call
      end

      def extract_file(*file_ids)
        Utils::FileExtracter.new(@data).extract_file(*file_ids)
      end

      def extract_all_files
        file_ids = @data.reject { |e| e.status == EMPTY_ENTRY }
                        .map { |e| Filename.new(radix50: e.filename) }

        extract_file(*file_ids)
      end

      def rename_file(old_filename, new_filename)
        @data.rename_file(
          Filename.new(ascii: old_filename),
          Filename.new(ascii: new_filename)
        )
      end

      def delete_file(filename)
        @data.delete_file(
          Filename.new(ascii: filename)
        )
      end

      private

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
