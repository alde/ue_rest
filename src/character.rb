module UnknownEntity
  class Character

    attr_accessor :conn, :chars, :all_shares, :all_chars, :loot_value

    def initialize conn
      @chars = {}
      @conn = conn
      @conn.query_options.merge!({symbolize_keys: true, cast_booleans: true})
    end

    def all
      get_all_chars
    end

    def unique id
      get_unique_char id
    end

    private
      def get_char_adjustments id
        0
      end

      ##
      # Get shares for a character by id.
      #
      # return: float
      def get_char_shares id
        if @chars[id][:shares].nil? then
          sql = <<EOQ
SELECT SUM(r.number_of_shares) AS shares
  FROM rewards AS r
  JOIN character_rewards AS cr
  WHERE cr.character_id = #{id} AND reward_id = r.id
EOQ
          @chars[id][:shares] = conn.query(sql).first[:shares]
        end

        @chars[id][:shares]
      end

      ##
      # Get the total amount of shares.
      #
      # return float
      def total_shares
        if @all_shares.nil? then
          sql = <<SQL
SELECT SUM(number_of_shares) AS shares
  FROM rewards AS r
  JOIN character_rewards AS cr ON cr.reward_id = r.id
  JOIN characters AS c ON cr.character_id = c.id
  AND c.active = 1
SQL
          @all_shares = conn.query(sql).first[:shares]
        end

        @all_shares
      end

      ##
      # Get DKP spent by a character.
      #
      # return: float
      def get_dkp_spent id
        if @chars[id][:dkp][:spent].nil? then
          sql = "SELECT SUM(l.price) AS spent FROM loots as l WHERE l.character_id = #{id}"
          @chars[id][:dkp][:spent] = conn.query(sql).first[:spent]
        end

        @chars[id][:dkp][:spent]
      end

      ##
      # Get total value of all looted items. Only active characters contribute.
      #
      # return: float
      def loot_value
        if @loot_value.nil? then
          sql = <<SQL
SELECT SUM(l.price) AS loot_value
  FROM loots AS l
  JOIN characters AS c
  WHERE l.character_id = c.id AND c.active = true
SQL
          @loot_value = conn.query(sql).first[:loot_value]
        end

        @loot_value
      end

      ##
      # The value of a share.
      #
      # return: float
      def share_value
        return 0 if total_shares == 0
        loot_value / total_shares
      end

      ##
      # Get DKP for a character by id.
      #
      # return: Hash
      def get_char_dkp id
        @chars[id][:dkp] = {} if @chars[id][:dkp].nil?
        adj = get_char_adjustments id
        shares = get_char_shares id
        spent = get_dkp_spent id

        earned = shares * share_value
        dkp = earned - spent

        {
          current: dkp.round(2),
          spent: spent.round(2),
          earned: earned.round(2)
        }
      end

      ##
      # Get all characters.
      #
      # return: Array
      def get_all_chars
        if @all_chars.nil?
          sql = <<SQL
SELECT name, id FROM characters
SQL
          arr = []
          conn.query(sql).each {
            |row| arr << {
              id: row['id'],
              name: row['name']
            }
          }
          @all_chars = arr
        end

        @all_chars
      end

      ##
      # Get a character by id
      #
      # return: Hash
      def get_unique_char id
        if @chars[id].nil?
          @chars[id] = {}
          sql = <<SQL
SELECT c.name as name, cl.name AS class, c.active
  FROM characters AS c
  JOIN character_classes AS cl
  WHERE c.character_class_id = cl.id AND c.id = #{id}
SQL

          char = {}
          conn.query(sql).each { |row| char = row }

          char[:shares] = get_char_shares(id).round(2)
          char[:dkp] = get_char_dkp id

          @chars[id] = char
        end

        @chars[id]
      end
  end
end
