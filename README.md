# 📅 Calendário de Marketing

Calendário simples de publicações por canal, com sincronização **ao vivo** entre dispositivos (Supabase Realtime).

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
| `supabase/whatsapp.sql` | Lembretes no WhatsApp (Z-API): coluna `phone`, agendamento diário às 13h e funções de envio |

O site fala direto com o Supabase usando a chave **publishable** (pública), que fica em `index.html`.
A chave **secret** não é usada pelo site e **nunca** deve ser colocada no código.

## 1. Preparar o banco (uma vez só)

1. Abra o projeto no [Supabase](https://supabase.com/dashboard) → **SQL Editor** → **New query**.
2. Cole todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**.

Pronto: as tabelas são criadas, o tempo real é ligado e os canais iniciais são inseridos.

## 1b. Lembretes no WhatsApp (Z-API)

Todo dia às **13h (Brasília)**, cada responsável com WhatsApp cadastrado recebe a lista dos posts dele marcados para o **dia seguinte** que ainda não foram publicados.

1. No SQL Editor do Supabase, rode [`supabase/whatsapp.sql`](supabase/whatsapp.sql).
2. Na [Z-API](https://z-api.io), crie uma instância e leia o QR Code com o WhatsApp que vai **enviar** as mensagens.
3. Cadastre as credenciais (Instance ID, Token e o Client-Token da aba Segurança):

```sql
insert into public.app_settings (key, value) values
  ('zapi_instance_id',  'SEU_INSTANCE_ID'),
  ('zapi_token',        'SEU_TOKEN'),
  ('zapi_client_token', 'SEU_CLIENT_TOKEN')
on conflict (key) do update set value = excluded.value;
```

4. No site, cadastre (ou edite no ✎) o WhatsApp de cada responsável com DDD.

Teste: `select public.mkt_whatsapp_send('11987654321', 'Teste ✅');` — e veja a resposta em `select * from net._http_response order by created desc limit 5;`

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

- Qualquer pessoa com o link consegue ver e editar o calendário.
- Arrastar posts funciona no computador; no celular dá para ver, adicionar e editar tocando nos posts.
- Se aparecer "Banco sem tabelas", rode o `supabase/schema.sql` (passo 1).
