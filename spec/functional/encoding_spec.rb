require 'spec_helper'

include RubySandbox

describe Sandbox, 'RubySandbox sandbox' do

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.run("# encoding: utf-8\n'кириллица'")).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via sandbox run options' do
    expect(Sandbox.new.run("'кириллица'", encoding: 'utf-8')).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.run("# encoding:        utf-8\n'кириллица'")).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.run("#        encoding: utf-8\n'кириллица'")).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.packet("# encoding: utf-8\n'кириллица'").run).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via sandbox run options' do
    expect(Sandbox.new.packet("'кириллица'", encoding: 'utf-8').run).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.packet("# encoding:        utf-8\n'кириллица'").run).to be == 'кириллица'
  end

  it 'should accept UTF-8 encoding via ruby header comments' do
    expect(Sandbox.new.packet("#        encoding: utf-8\n'кириллица'").run).to be == 'кириллица'
  end
end
