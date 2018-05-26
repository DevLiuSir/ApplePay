//
//  ViewController.swift
//  ApplePay
//
//  Created by Liu Chuan on 2018/2/27.
//  Copyright © 2018年 LC. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {
    
    
    var summaryItems = [PKPaymentSummaryItem]()
    var shippingMethods = [PKShippingMethod]()
    
    // MARK: - lazy loading
    
/*
     Apple Pay Buttons 按钮有三个样式：White, WhiteOutLine, Black
     同样具有三个不同类型：Plain, Buy,SetUp
 */
    /// 支付按钮
    private lazy var payButton: PKPaymentButton = {
        let pay = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        pay.frame = CGRect(x: 191, y: 667, width: 168, height: 53)
        pay.addTarget(self, action: #selector(payBtnClickted), for: .touchUpInside)
        return pay
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        view.addSubview(payButton)
    }
   
}

// MARK: - Event Handling
extension ViewController {
    
    /// 支付按钮点击事件
    @objc private func payBtnClickted() {
        
        // 确定该设备是否能够处理支付请求(是否支持 Apple Pay)
        if !PKPaymentAuthorizationViewController.canMakePayments() {
            print("设备不支持 Apple Pay")
            let alert = UIAlertController(title: "设备不支持 Apple Pay", message: nil, preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "确定", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        /// 检查是否支持用户卡片
        var paymentNetworks: [PKPaymentNetwork]!
        
        if #available(iOS 9.2, *) {
            paymentNetworks = [
                PKPaymentNetwork(rawValue: PKPaymentNetwork.visa.rawValue),
                PKPaymentNetwork(rawValue: PKPaymentNetwork.masterCard.rawValue),
                PKPaymentNetwork(rawValue: PKPaymentNetwork.chinaUnionPay.rawValue) // 银联卡要求 iOS 9.2 +
            ]
        }else {
            paymentNetworks = [
                PKPaymentNetwork(rawValue: PKPaymentNetwork.visa.rawValue),
                PKPaymentNetwork(rawValue: PKPaymentNetwork.masterCard.rawValue)
            ]
        }
        
        // 创建付款请求
        let request = PKPaymentRequest()
        
        // 国家代码
        request.countryCode = "CN"
        
        // RMB的币种代码
        request.currencyCode = "CNY"
        
        // 用户可进行支付的银行卡
        request.supportedNetworks = paymentNetworks
        
        // 申请的merchantID
        request.merchantIdentifier = "merchant.me.leodev2.ApplePayDemo"
        
        // 设置支持的交易处理协议，3DS必须支持，EMV为可选，目前国内的话使用两者
        request.merchantCapabilities = [.capability3DS, .capabilityEMV]
        
        request.requiredBillingContactFields = [PKContactField.emailAddress]
        
        // 邮寄账单, 默认PKAddressField.none(不邮寄账单)
        request.requiredShippingContactFields = [.postalAddress, .phoneNumber, .name]
        
        //设置两种配送方式
        let freeShipping = PKShippingMethod(label: "包邮", amount: NSDecimalNumber.zero)
        freeShipping.identifier = "freeshipping"
        freeShipping.detail = "6-8 天 送达"
        let expressShipping = PKShippingMethod(label: "极速送达", amount: NSDecimalNumber(string: "10.00"))
        expressShipping.identifier = "expressshipping"
        expressShipping.detail = "2-3 小时 送达"
        
        shippingMethods = [freeShipping, expressShipping]
        
        // 送货方式
        request.shippingMethods = [freeShipping, expressShipping]
        
        // 添加付款项目
        let item1 = PKPaymentSummaryItem(label: "购物袋小计", amount: NSDecimalNumber(value: 102073.00))
        let item2 = PKPaymentSummaryItem(label: "免费送货", amount: NSDecimalNumber(value: 0.00))
        let item3 = PKPaymentSummaryItem(label: "APPLE", amount: NSDecimalNumber(value: 102073.00))
        
        summaryItems = [item1, item2, item3]
        
        request.paymentSummaryItems = [item1, item2, item3]
        
        // 初始化支付授权控制器并显示
        let authViewController = PKPaymentAuthorizationViewController(paymentRequest: request)
        authViewController?.delegate = self
        present(authViewController!, animated: true, completion: nil)
    }
}

// MARK: - PKPaymentAuthorizationViewControllerDelegate
extension ViewController: PKPaymentAuthorizationViewControllerDelegate {
    
    /// 送货信息选择回调，如果需要根据送货地址调整送货方式，比如普通地区包邮+极速配送，偏远地区只有付费普通配送，进行支付金额重新计算，可以实现该代理
    ///
    /// - Parameters:
    ///   - controller: PKPaymentAuthorizationViewController
    ///   - contact: 地址
    ///   - completion: 回调
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        
        /*** contact送货地址信息，PKContact类型 ***/
/*
        /// 联系人姓名
        let name = contact.name
        /// 联系人地址
        let postalAddress = contact.postalAddress
        /// 联系人邮箱
        let emailAddress = contact.emailAddress
        /// /联系人手机
        let phoneNumber = contact.phoneNumber
*/
        completion(.success, shippingMethods, summaryItems)
    }
    
    /// 处理交易数据，并把状态返回给应用
    ///
    /// - Parameters:
    ///   - controller: 当前的 PKPaymentAuthorizationViewController
    ///   - payment: payment
    ///   - completion: 回调
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        /// 支付凭据，发给服务端进行验证支付是否真实有效
        let paymentToken = payment.token
        /// 账单信息
        let billingContact = payment.billingContact
        /// 送货信息
        let shippingContact = payment.shippingContact
        /// 送货方式
        let shippingMethod = payment.shippingMethod
        
        print("账单信息: \(String(describing: billingContact))")
        print("送货信息: \(String(describing: shippingContact))")
        print("送货方式: \(String(describing: shippingMethod))")
        
        print("交易成功!......\(paymentToken)")
        
        // 交易成功了
        completion(.success)
        
        // 交易成功后的处理
        // ...
    }
    
    
    /// 支付完成，隐藏 PKPaymentAuthorizationViewController
    ///
    /// - Parameter controller: 当前的 PKPaymentAuthorizationViewController
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
