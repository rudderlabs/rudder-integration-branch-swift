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
            case RSEvents.Ecommerce.productsSearched:
                if let query = message.properties?[RSKeys.Ecommerce.query] {
                    let object = BranchUniversalObject()
                    object.keywords = ["\(query)"]
                    branchEvent.contentItems = [object]
                }
            default:
                insertECommerceProductData(branchEvent: &branchEvent, properties: message.properties)
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
        return [RSKeys.Ecommerce.productId, RSKeys.Ecommerce.sku, RSKeys.Ecommerce.brand, RSKeys.Ecommerce.variant, RSKeys.Ecommerce.rating, RSKeys.Ecommerce.currency ,RSKeys.Ecommerce.productName, RSKeys.Ecommerce.category, RSKeys.Ecommerce.quantity, RSKeys.Ecommerce.price, RSKeys.Ecommerce.revenue, RSKeys.Ecommerce.total, RSKeys.Ecommerce.value, RSKeys.Ecommerce.currency, RSKeys.Ecommerce.shipping, RSKeys.Ecommerce.affiliation, RSKeys.Ecommerce.coupon, RSKeys.Ecommerce.tax, RSKeys.Ecommerce.orderId, RSKeys.Ecommerce.products, RSKeys.Ecommerce.query]
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
        
    func getProductData(from properties: [String: Any]?, isProductArray: Bool = false) -> BranchContentMetadata? {
        guard let properties = properties else {
            return nil
        }
        let product = BranchContentMetadata()
        var productId: String?
        var sku: String?
        var customMetadata = [String: String]()
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
                if isProductArray {
                    customMetadata[key] = "\(value)"
                }
            }
        }
        if let sku = sku {
            product.sku = sku
        } else if let productId = productId {
            product.sku = productId
        }
        if !customMetadata.isEmpty {
            product.customMetadata = NSMutableDictionary(dictionary: customMetadata)
        }
        if product.isEmpty {
            return nil
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
                if let product = getProductData(from: productDict, isProductArray: true) {
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
        var revenue: NSDecimalNumber?
        var total: NSDecimalNumber?
        var value: NSDecimalNumber?
        for (key, val) in properties {
            switch key {
            case RSKeys.Ecommerce.revenue:
                revenue = NSDecimalNumber(string: "\(val)")
            case RSKeys.Ecommerce.total:
                total = NSDecimalNumber(string: "\(val)")
            case RSKeys.Ecommerce.value:
                value = NSDecimalNumber(string: "\(val)")
            case RSKeys.Ecommerce.currency:
                if BNCCurrencyAllCurrencies().contains("\(val)") {
                    branchEvent.currency = BNCCurrency(rawValue: "\(val)")
                }
            case RSKeys.Ecommerce.shipping:
                branchEvent.shipping = NSDecimalNumber(string: "\(val)")
            case RSKeys.Ecommerce.affiliation:
                branchEvent.affiliation = "\(val)"
            case RSKeys.Ecommerce.coupon:
                branchEvent.coupon = "\(val)"
            case RSKeys.Ecommerce.tax:
                branchEvent.tax = NSDecimalNumber(string: "\(val)")
            case RSKeys.Ecommerce.orderId:
                branchEvent.transactionID = "\(val)"
            default: break
            }
        }
        if let revenue = revenue {
            branchEvent.revenue = revenue
        } else if let total = total {
            branchEvent.revenue = total
        } else if let value = value {
            branchEvent.revenue = value
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

extension BranchContentMetadata {
    var isEmpty: Bool {
        return sku == nil && productBrand == nil && productVariant == nil && productName == nil && productCategory == nil
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
