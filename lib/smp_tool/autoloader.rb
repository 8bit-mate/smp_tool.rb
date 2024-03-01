# frozen_string_literal: true

require "pathname"

module SMPTool
  #
  # Gem's autoloader.
  #
  class Autoloader
    class << self
      def setup
        loader = Zeitwerk::Loader.new
        loader.push_dir(Pathname(__dir__).join("../")) # lib
        loader.inflector.inflect(
          "smp_tool" => "SMPTool",
          "volume_io" => "VolumeIO",
          "converter_from_volume_io" => "ConverterFromVolumeIO",
          "converter_to_volume_io" => "ConverterToVolumeIO"
        )
        loader.setup
      end
    end
  end
end
