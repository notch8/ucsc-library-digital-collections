# frozen_string_literal: true

module Bulkrax::HasLocalProcessing
  # This method is called during build_metadata
  # add any special processing here, for example to reset a metadata property
  # to add a custom property from outside of the import data
  def add_local
    parsed_metadata.delete('rights_statement')
    if override_rights_statement || parsed_metadata['rightsStatement'].blank?
      parsed_metadata['rightsStatement'] = [parser.parser_fields['rights_statement']]
    end
  end
end
