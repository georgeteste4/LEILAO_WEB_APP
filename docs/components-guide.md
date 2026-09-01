# 🧩 Guia de Componentes Universais — Universal Design System

Snippets de componentes HTML + Tailwind CSS agnósticos de nicho, prontos para produção.

---

## 1. Cartão de Entidade com Destaque e Métricas

```html
<article class="app-card overflow-hidden flex flex-col justify-between group">
    <div>
        <!-- Imagem com Badge Superior e Categoria -->
        <div class="relative h-44 w-full overflow-hidden bg-neutral-100 dark:bg-neutral-900 cursor-pointer">
            <img src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&auto=format&fit=crop" alt="Item" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" loading="lazy" />
            
            <div class="absolute top-2.5 right-2.5 bg-rose-600 text-white font-mono font-extrabold text-xs px-2.5 py-1 rounded shadow-md tracking-tight">
                -35% OFF
            </div>

            <span class="absolute bottom-2.5 left-2.5 app-tag bg-base-100/90 text-base-content backdrop-blur-sm font-medium">
                Categoria Principal
            </span>
        </div>

        <!-- Conteúdo Textual -->
        <div class="p-3.5 space-y-2">
            <div class="flex items-center justify-between text-[11px] opacity-70">
                <span class="font-semibold text-primary">Subtítulo / Região</span>
                <span class="opacity-80">Status Ativo</span>
            </div>

            <h3 class="font-semibold text-xs leading-snug line-clamp-2 hover:text-primary cursor-pointer transition-colors">
                Título do Item ou Serviço com Tipografia Fluida em Duas Linhas
            </h3>

            <div class="text-[11px] opacity-60 line-clamp-1">
                Descrição de suporte, localização ou resumo dos atributos principais
            </div>

            <!-- Tags Semânticas -->
            <div class="flex flex-wrap gap-1 pt-0.5">
                <span class="app-tag text-[10.5px]">Tag A</span>
                <span class="app-tag text-[10.5px]">Tag B</span>
            </div>
        </div>
    </div>

    <!-- Rodapé Financeiro / Métricas -->
    <div class="p-3.5 pt-0 mt-auto">
        <div class="border-t border-base-200 pt-2.5 space-y-1">
            <div class="flex items-center justify-between text-[10.5px]">
                <span class="opacity-50 line-through font-mono tabular-nums">R$ 1.500,00</span>
                <span class="text-rose-500 font-semibold font-mono tabular-nums">Economia: R$ 525,00</span>
            </div>

            <div class="flex items-end justify-between">
                <div>
                    <div class="text-[10px] opacity-50 uppercase tracking-wider font-semibold">Valor Final</div>
                    <div class="font-mono font-bold text-base text-emerald-600 dark:text-emerald-400 tabular-nums">
                        R$ 975,00
                    </div>
                </div>
                <button class="btn btn-xs btn-neutral font-medium text-[11px] rounded px-3">
                    Visualizar
                </button>
            </div>
        </div>
    </div>
</article>
```

---

## 2. Fast Combobox / Seletor com Atalho de Teclado (Command-Style)

```html
<div class="dropdown">
    <div tabindex="0" role="button" class="btn btn-xs btn-ghost gap-1.5 border border-base-300 font-medium h-7 rounded-md">
        <span>Filtro Selecionado (2)</span>
        <svg class="w-3 h-3 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
    </div>
    <div tabindex="0" class="dropdown-content z-30 p-3 shadow-xl bg-base-100 rounded-xl border border-base-300 w-80 sm:w-96 mt-1 space-y-2.5">
        
        <div class="flex items-center justify-between pb-1.5 border-b border-base-200 text-xs">
            <span class="font-semibold opacity-70">Opções Disponíveis</span>
            <div class="flex items-center gap-2 text-[11px]">
                <button type="button" class="text-primary hover:underline font-medium">Marcar Visíveis</button>
                <span class="opacity-30">|</span>
                <button type="button" class="opacity-60 hover:opacity-100 hover:underline">Limpar</button>
            </div>
        </div>

        <!-- Input com busca rápida -->
        <div class="relative">
            <input 
                type="text" 
                placeholder="Filtrar... (Enter para selecionar)" 
                class="input input-xs input-bordered w-full text-xs rounded-md pl-2 pr-6" 
            />
        </div>

        <!-- Tags Selecionadas no Topo -->
        <div class="flex flex-wrap gap-1 max-h-16 overflow-y-auto py-0.5">
            <span class="app-tag app-tag-accent text-[10.5px]">
                <span>Item 1</span>
                <button type="button" class="hover:opacity-75 font-bold ml-0.5">✕</button>
            </span>
        </div>

        <!-- Lista Filtrável -->
        <div class="max-h-48 overflow-y-auto space-y-0.5 text-xs pr-1 border-t border-base-200 pt-1.5">
            <label class="flex items-center gap-2 p-1.5 rounded hover:bg-base-200/80 cursor-pointer select-none">
                <input type="checkbox" checked class="checkbox checkbox-xs checkbox-primary" />
                <span class="truncate flex-1 text-[11.5px] font-normal">Opção 1</span>
            </label>
            <label class="flex items-center gap-2 p-1.5 rounded hover:bg-base-200/80 cursor-pointer select-none">
                <input type="checkbox" class="checkbox checkbox-xs checkbox-primary" />
                <span class="truncate flex-1 text-[11.5px] font-normal">Opção 2</span>
            </label>
        </div>

        <div class="flex items-center justify-between pt-1.5 border-t border-base-200 text-[11px] opacity-70">
            <span>2 selecionados</span>
            <button type="button" class="btn btn-xs btn-neutral font-medium px-2.5 rounded">
                Concluir
            </button>
        </div>

    </div>
</div>
```

---

## 3. Tabela Corporativa com Números Tabulares e Status

```html
<div class="overflow-x-auto bg-base-100 rounded-xl border border-base-300 shadow-sm">
    <table class="table table-xs table-pin-rows table-pin-cols w-full">
        <thead>
            <tr class="text-[11px] font-mono uppercase tracking-wider opacity-60 border-b border-base-300 bg-base-200/40">
                <th class="py-2.5">Nome / Identificador</th>
                <th>Categoria</th>
                <th>Origem</th>
                <th class="text-right">Valor Bruto</th>
                <th class="text-right">Valor Líquido</th>
                <th class="text-center">Status / Variação</th>
                <th>Data</th>
                <th class="text-right">Ação</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-base-200 text-xs">
            <tr class="hover:bg-base-200/40 transition-colors">
                <td class="font-medium max-w-xs truncate cursor-pointer hover:text-primary py-2.5">
                    Serviço de Infraestrutura em Nuvem
                </td>
                <td><span class="app-tag">DevOps</span></td>
                <td class="opacity-75">Global / US-East</td>
                <td class="text-right opacity-60 font-mono tabular-nums">R$ 4.200,00</td>
                <td class="text-right font-mono font-bold text-emerald-600 dark:text-emerald-400 tabular-nums">R$ 2.730,00</td>
                <td class="text-center">
                    <span class="bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/25 font-mono font-bold text-[11px] px-2 py-0.5 rounded">
                        -35%
                    </span>
                </td>
                <td class="opacity-75 text-[11px] font-mono tabular-nums">24/08/2026</td>
                <td class="text-right">
                    <button class="btn btn-xs btn-ghost border border-base-300 rounded">
                        Detalhes
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
</div>
```

---

## 4. Modal / Slide-Over com Ficha Estruturada (Zero Delay)

```html
<dialog id="item_modal" class="modal">
    <div class="modal-box max-w-2xl bg-base-100 border border-base-300 shadow-2xl rounded-xl p-6">
        <form method="dialog">
            <button class="btn btn-sm btn-circle btn-ghost absolute right-3.5 top-3.5">✕</button>
        </form>
        
        <div class="space-y-4 text-xs">
            <div>
                <h3 class="font-bold text-base text-base-content leading-snug">Nome da Entidade / Produto</h3>
                <div class="opacity-60 text-[11px] mt-0.5">Informações e Ficha Técnica Completa</div>
            </div>

            <!-- Resumo em Grade de 4 Colunas -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 bg-base-200/50 p-3 rounded-lg border border-base-300 text-center">
                <div class="p-1">
                    <div class="text-[10px] uppercase font-semibold opacity-60">Referência</div>
                    <div class="font-mono font-semibold text-xs opacity-75 tabular-nums mt-0.5">R$ 1.500,00</div>
                </div>
                <div class="p-1 border-l border-base-300">
                    <div class="text-[10px] uppercase font-semibold opacity-60">Atual</div>
                    <div class="font-mono font-bold text-sm text-emerald-600 dark:text-emerald-400 tabular-nums mt-0.5">R$ 975,00</div>
                </div>
                <div class="p-1 border-l border-base-300">
                    <div class="text-[10px] uppercase font-semibold opacity-60">Variação</div>
                    <div class="font-mono font-bold text-xs text-rose-500 tabular-nums mt-0.5">-35%</div>
                </div>
                <div class="p-1 border-l border-base-300">
                    <div class="text-[10px] uppercase font-semibold opacity-60">Diferença</div>
                    <div class="font-mono font-bold text-xs text-emerald-600 dark:text-emerald-400 tabular-nums mt-0.5">R$ 525,00</div>
                </div>
            </div>

            <!-- Tabela Estruturada de Metadados -->
            <div class="bg-base-100 rounded-lg border border-base-300 divide-y divide-base-200">
                <div class="grid grid-cols-3 p-2.5">
                    <span class="opacity-60 font-medium">Categoria</span>
                    <span class="col-span-2 font-semibold">Tecnologia & Cloud</span>
                </div>
                <div class="grid grid-cols-3 p-2.5">
                    <span class="opacity-60 font-medium">Última Atualização</span>
                    <span class="col-span-2 font-mono font-medium tabular-nums">24/08/2026 19:10</span>
                </div>
            </div>

            <div class="pt-2">
                <button class="btn btn-xs btn-neutral w-full font-medium h-8 rounded-lg">
                    Ação Principal
                </button>
            </div>
        </div>
    </div>
</dialog>
```
