//
//  PaywallView.swift
//  Min
//
//  订阅会员 Paywall：月度 / 年度权益相同；突出免费与 Pro 差异
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscription: SubscriptionManager
    @State private var selectedPlan: Plan = .annual
    @State private var isPurchasing = false
    @State private var appear = false

    private let privacyPolicyURL = URL(string: "https://min.anuhao.com/privacy-policy")
    private let termsOfServiceURL = URL(string: "https://min.anuhao.com/terms-of-service")

    enum Plan: String {
        case monthly
        case annual

        var productID: String {
            switch self {
            case .monthly: return SubscriptionManager.ProductID.monthly
            case .annual: return SubscriptionManager.ProductID.annual
            }
        }
    }

    private let benefits: [(icon: String, title: String, free: String, pro: String)] = [
        (
            "square.stack.3d.up",
            "应用卡片",
            "免费可新增 1 个",
            "Pro 最多 4 个"
        ),
        (
            "textformat",
            "自定义字体",
            "系统字体 + 仓耳非白、抖音美好体",
            "全部字体均可下载使用"
        ),
        (
            "cloud.sun",
            "顶部小组件",
            "可用时间、日期",
            "额外解锁天气"
        )
    ]

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 12)

                    hero
                        .padding(.top, 8)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 12)

                    comparisonSection
                        .padding(.top, 28)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 16)

                    if subscription.isPro {
                        proActiveSection
                            .padding(.top, 36)
                    } else {
                        pricingSection
                            .padding(.top, 32)

                        purchaseButton
                            .padding(.top, 20)

                        legalFooter
                            .padding(.top, 22)
                    }

                    Spacer().frame(height: 36)
                }
                .padding(.horizontal, 22)
            }

            if isBusy {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.15)
            }
        }
        .alert("提示", isPresented: Binding(
            get: { subscription.errorMessage != nil },
            set: { if !$0 { subscription.errorMessage = nil } }
        )) {
            Button("好的", role: .cancel) {
                subscription.errorMessage = nil
            }
        } message: {
            Text(subscription.errorMessage ?? "")
        }
        .task {
            if subscription.products.isEmpty {
                await subscription.refresh()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appear = true
            }
        }
    }

    private var isBusy: Bool {
        // 仅遮罩拉商品；购买走系统支付表，不用全局 loading 盖住金额确认
        isPurchasing || subscription.isLoading
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.045)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.22, green: 0.20, blue: 0.17).opacity(0.55),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 340
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.10, green: 0.11, blue: 0.13).opacity(0.5)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Top / Hero

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Text("MIN")
                .font(.system(size: 13, weight: .semibold))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.45))

            Text(subscription.isPro ? "你已是 Pro" : "升级 Min Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text(subscription.isPro
                  ? "全部权益已解锁，感谢支持"
                  : "更多卡片 · 全部字体 · 天气小组件")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("权益对比")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(0.5)
                Spacer()
                Text("月度 · 年度相同")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.28))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, item in
                    benefitRow(
                        icon: item.icon,
                        title: item.title,
                        free: item.free,
                        pro: item.pro
                    )
                    if index < benefits.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.045))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
    }

    private func benefitRow(icon: String, title: String, free: String, pro: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.06)))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("免费")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        Text(free)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.white.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("Pro")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 0.95, green: 0.92, blue: 0.86))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 0.95, green: 0.92, blue: 0.86).opacity(0.14)))
                        Text(pro)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Already Pro

    private var proActiveSection: some View {
        VStack(spacing: 16) {
            Text("Pro 权益已全部生效")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.65))

            Button {
                dismiss()
            } label: {
                Text("继续使用")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                planCard(
                    plan: .monthly,
                    title: "月度",
                    price: displayPrice(for: .monthly, fallback: "¥12"),
                    subtitle: "按月续订",
                    badge: nil
                )
                legalLink("隐私政策", url: privacyPolicyURL, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                planCard(
                    plan: .annual,
                    title: "年度",
                    price: displayPrice(for: .annual, fallback: "¥108"),
                    subtitle: "约 ¥9 / 月",
                    badge: "更划算"
                )
                legalLink("用户协议", url: termsOfServiceURL, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func legalLink(_ title: String, url: URL?, alignment: Alignment) -> some View {
        Button(title) {
            if let url { openURL(url) }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.white.opacity(0.42))
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.horizontal, 16)
        .buttonStyle(.plain)
    }

    private func displayPrice(for plan: Plan, fallback: String) -> String {
        if let product = subscription.product(id: plan.productID) {
            return product.displayPrice
        }
        return fallback
    }

    private func planCard(
        plan: Plan,
        title: String,
        price: String,
        subtitle: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            HapticFeedbackHelper.shared.selection()
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 0.12, green: 0.11, blue: 0.10))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color(red: 0.95, green: 0.92, blue: 0.86))
                            )
                    }
                }

                Text(price)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.38))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.09 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color(red: 0.95, green: 0.92, blue: 0.86).opacity(0.7)
                            : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Purchase

    private var purchaseButton: some View {
        Button {
            Task { await purchaseSelected() }
        } label: {
            Text(selectedPlan == .annual ? "开通年度 Pro" : "开通月度 Pro")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isBusy)
    }

    private var legalFooter: some View {
        Text("订阅到期前24小时内自动续订，可在系统设置中取消")
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.32))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity)
    }

    private func purchaseSelected() async {
        guard let product = subscription.product(id: selectedPlan.productID) else {
            await subscription.refresh()
            if subscription.product(id: selectedPlan.productID) == nil {
                subscription.errorMessage = "暂时无法加载订阅商品，请稍后重试。"
            }
            return
        }

        let ok = await subscription.purchase(product)
        guard ok, subscription.isPro else { return }

        isPurchasing = true
        HapticFeedbackHelper.shared.success()
        isPurchasing = false
        dismiss()
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
