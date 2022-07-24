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
    include Anima.new(:directory, :random)

    def self.parse(argv)
      opts =
        Slop.parse(argv) do |slop|
          slop.string('-d', '--dir', 'Directory to scan for videos', required: true)
          slop.bool('-r', '--random', 'Play videos in random order', default: false)

          slop.on('-h', '--help', 'Print this help') do
            puts slop.help
            exit
          end
        end

      new(directory: opts.fetch(:dir), random: opts.fetch(:random))
    end

    def runner
      Runner.new(
        player: video_player,
        system_manager: SystemManager.new(world.shell),
        playlist: playlist,
        logger: logger,
      )
    end

    def playlist
      playlist = Playlist.from_dir(Pathname.new(directory))
      playlist = playlist.shuffle if random
      playlist
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
    include Anima.new(:player, :system_manager, :playlist, :logger)

    def run
      log_playlist

      system_manager.no_sleep do
        playlist.each_video do |video|
          player.play(video)
        end
      end
    end

    private

    def log_playlist
      logger.info("Playing #{playlist.size} videos.")
    end
  end

  class SystemManager
    include Concord.new(:shell)

    def no_sleep
      xset_screen_blanking('off')
      hide_cursor

      yield
    ensure
      xset_screen_blanking('600')
    end

    private

    def hide_cursor
      shell.spawn('unclutter', '-idle', '0', '-display', ':0')
    end

    def xset_screen_blanking(value)
      # We do `-display :0` to specify we want the first physical display. Useful if run over SSH
      #
      # NOTE: If you want to view the current XOrg settings, you can do `xset -display :0 -q`
      shell.run('xset', '-display', ':0', 's', value)
    end
  end

  class VideoPlayer
    include Concord.new(:shell)

    def play(video_path)
      shell.run(
        'omxplayer',
        '-p',
        '-o',
        'hdmi',
        video_path.to_s
      )
    end
  end

  class Playlist
    include Concord.new(:video_paths)

    def self.from_dir(dir)
      paths = dir.expand_path.glob('*.{mp4,mov,avi,mkv,m4v}')

      new(paths)
    end

    def shuffle
      self.class.new(video_paths.shuffle)
    end

    def size
      video_paths.size
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
      Result.new(stdout: stdout, stderr: stderr, status: status)
    end

    def spawn(*command)
      stdin, stdout, stderr, thread = Open3.popen3(*command)

      BackgroundProcess.new(
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
        thread: thread
      )
    end

    class BackgroundProcess
      include Anima.new(:stdin, :stdout, :stderr, :thread)
    end

    class Result
      include Anima.new(:stdout, :stderr, :status)
    end
  end
end
