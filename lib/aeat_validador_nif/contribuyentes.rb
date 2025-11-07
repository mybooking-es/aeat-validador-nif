module AeatValidadorNif
  class Contribuyentes

    attr_reader :contribuyentes

    def initialize
      @contribuyentes = []
    end

    # Add nif to the list to validate
    def agregar_nif(nif:, nombre: nil)
      raise AeatValidadorNif::AeatValidadorNifError, 'NIF is required' if nif.nil? || nif.empty?
      raise AeatValidadorNif::AeatValidadorNifError, 'NIF must be a string' unless nif.is_a?(String)
      raise AeatValidadorNif::AeatValidadorNifError, 'Tamaño máximo NIF 9 caracteres' if nif.length != 9
      raise AeatValidadorNif::AeatValidadorNifError, 'A max of 10.000 nifs can be validated at once' if @contribuyentes.size >= 10_000
      @contribuyentes << Contribuyente.new(nif: nif, nombre: nombre)
      self
    end

  end
end
