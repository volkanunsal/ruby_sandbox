require 'spec_helper'

describe RubySandbox::Sandbox do
  tbl = [
    ["# encoding: utf-8\n'кириллица'", {}, 'кириллица'],
    ["'кириллица'", { encoding: 'utf-8' }, 'кириллица'],
    ["# encoding:        utf-8\n'кириллица'", {}, 'кириллица'],
    ["#        encoding: utf-8\n'кириллица'" , {}, 'кириллица']
  ]
  let(:inst) { described_class.new }

  tbl.each do |input, opts, output|
    describe input do
      describe 'run' do
        subject { inst.run(input, opts) }
        it { is_expected.to eq output }
      end

      describe 'packet' do
        subject { inst.packet(input, opts).run }
        it { is_expected.to eq output }
      end
    end
  end
end
