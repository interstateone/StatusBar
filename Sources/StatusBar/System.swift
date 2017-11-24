import IOKit
import Darwin

// https://github.com/beltex/SystemKit/blob/master/SystemKit/Battery.swift
public struct Battery {
    fileprivate enum Key: String {
        case acPowered        = "ExternalConnected"
        case currentCapacity  = "CurrentCapacity"
        case fullyCharged     = "FullyCharged"
        case isCharging       = "IsCharging"
        case maxCapacity      = "MaxCapacity"
        case timeRemaining    = "TimeRemaining"
    }

    fileprivate static let serviceName = "AppleSmartBattery"
    fileprivate var service: io_service_t = 0

    public init() { }

    public mutating func open() -> kern_return_t {
        if service != 0 {
            return kIOReturnStillOpen
        }

        service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceNameMatching(Battery.serviceName))

        if service == 0 {
            return kIOReturnNotFound
        }

        return kIOReturnSuccess
    }

    public mutating func close() -> kern_return_t {
        let result = IOObjectRelease(service)
        service = 0
        return result
    }

    public var currentCapacity: Int {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.currentCapacity.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Int
    }

    public var maxCapacity: Int {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.maxCapacity.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Int
    }

    public var isACPowered: Bool {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.acPowered.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Bool
    }

    public var isCharging: Bool {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.isCharging.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Bool
    }

    public var isCharged: Bool {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.fullyCharged.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Bool
    }

    public var charge: Double {
        return (Double(currentCapacity) / Double(maxCapacity) * 100.0).rounded()
    }

    public var timeRemaining: Int {
        let prop = IORegistryEntryCreateCFProperty(service,
                                                   Key.timeRemaining.rawValue as CFString!,
                                                   kCFAllocatorDefault, 0)
        return prop!.takeUnretainedValue() as! Int
    }

    public var timeRemainingFormatted: String {
        let time = timeRemaining
        return String(format: "%d:%02d", time / 60, time % 60)
    }

    var icon: String {
        if isACPowered {
            return "🔌"
        }
        else if isCharged {
            return "🔋"
        }
        else if isCharging {
            return "⚡️"
        }
        else {
            return "B"
        }
    }
}

// https://github.com/beltex/SystemKit/blob/master/SystemKit/System.swift
struct System {
    fileprivate var loadPrevious = host_cpu_load_info()

    public mutating func usageCPU() -> (system: Double, user: Double, idle: Double, nice: Double) {
            let load = System.hostCPULoadInfo()

            let userDiff = Double(load.cpu_ticks.0 - loadPrevious.cpu_ticks.0)
            let sysDiff  = Double(load.cpu_ticks.1 - loadPrevious.cpu_ticks.1)
            let idleDiff = Double(load.cpu_ticks.2 - loadPrevious.cpu_ticks.2)
            let niceDiff = Double(load.cpu_ticks.3 - loadPrevious.cpu_ticks.3)

            let totalTicks = sysDiff + userDiff + niceDiff + idleDiff

            let sys  = sysDiff  / totalTicks * 100.0
            let user = userDiff / totalTicks * 100.0
            let idle = idleDiff / totalTicks * 100.0
            let nice = niceDiff / totalTicks * 100.0

            loadPrevious = load

            return (sys, user, idle, nice)
    }

    fileprivate static func hostCPULoadInfo() -> host_cpu_load_info {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate(capacity: 1)

        return data
    }
}
