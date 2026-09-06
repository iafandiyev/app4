import SwiftUI

class AdminViewModel: ObservableObject {
    @Published var orders: [OrderItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastNotificationId: Int = 0
    @Published var newOrderAlert: String?
    
    @AppStorage("server_url") var serverURL: String = "http://192.168.1.84"
    
    private var pollTimer: Timer?
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        fetchOrders()
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            self?.pollNotifications()
        }
    }
    
    func fetchOrders() {
        guard let url = URL(string: "\(serverURL)/api/admin/orders") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Serverə qoşulmadı (\(error.localizedDescription)). Wi-Fi-ya qoşulduğunuzdan əmin olun."
                    return
                }
                if let data = data {
                    do {
                        let decoded = try JSONDecoder().decode(OrdersResponse.self, from: data)
                        self?.orders = decoded.orders
                        self?.errorMessage = nil
                    } catch {
                        self?.errorMessage = "Məlumat oxunmadı: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
    }
    
    func pollNotifications() {
        guard let url = URL(string: "\(serverURL)/api/admin/notifications/poll") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Serverə qoşulmadı: \(error.localizedDescription)"
                }
                return
            }
            guard let data = data else { return }
            do {
                let res = try JSONDecoder().decode(NotificationsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.errorMessage = nil
                    if let latest = res.notifications.first, latest.id > self.lastNotificationId {
                        self.lastNotificationId = latest.id
                        self.newOrderAlert = "\(latest.title): \(latest.message)"
                        NotificationManager.shared.showLocalNotification(
                            title: "🔔 " + latest.title,
                            body: latest.message
                        )
                        self.fetchOrders()
                    }
                }
            } catch {
                // Ignore poll decoding errors silently
            }
        }.resume()
    }
    
    func updateOrder(orderId: Int, status: String, location: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/admin/orders/\(orderId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = OrderUpdatePayload(status: status, current_location: location, admin_notes: nil)
        request.httpBody = try? JSONEncoder().encode(payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data, error == nil {
                    self?.fetchOrders()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
}

struct ContentView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var showingSettings = false
    @State private var selectedFilter: String = "Hamısı"
    
    let filters = ["Hamısı", "Gözləmədə", "Hazırlanır", "Çatdırılmada", "Təhvil verildi"]
    
    var filteredOrders: [OrderItem] {
        if selectedFilter == "Hamısı" {
            return vm.orders
        }
        return vm.orders.filter { $0.status == selectedFilter }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // New Order Alert Banner
                    if let alert = vm.newOrderAlert {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.yellow)
                            Text(alert)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Spacer()
                            Button(action: { vm.newOrderAlert = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top))
                    }
                    
                    // Network Connection Error Banner
                    if let err = vm.errorMessage {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.white)
                            Text(err)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Spacer()
                            Button(action: {
                                vm.fetchOrders()
                                vm.pollNotifications()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 6)
                    }
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    // Orders List
                    if filteredOrders.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Sifariş tapılmadı")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Yeni sifariş daxil olduqda bildiriş səsi ilə xəbərdar olacaqsınız.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredOrders) { order in
                                    OrderCardView(order: order, onSave: { newStatus, newLocation in
                                        vm.updateOrder(orderId: order.id, status: newStatus, location: newLocation) { success in
                                            if success {
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            }
                                        }
                                    })
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Kitabça Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { vm.fetchOrders() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(serverURL: $vm.serverURL)
            }
        }
    }
}

struct OrderCardView: View {
    let order: OrderItem
    let onSave: (String, String) -> Void
    
    @State private var selectedStatus: String = ""
    @State private var selectedLocation: String = ""
    @State private var isSavedFeedback = false
    
    let statusOptions = ["Gözləmədə", "Hazırlanır", "Çatdırılmada", "Təhvil verildi", "Ləğv edildi"]
    let locationPresets = [
        "Kuryerdə (Yoldadır)",
        "28 May metrosunda",
        "Koroğlu metrosunda",
        "Gənclik metrosunda",
        "Sahil metrosunda",
        "Elmlər Akademiyası metrosunda",
        "Nərimanov metrosunda",
        "Anbarda çap olunur",
        "Paketləndi, kuryerə verilir",
        "Azərpoçt şöbəsinə göndərildi",
        "Müştəriyə təhvil verildi"
    ]
    
    init(order: OrderItem, onSave: @escaping (String, String) -> Void) {
        self.order = order
        self.onSave = onSave
        _selectedStatus = State(initialValue: order.status)
        _selectedLocation = State(initialValue: order.current_location ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Code & Status
            HStack {
                Text("#" + order.order_code.replacingOccurrences(of: "kitab[", with: "").replacingOccurrences(of: "]", with: ""))
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.blue)
                
                Spacer()
                
                StatusBadge(status: order.status)
            }
            
            Divider()
            
            // Book Info
            VStack(alignment: .leading, spacing: 4) {
                Text(order.book_title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack {
                    Text("\(String(format: "%.2f", order.total_amount)) AZN")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("(\(order.quantity) ədəd)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.created_at)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Delivery Target
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                Text(order.delivery_target)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("(\(order.delivery_type))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = order.notes, !notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .foregroundColor(.orange)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Customer Contact Actions
            HStack(spacing: 12) {
                // Direct Call
                Button(action: {
                    let clean = order.customer_phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let url = URL(string: "tel:\(clean)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                        Text(order.customer_phone)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // WhatsApp
                Button(action: {
                    let clean = order.customer_phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let url = URL(string: "https://wa.me/\(clean)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("WhatsApp")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // Status & Location Editor
            VStack(alignment: .leading, spacing: 8) {
                // Status Picker
                HStack {
                    Text("Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) { st in
                            Text(st).tag(st)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Location Selector ("Hansı yerdə olduğunu seçim")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hansı yerdə olduğu:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(locationPresets, id: \.self) { preset in
                            Button(preset) {
                                selectedLocation = preset
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedLocation.isEmpty ? "Yer seçin..." : selectedLocation)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    
                    // Or custom input
                    TextField("və ya dəqiq yer yazın...", text: $selectedLocation)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
                
                // Save Button
                Button(action: {
                    onSave(selectedStatus, selectedLocation)
                    isSavedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isSavedFeedback = false
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: isSavedFeedback ? "checkmark.circle.fill" : "square.and.arrow.down")
                        Text(isSavedFeedback ? "Yadda Saxlanıldı!" : "Yeri & Statusu Yadda Saxla")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(isSavedFeedback ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct StatusBadge: View {
    let status: String
    
    var color: Color {
        switch status {
        case "Gözləmədə": return .orange
        case "Hazırlanır": return .blue
        case "Çatdırılmada": return .purple
        case "Təhvil verildi": return .green
        case "Ləğv edildi": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct SettingsView: View {
    @Binding var serverURL: String
    @Environment(\.presentationMode) var presentationMode
    @State private var tempURL: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Ünvanı"), footer: Text("Nümunə: http://192.168.1.84 və ya ngrok/domen ünvanı.")) {
                    TextField("Server URL", text: $tempURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Bildiriş & Səs Yoxlanışı"), footer: Text("Bu düyməyə basaraq tətbiqin səs və bildiriş pəncərəsinin işləməsini dərhal yoxlaya bilərsiniz.")) {
                    Button(action: {
                        NotificationManager.shared.showLocalNotification(
                            title: "🔔 Test Bildirişi",
                            body: "Kitabça Admin bildiriş və səs sistemi aktivdir!"
                        )
                    }) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.blue)
                            Text("Bildirişi Yoxla (Səs & Siqnal)")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Tənzimləmələr")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Yadda saxla") {
                        serverURL = tempURL
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ləğv et") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                tempURL = serverURL
            }
        }
    }
}