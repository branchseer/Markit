
protocol Connector {
    func value(named name: String) -> Any?
    func setValue(_ value: Any?, withName name: String)
}

class OnwerConnector: Connector {
    func value(named name: String) -> Any? {
        if (name.isEmpty) {
            return owner
        }
        else {
            return owner?.value(forKeyPath: name)
        }
    }
    
    func setValue(_ value: Any?, withName name: String) {
        owner?.setValue(value, forKeyPath: name)
    }
    
    private weak var owner: NSObject?
    
    init(owner: NSObject?) {
        self.owner = owner
    }
}
