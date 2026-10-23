import SwiftUI
import UIKit

/// Seletor numa cápsula de Liquid Glass, com a opção escolhida num chip do
/// accent. Tem dois modos, e o modo é obrigatório porque cada um só serve
/// para um tipo de lista:
///
/// - `.fixed`: poucas opções, todas sempre visíveis, dividindo a cápsula em
///   partes iguais; o chip desliza até a opção tocada. Para conjuntos
///   fechados e curtos (2–4 itens que cabem na largura): "Semana / Mês /
///   Ano", "Entradas / Saídas".
/// - `.scrolling`: a escolhida fica sempre no centro e as vizinhas saem
///   pelas bordas; tocar numa vizinha faz a fileira deslizar. Para
///   sequências contínuas em que só a vizinhança importa e as opções mudam
///   com a escolha: meses, semanas, anos. Passe só a janela em volta da
///   escolhida (ex.: mês anterior, atual e seguinte). Com uma lista fixa e
///   curta, este modo deixa a cápsula vazia de um lado — use `.fixed`.
///
/// Nasceu no seletor de meses da Início do Cashola (`HomeMonthHeader`).
public struct LiquidGlassPicker<Value: Hashable>: View {
    public struct Option {
        public let value: Value
        public let label: String

        public init(value: Value, label: String) {
            self.value = value
            self.label = label
        }
    }

    public enum Mode {
        /// Todas as opções visíveis, em partes iguais.
        case fixed
        /// Escolhida no centro, vizinhas saindo pelas bordas. Recolhido
        /// (`isCollapsed`), a cápsula encolhe até o chip escolhido e qualquer
        /// toque chama `onExpand`.
        case scrolling(isCollapsed: Bool = false, onExpand: (() -> Void)? = nil)
    }

    private let title: String
    @Binding private var selection: Value
    private let options: [Option]
    private let mode: Mode
    private let accent: Color
    private let unselectedColor: Color
    private let prefersReducedVisualEffects: Bool
    private let prefersReducedMotion: Bool?
    private let hapticFeedback: Bool
    private let onSelectedTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selectionAnimation

    private static var controlHeight: CGFloat { 44 }
    private static var chipHeight: CGFloat { 36 }
    private static var inset: CGFloat { 4 }
    private static var chipSpacing: CGFloat { 4 }
    private static var chipPadding: CGFloat { 14 }
    private static var selectedChipPadding: CGFloat { 28 }
    private static var font: UIFont { .systemFont(ofSize: 15, weight: .semibold) }
    private static var animation: Animation { .spring(response: 0.34, dampingFraction: 0.84) }

    /// - Parameters:
    ///   - title: rótulo de acessibilidade do controle.
    ///   - mode: `.fixed` para listas curtas e fechadas; `.scrolling` para
    ///     sequências contínuas (veja a documentação do tipo).
    ///   - accent: cor do chip escolhido (o texto dele é branco).
    ///   - unselectedColor: cor do texto das outras opções.
    ///   - prefersReducedVisualEffects: troca o vidro por um fundo sólido.
    ///   - prefersReducedMotion: `nil` segue o ajuste de acessibilidade.
    ///   - hapticFeedback: haptic de seleção a cada troca.
    ///   - onSelectedTap: toque na opção já escolhida (ex.: voltar ao mês atual).
    public init(
        _ title: String,
        selection: Binding<Value>,
        options: [Option],
        mode: Mode,
        accent: Color = .accentColor,
        unselectedColor: Color = .secondary,
        prefersReducedVisualEffects: Bool = false,
        prefersReducedMotion: Bool? = nil,
        hapticFeedback: Bool = true,
        onSelectedTap: (() -> Void)? = nil
    ) {
        self.title = title
        _selection = selection
        self.options = options
        self.mode = mode
        self.accent = accent
        self.unselectedColor = unselectedColor
        self.prefersReducedVisualEffects = prefersReducedVisualEffects
        self.prefersReducedMotion = prefersReducedMotion
        self.hapticFeedback = hapticFeedback
        self.onSelectedTap = onSelectedTap
    }

    private var reducesMotion: Bool {
        prefersReducedMotion ?? accessibilityReduceMotion
    }

    private var selectedIndex: Int {
        options.firstIndex { $0.value == selection } ?? 0
    }

    private var isCollapsed: Bool {
        if case .scrolling(let isCollapsed, _) = mode { return isCollapsed }
        return false
    }

    public var body: some View {
        Group {
            switch mode {
            case .fixed:
                fixedBody
            case .scrolling:
                scrollingBody
            }
        }
        .frame(height: Self.controlHeight)
        .sensoryFeedback(.selection, trigger: selection) { _, _ in hapticFeedback }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    // MARK: - Fixed

    private var fixedBody: some View {
        let selectedIndex = selectedIndex
        return HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                chip(options[index], isSelected: index == selectedIndex, fillsWidth: true)
            }
        }
        .padding(.horizontal, Self.inset)
        .frame(maxWidth: .infinity)
        .frame(height: Self.controlHeight)
        .background { background }
    }

    // MARK: - Scrolling

    private var scrollingBody: some View {
        let selectedIndex = selectedIndex
        let widths = options.indices.map { index in
            let textWidth = (options[index].label as NSString).size(withAttributes: [.font: Self.font]).width
            return ceil(textWidth) + 2 * (index == selectedIndex ? Self.selectedChipPadding : Self.chipPadding)
        }
        let offsets = LiquidGlassPickerLayout.centeredOffsets(
            widths: widths,
            selectedIndex: selectedIndex,
            spacing: Self.chipSpacing
        )

        return GeometryReader { proxy in
            let expandedWidth = proxy.size.width
            let selectedWidth = widths.indices.contains(selectedIndex) ? widths[selectedIndex] : expandedWidth
            let targetWidth = isCollapsed
                ? min(expandedWidth, selectedWidth + 2 * Self.inset)
                : expandedWidth

            ZStack {
                background

                ZStack {
                    ForEach(options.indices, id: \.self) { index in
                        chip(options[index], isSelected: index == selectedIndex, fillsWidth: false)
                            .offset(x: offsets[index])
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Self.inset)
                .clipShape(Capsule(style: .continuous))
            }
            .frame(width: targetWidth, height: Self.controlHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Capsule(style: .continuous))
            .animation(reducesMotion ? nil : Self.animation, value: isCollapsed)
        }
    }

    // MARK: - Peças

    @ViewBuilder
    private var background: some View {
        if prefersReducedVisualEffects {
            Capsule(style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
        } else {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: Capsule(style: .continuous))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.10), radius: 8, y: 3)
        }
    }

    private func chip(_ option: Option, isSelected: Bool, fillsWidth: Bool) -> some View {
        let isHidden = isCollapsed && !isSelected
        return Button {
            if case .scrolling(true, let onExpand) = mode {
                onExpand?()
            } else if isSelected {
                onSelectedTap?()
            } else {
                withAnimation(reducesMotion ? nil : Self.animation) {
                    selection = option.value
                }
            }
        } label: {
            Text(option.label)
                .font(Font(Self.font))
                .foregroundStyle(isSelected ? Color.white : unselectedColor)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .allowsTightening(true)
                .padding(.horizontal, fillsWidth ? 8 : (isSelected ? Self.selectedChipPadding : Self.chipPadding))
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(height: Self.chipHeight)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(accent)
                            .matchedGeometryEffect(id: "selected", in: selectionAnimation)
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(isHidden ? 0 : 1)
        .scaleEffect(isHidden ? 0.92 : 1)
        .allowsHitTesting(!isHidden)
        .accessibilityHidden(isHidden)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public enum LiquidGlassPickerLayout {
    /// Deslocamento horizontal de cada chip a partir do centro (modo
    /// `.scrolling`): o escolhido em 0 e os outros encostados nele,
    /// separados por `spacing`.
    public static func centeredOffsets(widths: [CGFloat], selectedIndex: Int, spacing: CGFloat) -> [CGFloat] {
        guard widths.indices.contains(selectedIndex) else {
            return Array(repeating: 0, count: widths.count)
        }
        return widths.indices.map { index in
            if index < selectedIndex {
                return (index..<selectedIndex).reduce(CGFloat.zero) { offset, current in
                    offset - widths[current] / 2 - spacing - widths[current + 1] / 2
                }
            }
            return (selectedIndex..<index).reduce(CGFloat.zero) { offset, current in
                offset + widths[current] / 2 + spacing + widths[current + 1] / 2
            }
        }
    }
}
