//
//  SubscriptionManager.swift
//  Min
//
//  StoreKit 2：月/年订阅 + 终身买断；无自建账号，权益跟 Apple ID。
//  本地用 Products.storekit 测试；上架后在 App Store Connect 建同 ID 产品即可。
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    enum ProductID {
        static let monthly = "Denghao.Min.pro.monthly"
        static let annual = "Denghao.Min.pro.annual"
        static let lifetime = "Denghao.Min.pro.lifetime"
        static let all: [String] = [monthly, annual, lifetime]
    }

    /// 与 Paywall 一致：免费 1 张卡片，Pro 最多 4 张
    static let freeCardLimit = 1
    static let proCardLimit = 4

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Entitlement helpers（与 Paywall 权益对齐）

    var maxCardCount: Int {
        isPro ? Self.proCardLimit : Self.freeCardLimit
    }

    /// 卡片 group 为 1...4。免费可用第 1 张；已有内容的卡片予以保留（避免丢数据）。
    func canUseCard(group: Int, hasExistingItems: Bool) -> Bool {
        if isPro { return true }
        if group <= Self.freeCardLimit { return true }
        return hasExistingItems
    }

    func canUseFontFamily(_ familyName: String) -> Bool {
        isPro || ODRFontCatalog.isFreeFamily(familyName)
    }

    var canUseWeatherWidget: Bool { isPro }

    // MARK: - Public

    func product(id: String) -> Product? {
        products.first { $0.id == id }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
            await updateEntitlements()
        } catch {
            errorMessage = "无法加载订阅商品：\(error.localizedDescription)"
        }
    }

    /// 购买。等待系统支付表期间不置 `isLoading`，避免遮罩挡住金额确认。
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                // 先按本次成交解锁，再同步 currentEntitlements，最后 finish
                if ProductID.all.contains(transaction.productID) {
                    isPro = true
                }
                await updateEntitlements()
                await transaction.finish()
                return isPro
            case .userCancelled:
                return false
            case .pending:
                errorMessage = "购买待处理，完成后会自动解锁 Pro"
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
            return false
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await updateEntitlements()
            if !isPro {
                errorMessage = "未找到可恢复的购买"
            }
        } catch {
            errorMessage = "恢复失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Entitlements

    private func updateEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if ProductID.all.contains(transaction.productID) {
                entitled = true
                break
            }
        }
        isPro = entitled
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            if ProductID.all.contains(transaction.productID) {
                isPro = true
            }
            await updateEntitlements()
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
