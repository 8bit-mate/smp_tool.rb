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

      def initialize(volume_params:, volume_data: nil)
        @volume_params = Utils::VolumeParamsValidator.call(volume_params)
        @extra_word = volume_params[:extra_word]
        @data = volume_data || _init_empty_volume_data

        @volume_params[:n_max_entries_per_dir_seg] =
          volume_params[:n_max_entries_per_dir_seg] || _calc_n_max_entries_per_dir_seg

        @n_max_entries = @volume_params[:n_dir_segs] * @volume_params[:n_max_entries_per_dir_seg]
      end

      def to_raw_volume
        Utils::ConverterToRawVolume.new(
          @volume_params,
          @data
        ).call
      end

      def add_clusters(n_add_clusters)
        _check_dir_overflow

        return self unless n_add_clusters.positive?

        if n_add_clusters + @volume_params[:n_clusters_allocated] > N_CLUSTERS_MAX
          raise ArgumentError, "Can't allocate more than #{N_CLUSTERS_MAX} clusters"
        end

        @volume_params[:n_clusters_allocated] += n_add_clusters

        @data.push_empty_entry(n_add_clusters)

        self
      end

      def trim
        @volume_params[:n_clusters_allocated] -= @data.trim

        self
      end

      #
      # Push file(s) to the volume.
      #
      def f_push(*files, &block)
        block = ->(str) { InjalidDejice.utf_to_koi(str, forced_latin: "\"") } unless block_given?

        files.each do |f|
          _f_push(f, &block)
        end

        self
      end

      #
      # Extract file(s) by the ASCII filename.
      #
      # @param [<String>] *ascii_ids
      #   ASCII filenames.
      #
      # @return [<Type>] <description>
      #
      def f_extract(*ascii_ids)
        filenames = *ascii_ids.map { |id| Filename.new(ascii: id) }

        _f_extract(*filenames)
      end

      #
      # Extract all files.
      #
      def f_extract_all
        filenames = @data.reject { |e| e.status == EMPTY_ENTRY }
                         .map { |e| Filename.new(radix50: e.filename) }

        _f_extract(*filenames)
      end

      #
      # Rename file.
      #
      # @param [<String>] old_filename
      # @param [<String>] new_filename
      #
      # @return [Volume] self
      #
      def f_rename(old_filename, new_filename)
        @data.f_rename(
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
      def f_delete(filename)
        @data.f_delete(Filename.new(ascii: filename))

        squeeze

        self
      end

      private

      def _check_dir_overflow
        raise ArgumentError, "Directory table is full." if @data.length == @n_max_entries
      end

      def _calc_n_max_entries_per_dir_seg
        entry_size = ENTRY_BASE_SIZE + @volume_params[:n_extra_bytes_per_entry]
        (((@volume_params[:n_clusters_per_dir_seg] * CLUSTER_SIZE) - HEADER_SIZE - FOOTER_SIZE) / entry_size).floor
      end

      def _init_empty_volume_data
        n_data_clusters = @volume_params[:n_clusters_allocated] -
                          N_SYS_CLUSTERS -
                          (@volume_params[:n_dir_segs] * @volume_params[:n_clusters_per_dir_seg])

        data = VolumeData.new(
          [],
          @volume_params[:extra_word]
        )

        data.push_empty_entry(n_data_clusters)
      end

      def _f_push(f_hash, &block)
        _check_dir_overflow

        file = SMPTool::VirtualVolume::Utils::FileConverter.hash_to_data_entry(
          f_hash,
          @extra_word,
          &block
        )
        @data.f_push(file)

        squeeze
      end

      def _f_extract(*filenames)
        Utils::FileExtracter.new(@data).f_extract(*filenames)
      end
    end
  end
end
