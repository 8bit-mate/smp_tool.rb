# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Ruby representation of the volume.
    #
    class Volume
      def self.read_volume_io(volume_io)
        Utils::ConverterFromVolumeIO.read_volume_io(volume_io)
      end

      def self.read_io(volume_io)
        Utils::ConverterFromVolumeIO.read_io(volume_io)
      end

      def initialize(bootloader:, home_block:, volume_params:, volume_data: nil)
        @bootloader = bootloader
        @home_block = home_block

        @volume_params = Utils::VolumeParamsValidator.call(volume_params)
        @data = volume_data || Utils::EmptyVolDataInitializer.call(@volume_params)

        @volume_params[:n_max_entries_per_dir_seg] =
          volume_params[:n_max_entries_per_dir_seg] || _calc_n_max_entries_per_dir_seg

        @n_max_entries = @volume_params[:n_dir_segs] * @volume_params[:n_max_entries_per_dir_seg]
      end

      def snapshot
        {
          volume_params: @volume_params,
          volume_data: @data.snapshot,
          n_free_clusters: @data.calc_n_free_clusters,
          n_max_entries: @n_max_entries
        }
      end

      #
      # Convert `self` to a VolumeIO object.
      #
      # @return [VolumeIO]
      #
      def to_volume_io
        Utils::ConverterToVolumeIO.new(
          bootloader: @bootloader,
          home_block: @home_block,
          volume_params: @volume_params,
          volume_data: @data
        ).call
      end

      #
      # Convert `self` to a binary string. Write this string to a binary file
      # to get a MK90 volume that works on an emulator or on a real machine.
      #
      # @return [String]
      #
      def to_binary_s
        to_volume_io.to_binary_s
      end

      #
      # Allocate more clusters to the volume or trim free clusters.
      #
      # @param [Integer] n_clusters
      #   Number of clusters to add (pos. int.) or to trim (neg. int.)
      #
      # @return [Volume] self
      #
      def resize(n_clusters)
        if n_clusters.positive?
          _resize_check_pos_input(n_clusters)
        elsif n_clusters.negative?
          _resize_check_neg_input(n_clusters)
        else
          return self
        end

        _resize(n_clusters)

        self
      end

      #
      # Push an arr. of files to the volume.
      #
      # @param [FileInterface, Hash{ Symbol => Object }] *files
      #
      # @yield [str]
      #   Each line of a file gets passed through this block. The default block encodes
      #   a string from the UTF-8 to the KOI-7, but a custom block allows to alter this
      #   behavior (e.g. when the files are already in the KOI-7 encoding).
      #
      # @return [VirtualVolume] self
      #
      def f_push(*files, &block)
        block = ->(str) { InjalidDejice.utf_to_koi(str, forced_latin: "\"") } unless block_given?

        files.each do |f|
          _f_push(f, &block)
        end

        self
      end

      #
      # Extract content of a file as an array of strings.
      #
      # @param [<String>] *ascii_ids
      #   ASCII filenames.
      #
      # @yield [str]
      #   Each line of a file gets passed through this block. The default block decodes
      #   a string from the KOI-7 to the UTF-8, but a custom block allows to alter this
      #   behavior.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_txt(*ascii_ids, &block)
        block = ->(str) { InjalidDejice.koi_to_utf(str) } unless block_given?

        Utils::FileExtracter.new(@data).f_extract_txt(
          _map_filenames(ascii_ids),
          &block
        )
      end

      #
      # Extract all files as arrays of strings.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_txt_all
        f_extract_txt(*_all_filenames)
      end

      #
      # Extract content of a file as a 'raw' string (as is).
      #
      # @param [<String>] *ascii_ids
      #   ASCII filenames.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_raw(*ascii_ids)
        Utils::FileExtracter.new(@data).f_extract_raw(
          _map_filenames(ascii_ids)
        )
      end

      #
      # Extract all files as 'raw' strings.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_raw_all
        f_extract_raw(*_all_filenames)
      end

      #
      # Rename a file.
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
      # Delete a file.
      #
      # @param [<String>] filename
      #
      # @return [Volume] self
      #
      def f_delete(filename)
        @data.f_delete(Filename.new(ascii: filename))

        self
      end

      #
      # Consolidate all free space at the end ot the volume.
      #
      # @return [Volume] self
      #
      def squeeze
        @data.squeeze

        self
      end

      private

      def _map_filenames(arr)
        arr.map { |id| Filename.new(ascii: id) }
      end

      def _all_filenames
        @data.reject { |e| e.status == EMPTY_ENTRY }
             .map { |e| e.header.ascii_filename }
      end

      def _resize_check_pos_input(n_clusters)
        _check_dir_overflow

        return unless n_clusters + @volume_params[:n_clusters_allocated] > N_CLUSTERS_MAX

        raise ArgumentError, "Volume size can't be more than #{N_CLUSTERS_MAX} clusters"
      end

      def _resize_check_neg_input(n_clusters)
        n_free_clusters = @data.calc_n_free_clusters

        return unless n_clusters > n_free_clusters

        raise ArgumentError, "Can't trim more than #{n_free_clusters} clusters" if diff.negative?
      end

      def _resize(n_clusters)
        @data.resize(n_clusters)
        @volume_params[:n_clusters_allocated] += n_clusters

        self
      end

      def _check_dir_overflow
        raise ArgumentError, "Directory table is full." if @data.length >= @n_max_entries
      end

      def _calc_n_max_entries_per_dir_seg
        entry_size = ENTRY_BASE_SIZE + @volume_params[:n_extra_bytes_per_entry]
        (((@volume_params[:n_clusters_per_dir_seg] * CLUSTER_SIZE) - HEADER_SIZE - FOOTER_SIZE) / entry_size).floor
      end

      def _f_push(f_hash, &block)
        _check_dir_overflow

        file = SMPTool::VirtualVolume::Utils::FileConverter.new(
          f_hash,
          @volume_params[:extra_word],
          &block
        ).call

        @data.f_push(file)

        @data.squeeze
      end
    end
  end
end
