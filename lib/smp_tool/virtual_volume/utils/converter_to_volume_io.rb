# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts virtual volume to the volume IO.
      #
      class ConverterToVolumeIO
        def initialize(volume)
          @bootloader = volume.bootloader
          @home_block = volume.home_block
          @n_clusters_allocated = volume.n_clusters_allocated
          @n_extra_bytes_per_entry = volume.n_extra_bytes_per_entry
          @n_clusters_per_dir_seg = volume.n_clusters_per_dir_seg
          @n_max_entries_per_dir_seg = volume.n_max_entries_per_dir_seg
          @n_dir_segs = volume.n_dir_segs

          @data = _group_entries(volume.data)

          @data_offset = N_SYS_CLUSTERS + @n_dir_segs * @n_clusters_per_dir_seg
        end

        def call
          VolumeIO::VolumeIO.new(
            bootloader: _build_bootloader,
            home_block: _build_home_block,
            directory: _build_directory,
            data: _build_data,
            n_clusters_allocated: @n_clusters_allocated
          )
        end

        private

        def _build_data
          @data.flatten.map do |e|
            VolumeIO::FileContent.new(
              e.data
            )
          end
        end

        def _group_entries(arr)
          result = arr.each_slice(@n_max_entries_per_dir_seg).to_a
          diff = @n_dir_segs - result.length
          diff.times { result << [] }
          result
        end

        def _build_bootloader
          VolumeIO::Bootloader.new(bytes: @bootloader)
        end

        def _build_home_block
          VolumeIO::HomeBlock.new(bytes: @home_block)
        end

        def _build_directory
          segments = (1..@n_dir_segs).map do |i_dir_seg|
            _build_dir_seg(i_dir_seg, _build_dir_seg_entries(i_dir_seg))
          end

          VolumeIO::Directory.new(
            segments: segments
          )
        end

        def _build_dir_seg_entries(i_dir_seg)
          @data[i_dir_seg - 1]
            .map { |e| _build_dir_entry(e) }
            .push(_build_dir_seg_footer)
        end

        def _build_dir_entry(v_entry)
          VolumeIO::DirEntry.new(
            status: v_entry.status,
            filename: v_entry.filename,
            n_clusters: v_entry.n_clusters,
            ch_job: v_entry.ch_job,
            date: v_entry.date,
            extra_word: v_entry.extra_word
          )
        end

        def _build_dir_seg(i_dir_seg, dir_seg_entries)
          i_next_seg = i_dir_seg == @n_dir_segs ? 0 : i_dir_seg + 1

          dir_seg = VolumeIO::DirSeg.new(
            header: _build_header(
              i_next_seg: i_next_seg,
              data_offset: @data_offset
            ),
            dir_seg_entries: dir_seg_entries
          )

          _upd_data_offset(i_dir_seg)

          dir_seg
        end

        def _upd_data_offset(i_dir_seg)
          n_clustes_in_files = @data[i_dir_seg - 1].sum(&:n_clusters)

          @data_offset += n_clustes_in_files
        end

        def _build_header(i_next_seg:, data_offset:)
          VolumeIO::DirSegHeader.new(
            n_dir_segs: @n_dir_segs,
            i_next_seg: i_next_seg,
            n_extra_bytes_per_entry: @n_extra_bytes_per_entry,
            data_offset: data_offset
          )
        end

        def _build_dir_seg_footer
          VolumeIO::DirEntry.new(
            status: DIR_SEG_FOOTER
          )
        end
      end
    end
  end
end
