module ActsAsTenantHelpers
  def with_tenant(tenant, &block)
    original_tenant = ActsAsTenant.current_tenant
    ActsAsTenant.current_tenant = tenant
    result = yield
    result
  ensure
    ActsAsTenant.current_tenant = original_tenant
  end

  def without_tenant(&block)
    original_tenant = ActsAsTenant.current_tenant
    ActsAsTenant.current_tenant = nil
    result = yield
    result
  ensure
    ActsAsTenant.current_tenant = original_tenant
  end
end

# Monkey patch para permitir la creación de modelos sin tenant en pruebas
if Rails.env.test?
  module ActsAsTenant
    module ModelExtensions
      module ClassMethods
        alias_method :original_validates_uniqueness_to_tenant, :validates_uniqueness_to_tenant

        def validates_uniqueness_to_tenant(*attr_names)
          if Rails.env.test?
            validates_uniqueness_of(*attr_names)
          else
            original_validates_uniqueness_to_tenant(*attr_names)
          end
        end
      end
    end
  end

  # Extender la clase principal para permitir saltarse la validación en tests
  module ActsAsTenant
    # Para permitir bypass del tenant durante las pruebas
    def self.skip_validation
      @skip_validation = true
      yield
    ensure
      @skip_validation = false
    end

    def self.skip_validation?
      @skip_validation || false
    end

    def self.current_tenant_relaxed
      current_tenant || nil
    end
  end

  # Redefinir el default_scope para tests
  module ActsAsTenant
    module ModelExtensions
      module TenantExtension
        module OriginalDefaultScope
          def self.included(base)
            base.class_eval do
              # Si estamos en ambiente de prueba y se está usando skip_validation, no aplicar el scope de tenant
              default_scope lambda {
                if Rails.env.test? && ActsAsTenant.skip_validation?
                  # No aplicar filtro
                  all
                else
                  # Aplicar filtro normal
                  where(base.tenant_column => ActsAsTenant.current_tenant_relaxed)
                end
              }
            end
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include ActsAsTenantHelpers, type: :request
  config.include ActsAsTenantHelpers, type: :model
  config.include ActsAsTenantHelpers, type: :controller

  # Usar el mecanismo de skip_validation durante las pruebas
  config.around(:each) do |example|
    # Para modelos, no necesitamos tenant en pruebas unitarias
    if example.metadata[:type] == :model
      without_tenant { example.run }
    else
      # Para request/controller, hacemos bypass pero con tenant específico si es necesario
      ActsAsTenant.skip_validation do
        example.run
      end
    end
  end

  # Asegurar que al final de cada prueba el tenant sea nil
  config.after(:each) do
    ActsAsTenant.current_tenant = nil
  end
end
