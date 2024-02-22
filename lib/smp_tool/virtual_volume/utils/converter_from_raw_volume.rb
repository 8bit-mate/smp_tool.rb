# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts raw volume to the virtual volume.
      #
      module ConverterFromRawVolume
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

          volume_params = parse_volume_params(raw_volume)

          VirtualVolume::Volume.new(
            volume_params: volume_params,
            volume_data: zip_volume_data(entries, data, volume_params[:extra_word])
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
            n_clusters_per_dir_seg: raw_volume.n_clusters_per_dir_seg,
            extra_word: choose_extra_word(raw_volume.n_extra_bytes_per_entry)
          }
        end
      end
    end
  end
end
