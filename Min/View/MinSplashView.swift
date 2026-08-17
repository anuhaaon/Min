//
//  MinSplashView.swift
//  Min
//
//  首次启动引导：左右横滑；插画贴近真实桌面小组件
//

import SwiftUI

// MARK: - Model

private struct MinIntroPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let kind: Kind

    enum Kind {
        case cards
        case topWidget
        case style
    }
}

private let minIntroPages: [MinIntroPage] = [
    .init(
        title: "分组直达",
        subtitle: "常用 App 排成一组。一点即开。",
        kind: .cards
    ),
    .init(
        title: "顶部小组件",
        subtitle: "日期、时间或天气，显示在分组上方。",
        kind: .topWidget
    ),
    .init(
        title: "桌面风格",
        subtitle: "换一种字体，主屏幕就换一种气质。",
        kind: .style
    )
]

private let minIntroAppNames = ["微信", "短信", "电话", "地图"]

private struct MinIntroFontSample: Identifiable {
    let id: String
    let label: String
    let design: Design

    enum Design {
        case system(Font.Design, Font.Weight)
        case custom(String)
    }

    func font(size: CGFloat) -> Font {
        switch design {
        case .system(let design, let weight):
            return .system(size: size, weight: weight, design: design)
        case .custom(let name):
            return .custom(name, size: size)
        }
    }
}

private let minIntroFonts: [MinIntroFontSample] = [
    .init(id: "serif", label: "衬线", design: .system(.serif, .regular)),
    .init(id: "didot", label: "Didot", design: .custom("Didot")),
    .init(id: "rounded", label: "圆体", design: .system(.rounded, .regular)),
    .init(id: "light", label: "细体", design: .system(.default, .ultraLight))
]

private enum MinIntroTopKind: Int, CaseIterable, Identifiable {
    case time, date, weather
    var id: Int { rawValue }
}

// MARK: - Root Splash

struct MinSplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentIndex = 0
    @State private var isFinishing = false
    @State private var heroVisible = false
    @State private var taglineVisible = false

    private var lastIndex: Int { minIntroPages.count }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == lastIndex }

    private var pageSpring: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .interactiveSpring(response: 0.9, dampingFraction: 0.8, blendDuration: 0.5)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            pages
            navBar
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: playLandingFade)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: Pages

    private var pages: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                landingView(size: size, index: 0)

                ForEach(minIntroPages.indices, id: \.self) { index in
                    pageView(size: size, index: index)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(swipeGesture(width: size.width))
            .clipped()
            .overlay(alignment: .bottom) {
                nextControl(width: size.width)
                    .padding(.bottom, 36)
                    .opacity(isFirst ? (taglineVisible ? 1 : 0) : 1)
            }
        }
    }

    private func landingView(size: CGSize, index: Int) -> some View {
        let dx = -size.width * CGFloat(currentIndex - index)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Text("Min")
                    .font(.system(size: 72, weight: .medium))
                    .tracking(heroVisible ? 6 : 14)
                    .foregroundStyle(.white)
                    .opacity(heroVisible ? 1 : 0)
                    .blur(radius: heroVisible ? 0 : 8)
                    .scaleEffect(heroVisible ? 1 : 0.96)

                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 28, height: 0.5)
                    .padding(.top, 28)
                    .opacity(taglineVisible ? 1 : 0)

                Text("极简桌面，触手可及")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.top, 18)
                    .opacity(taglineVisible ? 1 : 0)
                    .blur(radius: taglineVisible ? 0 : 6)
            }
            .offset(x: dx)
            .animation(pageSpring, value: currentIndex)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 120)
        .allowsHitTesting(currentIndex == index)
    }

    private func pageView(size: CGSize, index: Int) -> some View {
        let page = minIntroPages[index]
        let pageIndex = index + 1
        let dx = -size.width * CGFloat(currentIndex - pageIndex)
        let active = currentIndex == pageIndex

        return VStack(spacing: 0) {
            Text(page.title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: dx)
                .animation(pageSpring.delay(active ? 0.12 : 0), value: currentIndex)

            Text(page.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)
                .offset(x: dx)
                .animation(pageSpring.delay(0.08).delay(active ? 0.12 : 0), value: currentIndex)

            Spacer(minLength: 28)

            MinIntroIllustration(kind: page.kind, isActive: active)
                .frame(maxWidth: 320)
                .frame(height: illustrationHeight(for: page.kind, in: size))
                .padding(.horizontal, 28)
                .offset(x: dx)
                .animation(
                    pageSpring.delay(active ? 0 : 0.12).delay(active ? 0.12 : 0),
                    value: currentIndex
                )

            Spacer(minLength: 12)
        }
        .padding(.top, 96)
        .padding(.bottom, 120)
        .allowsHitTesting(active)
    }

    private func illustrationHeight(for kind: MinIntroPage.Kind, in size: CGSize) -> CGFloat {
        switch kind {
        case .cards:
            return min(size.height * 0.42, 300)
        case .topWidget:
            return 176
        case .style:
            return 150
        }
    }

    private func nextControl(width: CGFloat) -> some View {
        Button {
            advance()
        } label: {
            ZStack {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .scaleEffect(!isFirst && !isLast ? 1 : 0.001)
                    .opacity(!isFirst && !isLast ? 1 : 0)

                Text("开始了解")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .scaleEffect(isFirst ? 1 : 0.001)
                    .opacity(isFirst ? 1 : 0)

                HStack(spacing: 8) {
                    Text("开始使用")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .scaleEffect(isLast ? 1 : 0.001)
                .opacity(isLast ? 1 : 0)
            }
            .frame(
                width: (isFirst || isLast) ? width / 1.55 : 55,
                height: (isFirst || isLast) ? 52 : 55
            )
            .background {
                RoundedRectangle(
                    cornerRadius: (isFirst || isLast) ? 16 : 28,
                    style: (isFirst || isLast) ? .continuous : .circular
                )
                .fill(Color.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(isFinishing)
        .animation(pageSpring, value: currentIndex)
        .accessibilityLabel(isLast ? "开始使用" : (isFirst ? "开始探索" : "下一页"))
    }

    // MARK: Nav

    private var navBar: some View {
        HStack {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .modifier(MinGlassChipIfAvailable())
            }
            .buttonStyle(.plain)
            .opacity(isFirst || isLast ? 0 : 1)
            .allowsHitTesting(!isFirst && !isLast)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeOut(duration: 0.2), value: currentIndex)
    }

    // MARK: Actions

    private func playLandingFade() {
        if reduceMotion {
            heroVisible = true
            taglineVisible = true
            return
        }
        withAnimation(.easeOut(duration: 1.15).delay(0.12)) {
            heroVisible = true
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.55)) {
            taglineVisible = true
        }
    }

    private func swipeGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width
                let delta = abs(predicted) > abs(dx) ? predicted : dx
                guard abs(delta) > width * 0.12 else { return }
                if delta < 0 {
                    goForward()
                } else {
                    goBack()
                }
            }
    }

    private func advance() {
        if isLast {
            finish()
        } else {
            goForward()
        }
    }

    private func goForward() {
        guard currentIndex < lastIndex else { return }
        withAnimation(pageSpring) {
            currentIndex += 1
        }
    }

    private func finish() {
        guard !isFinishing else { return }
        isFinishing = true
        onFinished()
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        withAnimation(pageSpring) {
            currentIndex -= 1
        }
    }
}

// MARK: - iOS 26 Glass helpers

private struct MinGlassChipIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Widget chrome

private struct MinIntroWidgetFrame<Content: View>: View {
    var corner: CGFloat = 20
    var alignment: Alignment = .center
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.6)
            )
    }
}

private struct MinIntroProgressMarks: View {
    let count: Int
    let index: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(i == index ? 0.9 : 0.2))
                    .frame(width: i == index ? 16 : 5, height: 5)
                    .onTapGesture { onSelect(i) }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: index)
        .accessibilityHidden(true)
    }
}

// MARK: - Illustrations

private struct MinIntroIllustration: View {
    let kind: MinIntroPage.Kind
    let isActive: Bool

    var body: some View {
        switch kind {
        case .cards:
            MinIntroCardsArt()
        case .topWidget:
            MinIntroTopWidgetArt(isActive: isActive)
        case .style:
            MinIntroStyleArt(isActive: isActive)
        }
    }
}

private struct MinIntroCardsArt: View {
    var body: some View {
        MinIntroWidgetFrame(alignment: .center) {
            VStack(spacing: 20) {
                ForEach(minIntroAppNames, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
        }
    }
}

private struct MinIntroTopWidgetArt: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var kind: MinIntroTopKind = .time

    var body: some View {
        VStack(spacing: 18) {
            MinIntroWidgetFrame(alignment: .center) {
                Group {
                    switch kind {
                    case .time:
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(Self.timeString(from: context.date))
                                .font(.system(size: 46, weight: .regular))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        }
                    case .date:
                        Text(Self.dateString())
                            .font(.system(size: 46, weight: .regular))
                            .foregroundStyle(.white)
                    case .weather:
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 36, weight: .medium))
                                .symbolRenderingMode(.monochrome)
                            Spacer(minLength: 0)
                            Text("16°")
                                .font(.system(size: 32, weight: .regular))
                                .monospacedDigit()
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                    }
                }
                .id(kind)
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 132)

            MinIntroProgressMarks(count: MinIntroTopKind.allCases.count, index: kind.rawValue) { i in
                guard let next = MinIntroTopKind(rawValue: i) else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    kind = next
                }
            }
        }
        .task(id: isActive) {
            await cycleIfNeeded()
        }
    }

    private func cycleIfNeeded() async {
        guard isActive, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled, isActive else { return }
            let all = MinIntroTopKind.allCases
            let next = all[(kind.rawValue + 1) % all.count]
            withAnimation(.easeInOut(duration: 0.45)) {
                kind = next
            }
        }
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func dateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}

private struct MinIntroStyleArt: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fontIndex = 0

    private var sample: MinIntroFontSample {
        minIntroFonts[fontIndex]
    }

    var body: some View {
        VStack(spacing: 22) {
            Text("Min")
                .font(sample.font(size: 64))
                .foregroundStyle(.white)
                .id(sample.id)
                .transition(.opacity)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(sample.label)
                .font(.system(size: 12, weight: .regular))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.32))
                .id("label-\(sample.id)")
                .transition(.opacity)

            MinIntroProgressMarks(count: minIntroFonts.count, index: fontIndex) { i in
                withAnimation(.easeInOut(duration: 0.35)) {
                    fontIndex = i
                }
            }
        }
        .task(id: isActive) {
            await cycleIfNeeded()
        }
    }

    private func cycleIfNeeded() async {
        guard isActive, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled, isActive else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                fontIndex = (fontIndex + 1) % minIntroFonts.count
            }
        }
    }
}

// MARK: - Root Gate

struct MinRootView: View {
    @AppStorage("hasSeenBrandSplash") private var hasSeenBrandSplash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            MainTabView()

            if !hasSeenBrandSplash {
                MinSplashView(onFinished: dismissSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.45),
            value: hasSeenBrandSplash
        )
    }

    private func dismissSplash() {
        hasSeenBrandSplash = true
    }
}

#Preview("Intro Flow") {
    MinSplashView(onFinished: {})
}
