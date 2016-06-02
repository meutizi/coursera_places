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
    
    
end