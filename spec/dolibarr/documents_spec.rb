# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'tmpdir'

RSpec.describe Dolibarr::Documents do
  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:documents)  { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#download_invoice_pdf' do
    let(:pdf) { '%PDF-1.4 fake bytes' }

    before do
      allow(connection).to receive(:call).and_return(
        resp('filename' => 'FA-7.pdf', 'content' => Base64.strict_encode64(pdf), 'encoding' => 'base64')
      )
    end

    it 'decodes the base64 payload and writes it to the destination path' do
      Dir.mktmpdir do |dir|
        dest = File.join(dir, 'FA-7.pdf')

        returned = documents.download_invoice_pdf(ref: 'FA-7', to: dest)

        expect(returned).to eq dest
        expect(File.binread(dest)).to eq pdf
      end
    end

    it 'requests the invoice PDF from the facture modulepart' do
      Dir.mktmpdir do |dir|
        documents.download_invoice_pdf(ref: 'FA-7', to: File.join(dir, 'FA-7.pdf'))
      end

      expect(connection).to have_received(:call).with(
        :GET, '/documents/download',
        hash_including(query: hash_including(
          'modulepart' => 'facture', 'original_file' => 'FA-7/FA-7.pdf'
        ))
      )
    end

    it 'maps a 404 (PDF not generated) to NotFound' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      Dir.mktmpdir do |dir|
        expect { documents.download_invoice_pdf(ref: 'FA-7', to: File.join(dir, 'x.pdf')) }
          .to raise_error(Dolibarr::Client::NotFound, /FA-7/)
      end
    end

    it 'raises Error when the response carries no content' do
      allow(connection).to receive(:call).and_return(resp('filename' => 'FA-7.pdf'))

      Dir.mktmpdir do |dir|
        expect { documents.download_invoice_pdf(ref: 'FA-7', to: File.join(dir, 'x.pdf')) }
          .to raise_error(Dolibarr::Client::Error, /content/)
      end
    end
  end
end
