# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Converts virtual volume to the raw volume.
      #
      class ConverterToRawVolume
        def initialize(
          volume_params,
          volume_data
        )
          @bootloader = volume_params[:bootloader]
          @home_block = volume_params[:home_block]
          @n_clusters_allocated = volume_params[:n_clusters_allocated]
          @n_extra_bytes_per_entry = volume_params[:n_extra_bytes_per_entry]
          @n_clusters_per_dir_seg = volume_params[:n_clusters_per_dir_seg]
          @n_max_entries_per_dir_seg = volume_params[:n_max_entries_per_dir_seg]
          @n_dir_segs = volume_params[:n_dir_segs]

          @data = _group_entries(volume_data, @n_max_entries_per_dir_seg)

          @data_offset = N_SYS_CLUSTERS + @n_dir_segs * @n_clusters_per_dir_seg
        end

        def call
          VolumeIO::RawVolume.new(
            bootloader: _init_bootloader,
            home_block: _init_home_block,
            directory: _init_directory,
            data: _init_data,
            n_clusters_allocated: @n_clusters_allocated
          )
        end

        private

        def _init_data
          @data.flatten.map do |e|
            VolumeIO::FileContent.new(
              e.data
            )
          end
        end

        def _group_entries(array, group_size)
          groups = (array.length / group_size.to_f).ceil

          (1..groups).map do |group|
            start_index = (group - 1) * group_size
            array.slice(start_index, group_size)
          end
        end

        def _init_bootloader
          VolumeIO::Bootloader.new(bytes: @bootloader)
        end

        def _init_home_block
          VolumeIO::HomeBlock.new(bytes: @home_block)
        end

        def _init_directory
          segments = (1..@n_dir_segs).map do |i_dir_seg|
            _init_dir_seg(i_dir_seg, _init_dir_seg_entries(i_dir_seg))
          end

          VolumeIO::Directory.new(
            segments: segments
          )
        end

        def _init_dir_seg_entries(i_dir_seg)
          @data[i_dir_seg - 1]
            .map { |e| _init_dir_entry(e) }
            .push(_init_dir_seg_footer)
        end

        def _init_dir_entry(v_entry)
          VolumeIO::DirEntry.new(
            status: v_entry.status,
            filename: v_entry.filename,
            n_clusters: v_entry.n_clusters,
            ch_job: v_entry.ch_job,
            date: v_entry.date,
            extra_word: v_entry.extra_word
          )
        end

        def _init_dir_seg(i_dir_seg, dir_seg_entries)
          i_next_seg = i_dir_seg == @n_dir_segs ? 0 : i_dir_seg + 1

          dir_seg = VolumeIO::DirSeg.new(
            header: _init_header(
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

        def _init_header(i_next_seg:, data_offset:)
          VolumeIO::DirSegHeader.new(
            n_dir_segs: @n_dir_segs,
            i_next_seg: i_next_seg,
            n_extra_bytes_per_entry: @n_extra_bytes_per_entry,
            data_offset: data_offset
          )
        end

        def _init_dir_seg_footer
          VolumeIO::DirEntry.new(
            status: DIR_SEG_FOOTER
          )
        end
      end
    end
  end
end
