require 'savon'
require 'nokogiri'
require 'erb'

require_relative 'aeat_validador_nif/helpers/valida_nif_xsd'
require_relative 'aeat_validador_nif/helpers/xsd_loader'
require_relative 'aeat_validador_nif/helpers/transforma_respuesta'

require_relative 'aeat_validador_nif/aeat_validador_nif_error'
require_relative 'aeat_validador_nif/contribuyente'
require_relative 'aeat_validador_nif/contribuyentes'
require_relative 'aeat_validador_nif/aeat_nif_xml_builder'
require_relative 'aeat_validador_nif/envio_aeat_nif_service'
