module AeatValidadorNif
  class EnvioAeatNifService

    URL = 'https://www1.agenciatributaria.gob.es/wlpl/BURT-JDIT/ws/VNifV2SOAP'

    # Envia un registro de NIF a AEAT
    # @param contribuyentes_xml [String] XML del registro de NIF
    # @param client_cert [String] Certificado del cliente en formato PEM
    # @param client_key [String] Clave privada del cliente en formato PEM
    # @param cert_password [String, nil] Contraseña del certificado (opcional)
    #
    def send_aeat(contribuyentes_xml:, client_cert: nil, client_key:, cert_password: nil)

      # Validates XML content
      if contribuyentes_xml.nil? || contribuyentes_xml.empty?
        raise AeatValidadorNif::AeatValidadorNifError, 'XML del NIF no puede estar vacío'
      end

      # Validates the XML schema
      validate_schema = validate_schema(contribuyentes_xml)
      unless validate_schema[:valid]
        raise AeatValidadorNif::AeatValidadorNifError, "El XML del NIF no es válido según el esquema XSD: "\
                             "#{validate_schema[:error_type]} - #{validate_schema[:errors].join(', ')}"
      end

      # Build SOAP request
      request_str = build_soap_request(contribuyentes_xml)
      p request_str

      # Send the request
      send_request(url: URL,
                   xml: request_str,
                   client_cert: client_cert,
                   client_key: client_key,
                   cert_password: cert_password)


    end

    private

    #
    # Builds the SOAP request for AEAT
    # @param xml [String] XML del registro de NIF
    # @return [String] SOAP request
    #
    def build_soap_request(xml)

      message = <<-SOAP
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
          xmlns:vnif="http://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/burt/jdit/ws/VNifV2Ent.xsd">
          <soapenv:Header/>
          <soapenv:Body>
            #{xml}
          </soapenv:Body>
        </soapenv:Envelope>
      SOAP

      message

    end

    #
    # Sends a request to the AEAT service using Savon
    # @param url [String] URL del servicio AEAT
    # @param xml [String] XML del registro de NIF
    # @param client_cert [String] Certificado del cliente en formato PEM
    # @param client_key [String] Clave privada del cliente en formato PEM
    # @param cert_password [String, nil] Contraseña del certificado (opcional)
    # @return [Hash] Resultado de la petición con claves :result, :body, :fault, :http_code, :error, :backtrace
    #
    # @example
    #   send_request(url: 'https://example.com/soap',
    #                xml: '<xml>...</xml>',
    #                client_cert: '-----BEGIN CERTIFICATE----- ... -----END CERTIFICATE-----',
    #                client_key: '-----BEGIN RSA PRIVATE KEY----- ... -----END RSA PRIVATE KEY-----',
    #                cert_password: 'password')
    #
    # @return [Hash] Resultado de la petición con claves :result, :body, :fault, :http_code, :error, :backtrace
    #
    # @raise [Verifactu::VerifactuError] Si el XML está vacío o si el entorno no es válido
    #
    # @raise [Savon::SOAPFault] Si hay un error en la respuesta SOAP
    # @raise [Savon::HTTPError] Si hay un error HTTP al hacer la petición
    # @raise [StandardError] Si ocurre cualquier otro error durante la petición
    #
    def send_request(url:, xml:, client_cert:, client_key:, cert_password: nil)

      # Create the Savon client
      client = build_savon_client(url: url,
                                  client_cert: client_cert,
                                  client_key: client_key,
                                  cert_password: cert_password)

      begin
        response = client.call(
          :aeat_nif_validator,
          xml: xml
        )

        return {
          result: :ok,
          body: response.body
        }

      rescue Savon::SOAPFault => e
        return {
          result: :error_soap_fault,
          fault: e.to_hash
        }

      rescue Savon::HTTPError => e
        return {
          result: :error_http,
          http_code: e.http.code,
          body: e.http.body
        }

      rescue => e
        return {
          result: :error_exception,
          error: e.message,
          backtrace: e.backtrace
        }
      end


    end

    # Builds a Savon client for the Verifactu service
    # @param url [String] URL del servicio Verifactu
    # @param client_cert [String] Certificado del cliente en formato PEM
    # @param client_key [String] Clave privada del cliente en formato PEM
    # @param cert_password [String, nil] Contraseña del certificado (opcional)
    # @return [Savon::Client] Cliente Savon configurado
    #
    # @raise [Verifactu::VerifactuError] Si el certificado o la clave están vacíos
    #
    # @example
    #   client = build_savon_client(
    #     url: 'https://example.com/soap',
    #     client_cert: '-----BEGIN CERTIFICATE----- ... -----END CERTIFICATE-----',
    #     client_key: '-----BEGIN RSA PRIVATE KEY----- ... -----END RSA PRIVATE KEY-----',
    #     cert_password: 'password'
    #   )
    def build_savon_client(url:, client_cert:, client_key:, cert_password: nil)

      cert = OpenSSL::X509::Certificate.new(client_cert)
      key = if cert_password && !cert_password.empty?
              OpenSSL::PKey.read(client_key, cert_password)
            else
              OpenSSL::PKey::RSA.new(client_key)
            end

      Savon.client(
        endpoint: url,
        namespace: "http://schemas.xmlsoap.org/soap/envelope/",
        soap_version: 1,
        ssl_cert: cert,
        ssl_cert_key: key,
        ssl_verify_mode: :peer,
        log: true,
        log_level: :debug,
        pretty_print_xml: true,
        convert_request_keys_to: :none,
        headers: {
          "Content-Type" => "text/xml;charset=UTF-8"
        }
      )

    end

    #
    # Validates the XML schema
    # @param xml [String] XML del registro de NIF
    # @return [Hash] Resultado de la validación con claves :valid, :errors, :error_type
    # @example
    #   validate_schema(xml)
    #   => {valid: true, errors: [], error_type: nil}
    # @example
    #   validate_schema(xml)
    #   => {valid: false, errors: ['Error de sintaxis en el XML: El elemento 'vnif:Contribuyente' no está definido.'], error_type: :XMLSyntaxError}
    # @example
    #   validate_schema(xml)
    #   => {valid: false, errors: ['Error inesperado: Error al validar el XML'], error_type: :StandardError}
    def validate_schema(registro_xml)

      AeatValidadorNif::Helpers::ValidaNifXSD.execute(registro_xml)

    end

  end
end
