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
        self.isAdsRemoved = userDefaults.bool(forKey: AppStorageKeys.adsRemoved)
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
        if product == nil {
            await loadProduct()
        }

        guard let product else {
            state = .failed(AppLocalization.string("구매 상품을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요."))
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
            try await AppStore.sync()
            await refreshEntitlements()
            state = isAdsRemoved ? .purchased : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func loadProduct() async {
        state = .loading
        do {
            product = try await Product.products(for: [productID]).first
            state = product == nil
                ? .failed(AppLocalization.string("구매 상품을 찾을 수 없습니다."))
                : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
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
