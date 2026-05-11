//
//  AdRemovalPurchaseManager.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/05/06.
//

import Foundation
import StoreKit
import RockCrabShared

@MainActor
@Observable
final class AdRemovalPurchaseManager {
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case restoring
        case purchased
        case failed(String)
    }

    private let productID: String
    private let userDefaults: UserDefaults
    private var updatesTask: Task<Void, Never>?
    #if DEBUG
    private let debugOverrideKey: String
    #endif

    private(set) var product: Product?
    private(set) var state: PurchaseState = .idle
    var isAdsRemoved: Bool {
        didSet {
            userDefaults.set(isAdsRemoved, forKey: AppStorageKeys.adsRemoved)
        }
    }

    init(
        productID: String = AdConfiguration.removeAdsProductID,
        userDefaults: UserDefaults = AppGroupUserDefaults.shared
    ) {
        self.productID = productID
        self.userDefaults = userDefaults
        #if DEBUG
        self.debugOverrideKey = "\(AppStorageKeys.adsRemoved).debugOverride"
        self.isAdsRemoved = userDefaults.object(forKey: debugOverrideKey) as? Bool
            ?? userDefaults.bool(forKey: AppStorageKeys.adsRemoved)
        #else
        self.isAdsRemoved = userDefaults.bool(forKey: AppStorageKeys.adsRemoved)
        #endif
        self.updatesTask = observeTransactions()
    }

    var displayPrice: String {
        product?.displayPrice ?? "3,900원"
    }

    func refresh() async {
        await loadProduct()
        await refreshEntitlements()
    }

    func purchase() async {
        #if DEBUG
        clearDebugOverride()
        #endif

        if product == nil {
            await loadProduct()
        }

        guard let product else {
            state = .failed(productUnavailableMessage)
            return
        }

        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try verifiedTransaction(from: verificationResult)
                await transaction.finish()
                isAdsRemoved = transaction.productID == productID && transaction.revocationDate == nil
                state = isAdsRemoved ? .purchased : .idle
            case .userCancelled, .pending:
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func restorePurchases() async {
        state = .restoring
        do {
            #if DEBUG
            clearDebugOverride()
            #endif
            try await AppStore.sync()
            await refreshEntitlements()
            state = isAdsRemoved ? .purchased : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    #if DEBUG
    func applyDebugPurchase() {
        userDefaults.set(true, forKey: debugOverrideKey)
        isAdsRemoved = true
        state = .purchased
    }

    func resetDebugPurchase() {
        userDefaults.set(false, forKey: debugOverrideKey)
        isAdsRemoved = false
        state = .idle
    }

    private func clearDebugOverride() {
        userDefaults.removeObject(forKey: debugOverrideKey)
    }
    #endif

    private func loadProduct() async {
        state = .loading
        do {
            product = try await Product.products(for: [productID]).first
            state = product == nil
                ? .failed(productUnavailableMessage)
                : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private var productUnavailableMessage: String {
        #if DEBUG
        AppLocalization.string("StoreKit 테스트 상품을 찾을 수 없습니다. Scheme의 StoreKit Configuration과 상품 ID를 확인해 주세요.")
        #else
        AppLocalization.string("구매 상품을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.")
        #endif
    }

    private func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verifiedTransaction(from: result) else { continue }
            if transaction.productID == productID, transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }

        #if DEBUG
        if let debugOverride = userDefaults.object(forKey: debugOverrideKey) as? Bool {
            isAdsRemoved = debugOverride
            state = debugOverride ? .purchased : .idle
            return
        }
        #endif

        isAdsRemoved = hasEntitlement
        if hasEntitlement {
            state = .purchased
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.verifiedTransaction(from: result) else { continue }
                if transaction.productID == self.productID {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            throw error
        }
    }
}
