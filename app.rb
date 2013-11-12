module UnknowEntity


  class API < Grape::API
    version 'v1', using: :header, vendor: :unknown_entity
    format :json

    attr_accessor :character, :config, :mysql_client

    helpers do
      def root
        { rel: :root, href: '/api' }
      end

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
        _links: [
          { rel: :characters, href: '/api/character/' }
        ]
      }
    end

    resource :api do
      resource :character do
        get "/" do
          characters = char.all
          {
            _links: [
              { rel: :self, href: '/api/character/' },
              root
            ],
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
              _links: [
                  root,
                  { rel: :self, href: "/api/character/#{id}" },
                  { rel: :loots, href: "/api/character/#{id}/loots" },
                  { rel: :raids, href: "/api/character/#{id}/raids" },
                  { rel: :adjustments, href: "/api/character/#{id}/adjustments" }
              ],
              data: character
            }
          end
          get '/loots' do
            id = params[:id]
            loots = char.loots id
            {
              _links: [
                root,
                { rel: :self, href: "/api/character/#{id}/loots" }
              ],
              data: loots
            }
          end

          get '/raids' do
            {
              _links: [
                root,
                { rel: :self, href: "/api/character/#{id}/raids" }
              ]
            }
          end

          get '/adjustments' do
            id = params[:id]
            character_adjustment = char.adjustments(id)
            {
              _links: [
                root,
                { rel: :self, href: "/api/character/#{id}/adjustments" }
              ],
              data: character_adjustment
            }
          end
        end
      end
    end
  end
end
