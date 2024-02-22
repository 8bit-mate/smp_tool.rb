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
        @volume_params = volume_params
        @n_max_entries = volume_params[:n_dir_segs] * volume_params[:n_max_entries_per_dir_seg]
        @data = volume_data
      end

      def to_raw_volume
        Utils::ConverterToRawVolume.new(
          @volume_params,
          @data
        ).call
      end

      def f_push(*files)
        files.each do |f|
          file = SMPTool::VirtualVolume::Utils::FileConverter.hash_to_data_entry(
            f,
            0
          )

          @data.f_push(file)

          squeeze
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

      def _f_extract(*filenames)
        Utils::FileExtracter.new(@data).f_extract(*filenames)
      end
    end
  end
end
