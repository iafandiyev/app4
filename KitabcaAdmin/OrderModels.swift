import Foundation

struct OrderItem: Codable, Identifiable {
    let id: Int
    let order_code: String
    let customer_phone: String
    let customer_name: String?
    let delivery_type: String
    let delivery_target: String
    let book_id: Int
    let book_title: String
    let book_price: Double
    let quantity: Int
    let total_amount: Double
    var status: String
    var current_location: String?
    let notes: String?
    var admin_notes: String?
    let created_at: String
}

struct OrdersResponse: Codable {
    let orders: [OrderItem]
}

struct NotificationItem: Codable, Identifiable {
    let id: Int
    let order_id: Int?
    let order_code: String?
    let title: String
    let message: String
    let is_read: Int
    let created_at: String
}

struct NotificationsResponse: Codable {
    let unread_count: Int
    let notifications: [NotificationItem]
}

struct OrderUpdatePayload: Codable {
    let status: String?
    let current_location: String?
    let admin_notes: String?
}