# frozen_string_literal: true

RSpec.describe Looper::CLI do
  describe '#parse' do
    let(:playlist) { instance_double(Looper::Playlist) }

    let(:given_dir) { Pathname.new('/home/user/videos') }

    let(:logger) { instance_double(Logger) }

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

      expect(cli.runner).to eql(
        Looper::Runner.new(
          player:   Looper::VideoPlayer.new(
            Looper::Shell.new(open3: Open3, logger: logger)
          ),
          playlist: playlist
        )
      )
    end
  end
end
