//
//  SubscriptionManager.swift
//  Hype Buddy
//
//  StoreKit 2 subscription handling
//

import Foundation
import StoreKit
import Observation
import os.log

private let storeLogger = Logger(subsystem: "com.hypebuddy", category: "Store")

/// Manages premium subscription state using StoreKit 2
@Observable
@MainActor
final class SubscriptionManager {
    private(set) var isPremium: Bool = false
    private(set) var products: [Product] = []
    private(set) var purchaseInProgress = false
    
    // Store the task in a nonisolated way to allow cancellation in deinit
    @ObservationIgnored
    nonisolated(unsafe) private var updateListenerTask: Task<Void, Never>? = nil
    
    // MARK: - Initialization
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let productIDs = [
                Config.premiumMonthlyProductID,
                Config.premiumYearlyProductID
            ]
            products = try await Product.products(for: productIDs)
            storeLogger.info("Loaded \\(self.products.count) products")
        } catch {
            storeLogger.error("Failed to load products: \\(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            storeLogger.info("Purchase successful: \\(product.id)")
            
        case .userCancelled:
            throw SubscriptionError.userCancelled
            
        case .pending:
            throw SubscriptionError.pending
            
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Config.premiumMonthlyProductID ||
                   transaction.productID == Config.premiumYearlyProductID {
                    hasActiveSubscription = transaction.revocationDate == nil
                }
            }
        }
        
        isPremium = hasActiveSubscription
        storeLogger.info("Subscription status updated: isPremium = \\(self.isPremium)")
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Product Info
    
    var monthlyProduct: Product? {
        products.first { $0.id == Config.premiumMonthlyProductID }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == Config.premiumYearlyProductID }
    }
    
    var monthlyPriceString: String {
        monthlyProduct?.displayPrice ?? "$5.99"
    }
    
    var yearlyPriceString: String {
        yearlyProduct?.displayPrice ?? "$34.99"
    }
    
    var yearlySavings: String {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return "Save 50%"
        }
        
        let monthlyAnnual = monthly.price * 12
        let savings = monthlyAnnual - yearly.price
        let percentage = NSDecimalNumber(decimal: (savings / monthlyAnnual) * 100)
        return "Save \(percentage.intValue)%"
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError, Equatable {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
