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
                RSECommerceConstants.Event.productViewed,
                RSECommerceConstants.Event.productShared,
                RSECommerceConstants.Event.productReviewed:
                if let product = getProductData(from: message.properties) {
                    let object = BranchUniversalObject()
                    object.contentMetadata = product
                    object.contentMetadata.contentSchema = .commerceProduct
                    branchEvent.contentItems = [object]
                }
            case
                RSECommerceConstants.Event.productAdded,
                RSECommerceConstants.Event.productAddedToWishList,
                RSECommerceConstants.Event.cartViewed,
                RSECommerceConstants.Event.checkoutStarted,
                RSECommerceConstants.Event.paymentInfoEntered,
                RSECommerceConstants.Event.orderCompleted,
                RSECommerceConstants.Event.spendCredits,
                RSECommerceConstants.Event.productListViewed:
                insertECommerceProductData(branchEvent: &branchEvent, properties: message.properties)
            case
                RSECommerceConstants.Event.productsSearched:
                if let query = message.properties?[RSECommerceConstants.Key.query] {
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
        return [RSECommerceConstants.Key.productId, RSECommerceConstants.Key.sku, RSECommerceConstants.Key.brand, RSECommerceConstants.Key.variant, RSECommerceConstants.Key.rating, RSECommerceConstants.Key.currency ,RSECommerceConstants.Key.name, RSECommerceConstants.Key.category, RSECommerceConstants.Key.quantity, RSECommerceConstants.Key.price, RSECommerceConstants.Key.revenue, RSECommerceConstants.Key.total, RSECommerceConstants.Key.value, RSECommerceConstants.Key.currency, RSECommerceConstants.Key.shipping, RSECommerceConstants.Key.affiliation, RSECommerceConstants.Key.coupon, RSECommerceConstants.Key.tax, RSECommerceConstants.Key.orderId]
    }
    
    func getBranchEvent(eventName: String) -> BranchEvent {
        switch eventName {
        case RSECommerceConstants.Event.productAdded:
            return BranchEvent.standardEvent(BranchStandardEvent.addToCart)
        case RSECommerceConstants.Event.productAddedToWishList:
            return BranchEvent.standardEvent(BranchStandardEvent.addToWishlist)
        case RSECommerceConstants.Event.cartViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewCart)
        case RSECommerceConstants.Event.checkoutStarted:
            return BranchEvent.standardEvent(BranchStandardEvent.initiatePurchase)
        case RSECommerceConstants.Event.paymentInfoEntered:
            return BranchEvent.standardEvent(BranchStandardEvent.addPaymentInfo)
        case RSECommerceConstants.Event.orderCompleted:
            return BranchEvent.standardEvent(BranchStandardEvent.purchase)
        case RSECommerceConstants.Event.spendCredits:
            return BranchEvent.standardEvent(BranchStandardEvent.spendCredits)
        case RSECommerceConstants.Event.productsSearched:
            return BranchEvent.standardEvent(BranchStandardEvent.search)
        case RSECommerceConstants.Event.productViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewItem)
        case RSECommerceConstants.Event.productListViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewItems)
        case RSECommerceConstants.Event.productShared:
            return BranchEvent.standardEvent(BranchStandardEvent.share)
        case RSECommerceConstants.Event.completeRegistration:
            return BranchEvent.standardEvent(BranchStandardEvent.completeRegistration)
        case RSECommerceConstants.Event.completeTutorial:
            return BranchEvent.standardEvent(BranchStandardEvent.completeTutorial)
        case RSECommerceConstants.Event.achieveLevel:
            return BranchEvent.standardEvent(BranchStandardEvent.achieveLevel)
        case RSECommerceConstants.Event.unlockAchievement:
            return BranchEvent.standardEvent(BranchStandardEvent.unlockAchievement)
        case RSECommerceConstants.Event.productAddedToWishList:
            return BranchEvent.standardEvent(BranchStandardEvent.addToWishlist)
        case RSECommerceConstants.Event.promotionViewed:
            return BranchEvent.standardEvent(BranchStandardEvent.viewAd)
        case RSECommerceConstants.Event.promotionClicked:
            return BranchEvent.standardEvent(BranchStandardEvent.clickAd)
        case RSECommerceConstants.Event.productReviewed:
            return BranchEvent.standardEvent(BranchStandardEvent.rate)
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
            case RSECommerceConstants.Key.productId:
                productId = "\(value)"
            case RSECommerceConstants.Key.sku:
                sku = "\(value)"
            case RSECommerceConstants.Key.brand:
                product.productBrand = "\(value)"
            case RSECommerceConstants.Key.variant:
                product.productVariant = "\(value)"
            case RSECommerceConstants.Key.rating:
                product.rating = Double("\(value)") ?? 0
            case RSECommerceConstants.Key.currency:
                if BNCCurrencyAllCurrencies().contains("\(value)") {
                    product.currency = BNCCurrency(rawValue: "\(value)")
                }
            case RSECommerceConstants.Key.name:
                product.productName = "\(value)"
            case RSECommerceConstants.Key.category:
                if BNCProductCategoryAllCategories().contains("\(value)") {
                    product.productCategory = BNCProductCategory(rawValue: "\(value)")
                }
            case RSECommerceConstants.Key.quantity:
                product.quantity = Double("\(value)") ?? 0
            case RSECommerceConstants.Key.price:
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
        if let products = properties[RSECommerceConstants.Key.products] as? [[String: Any]] {
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
            case RSECommerceConstants.Key.revenue:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSECommerceConstants.Key.total:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSECommerceConstants.Key.value:
                branchEvent.revenue = NSDecimalNumber(string: "\(value)")
            case RSECommerceConstants.Key.currency:
                if BNCCurrencyAllCurrencies().contains("\(value)") {
                    branchEvent.currency = BNCCurrency(rawValue: "\(value)")
                }
            case RSECommerceConstants.Key.shipping:
                branchEvent.shipping = NSDecimalNumber(string: "\(value)")
            case RSECommerceConstants.Key.affiliation:
                branchEvent.affiliation = "\(value)"
            case RSECommerceConstants.Key.coupon:
                branchEvent.coupon = "\(value)"
            case RSECommerceConstants.Key.tax:
                branchEvent.tax = NSDecimalNumber(string: "\(value)")
            case RSECommerceConstants.Key.orderId:
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
