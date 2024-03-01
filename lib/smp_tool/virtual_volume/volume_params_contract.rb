# frozen_string_literal: true

module SMPTool
  module VirtualVolume
    #
    # Virtual volume params contract.
    #
    class VolumeParamsContract < Dry::Validation::Contract
      config.messages.default_locale = :en

      # rubocop:disable Metrics/BlockLength
      json do
        required(:bootloader).value(
          :array,
          max_size?: CLUSTER_SIZE
        )

        required(:home_block).value(
          :array,
          max_size?: CLUSTER_SIZE
        )

        required(:n_clusters_allocated).value(
          :integer,
          lteq?: N_CLUSTERS_MAX
        )

        required(:n_extra_bytes_per_entry).value(
          :integer,
          included_in?: [0, 2]
        )

        required(:n_dir_segs).value(
          :integer,
          gteq?: 1,
          lteq?: 2
        )

        required(:n_clusters_per_dir_seg).value(
          :integer,
          gteq?: 1,
          lteq?: 2
        )

        required(:extra_word).value(
          :integer
        )
      end
      # rubocop:enable Metrics/BlockLength

      rule(:n_dir_segs, :n_clusters_per_dir_seg) do
        msg = "Can't use :n_dir_segs => #{values[:n_dir_segs]}" \
              "& :n_clusters_per_dir_seg => #{values[:n_clusters_per_dir_seg]}"

        key.failure(msg) if values[:n_dir_segs] == 2 && values[:n_clusters_per_dir_seg] == 1
      end

      rule(:n_clusters_allocated, :n_clusters_per_dir_seg, :n_dir_segs) do
        n_min_clusters = N_SYS_CLUSTERS + values[:n_clusters_per_dir_seg] * values[:n_dir_segs] + 1
        msg = "Min. number of clusters for the configuration is: #{n_min_clusters}"
        key.failure(msg) if values[:n_clusters_allocated] < n_min_clusters
      end
    end
  end
end
