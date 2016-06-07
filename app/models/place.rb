class Place
    
    attr_accessor :id, :formatted_address, :location, :address_components

    def self.mongo_client
        Mongoid::Clients.default	  	
    end

    def self.collection
        self.mongo_client['places']
    end

    def self.load_all(file)
        docs = JSON.parse(file.read)
        collection.insert_many(docs)
    end
    
    def initialize(hash={})
        @id = hash[:_id].nil? ? hash[:id] : hash[:_id].to_s
        @formatted_address = hash[:formatted_address]
        @location = Point.new(hash[:geometry][:geolocation])
        if !hash[:address_components].nil?
            @address_components = hash[:address_components].map { |a| AddressComponent.new(a) }
        end
    end
    
    def self.find_by_short_name(short_name)
        collection.find(:'address_components.short_name' => short_name)
    end
    
    def self.to_places(places)
        places.map do |place|
            Place.new(place)
        end
    end
    
    def self.find id
        it = collection.find(:id=>BSON::ObjectId.from_string(id)).first
        return it.nil? ? nil : Place.new(it)
    end
    
    def self.all(offset=0, limit=nil)
        result = collection.find({}).skip(offset)
        result.limit(limit) if !limit.nil?
        return to_places(result)
    end
    
    def destroy
        id = BSON::ObjectId.from_string(@id)
        self.class.collection.delete_one(:_id => id)
        
    end
    
    def self.get_address_components(sort=nil, offset=nil, limit=nil)
        prototype = [
            { :$unwind => '$address_components' },
            { :$project => 
                {
                    :address_components => 1,
                    :formatted_address => 1,
                    :'geometry.geolocation' => 1
                }
            }
        ]
        
        prototype << {:$sort => sort} if !sort.nil?
        prototype << {:$skip => offset} if !offset.nil?
        prototype << {:$limit => limit} if !limit.nil?
        collection.find.aggregate(prototype)
    end
    
    def self.get_country_names
        results = collection.find.aggregate([
            { :$unwind => '$address_components' },
            { :$project => 
                {
                    :_id => 0,
                    :'address_components.long_name' => 1,
                    :'address_components.types' => 1,
                }
            },
            { :$match => { :'address_components.types' => 'country' } },
            { :$group => { :_id => '$address_components.long_name'} }
        ])
        
        results.to_a.map { |doc| doc[:_id] }
    end
    
    def self.find_ids_by_country_code(country_code)
        result = collection.find.aggregate([
            {
                :$match => {
                    :'address_components.types' => 'country',
                    :'address_components.short_name' => country_code
                }
            },
            { :$project => { :_id => 1 } }
        ])

        result.map { |doc| doc[:_id].to_s }
    end
    
    def self.create_indexes
        collection.indexes.create_one(:'geometry.geolocation' => Mongo::Index::GEO2DSPHERE)
    end
    
    def self.remove_indexes
        collection.indexes.drop_one('geometry.geolation_2dsphere')
    end
    
    def self.near(point, max_meters=nil)
        qry= {
            :'geometry.geolocation' => {
                :$near => { :$geometry => point.to_hash, :$max_distance => max_meters }    
            }    
        }
        collection.find(qry)
    end
    
    def near(max_distance=nil)
        result = self.class.near(@location, max_distance)
        self.class.to_places(result)
    end
end