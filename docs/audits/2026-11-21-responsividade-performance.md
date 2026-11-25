# Auditoria de responsividade e performance — 2026-11-21

Checkpoint antes das mudanças: `backups/skill_suap-pre-responsividade-2026-11-21.zip`.
Linha de base: `dart format` sem mudanças, `flutter analyze` sem achados, 192 testes passando.
Final: `dart format` sem mudanças, `flutter analyze` sem achados, **269 testes passando**.

## Telas auditadas
Rotas: Match (discover), Comunidade, Conversas, Perfil, Editar perfil / Cadastro inicial, Chat, Nova publicação, Editar publicação, Busca, Salvos, Notificações, Detalhe do post, Perfil de membro, Seguidores, Seguindo, Termos, Consentimento, Login, Splash.
Modais: menu do post (meu / de outro), excluir post, bloquear, denúncia de post / comentário / membro, compartilhar, menu do comentário, excluir comentário, menu do membro, menu do chat, detalhes do perfil (Match).

## Método
- `test/responsive_matrix_test.dart`: todas as rotas em 11 viewports (320×568, 360×640, 375×667, 390×844, 412×915, 430×932, 600×960, 768×1024, 1024×1366, paisagem 640×360 e 915×412) × texto 100/130/200 %, rolando cada lista até o fim; celular com notch em paisagem (932×430, insets 47/47/21); modais em 5 tamanhos × 100/200 %, conferindo que abrem e para onde levam; login, cadastro e consentimento com e sem teclado; telas com campo de texto com teclado aberto; diretrizes de acessibilidade (48 dp, rótulos, contraste) em 412×915/100 % e 360×640/130 %.
- Capturas renderizadas com Roboto em 6 configurações (inspeção visual de recortes silenciosos).
- Emulador Pixel 8 (API 36, renderização por software), fonte do sistema 100 % e 200 %.

## Problemas encontrados e corrigidos
| # | Gravidade | Problema | Correção |
|---|---|---|---|
| 1 | Alta | Menus de post e membro estouravam até 307 px (texto grande, paisagem) | `showActionSheet` rolável e compartilhado (3 cópias removidas) |
| 2 | Alta | AppBar de Notificações estourava até 175 px com texto ≥ 130 % | Ícone com tooltip quando largura/escala < 300 dp |
| 3 | Média | Menu do chat estourava 171 px a 200 % | Rótulo `Flexible` |
| 4 | Média | Linha "Responder" do comentário estourava 60 px (320 dp, 200 %) | `Align` em vez de `Row` |
| 5 | Média | Tablets: conteúdo esticado até ~1000 px | `ContentWidth` (coluna de 720 dp) em 15 telas |
| 6 | Média | Barra inferior: cada rótulo encolhia sozinho (alguns menores que 100 %) | Escala única medida, mínimo 100 % |
| 7 | Média | Perfil: nome quebrava no meio da palavra | Cabeçalho mede a palavra mais longa e empilha se preciso |
| 8 | Média | "Minhas publicações" quebrava palavra; estatísticas coladas | `AdaptiveButtonRow`; respiro nas estatísticas |
| 9 | Média | Match sem foto: iniciais decorativas cresciam com a fonte e cobriam nome/bio (contraste 2,3:1) | Iniciais sem escala de texto, tamanho pela altura do card |
| 10 | Baixa | Balões do chat calculados pela tela inteira em tablets | Largura relativa à coluna |

Correções da revisão (code-reviewer): `ContentWidth` mantém a mesma árvore em qualquer largura (girar não perde foco/rolagem); insets de notch somados à margem; sem `!` novo; medição da barra com o estilo real e texto em negrito do sistema; barra de progresso do compositor em largura total; testes de modais verificam o resultado.

## Código
- Novo: `lib/core/utils/person_name.dart` (`PersonName`), `ContentWidth`, `AdaptiveButtonRow`, `showActionSheet` em `app_widgets.dart`.
- Duplicação removida: 5 extrações de nome com `RegExp` recompilada a cada build; 3 folhas de ações escritas à mão.
- `DateFormat` do chat em cache por locale (antes, um por balão a cada build).

## Performance
- Sem gargalos comprovados encontrados: listas grandes já usam builders/slivers e paginação; imagens de post e avatares já decodificam no tamanho exibido (`cacheWidth`); miniaturas ≤ 320 px; o painel de vidro com `BackdropFilter` não é usado em listas; controllers e listeners têm `dispose`.
- **Sem métricas antes/depois**: o emulador usa SwiftShader (software), então FPS e tempo de frame não são representativos; não há aparelho físico conectado. Recomenda-se `flutter run --profile` + DevTools num Android real.

## Limitações e pendências
- Em tablets, as margens laterais do `ContentWidth` não rolam a lista (o limite está fora do scroll view); corrigir exige padding dentro de cada lista.
- Match com altura < 500 dp (paisagem, texto 200 % em 320×568): os botões ficam abaixo do card, alcançáveis rolando — decisão de design anterior, mantida; o card também aceita deslizar.
- O verificador de contraste acusa falso positivo no rótulo selecionado da barra (amostra o brilho neon); filtrado no teste com justificativa.
- Testes usam a fonte Ahem (1 em por glifo), mais pessimista que a Roboto; layouts por medição foram conferidos também em captura com Roboto e no emulador.
- iOS não verificado (requer Mac).
