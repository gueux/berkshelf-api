module Berkshelf::API
  class CacheBuilder
    module Worker
      class ChefServer < Worker::Base
        worker_type "chef_server"

        finalizer :finalize_callback

        def initialize(options = {})
          @connection = Ridley::Client.new_link(server_url: options[:url], client_key: options[:client_key],
            client_name: options[:client_name], ssl: { verify: options[:ssl_verify] })
          super
        end

        # @return [Array<RemoteCookbook>]
        #  The list of cookbooks this builder can find
        def cookbooks
          [].tap do |cookbook_versions|
            connection.cookbook.all.each do |cookbook, versions|
              versions.each do |version|
                cookbook_versions << RemoteCookbook.new(cookbook, version, self.class.worker_type,
                  @connection.server_url)
              end
            end
          end
        end

        # @param [RemoteCookbook] remote
        #
        # @return [Ridley::Chef::Cookbook::Metadata]
        def metadata(remote)
          metadata_hash = connection.cookbook.find(remote.name, remote.version).metadata
          Ridley::Chef::Cookbook::Metadata.from_hash(metadata_hash)
        end

        private

          attr_reader :connection

          def finalize_callback
            connection.terminate if connection && connection.alive?
          end
      end
    end
  end
end