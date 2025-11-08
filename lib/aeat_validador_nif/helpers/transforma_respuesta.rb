module AeatValidadorNif
  module Helpers
    module TransformaRespuesta
      def self.execute(respuesta)

        if respuesta[:result] == :ok
          if respuesta.has_key?(:body) and
            respuesta[:body].has_key?(:v_nif_v2_sal) and
            respuesta[:body][:v_nif_v2_sal].has_key?(:contribuyente)
            contribuyente = respuesta[:body][:v_nif_v2_sal][:contribuyente]
            if contribuyente.is_a?(Array)
              result = []
              contribuyente.each do |c|
                if c[:resultado] == 'IDENTIFICADO'
                  result << {
                             valid: true,
                             nif: c[:nif],
                             nombre: c[:nombre].to_s.strip
                           }
                else
                  result << {
                             valid: false,
                             nif: c[:nif],
                             nombre: c[:nombre].to_s.strip
                           }
                end
              end
              return result
            else
              if contribuyente[:resultado] == 'IDENTIFICADO'
                return {
                         valid: true,
                         nif: contribuyente[:nif],
                         nombre: contribuyente[:nombre].to_s.strip
                       }
              else
                return {
                          valid: false,
                          nif: contribuyente[:nif],
                          nombre: contribuyente[:nombre].to_s.strip
                        }
              end
            end
          else
            return {valid: false}
          end
        else
          return {valid: false}
        end
      end
    end
  end
end
