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
    
end