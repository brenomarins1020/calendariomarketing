# 📅 Calendário de Marketing

Calendário simples de publicações por canal, com sincronização **ao vivo** entre dispositivos.

- Coluna fixa com os canais (você cria, renomeia, reordena e remove)
- Todos os dias do mês no topo, com divisão por semanas (segunda a domingo)
- Botão **+** em cada dia → nome do post + responsável
- Arraste posts entre dias e canais (segure **Ctrl** ao soltar para duplicar)
- Clique e arraste o fundo do calendário para rolar para os lados
- Seção **Responsáveis**: cadastre as pessoas, escolha a cor e clique no nome para destacar os posts dela
- ✓ para marcar como publicado
- Exportar/Importar backup em JSON
- Tudo o que alguém muda aparece nos outros dispositivos em ~2–3 segundos (indicador "Ao vivo" no topo)

## Como funciona

| Arquivo | O que faz |
|---|---|
| `index.html` | O site inteiro (HTML + CSS + JS, sem build) |
| `api/state.js` | `GET` — devolve canais, responsáveis e posts |
| `api/op.js` | `POST` — grava alterações (criar, editar, mover, excluir) |
| `api/ver.js` | `GET` — número da versão; cada aba consulta a cada 2,5 s e recarrega quando muda |
| `api/_redis.js` | Cliente mínimo do Upstash Redis via REST (sem dependências) |

Os dados ficam num banco **Upstash Redis** (plano gratuito é suficiente).

## Publicar no Vercel

1. Em [vercel.com/new](https://vercel.com/new), importe este repositório.
   Não precisa mudar nada nas configurações (Framework: **Other**, sem comando de build). Clique em **Deploy**.
2. No projeto criado, vá em **Storage → Create Database → Upstash → Upstash for Redis**.
   Aceite os termos, escolha o plano **Free** e a região mais próxima (ex.: São Paulo), e **conecte ao projeto** (deixe todos os ambientes marcados).
   Isso cria automaticamente as variáveis `KV_REST_API_URL` e `KV_REST_API_TOKEN`.
3. Vá em **Deployments → ⋯ no último deploy → Redeploy** (as variáveis só valem para deploys novos).
4. Abra o site: o indicador no topo deve mostrar **"Ao vivo"**. Na primeira abertura, os canais padrão são criados automaticamente.

> Se aparecer "Sem conexão", confira se o banco está conectado ao projeto (Settings → Environment Variables deve listar `KV_REST_API_URL` e `KV_REST_API_TOKEN`) e faça o Redeploy.

## Observações

- Qualquer pessoa com o link consegue ver e editar o calendário.
- Arrastar posts funciona no computador; no celular dá para ver, adicionar e editar tocando nos posts.
