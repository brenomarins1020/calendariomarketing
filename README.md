# 📅 Calendário de Marketing

Calendário simples de publicações por canal, com contas (usuário + senha) e sincronização **ao vivo** entre dispositivos (Supabase Realtime).

- Coluna fixa com os canais (você cria, renomeia, reordena e remove)
- Todos os dias do mês no topo, com divisão por semanas (segunda a domingo)
- Botão **+** em cada dia → nome do post + responsável
- Arraste posts entre dias e canais (segure **Ctrl** ao soltar para duplicar)
- Clique e arraste o fundo do calendário para rolar para os lados
- Seção **Responsáveis**: cadastre as pessoas, escolha a cor e clique no nome para destacar os posts dela
- ✓ para marcar como publicado
- Exportar/Importar backup em JSON
- O que alguém muda aparece na hora em todos os dispositivos abertos (indicador **"Ao vivo"** no topo)

## Estrutura

| Arquivo | O que faz |
|---|---|
| `index.html` | O site inteiro (HTML + CSS + JS, sem build, sem servidor) |
| `supabase/schema.sql` | Cria as tabelas `channels`, `people` e `posts`, as permissões e o tempo real |
| `supabase/auth.sql` | Contas: cada registro ganha um dono e cada conta só vê o que é seu |

O site fala direto com o Supabase usando a chave **publishable** (pública), que fica em `index.html`.
A chave **secret** não é usada pelo site e **nunca** deve ser colocada no código.

## 1. Preparar o banco (uma vez só)

1. Abra o projeto no [Supabase](https://supabase.com/dashboard) → **SQL Editor** → **New query**.
2. Cole todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**.

Pronto: as tabelas são criadas, o tempo real é ligado e os canais iniciais são inseridos.

## 1b. Contas (usuário + senha)

Cada conta tem o seu próprio calendário (canais, responsáveis e posts).

1. No SQL Editor do Supabase, rode [`supabase/auth.sql`](supabase/auth.sql).
2. Em **Authentication → Sign In / Providers → Email**, desligue **Confirm email** e salve.

O site pede só usuário e senha. Por baixo, o usuário vira um e-mail interno (`usuario@calendariomarketing.vercel.app`) que ninguém precisa ver nem digitar.

## 2. Publicar no Vercel

1. Em [vercel.com/new](https://vercel.com/new), importe este repositório.
2. Não precisa mudar nada (Framework: **Other**, sem comando de build, sem variáveis de ambiente). Clique em **Deploy**.
3. Abra o site: o indicador no topo deve mostrar **"Ao vivo"**.

## Trocar de projeto Supabase

No `index.html`, altere as duas linhas no início do script:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';
```

## Observações

- É preciso entrar com usuário e senha; cada conta vê só o próprio calendário.
- No celular: abas embaixo, linha do tempo por dia (deslize para os lados), calendário compacto com a lista do dia e gráfico por semana.
- Se aparecer "Banco sem tabelas", rode o `supabase/schema.sql` (passo 1).
