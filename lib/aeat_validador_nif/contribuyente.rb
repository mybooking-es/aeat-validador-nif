module AeatValidadorNif
  class Contribuyente
    attr_reader :nif, :nombre

    def initialize(nif:, nombre:)
      # Validate Fields
      raise AeatValidadorNif::AeatValidadorNifError, 'NIF must be a 9-character string' if nif.nil? || nif.strip.empty? || nif.length != 9
      raise AeatValidadorNif::AeatValidadorNifError, 'Si el NIF es de persona fisica, el nombre es obligatorio' if nombre.nil? && nif[-1] =~ /[A-Za-z]/
      @nif = nif
      @nombre = nombre
    end
  end
end
