# GabeKit

Componentes SwiftUI reutilizáveis entre os apps do Gabe. Cada componente é um
produto do pacote; o app importa só o que usa.

| Produto | O que é | Usado em |
| --- | --- | --- |
| `LiquidGlassPicker` | Seletor em cápsula de Liquid Glass com a opção escolhida no centro (nasceu no seletor de meses do Cashola) | Cashola, Pagr |

## LiquidGlassPicker: escolher o modo

O `mode:` é obrigatório. Escolha pelo tipo de lista, não pela aparência:

| Lista | Modo | Exemplos |
| --- | --- | --- |
| Fechada e curta (2–4 opções que cabem na largura) | `.fixed` | Semana / Mês / Ano; Entradas / Saídas |
| Sequência contínua, só a vizinhança importa | `.scrolling` | Mês anterior / atual / seguinte |

- `.fixed` divide a cápsula em partes iguais e o chip desliza até a opção
  tocada. Nada sai pelas bordas.
- `.scrolling` mantém a escolhida no centro. Passe só a janela em volta dela
  e recalcule a cada escolha; com uma lista fixa e curta ele deixa a cápsula
  vazia de um lado. Só ele recolhe (`.scrolling(isCollapsed:onExpand:)`).

## Usar num app

- XcodeGen (`project.yml`): `packages: GabeKit: path: ../GabeKit` e, no
  target, `- package: GabeKit` com `product: LiquidGlassPicker`.
- Projeto Xcode: File › Add Package Dependencies › Add Local… e escolher esta
  pasta.

Componente novo: pasta em `Sources/<Produto>/`, `.library` e `.target` no
`Package.swift`, tipos e inits `public`, e nenhuma dependência de um app
(cores, fontes e modos de desempenho entram como parâmetros).

## Testes

```
xcodebuild -scheme GabeKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```
