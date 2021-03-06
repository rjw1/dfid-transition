require 'dfid-transition/extract/query/themes'
require 'dfid-transition/patch/rummager/base'
require 'dfid-transition/transform/themes'
require 'govuk/registers/country'
require 'rest-client'

module DfidTransition
  module Patch
    module Rummager
      class Themes < Base
        include DfidTransition::Transform::Themes

        def mutate_schema
          add_theme_field
          add_theme_expansions
        end

      private

        def add_theme_field
          unless schema_hash.fetch('fields').include?('dfid_theme')
            schema_hash.fetch('fields') << 'dfid_theme'
          end
        end

        def add_theme_expansions
          schema_hash['expanded_search_result_fields']['dfid_theme'] =
            transform_to_label_value(themes_query.solutions)
        end
      end
    end
  end
end
