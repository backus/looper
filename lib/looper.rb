require 'open3'
require 'pathname'
require 'logger'

require 'anima'
require 'concord'
require 'slop'

module Looper
  class World
    include Anima.new(:logger, :shell_class)

    def video_player
      VideoPlayer.new(shell)
    end

    def shell
      shell_class.new(open3: Open3, logger: logger)
    end
  end

  class CLI
    include Anima.new(:directory)

    def self.parse(argv)
      opts =
        Slop.parse(argv) do |slop|
          slop.string('-d', '--dir', 'Directory to scan for videos', required: true)

          slop.on('-h', '--help', 'Print this help') do
            puts slop.help
            exit
          end
        end

      new(directory: opts.fetch(:dir))
    end

    def runner
      Runner.new(player: video_player, playlist: playlist)
    end

    def playlist
      Playlist.from_dir(Pathname.new(directory))
    end

    def video_player
      world.video_player
    end

    private

    def world
      World.new(shell_class: Shell, logger: logger)
    end

    def logger
      Logger.new($stderr)
    end
  end

  class Runner
    include Anima.new(:player, :playlist)

    def run
      playlist.each_video do |video|
        player.play(video)
      end
    end
  end

  class VideoPlayer
    include Concord.new(:shell)

    def play(video_path)
    end
  end

  class Playlist
    include Concord.new(:video_paths)

    def self.from_dir(dir)
      paths = dir.expand_path.glob('*.{mp4,mov,avi,mkv,m4v')

      new(paths)
    end

    def each_video(&blk)
      video_paths.each(&blk)
    end
  end

  class Shell
    include Anima.new(:open3, :logger)

    def run(*command)
      logger.debug("[shell] Running #{command.inspect}")

      stdout, stderr, status = Open3.capture3(*command)
      Result.new(stout: stdout, stderr: stderr, status: status)
    end

    class Result
      include Anima.new(:stdout, :stderr, :status)
    end
  end
end
