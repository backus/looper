require 'open3'
require 'pathname'

require 'anima'
require 'concord'

module Looper
  class World
    include Anima.new(:fs, :shell_class)
  end

  class Playlist
    include Concord.new(:video_paths)

    def self.from_dir(dir)
      paths = dir.expand_path.glob('*.{mp4,mov,avi,mkv,m4v')

      new(paths)
    end
  end

  class Shell
    include Anima.new(:open3, :logger)

    def run(command)
      logger.debug("[shell] Running #{command.inspect}")

      stdout, stderr, status = Open3.capture3(command)
      Result.new(stout: stdout, stderr: stderr, status: status)
    end

    class Result
      include Anima.new(:stdout, :stderr, :status)
    end
  end
end
