# Família Prospera

Site para celular onde cada pessoa da família cultiva a sua árvore: Raiz (Espírito), Tronco (Corpo), Copa (Mente) e Frutos (Prosperidade), com metas trimestrais, check-in semanal e mural da família. As metas e a evolução ficam salvas no banco de dados (Supabase).

Versão de teste: sem login. Quem tem o link da família escolhe o próprio nome e usa.

Projeto independente: um projeto Supabase só dele, separado do Vitrine. Site hospedado no GitHub Pages.

## Como a família usa

1. Alguém cria a família e recebe o link (ex.: `.../familia-prospera/#K7P2QX`).
2. Manda o link no WhatsApp.
3. Cada pessoa abre, toca em **Sou novo aqui** e escreve o nome. O celular lembra quem ela é.

## Configurar o Supabase (uma vez)

1. Em https://supabase.com/dashboard, **New project** com o nome `familia-prospera`, região **South America (São Paulo)**.
2. **SQL Editor > New query**: cole todo o `banco.sql` e clique em **Run**.
3. **Project Settings > API**: copie a **Project URL** e a chave **anon public** para o `supabase-config.js`.

## Plano gratuito

- Cada conta Supabase tem 2 projetos gratuitos (Vitrine + Família Prospera cabem).
- Projetos gratuitos pausam depois de 7 dias sem acesso. Com check-in semanal, não acontece. Se pausar, reative no painel.

## Importante sobre esta versão de teste

Não tem senha: qualquer pessoa com o link da família consegue abrir e alterar o plano de qualquer membro. Compartilhe o link só com a família. Se o teste der certo, dá para adicionar um PIN por pessoa depois, sem perder os dados.
