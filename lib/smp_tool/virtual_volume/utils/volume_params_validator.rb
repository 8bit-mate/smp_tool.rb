# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Validates virtual volume params.
      #
      module VolumeParamsValidator
        def self.call(params)
          result = VolumeParamsContract.new.call(params)

          raise ArgumentError, result.errors.to_h.to_a.join(": ") unless result.success?

          result.schema_result.output
        end
      end
    end
  end
end
