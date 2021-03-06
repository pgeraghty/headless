require 'spec_helper'

describe Headless::VideoRecorder do
  before do
    stub_environment
  end

  describe "instantiation" do
    before do
      Headless::CliUtil.stub(:application_exists?).and_return(false)
    end

    it "throws an error if ffmpeg is not installed" do
        lambda { Headless::VideoRecorder.new(99, "1024x768x32") }.should raise_error(Headless::Exception)
    end
  end

  describe "#capture" do
    it "starts ffmpeg" do
      Headless::CliUtil.stub(:path_to).and_return('ffmpeg')
      recorder = Headless::VideoRecorder.new(99, "1024x768x32")

      Headless::CliUtil.should_receive(:fork_process).with(/#{recorder.capture_with}/, '/tmp/.headless_ffmpeg_99.pid', '/dev/null')
      recorder.start_capture
    end

    it "starts ffmpeg with specified codec" do
      Headless::CliUtil.stub(:path_to).and_return('ffmpeg')
      recorder = Headless::VideoRecorder.new(99, "1024x768x32", {:codec => 'libvpx'})
      Headless::CliUtil.should_receive(:fork_process).with(/#{recorder.capture_with}/, '/tmp/.headless_ffmpeg_99.pid', '/dev/null')
      recorder.start_capture
    end
  end

  context 'stopping, pausing and resuming video recording' do
    let(:tmpfile) { '/tmp/ci.mov' }
    let(:filename) { '/tmp/test.mov' }
    let(:pidfile) { '/tmp/pid' }

    subject do
      recorder = Headless::VideoRecorder.new(99, "1024x768x32", :pid_file_path => pidfile, :tmp_file_path => tmpfile)
      recorder.start_capture
      recorder
    end

    describe "using #stop_and_save" do
      it "stops video recording and saves file" do
        Headless::CliUtil.should_receive(:kill_process).with(pidfile, :wait => true, :sig => 'INT')
        File.should_receive(:exists?).with(tmpfile).and_return(true)
        FileUtils.should_receive(:mv).with(tmpfile, filename)

        expect(subject.stop_and_save(filename)).to eq(true)
      end

      it 'returns false after a rescued error when attempting to move file' do
        FileUtils.stub(:mv).and_raise(Errno::EINVAL)
        File.should_receive(:exists?).and_return(true)

        expect(subject.stop_and_save(tmpfile)).to eq(false)
      end

      it 'returns nil when target file does not exist' do
        File.stub(:exists?).and_return(false)

        expect(subject.stop_and_save(tmpfile)).to eq(nil)
      end
    end

    describe "using #stop_and_discard" do
      it "stops video recording and deletes temporary file" do
        Headless::CliUtil.should_receive(:kill_process).with(pidfile, :wait => true)
        FileUtils.should_receive(:rm).with(tmpfile)

        subject.stop_and_discard
      end
    end

    describe 'using #pause' do
      it 'pauses video recording' do
        Headless::CliUtil.should_receive(:signal_process).with(pidfile, 'STOP')

        expect(subject.pause).to eq(nil)
      end
    end

    describe 'using #resume' do
      it 'resumes video recording' do
        Headless::CliUtil.should_receive(:signal_process).with(pidfile, 'CONT')

        expect(subject.resume).to eq(nil)
      end
    end

    describe '#capture_running?' do
      it 'returns false unless the PID file exists' do
        Headless::CliUtil.should_receive(:read_pid).with(pidfile)

        expect(subject.capture_running?).to eq(false)
      end
    end
  end

private

  def stub_environment
    Headless::CliUtil.stub(:application_exists?).and_return(true)
    Headless::CliUtil.stub(:fork_process).and_return(true)
  end
end
