import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()
    var formattedDate: String {
        let dayOfMonth = Calendar.autoupdatingCurrent.component(.day, from: Date())
        return (ordinalFormatter.string(from: NSNumber(value: dayOfMonth)) ?? "") + " " + timeFormatter.string(from: Date())
    }
    var system = System()
    var battery = Battery()

    func applicationWillFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 500, height: 500), styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = true
        window.setFrame(NSScreen.main!.frame.divided(atDistance: 20, from: .maxYEdge).slice, display: true)
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.backgroundColor = .black
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.makeKeyAndOrderFront(self)

        let content = NSView()
        let container = NSStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.spacing = 20
        content.addSubview(container)
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            container.heightAnchor.constraint(equalTo: content.heightAnchor)
        ])
        window.contentView = content

        let dateLabel = NSTextField(labelWithString: self.formattedDate)
        dateLabel.textColor = .lightGray
        container.addArrangedSubview(dateLabel)

        let cpuLabel = NSTextField(labelWithString: "C 0%")
        cpuLabel.textColor = .lightGray
        container.addArrangedSubview(cpuLabel)

        let batteryLabel = NSTextField(labelWithString: "B 0%")
        batteryLabel.textColor = .lightGray
        container.addArrangedSubview(batteryLabel)

        _ = battery.open()

        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            dateLabel.stringValue = self.formattedDate
            let usage = self.system.usageCPU()
            cpuLabel.stringValue = String(format: "C %.0f%%", usage.system + usage.user)
            batteryLabel.stringValue = String(format: "%@ %.0f%%", self.battery.icon, self.battery.charge)
        }
        timer.tolerance = 0.1
    }

    func applicationWillTerminate(_ notification: Notification) {
        _ = battery.close()
    }
}

let app = NSApplication.shared
app.delegate = AppDelegate()
app.run()
exit(0)
