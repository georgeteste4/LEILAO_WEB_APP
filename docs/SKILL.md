---
name: "universal-frontend-design-system"
description: "Design System universal de engenharia de frontend corporativo e UI/UX de alta precisão para qualquer nicho (SaaS, Dashboards, E-commerce, FinTech, DevTools, Marketplaces e Plataformas de Dados). Focado em sobriedade visual, zero clichês de IA (sem tons roxos saturados, sem emojis em botões/menus), tipografia calibrada com alinhamento tabular, seletores rápidos por teclado (Command-Style), e arquitetura de componentes de alta performance."
version: 2.0.0
category: frontend
tags:
  - design-system
  - frontend
  - ui-ux
  - tailwindcss
  - corporate-ui
  - saas
  - universal
---

# 🏛️ Universal Frontend Design System — Guidelines & Architecture

O **Universal Frontend Design System** é uma especificação arquitetural completa de engenharia de interface e design de produto. Projetado para ser **independente de nicho**, ele fornece diretrizes, tokens semânticos e componentes reutilizáveis para qualquer tipo de aplicação web moderna (SaaS B2B, Painéis Administrativos, Plataformas Financeiras, Marketplaces, DevTools, E-commerce e Sistemas Operacionais Web).

O sistema prioriza **autenticidade visual, alta densidade de informação, navegação fluida por teclado e zero artefatos artificiais gerados por IA**.

---

## 🎯 1. Princípios Universais de Design (Anti-AI Slop)

### 1.1. Autenticidade e Sobriedade Visual
* **Eliminação de Roxos / Violetas Genéricos**: Interfaces geradas por IA frequentemente convergem para gradientes roxos saturados. O sistema utiliza uma paleta semântica ancorada em neutros estruturais (ardósia, grafite, cinza neutro) com acentos intencionais (azul naval corporativo, esmeralda funcional, coral/rose para destaques e âmbar para alertas).
* **Eliminação de Emojis em Botões e Menus**: Emojis em botões e títulos degradam a percepção de seriedade do produto. Toda iconografia deve usar **vetores SVG monocromáticos e nítidos** (espessura de traço de `1.5` ou `2px`, alinhados verticalmente).
* **Tipografia Não-Clichê**: Evitar o uso automático das 3 ou 4 fontes mais saturadas por IA (`Inter`, `Roboto`, `Geist`, `Plus Jakarta`). Utilizar famílias autênticas com excelente ritmo de leitura como **`Manrope`**, **`Albert Sans`** ou fontes de sistema (`-apple-system`, `Segoe UI`), sempre combinadas com **`JetBrains Mono`** para dados numéricos.

### 1.2. Densidade e Clareza de Informação
* **Alinhamento Numérico Tabular (`tabular-nums`)**: Qualquer número, preço, métrica, data ou percentual deve utilizar fontes monoespaçadas com alinhamento tabular, permitindo escaneabilidade instantânea.
* **Hierarquia por Contraste e Tipografia**: Diferenciar títulos, labels e dados por peso (`font-semibold`, `font-medium`), tamanho e opacidade (`opacity-60`, `opacity-75`), em vez de adicionar bordas ou cores gritantes em excesso.

---

## 🎨 2. Tokens Semânticos Universais

### 2.1. Variáveis de Superfície e Contraste
```css
/* Modo Claro (Light Mode) */
--bg-canvas: #f8fafc;       /* Fundo principal da página (Slate 50) */
--bg-surface: #ffffff;      /* Superfície de cartões, tabelas e modais */
--border-subtle: #e2e8f0;   /* Bordas estruturais de 1px (Slate 200) */
--text-main: #0f172a;       /* Texto principal de alto contraste (Slate 900) */
--text-muted: #64748b;      /* Texto secundário e legendas (Slate 500) */

/* Modo Escuro (Dark Mode) */
--bg-canvas: #090d16;       /* Fundo escuro profundo de alto conforto */
--bg-surface: #0f172a;      /* Superfície de cartões e painéis (Slate 900) */
--border-subtle: #1e293b;   /* Bordas sutis em superfícies escuras (Slate 800) */
--text-main: #f8fafc;       /* Texto principal legível (Slate 50) */
--text-muted: #94a3b8;      /* Texto secundário em modo escuro (Slate 400) */

/* Acentos Funcionais Universais */
--color-brand: #0284c7;     /* Ação primária, links e foco (Sky 600) */
--color-success: #059669;   /* Confirmação, valores positivos, ativo (Emerald 600) */
--color-danger: #e11d48;    /* Descontos, alertas críticos, remoção (Rose 600) */
--color-warning: #d97706;   /* Prazos, atenção, pendências (Amber 600) */
```

### 2.2. Escala Tipográfica Padronizada
* **Corpo e Interface**: `'Manrope', -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`
  * Tracking de interface: `letter-spacing: -0.011em;`
* **Números, Métricas e Código**: `'JetBrains Mono', ui-monospace, monospace`
  * Classe padrão: `tabular-nums font-mono`

---

## 🧩 3. Arquitetura de Componentes Universais

### 3.1. Header & Barra de Comando (`Ctrl+K` / `Cmd+K`)
Barra de topo fixa com logo minimalista, atalho de teclado global para busca e controles de sistema:

```html
<header class="bg-base-100/90 border-b border-base-300 px-4 lg:px-8 py-3 sticky top-0 z-40 backdrop-blur-md">
    <div class="max-w-7xl mx-auto flex items-center justify-between gap-4">
        <!-- Logo da Aplicação -->
        <a href="/" class="flex items-center gap-2.5 font-bold text-base tracking-tight text-base-content">
            <div class="w-7 h-7 rounded-lg bg-neutral-900 dark:bg-white text-white dark:text-neutral-900 flex items-center justify-center font-black text-xs">
                A
            </div>
            <span>Nome da Aplicação</span>
        </a>

        <!-- Atalho de Busca Command Palette -->
        <button class="btn btn-xs btn-ghost gap-2 font-normal text-xs border border-base-300 text-base-content/70 hover:bg-base-200 px-3 h-8 rounded-lg" onclick="focusSearch()">
            <svg class="w-3.5 h-3.5 opacity-60" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
            <span>Buscar...</span>
            <kbd class="kbd kbd-xs py-0.5 px-1.5 text-[10px] font-mono opacity-50 bg-base-200 border-base-300">Ctrl K</kbd>
        </button>
    </div>
</header>
```

---

### 3.2. Seletor de Alta Velocidade (Fast Keyboard Combobox)
Padrão definitivo para seleção simples ou múltipla em listas grandes (cidades, categorias, tags, usuários):

1. **Auto-Foco**: Ao abrir o dropdown, focar o input imediatamente (`input.focus()`).
2. **Atalho `Enter`**: Pressionar Enter seleciona a primeira opção filtrada e limpa o campo para digitar a próxima.
3. **Highlight em Tempo Real**: Destacar o termo digitado com `<span class="font-bold underline text-primary">`.
4. **Chips Selecionados no Topo**: Exibir itens já selecionados no topo do popover com botão `✕` para remoção rápida.
5. **Sugestões Rápidas**: Atalhos de 1 clique para os itens mais frequentes.

---

### 3.3. Cards de Entidade com Destaques Visuais
Estrutura adaptável para produtos, imóveis, ativos, serviços ou usuários:

```html
<article class="app-card overflow-hidden flex flex-col justify-between group">
    <div>
        <!-- Imagem ou Preview com Badges Sobrepostos -->
        <div class="relative h-44 w-full overflow-hidden bg-neutral-100 dark:bg-neutral-900 cursor-pointer">
            <img src="..." alt="Item" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
            
            <!-- Badge de Destaque -->
            <div class="absolute top-2.5 right-2.5 bg-rose-600 text-white font-mono font-extrabold text-xs px-2.5 py-1 rounded shadow-md">
                -54% OFF
            </div>

            <!-- Categoria / Tag -->
            <span class="absolute bottom-2.5 left-2.5 app-tag bg-base-100/90 text-base-content backdrop-blur-sm font-medium">
                Categoria
            </span>
        </div>

        <!-- Metadados e Título -->
        <div class="p-3.5 space-y-2">
            <div class="flex items-center justify-between text-[11px] opacity-70">
                <span class="font-semibold text-primary">Subtítulo / Região</span>
                <span class="opacity-80">Status</span>
            </div>

            <h3 class="font-semibold text-xs leading-snug line-clamp-2 hover:text-primary cursor-pointer transition-colors">
                Título Principal da Entidade com Até Duas Linhas
            </h3>

            <div class="text-[11px] opacity-60 line-clamp-1">
                Descrição secundária ou metadados de suporte
            </div>
        </div>
    </div>

    <!-- Rodapé Financeiro / Ações -->
    <div class="p-3.5 pt-0 mt-auto">
        <div class="border-t border-base-200 pt-2.5 flex items-end justify-between">
            <div>
                <div class="text-[10px] opacity-50 uppercase tracking-wider font-semibold">Valor Principal</div>
                <div class="font-mono font-bold text-base text-emerald-600 dark:text-emerald-400 tabular-nums">
                    R$ 146.000,00
                </div>
            </div>
            <button class="btn btn-xs btn-neutral font-medium text-[11px] rounded px-3">
                Visualizar
            </button>
        </div>
    </div>
</article>
```

---

### 3.4. Tabela de Banco de Dados Corporativa
Visualização tabular de alta densidade com paginação, colunas fixas e alinhamento numérico:

* **Colunas de Texto**: Alinhamento à esquerda (`text-left`).
* **Colunas Numéricas / Moeda / Métricas**: Alinhamento à direita (`text-right tabular-nums font-mono`).
* **Badges e Status**: Alinhamento centralizado (`text-center`).
* **Ações**: Alinhamento à direita (`text-right`).

---

### 3.5. Modal / Slide-Over de Detalhes (Zero Delay Pattern)
* **Regra de Ouro**: **Nunca exibir tela branca ou spinner vazio ao abrir um modal.**
* Ao clicar no item, preencher imediatamente o modal com os dados disponíveis no cache/objeto local (foto, título, resumo financeiro, tags).
* Caso existam dados assíncronos complementares a carregar, exibir skeleton loader apenas nos campos específicos, mantendo a interface interativa.

---

## 📐 4. Grid de Três Modos de Exibição

Qualquer catálogo ou listagem do sistema oferece 3 modos de visualização acessíveis por 1 clique no topo:
1. **Grade (Cards)**: Ideal para exploração visual e itens ricos em mídia.
2. **Tabela**: Ideal para auditoria rápida, comparação lado a lado e ordenação por colunas.
3. **Lista Compacta**: Ideal para varredura rápida e alta produtividade em telas menores ou fluxos de trabalho densos.

---

## ⚡ 5. Validação de Conformidade

O design system deve sempre manter conformidade mecânica de 0 antipadrões:
```bash
node detect.mjs --json <arquivos-html-ou-jsx>
# Resultado: [] (100% limpo)
```
