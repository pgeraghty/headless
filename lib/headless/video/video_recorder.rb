require 'tempfile'

class Headless
  class VideoRecorder
    attr_accessor :pid_file_path, :tmp_file_path, :log_file_path

    def initialize(display, dimensions, options = {})
      CliUtil.ensure_application_exists!('ffmpeg', 'Ffmpeg not found on your system. Install it with sudo apt-get install ffmpeg')

      @display = display
      @dimensions = dimensions[/.+(?=x)/]

      @pid_file_path = options.fetch(:pid_file_path, "/tmp/.headless_ffmpeg_#{@display}.pid")
      @tmp_file_path = options.fetch(:tmp_file_path, "/tmp/.headless_ffmpeg_#{@display}.mov")
      @log_file_path = options.fetch(:log_file_path, "/dev/null")
      @codec = options.fetch(:codec, "qtrle")
      @frame_rate = options.fetch(:frame_rate, 30)
      @nomouse = options.fetch(:nomouse, false)
      @audio = options.fetch(:audio, false)
    end

    def capture_running?
      CliUtil.read_pid @pid_file_path
    end

    def start_capture
      cmd = [
        CliUtil.path_to('ffmpeg'),  # TODO divine version or add option
        'y',                        # ignore already-existing file
        "r #{@frame_rate}",
        'g 600',
        "s #{@dimensions}",
        'f x11grab',
        ('draw_mouse 0' if @nomouse),
        "i :#{@display}",
        "vcodec #{@codec}",
        ("f alsa -ac 2 -i pulse" if @audio)
      ].compact*' -'
      CliUtil.fork_process("#{cmd} #{@tmp_file_path}", @pid_file_path, @log_file_path)
      at_exit do
        exit_status = $!.status if $!.is_a?(SystemExit)
        stop_and_discard
        exit exit_status if exit_status
      end
    end

    def stop_and_save(path)
      CliUtil.kill_process(@pid_file_path, :wait => true)
      if File.exists? @tmp_file_path
        begin
          FileUtils.mv(@tmp_file_path, path)
        rescue Errno::EINVAL
          nil
        end
      end
    end

    def stop_and_discard
      CliUtil.kill_process(@pid_file_path, :wait => true)
      begin
        FileUtils.rm(@tmp_file_path)
      rescue Errno::ENOENT
        # that's ok if the file doesn't exist
      end
    end
  end
end
