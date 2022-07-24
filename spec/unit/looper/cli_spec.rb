# frozen_string_literal: true

RSpec.describe Looper::CLI do
  describe '#parse' do
    let(:playlist) { instance_double(Looper::Playlist) }

    let(:given_dir) { Pathname.new('/home/user/videos') }

    let(:logger) { instance_double(Logger) }


  let(:system_manager) do
    instance_double(Looper::SystemManager).tap do |double|
      allow(double).to receive(:no_sleep).and_yield
    end
  end

    before do
      allow(Looper::Playlist)
        .to receive(:from_dir)
        .with(given_dir)
        .and_return(playlist)

      allow(Logger).to receive(:new).with($stderr).and_return(logger)
    end

    it 'can construct a runner from CLI arguments' do
      cli_args = ['--dir', given_dir]
      cli      = described_class.parse(cli_args)

      shell = Looper::Shell.new(open3: Open3, logger: logger)

      expect(cli.runner).to eql(
        Looper::Runner.new(
          player:   Looper::VideoPlayer.new(shell),
          system_manager: Looper::SystemManager.new(shell),
          playlist: playlist,
          logger:   logger
        )
      )
    end
  end
end
