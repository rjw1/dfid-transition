require 'spec_helper'
require 'json'
require 'rest-client'
require 'dfid-transition/patch/specialist_publisher/regions'

describe DfidTransition::Patch::SpecialistPublisher::Regions do
  subject(:patch) { described_class.new(patch_location) }

  describe '#location' do
    context 'a schema location is supplied' do
      let(:patch_location) { 'spec/fixtures/patchme.json' }

      it 'patches that location' do
        expect(patch.location).to eq(patch_location)
      end
    end

    context 'a location is not supplied' do
      let(:patch_location) { nil }

      it 'defaults to lib/documents/schemas/dfid_research_outputs.json relative to the current directory' do
        expect(patch.location).to eq(
          File.expand_path(
            File.join(
              Dir.pwd, '..', 'specialist-publisher-rebuild/lib/documents/schemas/dfid_research_outputs.json')))
      end
    end
  end

  describe '#run' do
    let(:patch_location) { 'spec/fixtures/schemas/regions-sparql.json' }

    context 'the target schema file does not exist' do
      it 'tells us so' do
        expect { patch.run }.to raise_error(
          Errno::ENOENT, /regions-sparql\.json/)
      end
    end

    context 'the target schema file exists' do
      let(:test_schema)  { 'spec/fixtures/schemas/specialist_publisher/dfid_research_outputs_src.json' }
      let(:parsed_json)  { JSON.parse(File.read(patch_location)) }
      let(:region_facet) { parsed_json['facets'].find { |f| f['key'] == 'region' } }
      let(:regions_response_body) { nil }

      before do
        allow(RestClient).to receive(:get).with(
          DfidTransition::R4D_ADVANCED_SEARCH
        ).and_return(regions_response_body)

        FileUtils.cp(test_schema, patch_location)
      end

      after do
        File.delete(patch_location)
      end

      context 'the target schema file does not have a regions facet to patch' do
        let(:test_schema) { 'spec/fixtures/schemas/specialist_publisher/dfid_research_outputs_no_facets.json' }

        it 'fails with an informative KeyError' do
          expect { patch.run }.to raise_error(KeyError, /No region facet found/)
        end
      end

      context 'we have a full set of regions from the regions SPARQL' do
        let(:regions_response_body) {
          File.read('spec/fixtures/service-results/r4dAdvancedSearch.html')
        }

        before do
          patch.run
        end

        it 'patches the schema with all extant regions' do
          expect(region_facet['allowed_values'].length).to eql(30)
        end

        it 'does not have an "All Regions" option' do
          expect(region_facet['allowed_values']).not_to include(
            'label' => 'All Regions',
            'value' => '=='
          )
        end

        it 'has titleized region names for labels and UN codes for facets' do
          expect(region_facet['allowed_values']).to include(
            'label' => 'Australia and New Zealand',
            'value' => '53'
          )
        end
      end
    end
  end
end