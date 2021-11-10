# frozen_string_literal: true

module Bulkrax::HasLocalProcessing
  include ControlledIndexerBehavior

  # This method is called during build_metadata
  # add any special processing here, for example to reset a metadata property
  # to add a custom property from outside of the import data
  def add_local
    parsed_metadata.delete('rights_statement')
    if override_rights_statement || parsed_metadata['rightsStatement'].blank?
      parsed_metadata['rightsStatement'] = [parser.parser_fields['rights_statement']]
    end

    add_controlled_fields
  end

  def add_controlled_fields
    ::ScoobySnacks::METADATA_SCHEMA.controlled_field_names.each do |field_name|
      parsed_metadata.delete(field_name) # remove non-standardized values
      next if raw_metadata[field_name].blank?

      raw_metadata[field_name].split(/\s*[|]\s*/).uniq.each_with_index do |value, i|
        data = if value.match?(::URI::DEFAULT_PARSER.make_regexp)
                 { id: value }
               else
                 authority = ::Qa::Authorities::Loc.subauthority_for('names') # TODO: might need to support more subauthorities
                 found_id = authority.search(value)&.first&.dig('id')

                 found_id.present? ? { id: found_id } : nil
               end
        # TODO: permit in obj factory
        parsed_metadata["#{field_name}_attributes"][i] = data
      end
    end
  end
end
