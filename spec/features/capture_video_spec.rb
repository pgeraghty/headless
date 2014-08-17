require 'spec_helper'

describe Headless::VideoRecorder do
  it 'should capture 10s of video on request' do
    h = Headless.new(:display => 99, :reuse => true, :dimensions => '1280x720x24')

    capture_file = '/tmp/screen-capture-mpeg4.mkv'
    log = '/tmp/ffmpeg_test.log'

    sleep 5 # give Xvfb some time
    `DISPLAY=:99 fluxbox > /dev/null 2>&1 &`
    sleep 3
    `ffmpeg -f x11grab -r 30 -s 1280x720 -i :99.0 -vcodec mpeg4 -qscale:v 2 -threads 1 -y -t 10 #{capture_file} > #{log} 2>&1`
    expected_duration =
        if h.video.guess_ffmpeg_version! > Gem::Version.new(1.2)
          /time=00:00:10/
        else
          /time=10/
        end
    expect(File.read log).to match(expected_duration)
    expect(`ffprobe #{capture_file} 2>&1 | grep Duration`).to match(/Duration: 00:00:10/)
    `rm #{capture_file}`
    expect { h.destroy }.not_to raise_error
  end
end if Headless::CliUtil.application_exists?('Xvfb') && Headless::CliUtil.application_exists?('ffmpeg')