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

          def _volume_data(entries, data, extra_word)
            VolumeData.new(
              _data_entries(entries, data),
              extra_word
            )
          end

          def _data_entries(entries, data)
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
          def _choose_extra_word(n_extra_bytes_per_entry)
            case n_extra_bytes_per_entry
            when 0
              Basic10::ENTRY_EXTRA_WORD
            else
              Basic20::ENTRY_EXTRA_WORD
            end
          end

          def _parse_volume_params(volume_io)
            {
              n_clusters_allocated: volume_io.n_clusters_allocated.to_i,
              n_extra_bytes_per_entry: volume_io.n_extra_bytes_per_entry.to_i,
              n_max_entries_per_dir_seg: volume_io.n_max_entries_per_dir_seg.to_i,
              n_dir_segs: volume_io.n_dir_segs.to_i,
              n_clusters_per_dir_seg: volume_io.n_clusters_per_dir_seg.to_i,
              extra_word: _choose_extra_word(volume_io.n_extra_bytes_per_entry)
            }
          end

          def _read_entries(volume_io)
            volume_io.directory.segments.to_ary.flat_map(&:dir_seg_entries)
                     .reject { |e| e.status == DIR_SEG_FOOTER }
          end
        end

        def self.read_io(io)
          read_volume_io(
            SMPTool::VolumeIO::VolumeIO.read(io)
          )
        end

        def self.read_volume_io(volume_io)
          entries = _read_entries(volume_io)
          data = volume_io.data.to_ary

          raise ArgumentError, "entries => data lengths mismatch" unless entries.length == data.length

          volume_params = _parse_volume_params(volume_io)

          VirtualVolume::Volume.new(
            bootloader: volume_io.bootloader.bytes.to_ary,
            home_block: volume_io.home_block.bytes.to_ary,
            volume_params: volume_params,
            volume_data: _volume_data(entries, data, volume_params[:extra_word])
          )
        end
      end
    end
  end
end
