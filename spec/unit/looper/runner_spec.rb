# frozen_string_literal: true

RSpec.describe Looper::Runner do
  subject(:runner) do
    described_class.new(
      player:   video_player,
      playlist: playlist,
      logger:   logger,
      system_manager: system_manager,
    )
  end

  let(:logger) { instance_spy(Logger) }

  let(:playlist) do
    Looper::Playlist.new(videos)
  end

  let(:videos) do
    [
      Pathname.new('/home/user/videos/video1.mp4'),
      Pathname.new('/home/user/videos/video2.m4v'),
      Pathname.new('/home/user/videos/vide3.mov')
    ]
  end

  let(:video_player) do
    instance_spy(Looper::VideoPlayer)
  end

  let(:system_manager) do
    instance_double(Looper::SystemManager).tap do |double|
      allow(double).to receive(:no_sleep).and_yield
    end
  end

  describe '#run' do
    it 'runs each video in order' do
      runner.run

      expect(video_player).to have_received(:play).with(videos[0]).ordered
      expect(video_player).to have_received(:play).with(videos[1]).ordered
      expect(video_player).to have_received(:play).with(videos[2]).ordered
    end

    it 'ensures the system goes to sleep' do
      runner.run

      expect(system_manager).to have_received(:no_sleep).ordered
      expect(video_player).to have_received(:play).thrice.ordered
    end
  end
end
