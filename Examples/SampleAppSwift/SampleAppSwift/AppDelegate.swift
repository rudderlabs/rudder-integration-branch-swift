//
//  AppDelegate.swift
//  ExampleSwift
//
//  Created by Arnab Pal on 09/05/20.
//  Copyright © 2020 RudderStack. All rights reserved.
//

import UIKit
import Rudder
import RudderBranch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var client: RSClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        let config: RSConfig = RSConfig(writeKey: "<WRITE_KEY>")
            .dataPlaneURL("<DATA_PLANE_URL>")
            .loglevel(.debug)
            .trackLifecycleEvents(false)
            .recordScreenViews(false)
        
        client = RSClient.sharedInstance()
        client?.configure(with: config)

        client?.addDestination(RudderBranchDestination())
        sendEvents()
        return true
    }
    
    func sendEvents() {
        identify()
        trackStandardEvent()
        trackCustomEvent()
        reset()
        func identify() {
            RSClient.sharedInstance().identify("iOS_user_3")
        }
        func trackStandardEvent() {
            let products: [[String: Any]] = [
                [
                    RSKeys.Ecommerce.productId: "3001", //SKU will be given preference
                    RSKeys.Ecommerce.sku: "sku",    //SKU will be given preference
                    RSKeys.Ecommerce.brand: "brand",
                    RSKeys.Ecommerce.variant: "variant",
                    RSKeys.Ecommerce.rating: 6,
                    RSKeys.Ecommerce.currency: "INR",
                    RSKeys.Ecommerce.productName: "name",
                    RSKeys.Ecommerce.category: "Animals & Pet Supplies",
                    RSKeys.Ecommerce.quantity: 10,
                    RSKeys.Ecommerce.price: 500
                ]
            ]
            let properties: [String: Any] = [
                RSKeys.Ecommerce.query: "Apple_sampleValue",
                RSKeys.Ecommerce.revenue: 11.11,
                RSKeys.Ecommerce.currency: "INR",
                RSKeys.Ecommerce.shipping: 200,
                RSKeys.Ecommerce.affiliation: "affliation_sampleValue",
                RSKeys.Ecommerce.coupon: "coupoun_sampleValue",
                RSKeys.Ecommerce.tax: 300,
                RSKeys.Ecommerce.orderId: "orderId_sampleValue",
                RSKeys.Ecommerce.products: products
            ]
            
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productAdded, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productAddedToWishList, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.cartViewed, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.checkoutStarted, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.paymentInfoEntered, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.orderCompleted, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.spendCredits, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.reserve, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.promotionViewed, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.promotionClicked, properties: properties)
            
            RSClient.sharedInstance().track(RSEvents.LifeCycle.completeRegistration, properties: properties)
            RSClient.sharedInstance().track(RSEvents.LifeCycle.completeTutorial, properties: properties)
            RSClient.sharedInstance().track(RSEvents.LifeCycle.achieveLevel, properties: properties)
            RSClient.sharedInstance().track(RSEvents.LifeCycle.unlockAchievement, properties: properties)
            
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productsSearched, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productViewed, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productListViewed, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productShared, properties: properties)
            RSClient.sharedInstance().track(RSEvents.Ecommerce.productReviewed, properties: properties)
        }
        func trackCustomEvent() {
            RSClient.sharedInstance().track("Empty Track Event")
            RSClient.sharedInstance().track("Custom Track Event", properties: [
                "key-1": "value-1",
                "key-2": 12,
                "key-3": 14.50
            ])
        }
        func reset() {
            RSClient.sharedInstance().identify("iOS_user_3")
            RSClient.sharedInstance().track("Custom track event before RESET call")
            RSClient.sharedInstance().reset()
            RSClient.sharedInstance().track("Custom track event after RESET call")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension UIApplicationDelegate {
    var client: RSClient? {
        if let appDelegate = self as? AppDelegate {
            return appDelegate.client
        }
        return nil
    }
}
