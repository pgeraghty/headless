require 'spec_helper'

describe Headless do
  let(:h) { Headless.new }

  it 'should start Xvfb when instantiated' do
    expect(h).to be_instance_of(Headless)
  end

  it 'should destroy Xvfb when requested' do
    expect { h.destroy }.not_to raise_error
  end
end if Headless::CliUtil.application_exists?('Xvfb')