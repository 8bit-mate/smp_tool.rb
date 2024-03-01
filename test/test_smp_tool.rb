# frozen_string_literal: true

require_relative "test_helper"

class TestSMPTool < Minitest::Test
  def read_bin_file(path)
    File.read(Pathname(__dir__).join(path).to_s)
  end

  def io_to_a(io)
    io.unpack("H2" * io.length).map(&:hex)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SMPTool::VERSION
  end

  # Read a full volume, check the number of files.
  # BASIC 1.0 ver.
  def test_read_volume_bas10
    io = read_bin_file("./data/read/basic_10/full_volume_121_bas_10.bin")
    n_files = SMPTool::VolumeIO::VolumeIO.read(io).snapshot.data.length

    assert_equal 121, n_files
  end

  # Read a full volume, check the number of files.
  # BASIC 2.0 ver.
  def test_read_volume_bas20
    io = read_bin_file("./data/read/basic_20/full_volume_121_bas_20.bin")
    n_files = SMPTool::VolumeIO::VolumeIO.read(io).snapshot.data.length

    assert_equal 121, n_files
  end

  def test_read_micro_vol_bas10
    io = read_bin_file("./data/read/basic_10/micro_bas_10.bin")
    SMPTool::VirtualVolume::Volume.read_io(io)
  end

  def test_virtual_volume_read_bas10
    io = read_bin_file("./data/read/basic_10/full_volume_121_bas_10.bin")

    orig_vol = SMPTool::VolumeIO::VolumeIO.read(io)
    conv_vol = SMPTool::VirtualVolume::Volume.read_volume_io(orig_vol).to_volume_io

    assert_equal orig_vol.to_binary_s, conv_vol.to_binary_s
  end

  def test_add_clusters
    io = read_bin_file("./data/read/basic_10/micro_bas_10.bin")
    vol = SMPTool::VirtualVolume::Volume.read_io(io)

    vol.add_clusters(1)

    vol.trim

    vol.inspect
  end

  def test_push_file
    io = read_bin_file("./data/read/basic_10/standard_vol_bas_10.bin")
    vol = SMPTool::VirtualVolume::Volume.read_io(io)

    vol.f_push(
      { filename: "test.bas", data: ["10 REM test"] }
    )
  end

  def test_init_new_volume
    test_params = {
      bootloader: SMPTool::Basic10::DEFAULT_BOOTLOADER,
      home_block: SMPTool::Basic10::HOME_BLOCK,
      n_clusters_allocated: 20,
      n_extra_bytes_per_entry: 0,
      n_dir_segs: 1,
      n_clusters_per_dir_seg: 2,
      extra_word: 0
    }

    vol = SMPTool::VirtualVolume::Volume.new(volume_params: test_params)

    vol.inspect
  end
end
