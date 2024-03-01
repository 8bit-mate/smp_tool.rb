# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts volume IO to the virtual volume.
      #
      module ConverterFromVolumeIO
        class << self
          private

          def zip_volume_data(entries, data, extra_word)
            VolumeData.new(
              data_entries(entries, data),
              extra_word
            )
          end

          def data_entries(entries, data)
            entries.each_with_index.map do |e, i|
              DataEntry.new(
                header: DataEntryHeader.new(e.snapshot.to_h),
                data: data[i]
              )
            end
          end

          # Extra word value is defined by the target BASIC version,
          # and the target BASIC version can be identified by the
          # number of extra bytes per entry (and vice versa).
          def choose_extra_word(n_extra_bytes_per_entry)
            case n_extra_bytes_per_entry
            when 0
              Basic10::ENTRY_EXTRA_WORD
            else
              Basic20::ENTRY_EXTRA_WORD
            end
          end

          def parse_volume_params(volume_io)
            {
              bootloader: volume_io.bootloader.bytes.to_ary,
              home_block: volume_io.home_block.bytes.to_ary,
              n_clusters_allocated: volume_io.n_clusters_allocated.to_i,
              n_extra_bytes_per_entry: volume_io.n_extra_bytes_per_entry.to_i,
              n_max_entries_per_dir_seg: volume_io.n_max_entries_per_dir_seg.to_i,
              n_dir_segs: volume_io.n_dir_segs.to_i,
              n_clusters_per_dir_seg: volume_io.n_clusters_per_dir_seg.to_i,
              extra_word: choose_extra_word(volume_io.n_extra_bytes_per_entry)
            }
          end
        end

        def self.read_io(io)
          read_volume_io(
            SMPTool::VolumeIO::VolumeIO.read(io)
          )
        end

        def self.read_volume_io(volume_io)
          entries = volume_io.directory.segments.to_ary.flat_map(&:dir_seg_entries)
                             .reject { |e| e.status == DIR_SEG_FOOTER }

          data = volume_io.data.to_ary

          raise ArgumentError, "entries => data sizes mismatch" unless entries.length == data.length

          volume_params = parse_volume_params(volume_io)

          VirtualVolume::Volume.new(
            volume_params: volume_params,
            volume_data: zip_volume_data(entries, data, volume_params[:extra_word])
          )
        end
      end
    end
  end
end
