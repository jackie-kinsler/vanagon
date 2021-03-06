require 'docopt'
require 'json'

class Vanagon
  class CLI
    class BuildRequirements < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        build_requirements [options] <project-name> <platform>

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [base, local, docker, pooler] [default: pooler]
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        puts e.message
        exit 1
      end

      def run(options) # rubocop:disable Metrics/AbcSize
        platform = options[:platform]
        project = options[:project_name]
        driver = Vanagon::Driver.new(platform, project)

        components = driver.project.components
        component_names = components.map(&:name)
        build_requirements = []
        components.each do |component|
          build_requirements << component.build_requires.reject do |requirement|
            # only include external requirements: i.e. those that do not match
            # other components in the project
            component_names.include?(requirement)
          end
        end

        $stdout.puts
        $stdout.puts "**** External packages required to build #{project} on #{platform}: ***"
        $stdout.puts JSON.pretty_generate(build_requirements.flatten.uniq.sort)
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--configdir' => :configdir,
          '--engine' => :engine,
          '<project-name>' => :project_name,
          '<platform>' => :platform,
        }
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end
