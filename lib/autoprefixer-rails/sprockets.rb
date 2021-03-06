require 'pathname'

module AutoprefixerRails
  # Register autoprefixer postprocessor in Sprockets and fix common issues
  class Sprockets
    def self.register_processor(processor)
      @processor = processor
    end

    # Sprockets 3 and 4 API
    def self.call(input)
      filename  = input[:filename]
      source    = input[:data]
      run(filename, source)
    end

    # Sprockets 2 compatibility
    def self.process(context, css)
      self.run(context.pathname.to_s, css)
    end

    # Add prefixes to `css`
    def self.run(filename, css)
      output = filename.chomp(File.extname(filename)) + '.css'
      result = @processor.process(css, from: filename, to: output)

      result.warnings.each do |warning|
        $stderr.puts "autoprefixer: #{ warning }"
      end

      result.css
    end

    # Register postprocessor in Sprockets depend on issues with other gems
    def self.install(env)
      if ::Sprockets::VERSION.to_f < 3.7
        env.register_postprocessor('text/css', :autoprefixer) do |context, css|
          process(context, css)
        end
      else
        env.register_bundle_processor('text/css',
          ::AutoprefixerRails::Sprockets)
      end
    end

    # Register postprocessor in Sprockets depend on issues with other gems
    def self.uninstall(env)
      if ::Sprockets::VERSION.to_f < 3.7
        env.unregister_postprocessor('text/css', :autoprefixer)
      else
        env.unregister_bundle_processor('text/css',
          ::AutoprefixerRails::Sprockets)
      end
    end

    # Sprockets 2 API new and render
    def initialize(filename, &block)
      @filename = filename
      @source   = block.call
    end

    # Sprockets 2 API new and render
    def render(_, _)
      self.class.run(@filename, @source)
    end
  end
end
