require 'spec_helper'

describe Headless::CliUtil do
  before do
    subject.class.stub(:path_to).and_return('ffmpeg')
  end

  describe 'application_exists?' do
    before { subject.class.stub(:`).and_return('/usr/bin/ffmpeg') }

    it 'calls which to find the process' do
      subject.class.should_receive(:`).with('which ffmpeg').and_return('/usr/bin/ffmpeg')
      subject.class.application_exists?('ffmpeg').should eq(true)
    end
  end

  describe 'fork_process' do
    before { subject.class.stub(:application_exists?).and_return(true) }

    it 'forks' do
      recorder = Headless::VideoRecorder.new(99, '1024x768x32')

      subject.class.should_receive(:fork).and_yield do |block|
        block.stub(:exec).and_return(123)
        block.stub(:exit!)
        STDERR.should_receive(:reopen).with('/dev/null')
        block.should_receive(:exec).with("#{recorder.capture_with} #{recorder.tmp_file_path}")
      end
      recorder.start_capture
    end

    it 'creates PID file' do
      recorder = Headless::VideoRecorder.new(99, '1024x768x32')
      subject.class.stub(:fork).and_return(123)

      file = double('file')
      File.should_receive(:open).with('/tmp/.headless_ffmpeg_99.pid', 'w').and_yield(file)
      file.should_receive(:puts).with(123)

      recorder.start_capture
    end
  end

  describe 'read_pid' do
    before do
      Process.stub(:kill)
      File.stub(:read).and_return('999999999999')
    end

    it 'reads PID file' do
      File.should_receive(:read).with('/tmp/.headless_ffmpeg_99.pid').and_return('')
      subject.class.read_pid('/tmp/.headless_ffmpeg_99.pid').should eq(nil)
    end

    it 'sends signal to process' do
      Process.should_receive(:kill).with(0, 999999999999)
      subject.class.read_pid('/tmp/.headless_ffmpeg_99.pid').should eq(999999999999)
    end

    it 'returns false after a rescued error when process does not exist' do
      Process.stub(:kill).and_raise(Errno::ESRCH)
      subject.class.read_pid('/tmp/.headless_ffmpeg_99.pid').should eq(false)
    end
  end

  describe 'signal_process' do
    let(:pidfile) { '/tmp/pid' }
    let(:fakepid) { 999999999999 }

    before do
      Process.stub(:kill)
      File.stub(:read).and_return(fakepid.to_s)
    end

    it 'reads PID file' do
      #File.should_receive(:read).with(pidfile).and_return('')
      File.stub(:read).and_return('')
      subject.class.should_receive(:read_pid).with(pidfile).and_return(nil)
      subject.class.signal_process(pidfile, 'CONT').should eq(nil)
    end

    it 'sends signal to process' do
      Process.should_receive(:kill).with('CONT', fakepid)
      subject.class.should_receive(:read_pid).with(pidfile).and_return(fakepid)
      subject.class.signal_process(pidfile, 'CONT').should eq(true)
    end

    it 'returns false after a rescued error when process does not exist' do
      Process.stub(:kill).and_raise(Errno::ESRCH)
      subject.class.should_receive(:read_pid).with(pidfile).and_return(fakepid)
      subject.class.signal_process(pidfile, 'STOP').should eq(false)
    end


  end
end
