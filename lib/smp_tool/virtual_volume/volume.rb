# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Ruby representation of the volume.
    #
    class Volume
      extend Forwardable

      def_delegators :@volume_params, :n_clusters_allocated, :n_extra_bytes_per_entry, :n_dir_segs,
                     :n_clusters_per_dir_seg, :extra_word, :n_max_entries_per_dir_seg, :n_max_entries

      attr_reader :bootloader, :home_block, :volume_params, :data

      def self.read_volume_io(volume_io)
        Utils::ConverterFromVolumeIO.read_volume_io(volume_io)
      end

      def self.read_io(volume_io)
        Utils::ConverterFromVolumeIO.read_io(volume_io)
      end

      def initialize(bootloader:, home_block:, volume_params:, volume_data: nil)
        @bootloader = bootloader
        @home_block = home_block

        @volume_params = volume_params
        @data = volume_data || Utils::EmptyVolDataInitializer.call(@volume_params)
      end

      def snapshot
        {
          volume_params: @volume_params.snapshot,
          volume_data: @data.snapshot,
          n_free_clusters: @data.calc_n_free_clusters
        }
      end

      #
      # Convert `self` to a VolumeIO object.
      #
      # @return [VolumeIO]
      #
      def to_volume_io
        Utils::ConverterToVolumeIO.new(self).call
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
      #   Number of clusters to add (pos. int.) or to trim (neg. int.).
      #
      # @return [Integer]
      #   Number of clusters that were added/trimmed.
      #
      def resize(n_clusters)
        if n_clusters.positive?
          _resize_validate_pos_input(n_clusters)
        elsif n_clusters.negative?
          _resize_validate_neg_input(n_clusters)
        else
          return n_clusters
        end

        _resize(n_clusters)
      end

      #
      # Push a file to the volume.
      #
      # @param [FileInterface, Hash{ Symbol => Object }] file_obj
      #
      # @yield [str]
      #   Each line of a file gets passed through this block. The default block encodes
      #   a string from the UTF-8 to the KOI-7, but a custom block allows to alter this
      #   behavior (e.g. when the file is already in the KOI-7 encoding).
      #
      # @return [String]
      #   ASCII filename of the pushed file.
      #
      def f_push(file_obj, &block)
        block = ->(str) { InjalidDejice.utf_to_koi(str, forced_latin: "\"") } unless block_given?

        _f_push(file_obj, &block)
      end

      #
      # Extract content of a file as an array of strings.
      #
      # @param [<String>] filename
      #   ASCII filename of the file to extract.
      #
      # @yield [str]
      #   Each line of a file gets passed through this block. The default block decodes
      #   a string from the KOI-7 to the UTF-8, but a custom block allows to alter this
      #   behavior.
      #
      # @return [FileInterface]
      #
      def f_extract_txt(filename, &block)
        block = ->(str) { InjalidDejice.koi_to_utf(str) } unless block_given?

        Utils::FileExtracter.new(@data).f_extract_txt(
          Filename.new(ascii: filename),
          &block
        )
      end

      #
      # Extract all files as arrays of strings.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_txt_all
        _all_filenames.map { |fn| f_extract_txt(fn) }
      end

      #
      # Extract content of a file as a 'raw' string (as is).
      #
      # @param [<String>] filename
      #   ASCII filename of the file to extract.
      #
      # @return [FileInterface]
      #
      def f_extract_raw(filename)
        Utils::FileExtracter.new(@data).f_extract_raw(
          Filename.new(ascii: filename)
        )
      end

      #
      # Extract all files as 'raw' strings.
      #
      # @return [Array<FileInterface>]
      #
      def f_extract_raw_all
        _all_filenames.map { |fn| f_extract_raw(fn) }
      end

      #
      # Rename a file.
      #
      # @param [<String>] old_filename
      # @param [<String>] new_filename
      #
      # @return [Array<String>]
      #   Old and new ASCII filenames of a renamed file.
      #
      def f_rename(old_filename, new_filename)
        @data.f_rename(
          Filename.new(ascii: old_filename),
          Filename.new(ascii: new_filename)
        )
      end

      #
      # Delete a file.
      #
      # @param [<String>] filename
      #
      # @return [String]
      #   ASCII filename of a deleted file.
      #
      def f_delete(filename)
        @data.f_delete(Filename.new(ascii: filename))
      end

      #
      # Consolidate all free space at the end ot the volume.
      #
      # @return [Integer]
      #   Number of free clusters that were joined.
      #
      def squeeze
        @data.squeeze
      end

      private

      def _all_filenames
        @data.reject { |e| e.status == EMPTY_ENTRY }
             .map { |e| e.header.print_ascii_filename }
      end

      def _resize_validate_pos_input(n_delta_clusters)
        _check_dir_overflow

        return if n_delta_clusters + @volume_params.n_clusters_allocated <= N_CLUSTERS_MAX

        raise ArgumentError, "Volume size can't be more than #{N_CLUSTERS_MAX} clusters"
      end

      def _resize_validate_neg_input(n_delta_clusters)
        n_free_clusters = @data.calc_n_free_clusters

        return if n_delta_clusters.abs <= n_free_clusters

        raise ArgumentError, "Can't trim more than #{n_free_clusters} clusters"
      end

      def _resize(n_clusters)
        @volume_params.n_clusters_allocated += n_clusters
        @data.resize(n_clusters)
      end

      def _check_dir_overflow
        raise ArgumentError, "Directory table is full" if @data.length >= @volume_params.n_max_entries
      end

      def _f_push(f_hash, &block)
        @data.squeeze

        _check_dir_overflow

        file = SMPTool::VirtualVolume::Utils::FileConverter.new(
          f_hash,
          @volume_params.extra_word,
          &block
        ).call

        @data.f_push(file)
      end
    end
  end
end
