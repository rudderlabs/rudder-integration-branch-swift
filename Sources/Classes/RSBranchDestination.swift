//
//  RSBranchDestination.swift
//  RudderBranch
//
//  Created by Pallab Maiti on 04/03/22.
//

import Foundation
import RudderStack
import Branch

class RSBranchDestination: RSDestinationPlugin {
    let type = PluginType.destination
    let key = "Branch Metrics"
    var client: RSClient?
    var controller = RSController()
    var branchInstance: Branch?
        
    func update(serverConfig: RSServerConfig, type: UpdateType) {
        guard type == .initial else { return }
        if let branchConfig: BranchConfig = serverConfig.getConfig(forPlugin: self) {
            if !branchConfig.branchKey.isEmpty {
                branchInstance = Branch.getInstance(branchConfig.branchKey)
            }
            if client?.configuration.logLevel == .debug {
                branchInstance?.enableLogging()
            }
        }
    }
    
    func identify(message: IdentifyMessage) -> IdentifyMessage? {
        if var userId = message.userId, !userId.isEmpty {
            if userId.count > 127 {
                userId = String(userId.prefix(127))
            }
            branchInstance?.setIdentity(userId)
        }
        return message
    }
    
    func track(message: TrackMessage) -> TrackMessage? {
        if !message.event.isEmpty {
            var branchEvent: BranchEvent = getBranchEvent(eventName: message.event)
            var customProperties = [String: String]()
            switch message.event {
            case
                RSEvents.Ecommerce.productViewed,
                RSEvents.Ecommerce.productShared,
                RSEvents.Ecommerce.productReviewed:
                if let product = getProductData(from: message.properties) {
                    let object = BranchUniversalObject()
                    object.contentMetadata = product
                    object.contentMetadata.contentSchema = .commerceProduct
                    branchEvent.contentItems = [object]
                }
            case
                RSEvents.Ecommerce.productAdded,
                RSEvents.Ecommerce.productAddedToWishList,
                RSEvents.Ecommerce.cartViewed,
                RSEvents.Ecommerce.checkoutStarted,
                RSEvents.Ecommerce.paymentInfoEntered,
                RSEvents.Ecommerce.orderCompleted,
                RSEvents.Ecommerce.spendCredits,
                RSEvents.Ecommerce.productListViewed:
                insertECommerceProductData(branchEvent: &branchEvent, properties: message.properties)
            case
                RSEvents.Ecommerce.productsSearched:
                if let query = message.properties?[RSKeys.Ecommerce.query] {
                    let object = BranchUniversalObject()
                    object.keywords = ["\(query)"]
                    branchEvent.contentItems = [object]
                }
            default:
                break
            }
            insertCustomPropertiesData(params: &customProperties, properties: message.properties)
            branchEvent.customData = customProperties
            branchEvent.logEvent()
        }
        return message
    }
    
    func screen(message: ScreenMessage) -> ScreenMessage? {
        return message
    }
    
    func reset() {
        branchInstance?.logout()
    }
}

// MARK: - Support methods

extension RSBranchDestination {
    var TRACK_RESERVED_KEYWORDS: [String] {
        return [RSKeys.Ecommerce.productId, RSKeys.Ecommerce.sku, RSKeys.Ecommerce.brand, RSKeys.Ecommerce.variant, RSKeys.Ecommerce.rating, RSKeys.Ecommerce.currency ,RSKeys.Ecommerce.productName, RSKeys.Ecommerce.category, RSKeys.Ecommerce.quantity, RSKeys.Ecommerce.price, RSKeys.Ecommerce.revenue, RSKeys.Ecommerce.total, RSKeys.Ecommerce.value, RSKeys.Ecommerce.currency, RSKeys.Ecommerce.shipping, RSKeys.Ecommerce.affiliation, RSKeys.Ecommerce.coupon, RSKeys.Ecommerce.tax, RSKeys.Ecommerce.orderId]
    }
    
    func getBranchEvent(eventName: String) -> BranchEvent {
        switch eventName {
        case RSEvents.Ecommerce.productAdded:
            return BranchEvent.standardEvent(BranchStandardEvent.addToCart)
        case RSEvents.Ecommerce.productAddedToWishList:
            return BranchEvent.standardEvent(BranchStandardEvent.addToWishlist)
        case RSEvents.Ecommerce.cartViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewCart)
        case RSEvents.Ecommerce.checkoutStarted:
            return BranchEvent.standardEvent(BranchStandardEvent.initiatePurchase)
        case RSEvents.Ecommerce.paymentInfoEntered:
            return BranchEvent.standardEvent(BranchStandardEvent.addPaymentInfo)
        case RSEvents.Ecommerce.orderCompleted:
            return BranchEvent.standardEvent(BranchStandardEvent.purchase)
        case RSEvents.Ecommerce.spendCredits:
            return BranchEvent.standardEvent(BranchStandardEvent.spendCredits)
        case RSEvents.Ecommerce.productsSearched:
            return BranchEvent.standardEvent(BranchStandardEvent.search)
        case RSEvents.Ecommerce.productViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewItem)
        case RSEvents.Ecommerce.productListViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewItems)
        case RSEvents.Ecommerce.productShared:
            return BranchEvent.standardEvent(BranchStandardEvent.share)
        case RSEvents.LifeCycle.completeRegistration:
            return BranchEvent.standardEvent(BranchStandardEvent.completeRegistration)
        case RSEvents.LifeCycle.completeTutorial:
            return BranchEvent.standardEvent(BranchStandardEvent.completeTutorial)
        case RSEvents.LifeCycle.achieveLevel:
            return BranchEvent.standardEvent(BranchStandardEvent.achieveLevel)
        case RSEvents.LifeCycle.unlockAchievement:
            return BranchEvent.standardEvent(BranchStandardEvent.unlockAchievement)
        case RSEvents.Ecommerce.productAddedToWishList:
            return BranchEvent.standardEvent(BranchStandardEvent.addToWishlist)
        case RSEvents.Ecommerce.promotionViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewAd)
        case RSEvents.Ecommerce.promotionClicked:
            return BranchEvent.standardEvent(BranchStandardEvent.clickAd)
        case RSEvents.Ecommerce.productReviewed:
            return BranchEvent.standardEvent(BranchStandardEvent.rate)
        case RSEvents.Ecommerce.reserve:
            return BranchEvent.standardEvent(BranchStandardEvent.reserve)
        default:
            return BranchEvent.customEvent(withName: eventName)
        }
    }
        
    func getProductData(from properties: [String: Any]?) -> BranchContentMetadata? {
        guard let properties = properties else {
            return nil
        }
        let product = BranchContentMetadata()
        var productId: String?
        var sku: String?
        for (key, value) in properties {
            switch key {
            case RSKeys.Ecommerce.productId:
                productId = "\(value)"
            case RSKeys.Ecommerce.sku:
                sku = "\(value)"
            case RSKeys.Ecommerce.brand:
                product.productBrand = "\(value)"
            case RSKeys.Ecommerce.variant:
                product.productVariant = "\(value)"
            case RSKeys.Ecommerce.rating:
                product.rating = Double("\(value)") ?? 0
            case RSKeys.Ecommerce.currency:
                if BNCCurrencyAllCurrencies().contains("\(value)") {
                    product.currency = BNCCurrency(rawValue: "\(value)")
                }
            case RSKeys.Ecommerce.productName:
                product.productName = "\(value)"
            case RSKeys.Ecommerce.category:
                if BNCProductCategoryAllCategories().contains("\(value)") {
                    product.productCategory = BNCProductCategory(rawValue: "\(value)")
                }
            case RSKeys.Ecommerce.quantity:
                product.quantity = Double("\(value)") ?? 0
            case RSKeys.Ecommerce.price:
                product.price = NSDecimalNumber(string: "\(value)")
            default:
                break
            }
        }
        if let sku = sku {
            product.sku = sku
        } else if let productId = productId {
            product.sku = productId
        }
        return product
    }
    
    func insertECommerceProductData(branchEvent: inout BranchEvent, properties: [String: Any]?) {
        guard let properties = properties else {
            return
        }
        var productList = [BranchUniversalObject]()
        if let products = properties[RSKeys.Ecommerce.products] as? [[String: Any]] {
            for productDict in products {
                if let product = getProductData(from: productDict) {
                    let object = BranchUniversalObject()
                    object.contentMetadata = product
                    object.contentMetadata.contentSchema = .commerceProduct
                    productList.append(object)
                }
            }
        } else {
            if let product = getProductData(from: properties) {
                let object = BranchUniversalObject()
                object.contentMetadata = product
                object.contentMetadata.contentSchema = .commerceProduct
                productList.append(object)
            }
        }
        if !productList.isEmpty {
            branchEvent.contentItems = productList
        }
        
        for (key, value) in properties {
            switch key {
            case RSKeys.Ecommerce.revenue:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSKeys.Ecommerce.total:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSKeys.Ecommerce.value:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSKeys.Ecommerce.currency:
                if BNCCurrencyAllCurrencies().contains("\(value)") {
                    branchEvent.currency = BNCCurrency(rawValue: "\(value)")
                }
            case RSKeys.Ecommerce.shipping:
                branchEvent.shipping = NSDecimalNumber(string: "\(value)")
            case RSKeys.Ecommerce.affiliation:
                branchEvent.affiliation = "\(value)"
            case RSKeys.Ecommerce.coupon:
                branchEvent.coupon = "\(value)"
            case RSKeys.Ecommerce.tax:
                branchEvent.tax = NSDecimalNumber(string: "\(value)")
            case RSKeys.Ecommerce.orderId:
                branchEvent.transactionID = "\(value)"
            default: break
            }
        }
    }
    
    func insertCustomPropertiesData(params: inout [String: String], properties: [String: Any]?) {
        guard let properties = properties else {
            return
        }
        for (key, value) in properties {
            if TRACK_RESERVED_KEYWORDS.contains(key) {
                continue
            }
            params[key] = "\(value)"
        }
    }
}

struct BranchConfig: Codable {
    let _branchKey: String?
    var branchKey: String {
        return _branchKey ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case _branchKey = "branchKey"
    }
}

@objc
public class RudderBranchDestination: RudderDestination {
    
    public override init() {
        super.init()
        plugin = RSBranchDestination()
    }
    
}
