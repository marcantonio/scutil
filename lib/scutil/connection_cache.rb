
module Scutil
  # Utiliy class to hold all the connections created, possibly for
  # reuse later.
  class ConnectionCache
    attr_reader :cache
    include Enumerable
    
    def initialize
      @cache = []
    end
    
    # Need each to mixin Enumerable
    def each
      @cache.each do |c|
        yield c
      end
    end
    
    def fetch(hostname)
      each do |c|
        return c if c.hostname == hostname
      end
    end
    
    def exists?(hostname)
      each do |c|
        return true if c.hostname == hostname
      end
      false
    end
    
    def remove_all
      @cache = []
    end
    
    # Remove all instances of _hostname_.
    def remove(hostname)
      @cache.delete_if { |c| c.hostname == hostname }
    end
    
    def <<(conn)
      @cache << conn
    end
    
    def to_s
      @cache.join("\n")
    end
  end
end
