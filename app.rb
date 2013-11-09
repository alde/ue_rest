module UnknowEntity


  class API < Grape::API
    version 'v1', using: :header, vendor: :unknown_entity
    format :json

    attr_accessor :character, :config, :mysql_client

    helpers do
      def conf
        @config ||= YAML.load_file 'settings.yml'
      end

      def mysql
        @mysql_client ||= Mysql2::Client.new({
            host: conf['database']['host'],
            username: conf['database']['user'],
            password: conf['database']['password'],
            database: conf['database']['table']
          })
      end

      def char
        @character ||= UnknownEntity::Character.new mysql


      end
    end

    get '/' do
      {
        links: {
          characters: '/api/character/'
        }
      }
    end

    resource :api do
      resource :character do
        get "/" do
          characters = char.all
          {
            links: {
              character: '/api/character/{id}'
            },
            data: {
              characters: characters
            }
          }
        end

        params do
          requires :id, type: Integer, desc: 'Character ID'
        end
        route_param :id do
          get do
            id = params[:id]
            character = char.unique id

            {
              links: {
                loot: "/api/character/#{id}/loot",
                raids: "/api/character/#{id}/raids"
              },
              data: character
            }
          end
        end
      end
    end
  end
end
