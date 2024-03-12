# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    module Utils
      #
      # Initializes empty data for a volume with the given params.
      #
      module EmptyVolDataInitializer
        #
        # Initialize empty data.
        #
        # @param [Hash{ Symbol => Object }] volume_params
        #
        # @return [VolumeData]
        #
        def self.call(volume_params)
          n_data_clusters = volume_params.n_clusters_allocated -
                            N_SYS_CLUSTERS -
                            (volume_params.n_dir_segs * volume_params.n_clusters_per_dir_seg)

          data = VolumeData.new(
            [],
            volume_params.extra_word
          )

          data.push_empty_entry(n_data_clusters)
        end
      end
    end
  end
end
